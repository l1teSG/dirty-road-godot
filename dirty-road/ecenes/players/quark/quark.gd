extends Player

# ══════════════════════════════════════════════════════════
#  JUGADOR (Quark) — núcleo: movimiento, disparo, vida.
#
#  Lógica separada en componentes (se crean por código en _ready):
#  • DashComponent       → estado del dash e i-frames
#  • AnimacionQuark      → pulso, squash, sombra, flash, feedback de dash
#  • EfectoRegeneracion  → barra/partículas/luces al regenerar
#  • FlechaArbol         → flecha que apunta al árbol
#  • SuperMeteoritos     → super de lluvia de meteoritos
#  • ContadorRespawn     → cuenta regresiva en UI
#  • SelectorObjetivo    → enemigo más cercano en rango
#  • EnemigosUtil        → grupos de enemigos y contrato de daño
#
#  CONTRATO: el nodo está en el grupo 'jugador'; los enemigos nuevos
#  dañan con recibir_danio(cantidad).
#  BALANCE (oleada 1): DPS base ≈ 17 (10 de daño / 0.6 s), +5% por
#  críticos. Daños de referencia: micro 2, nube 4, petróleo 8, jefe
#  12-19 contra 100 HP + regeneración 2 HP/s tras 5 s + i-frames de dash.
# ══════════════════════════════════════════════════════════

const ACC_IZQ := "ui_left"
const ACC_DER := "ui_right"
const ACC_ARR := "ui_up"
const ACC_ABA := "ui_down"
const ACC_DEBUG_KILL := "debug_kill"

# ── Nodos ─────────────────────────────────────────────
@onready var rangeArea = $Area2D/range
@onready var aim: Node2D = $aim
@onready var nucleo: Polygon2D = $Nucleo
@onready var cuerpo: Polygon2D = $body
@onready var body_interior: Polygon2D = $body/bodyInterior
@onready var luz_base: PointLight2D = $LuzBase
@onready var luz_punta: PointLight2D = $LuzPunta
@onready var sombra: Polygon2D = $sombra
@onready var colision: CollisionShape2D = $Collision
@onready var barra_vida: ProgressBar = $ui/margenUi/ContenedorVertical/FilaVida/BarraVida
@onready var contador_respawn: Label = $ui/ContadorRespawn
@onready var ui_contenedor: Node = $ui/margenUi
@onready var controles: CanvasLayer = $controls
@onready var timer_disparo: Timer = $Timer
@onready var pausa = get_node_or_null("Pausa")

const JOYSTICK_APUNTADO := preload("res://ecenes/players/quark/joystick_apuntado.gd")
const DRON := preload("res://ecenes/players/quark/dron.gd")
## Joystick de apuntado (solo modo disparo manual).
var _apuntado = null
## Dron compañero (carta "Dron Conservacionista").
var _dron = null
## Escala base del HUD definida en la escena (para no acumular el ajuste hud_escala).
var _hud_base_listo: bool = false
var _base_escala_botones: Vector2 = Vector2.ONE
var _base_escala_joystick: Vector2 = Vector2.ONE

# ── Disparo ───────────────────────────────────────────
var proyectil: PackedScene = preload("res://ecenes/players/projectile/quark/playerProyectil.tscn")
var onFire: bool = false
var enemi: Node2D = null

@export_category("Cadencia de Disparo")
## Segundos entre disparos. Con danio_disparo 10 → DPS ≈ 16.7.
@export var cadencia_basic: float = 0.6

@export_category("Estadísticas de Combate")
## Referencia: microplástico 8 HP (1 tiro), nube de gas 24 (3), petróleo 60 (6).
@export var danio_disparo: float = 10.0
@export var velocidad_proyectil: float = 400.0
@export_range(0.0, 1.0) var prob_critico: float = 0.05
@export_range(1.0, 5.0) var mult_critico: float = 2.0
## Escala el Area2D de detección. 1.0 = tamaño de la escena.
@export_range(0.5, 3.0) var rango_deteccion: float = 1.0

@export_category("Combate")
@export var disparoON: bool = true

# ── Movimiento / dash ─────────────────────────────────
@export_category("Movimiento")
@export var aceleracion: float = 1200.0
@export var friccion: float = 1400.0

