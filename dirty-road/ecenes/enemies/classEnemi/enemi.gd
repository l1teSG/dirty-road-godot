class_name enemigoNuevo
extends CharacterBody2D

var tiempo_anim: float = randf() * 10.0
var life: int = 30  # ajusta a la vida que quieras

# ── Parámetros de Ataque y Proximidad (editable desde Inspector) ──
@export_category("Parámetros de Ataque y Proximidad")
@export var distancia_ataque: float = 100.0
@export var danio_ataque: int = 10
@export var tiempo_recarga: float = 1.5
@export var distancia_urgencia_arbol: float = 60.0
@export var distancia_max_aggro: float = 350.0
@export var tiempo_aggro: float = 4.0

# ── Control interno ───────────────────────────────────
var puede_atacar: bool = true
var en_aggro: bool = false
var objetivo: Node2D = null

# ── Etiqueta de nombre ────────────────────────────────
@export var nombre_enemigo: String = ""
@export var offset_etiqueta_nombre: Vector2 = Vector2(0, -60)
var _etiqueta_nombre: Label = null

# ── Feedback visual de daño ──────────────────────────
@export_category("Feedback Visual de Daño")
@export var flash_color: Color = Color.WHITE
@export var flash_duration: float = 0.15
@export var damage_number_offset: Vector2 = Vector2(0, -80)
@export var damage_number_color: Color = Color.WHITE

var _flash_tween: Tween = null

func _physics_process(delta: float) -> void:
	animar_cuerpo_enemigo(delta)


func animar_cuerpo_enemigo(delta: float) -> void:
	var cuerpo_int = $CuerpoInterior as Polygon2D
	var nucleo = $NucleoToxico as Polygon2D

	if cuerpo_int == null:
		return

	tiempo_anim += delta * 8.0

	var deformacion = sin(tiempo_anim) * 0.06
	cuerpo_int.scale.x = 0.8 + deformacion
	cuerpo_int.scale.y = 0.8 - deformacion

	if nucleo != null:
		nucleo.rotation += delta * 2.0


func take_hit(damage: int = 10) -> void:
	recibir_danio(damage)


# ── Recepción de daño (con aggro) ────────────────────────

func recibir_danio(cantidad: int, atacante: Node2D = null) -> void:
	# ── Feedback visual inmediato ──
	_mostrar_flash_danio()
	_mostrar_numero_danio(cantidad)

	# Aggro: si el atacante es el jugador o un proyectil, entra en modo aggro
	if atacante != null and (atacante.is_in_group("player") or atacante.is_in_group("bullet")):
		en_aggro = true
		# Iniciar temporizador asíncrono para desactivar aggro
		await get_tree().create_timer(tiempo_aggro).timeout
		en_aggro = false

	life -= cantidad
	if life <= 0:
		var label = get_tree().current_scene.find_child("TextoBiomasa", true, false)
		if label:
			# Llamada original de take_hit (ajusta según tu implementación de BiomasaManager)
			BiomasaManager.emitir_biomasa(
				global_position,
				label.global_position,
				label.get_node("/root").find_child("ui", true, false)
			)
		queue_free()


# ── Utilidades comunes ─────────────────────────────────

func buscar_jugador() -> Node2D:
	var player: Node2D = get_tree().get_first_node_in_group("jugador")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	return player


func buscar_arbol() -> Node2D:
	var arbol: Node2D = get_tree().get_first_node_in_group("arbol")
	if arbol == null:
		arbol = get_tree().get_first_node_in_group("tree")
	return arbol


func _arbol_valido(arbol_node: Node2D) -> bool:
	if not is_instance_valid(arbol_node):
		return false
	if arbol_node.has_method("is_dead"):
		return not arbol_node.is_dead()
	var vida_actual = arbol_node.get("vida_actual")
	if vida_actual != null:
		return vida_actual > 0
	var vida_nodo = arbol_node.get("life")
	if vida_nodo != null:
		return vida_nodo > 0
	return true


# ── Selección de objetivo por defecto (opcional para subclases) ──

