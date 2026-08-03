extends Area2D

# Variable global al inicio del script para controlar el tiempo del latido
var tiempo_latido: float = 0.0
@export var vida_maxima: int = 100
var vida_actual: int
# -------------------------------------------------------------------
# FUNCIÓN VISUAL: LATIDO Y CHISPEO DE LUZ MÍSTICA DEL ÁRBOL
# -------------------------------------------------------------------
func animar_luz_mistica(delta: float) -> void:
	# Reference directa y segura al nodo de luz del árbol
	var luz = $LuzArbol as PointLight2D
	if luz == null:
		return
		
	tiempo_latido += delta
	
	# 1. RESPIRACIÓN (Expansión y contracción suave de la sombra)
	var onda_respiracion: float = sin(tiempo_latido * 2.5) # Velocidad de respiración
	var escala_dinamica: float = 3.5 + (onda_respiracion * 0.5) # Modifica el tamaño entre 3.0 y 4.0
	luz.texture_scale = escala_dinamica
	
	# 2. CHISPEO / PARPADEO ORGÁNICO (Micro-destellos de energía viva)
	var chispeo_aleatorio: float = randf_range(-0.18, 0.18)
	var energia_base: float = 1.6 + (onda_respiracion * 0.4) + chispeo_aleatorio
	luz.energy = max(0.8, energia_base)
	
	# 3. TRANSICIÓN CROMÁTICA (Oscila entre Verde Esmeralda y Cian Místico)
	var factor_color: float = (onda_respiracion + 1.0) / 2.0 # Transforma rango [-1,1] a [0,1]
	var color_verde := Color("#00FF88")
	var color_cian := Color("#00F0FF")
	luz.color = color_verde.lerp(color_cian, factor_color)
	
func _process(delta: float) -> void:
	animar_luz_mistica(delta)

func recibir_danio(cantidad: int) -> void:
	vida_actual = max(0, vida_actual - cantidad)
	actualizar_barra_vida()
	reaccionar_visualmente_al_danio()

	if vida_actual <= 0:
		destruir_arbol()

func actualizar_barra_vida() -> void:
	var barra = $BarraVida as ProgressBar
	if barra != null:
		barra.max_value = vida_maxima
		barra.value = vida_actual

# Efecto de destello rojo en la luz al recibir un golpe
func reaccionar_visualmente_al_danio() -> void:
	var luz = $LuzArbol as PointLight2D
	if luz == null:
		return

	# Guardar valores originales antes de la alerta
	var color_original = luz.color
	var energia_original = luz.energy
	var escala_original = luz.texture_scale

	# Valores de alerta intensa (instante)
	luz.color = Color("#FF0044") # Rojo neón de advertencia
	luz.energy = 8.0
	luz.texture_scale = 9.0

	# Tween para devolver suavemente a los valores originales
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(luz, "color", color_original, 0.3)
	tween.tween_property(luz, "energy", energia_original, 0.3)
	tween.tween_property(luz, "texture_scale", escala_original, 0.3)

func destruir_arbol() -> void:
	# Desactivar al jugador instantáneamente (sin transiciones) para que
	# no pueda moverse ni disparar mientras se reproduce la animación.
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.hide()
		player.process_mode = Node.PROCESS_MODE_DISABLED

	# Animar intensamente la luz del árbol antes del fade (paralelo)
	var luz = $LuzArbol as PointLight2D
	if luz != null:
		var tween_arbol = create_tween()
		tween_arbol.set_parallel(true)
		tween_arbol.tween_property(luz, "energy", 10.0, 0.8).set_ease(Tween.EASE_IN)
		tween_arbol.tween_property(luz, "texture_scale", 10.0, 0.8).set_ease(Tween.EASE_IN)
		tween_arbol.tween_property(luz, "color", Color(1, 0, 0, 1), 0.8).set_ease(Tween.EASE_IN)

	# Crear una capa de overlay para el desvanecimiento a negro
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128
	get_tree().current_scene.add_child(canvas_layer)

	# ColorRect de pantalla completa, inicialmente transparente
	var color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.modulate = Color(1, 1, 1, 0)
	color_rect.anchors_preset = Control.PRESET_FULL_RECT
	canvas_layer.add_child(color_rect)

	# Animación suave de fade a negro (1.5 segundos)
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_IN)
	await tween.finished

	# Cambiar a la escena de muerte
	get_tree().change_scene_to_file("res://ui/dead/dead.tscn")
	
func _ready() -> void:
	vida_actual = vida_maxima
	actualizar_barra_vida()