@export_category("Dash")
@export var velocidad_dash: float = 600.0
@export var duracion_dash: float = 0.15
@export var cooldown_dash: float = 0.8
## Durante el dash el jugador no recibe daño.
@export var invulnerable_en_dash: bool = true

# ── Super ─────────────────────────────────────────────
@export_category("Super - Lluvia de Meteoritos")
## 40 = un microplástico muere de un meteoro; el petróleo pierde 2/3.
@export var danio_meteorito: int = 40
@export var radio_impacto_meteorito: float = 90.0
@export var tiempo_advertencia_meteorito: float = 0.6
@export var retraso_entre_meteoritos: float = 0.08

# ── Vida / respawn ────────────────────────────────────
@export var vida_maxima: int = 100
@export var respawn_manager: Node

signal died
var _muerto: bool = false

@export_category("Feedback de Daño")
@export var color_flash_golpe: Color = Color(4.0, 1.0, 1.0, 1.0)
@export var duracion_flash_golpe: float = 0.12

@export_category("Regeneración")
## Tras 'retraso_regeneracion' s sin daño, cura 'regeneracion_por_segundo' HP/s.
@export var regeneracion_por_segundo: float = 2.0
@export var retraso_regeneracion: float = 5.0
@export var regeneracion_activa: bool = true

var tiempo_sin_recibir_danio: float = 0.0
var _acum_regen: float = 0.0  # acumula fracciones: 2 HP/s * 0.016 s no se pierde

# ── Flecha del árbol ──────────────────────────────────
@export_category("Flecha indicadora del árbol")
@export var distancia_flecha_arbol: float = 45.0
## Negativo = sube el origen de la órbita.
@export var offset_altura_flecha: float = -15.0
@export var distancia_minima_mostrar: float = 80.0
@export var margen_camara: float = 20.0
@export var color_flecha_arbol: Color = Color(1.0, 0.85, 0.2, 0.95)
@export var tamano_flecha_arbol: Vector2 = Vector2(18.0, 14.0)
@export var duracion_animacion_flecha: float = 0.25

# ── Componentes ───────────────────────────────────────
var _dash: DashComponent
var _anim: AnimacionQuark
var _regen_fx: EfectoRegeneracion
var _flecha: FlechaArbol
var _super: SuperMeteoritos
var _contador: ContadorRespawn
var _selector := SelectorObjetivo.new()


func _ready() -> void:
	add_to_group("jugador")
	_aplicar_stats_guardados()
	_crear_componentes()
	_aplicar_rango_deteccion()
	_actualizar_barra_vida()
	_conectar_respawn_manager()
	if timer_disparo != null:
		timer_disparo.wait_time = cadencia_basic
	if SaveManager != null and SaveManager.has_signal("stats_actualizados"):
		SaveManager.stats_actualizados.connect(refrescar_stats)
	if SaveManager != null and SaveManager.has_signal("ajustes_cambiados"):
		SaveManager.ajustes_cambiados.connect(_on_ajustes)
	_estilizar_botones()
	_configurar_hud()
	_configurar_dron()


# ── Stats desde SaveManager (fuente de verdad de la run) ──────────────

func _aplicar_stats_guardados() -> void:
	if SaveManager == null:
		return
	vida_maxima = int(SaveManager.get_stat("jugador.vida_maxima", float(vida_maxima)))
	speed = SaveManager.get_stat("jugador.velocidad", speed)
	danio_disparo = SaveManager.get_stat("jugador.danio", danio_disparo)
	cadencia_basic = SaveManager.get_stat("jugador.cadencia", cadencia_basic)
	prob_critico = SaveManager.get_stat("jugador.critico_prob", prob_critico)
	mult_critico = SaveManager.get_stat("jugador.critico_mult", mult_critico)
	velocidad_dash = SaveManager.get_stat("jugador.velocidad_dash", velocidad_dash)
	cooldown_dash = SaveManager.get_stat("jugador.cooldown_dash", cooldown_dash)
	regeneracion_por_segundo = SaveManager.get_stat("jugador.regen", regeneracion_por_segundo)
	retraso_regeneracion = SaveManager.get_stat("jugador.regen_espera", retraso_regeneracion)
	danio_meteorito = int(SaveManager.get_stat("jugador.super_danio", float(danio_meteorito)))
	radio_impacto_meteorito = SaveManager.get_stat("jugador.super_radio", radio_impacto_meteorito)
	# "Linterna de Dinamo": +rango de detección.
	rango_deteccion = 1.0 + SaveManager.get_stat("jugador.vision", 0.0) * 0.25