func seleccionar_objetivo() -> void:
	var jugador: Node2D = null
	var arbol: Node2D = null

	# Buscar en grupo "player" o "jugador"
	var jugadores = get_tree().get_nodes_in_group("player")
	if jugadores.is_empty():
		jugadores = get_tree().get_nodes_in_group("jugador")
	if jugadores.size() > 0 and is_instance_valid(jugadores[0]):
		jugador = jugadores[0] as Node2D

	# Buscar en grupo "arbol"
	var arboles = get_tree().get_nodes_in_group("arbol")
	if arboles.size() > 0 and is_instance_valid(arboles[0]):
		arbol = arboles[0] as Node2D

	var dist_jugador: float = INF
	var dist_arbol: float = INF

	if jugador != null:
		dist_jugador = global_position.distance_to(jugador.global_position)
	if arbol != null:
		dist_arbol = global_position.distance_to(arbol.global_position)

	# Regla 1: Urgencia Árbol (prioridad absoluta si está a quemarropa)
	if arbol != null and dist_arbol <= distancia_urgencia_arbol:
		objetivo = arbol
		return

	# Regla 2: Aggro con rango limitado
	if en_aggro:
		if jugador != null and dist_jugador <= distancia_max_aggro:
			objetivo = jugador
			return
		else:
			# Si el jugador está fuera del rango máximo, rompemos el aggro
			en_aggro = false

	# Regla 3: Proximidad pura (estado normal)
	var closest: Node2D = null
	var min_dist: float = INF
	if jugador != null and dist_jugador < min_dist:
		closest = jugador
		min_dist = dist_jugador
	if arbol != null and dist_arbol < min_dist:
		closest = arbol
		min_dist = dist_arbol
	objetivo = closest


# ── Ataque cuerpo a cuerpo (opcional para subclases) ──

func evaluar_y_ejecutar_ataque() -> void:
	if not is_instance_valid(objetivo):
		return

	if not puede_atacar:
		return

	var distancia = global_position.distance_to(objetivo.global_position)
	if distancia > distancia_ataque:
		return

	# Ejecutar ataque según el tipo de objetivo
	if objetivo.has_method("take_damage"):
		objetivo.take_damage(danio_ataque)
	elif objetivo.has_method("recibir_danio"):
		objetivo.recibir_danio(danio_ataque)

	# Iniciar recarga
	puede_atacar = false
	await get_tree().create_timer(tiempo_recarga).timeout
	puede_atacar = true


# ── Etiqueta de nombre ────────────────────────────────

func configurar_etiqueta_nombre(nombre: String = "") -> void:
	if _etiqueta_nombre == null:
		_etiqueta_nombre = Label.new()
		_etiqueta_nombre.name = "EtiquetaNombre"
		_etiqueta_nombre.z_index = 100
		_etiqueta_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_etiqueta_nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_etiqueta_nombre.add_theme_font_size_override("font_size", 14)
		_etiqueta_nombre.add_theme_color_override("font_color", Color.WHITE)
		_etiqueta_nombre.add_theme_color_override("font_outline_color", Color.BLACK)
		_etiqueta_nombre.add_theme_constant_override("outline_size", 2)
		_etiqueta_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_etiqueta_nombre)

	if nombre != "":
		_etiqueta_nombre.text = nombre
		nombre_enemigo = nombre

	# Posicionar la etiqueta relativa al nodo (se actualiza cada frame)
	_etiqueta_nombre.position = offset_etiqueta_nombre


# ── Feedback visual de daño ──────────────────────────

func _mostrar_flash_danio() -> void:
	# Cancelar cualquier flash anterior en curso
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	var color_original: Color = modulate
	modulate = flash_color

	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", color_original, flash_duration)


func _mostrar_numero_danio(cantidad: int) -> void:
	var label: Label = Label.new()
	label.text = str(cantidad)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", damage_number_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.z_index = 200
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Posición inicial: sobre la cabeza del enemigo con un pequeño desplazamiento horizontal aleatorio
	var offset_x: float = randf_range(-15.0, 15.0)
	var pos_inicial: Vector2 = global_position + damage_number_offset + Vector2(offset_x, 0.0)
	label.global_position = pos_inicial

	# Añadir a la escena actual para que no desaparezca si el enemigo muere
	get_tree().current_scene.add_child(label)

	# Animación: subir y desvanecer
	# IMPORTANTE: el tween se crea sobre "label", no sobre "self" (el enemigo),
	# así su ciclo de vida no depende de que el enemigo siga vivo.
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", pos_inicial + Vector2(0.0, -30.0), 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)

	tween.finished.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)
