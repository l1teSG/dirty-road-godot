class_name EnemigoBase
extends CharacterBody2D



# --- ATRIBUTOS ---
@export var vida_maxima: float = 20.0
@export var velocidad: float = 150.0

# Nodos hijos
@onready var cerebro = $AIController2D
@onready var visual = $ShapeCarbonilla

# --- VARIABLES CONTROLADAS POR LA IA ---
var vector_movimiento: Vector2 = Vector2.ZERO
var intentando_disparar: bool = false

# Estado interno
var vida_actual: float
var posicion_inicial: Vector2

func _ready() -> void:
	# Nos aseguramos de que Godot sepa que este es un enemigo
	add_to_group("enemigos")
	posicion_inicial = global_position
	reiniciar_estado()

# Función que el Cerebro llama cada vez que empieza un nuevo intento
func reiniciar_estado() -> void:
	vida_actual = vida_maxima
	global_position = posicion_inicial
	vector_movimiento = Vector2.ZERO
	visible = true
	set_physics_process(true)
	
	# Asegurarnos de que el colisionador funcione de nuevo si estaba apagado
	if has_node("CollisionPolygon2D"):
		$CollisionPolygon2D.disabled = false

func _physics_process(delta: float) -> void:
	# 1. Aplicamos el movimiento que el Cerebro nos dictó
	velocity = vector_movimiento * velocidad
	move_and_slide()
	
	# 2. CASTIGO LEVE CONSTANTE: La IA pierde un poquito de puntos por cada 
	# segundo que pasa. Esto la obliga a ser rápida y buscarte agresivamente.
	cerebro.otorgar_recompensa(-0.01)

# ---------------------------------------------------------
# SISTEMA DE DAÑO Y APRENDIZAJE
# ---------------------------------------------------------

# Tu arma debe llamar a esta función cuando golpee al enemigo
func recibir_dano(cantidad: float) -> void:
	vida_actual -= cantidad
	
	# CASTIGO: Le decimos al cerebro "¡Hiciste mal, te golpearon!"
	cerebro.otorgar_recompensa(-0.5) 
	
	# Efecto visual de parpadeo (opcional)
	if is_instance_valid(visual):
		visual.modulate = Color(5, 5, 5) # Brilla en blanco/neón
		await get_tree().create_timer(0.05).timeout
		visual.modulate = Color.WHITE

	if vida_actual <= 0:
		morir()

func morir() -> void:
	# CASTIGO MÁXIMO: La IA aprende que morir es lo peor que le puede pasar
	cerebro.otorgar_recompensa(-1.0) 
	cerebro.esta_muerto = true
	
	# En lugar de borrarlo (queue_free), lo escondemos. 
	# La IA necesita que siga existiendo para reiniciar el ciclo rápido.
	visible = false
	set_physics_process(false)
	if has_node("CollisionPolygon2D"):
		$CollisionPolygon2D.disabled = true

# Llama a esto desde un Area2D cuando el enemigo toque al jugador
func golpear_jugador() -> void:
	# PREMIO: ¡La IA aprende que golpear es su objetivo principal en la vida!
	cerebro.otorgar_recompensa(2.0)
