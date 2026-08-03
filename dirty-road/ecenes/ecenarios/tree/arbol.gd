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
	if luz != null:
		var color_original = luz.color
		luz.color = Color("#FF0044") # Destello rojo neón de daño
		
		var tween = create_tween()
		tween.tween_property(luz, "color", color_original, 0.25)

func destruir_arbol() -> void:
	# Desactivar al jugador instantáneamente (sin transiciones) para que
	# no pueda moverse ni disparar mientras se cambia a la escena de muerte.
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.hide()
		player.process_mode = Node.PROCESS_MODE_DISABLED

	# Cambiar a la escena de muerte en lugar de añadirla como hijo.
	get_tree().change_scene_to_file("res://ui/dead/dead.tscn")
	
func _ready() -> void:
	vida_actual = vida_maxima
	actualizar_barra_vida()
