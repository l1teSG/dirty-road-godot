extends Player

# ── Referencias a nodos ──────────────────────────────
@onready var rangeArea = $Area2D/range
@onready var aim: Node2D = $aim
@onready var nucleo: Polygon2D = $Nucleo
@onready var cuerpo: Polygon2D = $body
@onready var luz_base: PointLight2D = $LuzBase
@onready var luz_punta: PointLight2D = $LuzPunta
@onready var sombra: Polygon2D = $sombra
@onready var colision: CollisionShape2D = $Collision
@onready var barra_vida: ProgressBar = $ui/margenUi/ContenedorVertical/FilaVida/BarraVida
@onready var contador_respawn: Label = $ui/ContadorRespawn
@onready var ui_contenedor: Node = $ui/margenUi
@onready var contendor_controles: CanvasLayer = $controls

# ── Combate / disparo ─────────────────────────────────
var proyectil: PackedScene = preload("res://ecenes/players/projectile/quark/playerProyectil.tscn")
var power: String = 'basic'  # basic | super | mega
var onFire: bool = false
var enemi: Node2D = null
var enemigos_en_rango: Array[Node2D] = []

# ── Animación ──────────────────────────────────────────
var tiempo_caminata: float = 0.0
var tiempo_pulso: float = 0.0

# ── Vida / respawn ─────────────────────────────────────
## Vida máxima del jugador, usada para restaurarla al hacer respawn.
@export var vida_maxima: int = 100

## Referencia al RespawnManager de la escena, usada únicamente para
## escuchar las señales "respawn_iniciado" / "respawn_finalizado" y así
## manejar el contador visual de respawn. Debe asignarse desde el editor
## (cableado en la escena del nivel, p. ej. niviel1.tscn).
##
## NOTE: tipada como Node porque "respawn_iniciado"/"respawn_finalizado"
## pertenecen al script propio de respawn_manager.gd, no a la clase base
## Node. Se accede de forma dinámica (has_signal / connect por String)
## por el mismo motivo que RespawnManager accede al jugador de forma
## dinámica: el chequeo estático de tipos de GDScript rechazaría señales
## o métodos que no existen en el tipo declarado.
@export var respawn_manager: Node

# ── Control de disparo (editable desde Inspector) ─────
@export_category("Combate")
@export var disparoON: bool = true

## Emitida cuando la vida llega a 0. RespawnManager escucha esta señal
## para iniciar la secuencia de respawn.
signal died

## Evita que el jugador siga recibiendo daño (y re-emitiendo "died")
## mientras ya está esperando a que RespawnManager lo reposicione.
var _muerto: bool = false


func _ready() -> void:
	_actualizar_barra_vida()
	_conectar_respawn_manager()


## Conecta las señales del RespawnManager asignado, si existe, para poder
## mostrar el contador de respawn en pantalla.
func _conectar_respawn_manager() -> void:
	if respawn_manager == null:
		push_warning("Quark: falta asignar la referencia a RespawnManager (contador de respawn deshabilitado)")
		return

	if respawn_manager.has_signal("respawn_iniciado"):
		respawn_manager.connect("respawn_iniciado", _on_respawn_iniciado)

	if respawn_manager.has_signal("respawn_finalizado"):
		respawn_manager.connect("respawn_finalizado", _on_respawn_finalizado)


func _physics_process(delta: float) -> void:
	#debug()
	# Salvaguarda: si el jugador está muerto (esperando respawn), no debe
	# procesar movimiento ni animaciones.
	if _muerto:
		return

	aplicar_pulso_energia(delta)
	animar_sombra(delta)
	move()


func move() -> void:
	var vectorDireccion = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	velocity = vectorDireccion * speed
	move_and_slide()


# ── Disparo ────────────────────────────────────────────

func shot(target: Node2D, power_actual: String) -> void:
	# Guarda estricta: si el jugador está muerto o el disparo desactivado, no puede disparar.
	if _muerto or not disparoON:
		return

	if not onFire or not is_instance_valid(target):
		return

	var direction = (target.global_position - aim.global_position).normalized()

	var bullet = proyectil.instantiate()
	bullet.scale = Vector2(0.5, 0.5)
	bullet.rotation = direction.angle()
	bullet.add_to_group('bullet')
	bullet.global_position = aim.global_position
	bullet.positionEnemi = direction

	get_tree().current_scene.add_child(bullet)


func _on_timer_timeout() -> void:
	if onFire and disparoON and is_instance_valid(enemi):
		shot(enemi, power)
	else:
		_actualizar_objetivo()


# ── Detección de enemigos en rango ────────────────────

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemi') and not enemigos_en_rango.has(body):
		enemigos_en_rango.append(body)
		_actualizar_objetivo()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		enemigos_en_rango.erase(body)
		_actualizar_objetivo()


func _actualizar_objetivo() -> void:
	# limpia referencias a enemigos que ya no existen
	enemigos_en_rango = enemigos_en_rango.filter(func(e): return is_instance_valid(e))

	if enemigos_en_rango.is_empty():
		onFire = false
		enemi = null
		return

	# elige siempre el enemigo más cercano al punto de mira
	enemi = enemigos_en_rango[0]
	var dist_min = aim.global_position.distance_to(enemi.global_position)

	for e in enemigos_en_rango:
		var d = aim.global_position.distance_to(e.global_position)
		if d < dist_min:
			dist_min = d
			enemi = e

	onFire = true


# ── Poder de disparo ───────────────────────────────────

func _on_super_pressed() -> void:
	
	power = 'super'


