extends Area2D

## ══════════════════════════════════════════════════════════
##  ÁRBOL — objetivo de defensa (grupo 'arbol') y derrota.
##  CONTRATO CON EL SISTEMA:
##  • WaveManager y Enemigo.gd lo identifican por el grupo 'arbol'.
##  • Contrato único de daño:
##      recibir_danio(cantidad: float, fuente: Node = null)
##    Aliases take_hit / recibir_dano para scripts viejos.
##  • SIN armadura y SIN espinas (eliminadas del balance).
##  • Regeneración 1.5 HP/s después de 8 s sin recibir daño.
##
##  DAÑO FANTASMA (diagnóstico):
##  • Activa debug_danio_entrante y cada golpe imprime QUIÉN fue,
##    por qué vía entró y qué cuerpos hay dentro del área.
##  • Solo las shapes de shapes_danio registran daño; se ignora el
##    propio árbol (su tronco es un hijo) y los enemigos ya muertos.
##  • El contacto hace el primer golpe al instante y se repite cada
##    intervalo_contacto mientras el enemigo siga pegado.
## ══════════════════════════════════════════════════════════

signal vida_actualizada(vida: float, vida_max: int)
signal arbol_destruido
## Aviso de golpe recibido (para la viñeta roja de pantalla, etc.).
signal golpe_recibido(cantidad: float)

## Contador del latido: segundos desde el último daño recibido.
## Cuando supera regeneracion_espera, el árbol regenera vida.
var tiempo_latido: float = 0.0

@export_category("Vida")
## Vida del árbol (condición de derrota). Varios enemigos pueden
## golpearlo a la vez.
@export var vida_maxima: int = 150
var vida_actual: float = 0.0
var esta_destruido: bool = false

@export_category("Defensa")
## Shapes hijas (CollisionShape2D) autorizadas a registrar daño.
## Vacío = registran todas las shapes del Area2D.
@export var shapes_danio: Array[CollisionShape2D] = []
## Si es true, todo enemigo tocando una shape de daño hace su 'damage'
## cada intervalo_contacto segundos.
@export var danio_contacto_enemigos: bool = true
## Segundos entre golpes de contacto de un mismo enemigo.
@export_range(0.1, 5.0) var intervalo_contacto: float = 1.0

@export_category("Regeneración")
@export var regeneracion_por_segundo: float = 1.5
## Segundos sin recibir daño para empezar a regenerar.
@export var regeneracion_espera: float = 8.0

@export_category("Debug")
@export var debug_activo: bool = false
## Cada golpe imprime fuente, vía y cuerpos dentro del área.
@export var debug_danio_entrante: bool = false

## instance_id del enemigo en contacto → segundos acumulados.
var _contactos: Dictionary = {}
## Cargas de barrera (bloquean un golpe letal cada una).
var _barrera_restante: int = 0

# ── Feedback visual ──
@onready var _barra: ProgressBar = get_node_or_null("BarraVida")
@onready var _tronco: Polygon2D = get_node_or_null("tronco")
@onready var _copa: Polygon2D = get_node_or_null("copa")
@onready var _copa2: Polygon2D = get_node_or_null("copa2")
var _pos0: Vector2 = Vector2.ZERO
var _tween_flash: Tween = null
var _tween_shake: Tween = null
var _fuente: Font = null


func _ready() -> void:
	add_to_group("arbol")
	_aplicar_stats_guardados()
	vida_actual = float(vida_maxima)
	vida_actualizada.connect(_on_vida_actualizada)
	vida_actualizada.emit(vida_actual, vida_maxima)

	# Feedback: posición base para la sacudida y fuente para los números.
	_pos0 = position
	_fuente = EstiloUI.F_BOLD

	body_shape_entered.connect(_on_body_shape_entered)
	body_shape_exited.connect(_on_body_shape_exited)
	area_shape_entered.connect(_on_area_shape_entered)

	if SaveManager != null and SaveManager.has_signal("stats_actualizados"):
		SaveManager.stats_actualizados.connect(_on_stats_actualizados)


func _aplicar_stats_guardados() -> void:
	if SaveManager == null:
		return
	vida_maxima = int(SaveManager.get_stat("arbol.vida_maxima", float(vida_maxima)))
	regeneracion_por_segundo = SaveManager.get_stat("arbol.regen", regeneracion_por_segundo)
	regeneracion_espera = SaveManager.get_stat("arbol.regen_espera", regeneracion_espera)
	_barrera_restante = int(SaveManager.get_stat("arbol.barrera", float(_barrera_restante)))


## Refresca los stats del árbol tras comprar una mejora.
func _on_stats_actualizados() -> void:
	var vida_previa := vida_maxima
	_aplicar_stats_guardados()
	if vida_maxima > vida_previa and vida_previa > 0:
		vida_actual = minf(vida_actual + float(vida_maxima - vida_previa), float(vida_maxima))
	vida_actual = minf(vida_actual, float(vida_maxima))
	vida_actualizada.emit(vida_actual, vida_maxima)