## Reaplica los stats en caliente (tras comprar una mejora o cargar partida).
func refrescar_stats() -> void:
	_aplicar_stats_guardados()
	if _dash != null:
		_dash.configurar(velocidad_dash, duracion_dash, cooldown_dash, invulnerable_en_dash)
	if timer_disparo != null:
		timer_disparo.wait_time = maxf(cadencia_basic, 0.05)
	life = mini(life, vida_maxima)
	_actualizar_barra_vida()
	_configurar_dron()


## Crea/elimina el dron compañero según el stat "jugador.dron".
func _configurar_dron() -> void:
	var tiene := SaveManager != null and SaveManager.get_stat("jugador.dron", 0.0) > 0.0
	if tiene:
		if _dron == null:
			_dron = DRON.new()
			_dron.name = "Dron"
			_dron.jugador = self
			add_child(_dron)
	else:
		if _dron != null and is_instance_valid(_dron):
			_dron.queue_free()
		_dron = null


func _crear_componentes() -> void:
	_dash = DashComponent.new()
	_dash.configurar(velocidad_dash, duracion_dash, cooldown_dash, invulnerable_en_dash)
	add_child(_dash)

	_anim = AnimacionQuark.new()
	_anim.configurar(self, cuerpo, body_interior, nucleo, sombra, luz_punta)
	add_child(_anim)
	_dash.iniciado.connect(_anim.set_dash.bind(true))
	_dash.terminado.connect(_anim.set_dash.bind(false))

	_regen_fx = EfectoRegeneracion.new()
	_regen_fx.configurar(barra_vida, luz_base, luz_punta)
	add_child(_regen_fx)

	_flecha = FlechaArbol.new()
	_flecha.configurar(distancia_flecha_arbol, offset_altura_flecha, distancia_minima_mostrar,
		margen_camara, color_flecha_arbol, tamano_flecha_arbol, duracion_animacion_flecha)
	add_child(_flecha)

	_super = SuperMeteoritos.new()
	_super.configurar(danio_meteorito, radio_impacto_meteorito,
		tiempo_advertencia_meteorito, retraso_entre_meteoritos, self)
	add_child(_super)

	_contador = ContadorRespawn.new()
	_contador.configurar(contador_respawn)
	add_child(_contador)


func _aplicar_rango_deteccion() -> void:
	if rango_deteccion == 1.0 or rangeArea == null:
		return
	var area := rangeArea.get_parent() as Area2D
	if area != null:
		area.scale = Vector2.ONE * rango_deteccion


func _physics_process(delta: float) -> void:
	if _muerto:
		return

	_actualizar_ralentizado(delta)
	_anim.actualizar(delta)
	_dash.actualizar(delta)
	_mover(delta)
	_actualizar_aim()
	_regenerar(delta)


## Ralentización externa (la aplican enemigos con aura de ralentización).
var _slow_factor: float = 1.0
var _slow_t: float = 0.0


func aplicar_ralentizado(pct: float, duracion: float) -> void:
	_slow_factor = minf(_slow_factor, 1.0 - clampf(pct, 0.0, 0.9))
	_slow_t = maxf(_slow_t, duracion)


func _actualizar_ralentizado(delta: float) -> void:
	if _slow_t > 0.0:
		_slow_t -= delta
		if _slow_t <= 0.0:
			_slow_factor = 1.0


# ── Movimiento ────────────────────────────────────────

func _mover(delta: float) -> void:
	if _dash.activo:
		velocity = _dash.direccion * _dash.velocidad
	else:
		var dir := Input.get_vector(ACC_IZQ, ACC_DER, ACC_ARR, ACC_ABA)
		var tasa: float = aceleracion if dir != Vector2.ZERO else friccion
		velocity = velocity.move_toward(dir * speed * _slow_factor, tasa * delta)
	move_and_slide()