func _on_mega_pressed() -> void:
	
	power = 'mega'


# ── Vida / daño ────────────────────────────────────────

func take_damage(damage: int) -> void:
	# Si ya está esperando el respawn, ignoramos daño adicional para no
	# seguir bajando "life" indefinidamente ni re-emitir "died".
	if _muerto:
		return

	life -= damage
	_actualizar_barra_vida()

	if life <= 0:
		_muerto = true
		_ocultar_al_morir()
		BiomasaManager.reiniciar_biomasa()
		died.emit()


## Restaura la vida al máximo y reposiciona al jugador.
## Llamado por RespawnManager una vez transcurrido el tiempo de espera.
func respawn_at(posicion: Vector2) -> void:
	life = vida_maxima
	global_position = posicion
	_actualizar_barra_vida()
	_restaurar_al_reaparecer()
	_muerto = false


## Oculta y desactiva únicamente los elementos gráficos y de colisión del
## cuerpo del jugador (no el nodo raíz), para que la UI —incluyendo
## "ui/ajuste/ajustes" y el contador de respawn— permanezca visible y
## funcional mientras el jugador viaja invisible hacia el punto de origen.
func _ocultar_al_morir() -> void:
	if sombra != null:
		sombra.visible = false
	if nucleo != null:
		nucleo.visible = false
	if cuerpo != null:
		cuerpo.visible = false  # oculta también a "bodyInterior", su hijo
	if luz_base != null:
		luz_base.enabled = false
	if luz_punta != null:
		luz_punta.enabled = false
	if colision != null:
		colision.disabled = true
	if ui_contenedor != null:
		ui_contenedor.visible = false
	if contendor_controles != null:
		contendor_controles.visible = false


## Revierte "_ocultar_al_morir": restaura visibilidad de los gráficos,
## vuelve a encender las luces y reactiva la colisión del jugador.
func _restaurar_al_reaparecer() -> void:
	if sombra != null:
		sombra.visible = true
	if nucleo != null:
		nucleo.visible = true
	if cuerpo != null:
		cuerpo.visible = true
	if luz_base != null:
		luz_base.enabled = true
	if luz_punta != null:
		luz_punta.enabled = true
	if colision != null:
		colision.disabled = false
	if ui_contenedor != null:
		ui_contenedor.visible = true
	if contendor_controles != null:
		contendor_controles.visible = true

## Sincroniza la barra de vida de la UI con el valor actual de "life".
func _actualizar_barra_vida() -> void:
	if barra_vida == null:
		return
	barra_vida.max_value = vida_maxima
	barra_vida.value = clamp(life, 0, vida_maxima)


# ── Contador de respawn (UI) ────────────────────────────

## Llamado cuando RespawnManager emite "respawn_iniciado".
func _on_respawn_iniciado(tiempo_espera: float) -> void:
	_iniciar_contador_respawn(tiempo_espera)


## Llamado cuando RespawnManager emite "respawn_finalizado". Garantiza que
## el contador quede oculto aunque haya algún desajuste de redondeo entre
## este bucle local y el tiempo real de espera de RespawnManager.
func _on_respawn_finalizado() -> void:
	if contador_respawn != null:
		contador_respawn.visible = false


## Muestra el Label del contador y lo va actualizando segundo a segundo
## hasta llegar a 0, con una pequeña animación de "pop" en cada cambio.
func _iniciar_contador_respawn(tiempo_espera: float) -> void:
	if contador_respawn == null:
		return

	var segundos_restantes: int = int(ceil(tiempo_espera))
	contador_respawn.visible = true
	await _actualizar_texto_contador(segundos_restantes)

	while segundos_restantes > 0:
		await get_tree().create_timer(1.0).timeout
		segundos_restantes -= 1
		await _actualizar_texto_contador(segundos_restantes)

	contador_respawn.visible = false


## Actualiza el texto del contador y aplica el efecto de "pop": el Label
## aparece agrandado y se anima suavemente hasta su escala normal.
func _actualizar_texto_contador(segundos: int) -> void:
	contador_respawn.text = str(segundos)

	# se espera un frame para que el Label recalcule su tamaño real con el
	# nuevo texto antes de fijar el pivote de escala en su centro
	await get_tree().process_frame
	if contador_respawn == null:
		return
	contador_respawn.pivot_offset = contador_respawn.size / 2.0

	contador_respawn.scale = Vector2(1.4, 1.4)

	var tween = create_tween()
	tween.tween_property(contador_respawn, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ── Animaciones visuales ───────────────────────────────

func aplicar_pulso_energia(delta: float) -> void:
	if nucleo == null or luz_punta == null:
		return

	tiempo_pulso += delta * 5.0

	var factor_pulso: float = 1.0 + sin(tiempo_pulso) * 0.12
	nucleo.scale = Vector2(factor_pulso, factor_pulso)
	luz_punta.energy = 1.8 + sin(tiempo_pulso * 2.0) * 0.5


func animar_sombra(delta: float) -> void:
	if sombra == null:
		return

	if velocity != Vector2.ZERO:
		tiempo_caminata += delta * 18.0
		sombra.scale.x = 1.0 - sin(tiempo_caminata) * 0.1
	else:
		sombra.scale = sombra.scale.lerp(Vector2.ONE, delta * 10.0)


func _on_ajustes_button_down() -> void:
	$Pausa.visible = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_kill"):
		take_damage(9999)

func debug():
	print(contador_respawn.visible)

# ── Helpers para control de disparo ────────────────────

func activar_disparo() -> void:
	disparoON = true


func desactivar_disparo() -> void:
	disparoON = false