func _physics_process(delta: float) -> void:
	if esta_destruido:
		return
	_actualizar_regeneracion(delta)
	if danio_contacto_enemigos:
		_procesar_contactos(delta)
	_actualizar_congelar(delta)


## "Bloque de Hielo Seco" (arbol.congelar): ralentiza a los enemigos cercanos.
var _t_congelar: float = 0.0

func _actualizar_congelar(delta: float) -> void:
	if SaveManager == null:
		return
	var cong := SaveManager.get_stat("arbol.congelar", 0.0)
	if cong <= 0.0:
		return
	_t_congelar -= delta
	if _t_congelar > 0.0:
		return
	_t_congelar = 0.6
	var radio := 260.0
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e is Node2D and e.global_position.distance_to(global_position) <= radio:
			if e.has_method("aplicar_ralentizado"):
				e.call("aplicar_ralentizado", 0.4, 0.8)


# ───────────── DAÑO ─────────────

func recibir_danio(cantidad: float, fuente: Node = null) -> void:
	if esta_destruido:
		return
	if debug_danio_entrante:
		_log_danio(cantidad, fuente)

	var mult := 1.0
	if SaveManager != null:
		mult = SaveManager.get_stat("arbol.dano_recibido_mult", 1.0)

	var nuevo := vida_actual - cantidad * mult
	# Barrera: bloquea un golpe letal por carga (lo deja a 1 HP).
	if nuevo <= 0.0 and _barrera_restante > 0:
		_barrera_restante -= 1
		nuevo = 1.0

	vida_actual = maxf(nuevo, 0.0)
	tiempo_latido = 0.0
	vida_actualizada.emit(vida_actual, vida_maxima)

	_fx_golpe(cantidad)
	golpe_recibido.emit(cantidad)

	_reflejar_espinas(cantidad, fuente)

	if vida_actual <= 0.0:
		destruir_arbol()


## Espinas: devuelve un % del daño recibido al enemigo que atacó.
func _reflejar_espinas(cantidad: float, fuente: Node) -> void:
	if fuente == null or not is_instance_valid(fuente) or SaveManager == null:
		return
	var espinas := SaveManager.get_stat("arbol.espinas", 0.0)
	if espinas <= 0.0:
		return
	if fuente.has_method("recibir_danio"):
		fuente.call("recibir_danio", cantidad * espinas)


## Alias para scripts viejos.
func take_hit(cantidad: float, fuente: Node = null) -> void:
	recibir_danio(cantidad, fuente)


## Alias para scripts viejos (sin 'i').
func recibir_dano(cantidad: float, fuente: Node = null) -> void:
	recibir_danio(cantidad, fuente)


func destruir_arbol() -> void:
	if esta_destruido:
		return
	esta_destruido = true
	_contactos.clear()
	# Física SIEMPRE diferida: esta función se llama dentro de señales
	# de física y set_monitoring directo tira error "locked".
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	arbol_destruido.emit()


## Reubica el árbol (al cambiar de escenario) y actualiza la base de la
## sacudida para que el feedback no lo devuelva a la posición vieja.
func reubicar(p: Vector2) -> void:
	global_position = p
	_pos0 = position


# ───────────── FEEDBACK VISUAL ─────────────

func _on_vida_actualizada(vida: float, maxima: int) -> void:
	if _barra == null:
		return
	_barra.max_value = float(maxi(maxima, 1))
	_barra.value = clampf(vida, 0.0, _barra.max_value)


## Golpe: barra (vía señal), flash rojo, sacudida, hojas y número flotante.
func _fx_golpe(cantidad: float) -> void:
	if _pos0 == Vector2.ZERO and position != Vector2.ZERO:
		_pos0 = position
	var fuerza := clampf(cantidad / 40.0, 0.15, 1.0)

	# Flash rojo (modulate afecta a todo el árbol).
	if _tween_flash != null and _tween_flash.is_valid():
		_tween_flash.kill()
	modulate = Color(1.0 + fuerza, 1.0 - 0.6 * fuerza, 1.0 - 0.6 * fuerza, 1.0)
	_tween_flash = create_tween()
	_tween_flash.tween_property(self, "modulate", Color.WHITE, 0.25)

	# Sacudida.
	if _tween_shake != null and _tween_shake.is_valid():
		_tween_shake.kill()
	var amp := 4.0 * fuerza
	_tween_shake = create_tween()
	_tween_shake.tween_property(self, "position", _pos0 + Vector2(amp, -amp * 0.4), 0.04)
	_tween_shake.tween_property(self, "position", _pos0 + Vector2(-amp, amp * 0.4), 0.05)
	_tween_shake.tween_property(self, "position", _pos0 + Vector2(amp * 0.5, 0), 0.04)
	_tween_shake.tween_property(self, "position", _pos0, 0.05)

	_burst_hojas(fuerza)
	_numero_danio(cantidad)