func _on_mega_pressed() -> void:
	if _muerto:
		return
	if AudioManager != null and AudioManager.has_method("reproducir"):
		AudioManager.call("reproducir", "dash", -4.0)
	var dir := Input.get_vector(ACC_IZQ, ACC_DER, ACC_ARR, ACC_ABA)
	var respaldo := Vector2.RIGHT.rotated(aim.rotation) if is_instance_valid(aim) else Vector2.RIGHT
	_dash.intentar(dir, respaldo)


# ── Disparo y objetivo ────────────────────────────────

func _on_timer_timeout() -> void:
	# Modo manual: dispara en la dirección del joystick derecho.
	if _es_manual():
		if _apuntado != null and _apuntado.activo and _apuntado.direccion.length() > 10.0:
			var dir: Vector2 = _apuntado.direccion.normalized()
			if is_instance_valid(aim):
				aim.rotation = lerp_angle(aim.rotation, dir.angle(), 0.5)
			_disparar_rafaga(dir)
		return
	_actualizar_objetivo()  # siempre apunta al más cercano actual
	if onFire and disparoON:
		shot(enemi)


func _es_manual() -> bool:
	return SaveManager != null and not bool(SaveManager.get_ajuste("disparo_automatico", true))


func _on_ajustes() -> void:
	_configurar_hud()


## Rediseño de los botones de acción: quita la "luz" del poder y los deja
## como botones temáticos (círculo + color del juego) con su etiqueta.
func _estilizar_botones() -> void:
	if controles == null:
		return
	var defs := {
		"super": [Color("d81b60"), _icono_estrella()],
		"mega": [Color("99ff33"), _icono_chevron()],
	}
	for nombre in defs.keys():
		var b := controles.get_node_or_null("ContenedorBotones/" + nombre)
		if b == null:
			continue
		b.set("texture_normal", null)
		b.set("texture_pressed", null)
		var poly := Polygon2D.new()
		poly.polygon = defs[nombre][1]
		poly.color = defs[nombre][0]
		poly.scale = Vector2(1.7, 1.7)
		b.add_child(poly)


func _icono_chevron() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-10, -14), Vector2(2, 0), Vector2(-10, 14),
		Vector2(-3, 14), Vector2(9, 0), Vector2(-3, -14)])


func _icono_estrella() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -16), Vector2(5, -5), Vector2(16, 0), Vector2(5, 5),
		Vector2(0, 16), Vector2(-5, 5), Vector2(-16, 0), Vector2(-5, -5)])


## Guarda la escala original de los controles definida en la escena.
## Sin esto, `_aplicar_hud()` reemplazaría la escala 2.5 del `ContenedorBotones`
## por `hud_escala` (1.0) y los botones táctiles quedarían al 40 % de su tamaño.
func _capturar_escala_hud() -> void:
	if _hud_base_listo or controles == null:
		return
	var cont := controles.get_node_or_null("ContenedorBotones")
	if cont is Control:
		_base_escala_botones = (cont as Control).scale
	var joy := controles.get_node_or_null("Joystick")
	if joy is Control:
		_base_escala_joystick = (joy as Control).scale
	_hud_base_listo = true


## Crea/elimina el joystick de apuntado y aplica escala/opacidad del HUD.
func _configurar_hud() -> void:
	if controles == null:
		return
	if _es_manual():
		if _apuntado == null:
			_apuntado = JOYSTICK_APUNTADO.new()
			_apuntado.name = "JoystickApuntado"
			controles.add_child(_apuntado)
			# Al fondo del CanvasLayer: los botones super/mega quedan por encima
			# y siguen recibiendo el toque (el joystick cubre la mitad derecha).
			controles.move_child(_apuntado, 0)
	else:
		if _apuntado != null and is_instance_valid(_apuntado):
			_apuntado.queue_free()
		_apuntado = null
	_aplicar_hud()


func _aplicar_hud() -> void:
	if SaveManager == null or controles == null:
		return
	_capturar_escala_hud()
	var esc := float(SaveManager.get_ajuste("hud_escala", 1.0))
	var op := float(SaveManager.get_ajuste("hud_opacidad", 1.0))
	var cont := controles.get_node_or_null("ContenedorBotones")
	if cont is Control:
		(cont as Control).scale = _base_escala_botones * esc
		(cont as Control).modulate = Color(1, 1, 1, op)
	var joy := controles.get_node_or_null("Joystick")
	if joy is Control:
		(joy as Control).scale = _base_escala_joystick * esc
		(joy as Control).modulate = Color(1, 1, 1, op)
	if _apuntado is Control:
		(_apuntado as Control).modulate = Color(1, 1, 1, op)


func shot(target: Node2D, _power_actual: String = "basic") -> void:
	if _muerto or not disparoON or not onFire or not is_instance_valid(target):
		return
	_disparar_rafaga((target.global_position - aim.global_position).normalized())


func _disparar_rafaga(base_dir: Vector2) -> void:
	if _muerto or not disparoON:
		return
	if AudioManager != null and AudioManager.has_method("reproducir"):
		AudioManager.call("reproducir", "disparo", -8.0)
	var extra := 0
	var perforacion := 0
	var tamano := 1.0
	var alcance := 1.0
	if SaveManager != null:
		extra = int(SaveManager.get_stat("jugador.proyectiles_extra", 0.0))
		perforacion = int(SaveManager.get_stat("jugador.perforacion", 0.0))
		tamano = SaveManager.get_stat("jugador.tamano", 1.0)
		alcance = SaveManager.get_stat("jugador.alcance", 1.0)

	var total := 1 + maxi(extra, 0)
	var separacion := deg_to_rad(8.0)
	for i in total:
		var offset := 0.0
		if total > 1:
			offset = (float(i) - float(total - 1) * 0.5) * separacion
		_disparar_uno(base_dir.rotated(offset), tamano, perforacion, alcance)


func _disparar_uno(direccion: Vector2, tamano: float, perforacion: int, alcance: float) -> void:
	var danio_final: float = danio_disparo
	var critico: bool = randf() < prob_critico
	if critico:
		danio_final *= mult_critico
	# Bonus por estar quieto (carta "Raíces Profundas").
	if SaveManager != null and velocity.length() < 20.0:
		danio_final *= 1.0 + SaveManager.get_stat("jugador.bonus_quieto", 0.0)

	var bullet = proyectil.instantiate()
	bullet.scale = Vector2(0.5, 0.5) * tamano * (1.3 if critico else 1.0)
	if critico:
		bullet.modulate = Color(1.0, 0.75, 0.35)
	bullet.rotation = direccion.angle()
	bullet.add_to_group("bullet")
	bullet.global_position = aim.global_position
	bullet.positionEnemi = direccion
	# set() no falla si el proyectil no tiene la propiedad.
	bullet.set("dano", danio_final)
	bullet.set("sped", velocidad_proyectil)
	bullet.set("perforacion", perforacion)
	bullet.set("vida_util", 2.0 * alcance)
	get_tree().current_scene.add_child(bullet)


func _actualizar_objetivo() -> void:
	enemi = _selector.mas_cercano(aim.global_position)
	onFire = enemi != null


func _actualizar_aim() -> void:
	if not is_instance_valid(aim):
		return
	if is_instance_valid(enemi):
		aim.rotation = (enemi.global_position - aim.global_position).angle()
	elif velocity != Vector2.ZERO:
		aim.rotation = velocity.angle()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if EnemigosUtil.es_enemigo(body):
		_selector.agregar(body)
		_actualizar_objetivo()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if EnemigosUtil.es_enemigo(body):
		_selector.quitar(body)
		_actualizar_objetivo()


func activar_disparo() -> void:
	disparoON = true


func desactivar_disparo() -> void:
	disparoON = false


# ── Super ─────────────────────────────────────────────

func _on_super_pressed() -> void:
	if _muerto:
		return
	if not BiomasaManager.consumir_biomasa():
		return
	_super.lanzar()


# ── Vida / daño ───────────────────────────────────────

## Contrato nuevo: enemigos y proyectiles llaman recibir_danio(cantidad).
func recibir_danio(cantidad: float, fuente: Node = null) -> void:
	var c := cantidad
	if fuente != null and is_instance_valid(fuente) and SaveManager != null:
		var cat := str(fuente.get("categoria"))
		if cat == "nube":
			c *= 1.0 - clampf(SaveManager.get_stat("jugador.inmunidad_nube", 0.0), 0.0, 0.75)
		elif cat == "fuego":
			c *= 1.0 - clampf(SaveManager.get_stat("jugador.inmunidad_fuego", 0.0), 0.0, 0.75)
	take_damage(roundi(c))