func _burst_hojas(fuerza: float) -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(randf_range(-45.0, 45.0), randf_range(-140.0, -70.0))
	p.z_index = 20
	p.amount = int(8.0 + 14.0 * fuerza)
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.8
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, 260)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 210.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = Color(0.45, 0.95, 0.35, 0.95)
	p.emitting = true
	add_child(p)
	p.finished.connect(p.queue_free)


func _numero_danio(cantidad: float) -> void:
	var l := Label.new()
	l.text = "-%d" % int(round(cantidad))
	if _fuente != null:
		l.add_theme_font_override("font", _fuente)
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 5)
	l.position = Vector2(randf_range(-55.0, 55.0), randf_range(-150.0, -100.0))
	l.z_index = 30
	add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 55.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.chain().tween_callback(l.queue_free)


# ───────────── CONTACTO ─────────────
func _on_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, local_shape_index: int) -> void:
	if esta_destruido or not danio_contacto_enemigos:
		return
	if not _shape_registra(local_shape_index):
		return
	if body == null:
		return
	# Ignora partes del propio árbol (el StaticBody del tronco se
	# solapa con las shapes de daño por diseño).
	if body == self or is_ancestor_of(body):
		return
	# Ignora enemigos muertos (cuerpo aún presente en la animación).
	if "_muerto" in body and bool(body.get("_muerto")):
		return
	if not body.is_in_group("enemigos"):
		return

	var id := body.get_instance_id()
	if _contactos.has(id):
		return  # Ya está pegado y con su reloj de contacto.
	_contactos[id] = 0.0
	# Primer golpe al instante; los siguientes cada intervalo_contacto.
	recibir_danio(_f_nodo(body, "damage", 1.0), body)


func _on_body_shape_exited(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body == null:
		return
	_contactos.erase(body.get_instance_id())


func _on_area_shape_entered(_area_rid: RID, area: Node2D, _area_shape_index: int, local_shape_index: int) -> void:
	if esta_destruido:
		return
	if not _shape_registra(local_shape_index):
		return
	if area == null:
		return
	# Proyectiles enemigos. Si tu proyectil ya aplica el daño él mismo
	# al detectar el árbol, deja este handler solo para el diagnóstico.
	if not area.is_in_group("proyectil_enemigo"):
		return
	recibir_danio(_f_nodo(area, "damage", 1.0), area)


## true si la shape local que disparó la señal está autorizada.
func _shape_registra(local_shape_index: int) -> bool:
	if shapes_danio.is_empty():
		return true
	var owner_id := shape_find_owner(local_shape_index)
	var nodo := shape_owner_get_owner(owner_id) as CollisionShape2D
	return nodo != null and shapes_danio.has(nodo)


func _procesar_contactos(delta: float) -> void:
	var ids_fuera: Array = []
	for id in _contactos:
		var body := instance_from_id(id) as Node2D
		# Salió del árbol de escena o ya murió → fuera.
		if body == null or not is_instance_valid(body):
			ids_fuera.append(id)
			continue
		if "_muerto" in body and bool(body.get("_muerto")):
			ids_fuera.append(id)
			continue
		var t: float = float(_contactos[id]) + delta
		if t >= intervalo_contacto:
			t = 0.0
			recibir_danio(_f_nodo(body, "damage", 1.0), body)
		_contactos[id] = t
	for id in ids_fuera:
		_contactos.erase(id)


# ───────────── REGENERACIÓN ─────────────

func _actualizar_regeneracion(delta: float) -> void:
	if vida_actual <= 0.0 or vida_actual >= float(vida_maxima):
		return
	tiempo_latido += delta
	if tiempo_latido < regeneracion_espera:
		return
	vida_actual = minf(vida_actual + regeneracion_por_segundo * delta, float(vida_maxima))
	vida_actualizada.emit(vida_actual, vida_maxima)


# ───────────── DIAGNÓSTICO ─────────────

## Nombra la fuente y la vía exacta de cada golpe, y lista qué hay
## dentro del área en ese instante. Solo funciona en builds de debug.
func _log_danio(cantidad: float, fuente: Node) -> void:
	var origen := "desconocido"
	if fuente != null and is_instance_valid(fuente):
		origen = "%s (%s)" % [fuente.name, fuente.get_class()]
	var pila := get_stack()
	if pila != null and pila.size() > 1:
		var marco: Dictionary = pila[1]
		origen += " · vía %s:%d" % [String(marco.get("source", "?")).get_file(), int(marco.get("line", 0))]
	var dentro: Array[String] = []
	for b in get_overlapping_bodies():
		if b is Node2D:
			dentro.append("%s a %.0f px" % [b.name, global_position.distance_to((b as Node2D).global_position)])
	var lista := ", ".join(dentro) if not dentro.is_empty() else "ninguno"
	print("[Arbol] -%.1f de %s | cuerpos dentro del área: %s" % [cantidad, origen, lista])


# ───────────── HELPERS ─────────────

func _f_nodo(nodo: Node, propiedad: String, defecto: float) -> float:
	if nodo == null:
		return defecto
	var v: Variant = nodo.get(propiedad)
	return defecto if v == null else float(v)