func take_damage(damage: int) -> void:
	if _muerto or _dash.es_invulnerable():
		return

	# Inmortalidad de depuración (botón "Inmortal" del menú de depuración de Quark).
	var _dbg = get_node_or_null("MenuDebug")
	if _dbg != null and bool(_dbg.get("inmortal")):
		return

	if SaveManager != null:
		# Esquiva pasiva: probabilidad de evitar el golpe por completo.
		if randf() < SaveManager.get_stat("jugador.esquiva", 0.0):
			return
		# Armadura: reduce el daño recibido.
		var armadura := clampf(SaveManager.get_stat("jugador.armadura", 0.0), 0.0, 0.9)
		damage = int(round(float(damage) * (1.0 - armadura)))

	_anim.flash_golpe(color_flash_golpe, duracion_flash_golpe)

	life -= damage
	tiempo_sin_recibir_danio = 0.0
	_acum_regen = 0.0
	_actualizar_barra_vida()

	if life <= 0:
		_morir()


func _morir() -> void:
	_muerto = true
	velocity = Vector2.ZERO
	_dash.cancelar()
	_regen_fx.set_activo(false)
	_flecha.habilitada = false
	_set_visible_vivo(false)
	BiomasaManager.reiniciar_biomasa()
	died.emit()


func respawn_at(posicion: Vector2) -> void:
	life = vida_maxima
	global_position = posicion
	velocity = Vector2.ZERO
	tiempo_sin_recibir_danio = 0.0
	_acum_regen = 0.0
	_actualizar_barra_vida()
	_set_visible_vivo(true)
	_flecha.habilitada = true
	_muerto = false


## Muestra/oculta todo lo que depende de estar vivo.
func _set_visible_vivo(vivo: bool) -> void:
	for n in [sombra, nucleo, cuerpo, ui_contenedor, controles]:
		if n != null:
			n.visible = vivo
	for l in [luz_base, luz_punta]:
		if l != null:
			l.enabled = vivo
	if colision != null:
		colision.set_deferred("disabled", not vivo)


func _regenerar(delta: float) -> void:
	tiempo_sin_recibir_danio += delta

	var regenerando: bool = regeneracion_activa \
		and tiempo_sin_recibir_danio >= retraso_regeneracion \
		and life < vida_maxima
	_regen_fx.set_activo(regenerando)
	if not regenerando:
		return

	_acum_regen += regeneracion_por_segundo * delta
	var puntos: int = int(_acum_regen)
	if puntos > 0:
		_acum_regen -= puntos
		life = mini(life + puntos, vida_maxima)
		_actualizar_barra_vida()


func _actualizar_barra_vida() -> void:
	if barra_vida == null:
		return
	barra_vida.max_value = vida_maxima
	barra_vida.value = clampf(life, 0.0, vida_maxima)


# ── Respawn manager (UI) ──────────────────────────────

func _conectar_respawn_manager() -> void:
	if respawn_manager == null:
		push_warning("Quark: falta asignar RespawnManager (contador de respawn deshabilitado)")
		return
	if respawn_manager.has_signal("respawn_iniciado"):
		respawn_manager.connect("respawn_iniciado", _on_respawn_iniciado)
	if respawn_manager.has_signal("respawn_finalizado"):
		respawn_manager.connect("respawn_finalizado", _on_respawn_finalizado)


func _on_respawn_iniciado(tiempo_espera: float) -> void:
	_contador.iniciar(tiempo_espera)


func _on_respawn_finalizado() -> void:
	_contador.ocultar()


# ── Misc ──────────────────────────────────────────────

func _on_ajustes_button_down() -> void:
	if pausa == null:
		return
	if pausa.has_method("abrir"):
		pausa.call("abrir")
	else:
		pausa.visible = true
		get_tree().paused = true


func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and InputMap.has_action(ACC_DEBUG_KILL) \
			and event.is_action_pressed(ACC_DEBUG_KILL):
		take_damage(9999)
