class_name proyectil_player
extends Area2D

# --- PROPIEDADES CONFIGURABLES ---
@export var velocidad: float = 600.0
@export var dano: float = 10.0
@export var tiempo_vida: float = 3.0 # Segundos antes de destruirse si no choca

# Variables que se asignan al disparar
var direccion: Vector2 = Vector2.RIGHT
var color_proyectil: Color = Color("#00f0ff")
var es_penetrante: bool = false # Para Quark (atraviesa enemigos)

# --- REFERENCIAS A NODOS HIJOS ---
@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var particles_2d: GPUParticles2D = $GPUParticles2D
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	# 1. Conectar señales de detección de colisión y pantalla
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	notifier.screen_exited.connect(_on_screen_exited)
	
	# 2. Timer de seguridad para eliminarlo si no choca
	get_tree().create_timer(tiempo_vida).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# Mover el proyectil hacia la dirección asignada
	global_position += direccion * velocidad * delta

# --- MÉTODOS DE CONFIGURACIÓN ---

## Llama a esta función inmediatamente después de instanciar el proyectil
func inicializar(p_posicion: Vector2, p_direccion: Vector2, p_color: Color, p_dano: float, p_penetrante: bool = false) -> void:
	global_position = p_posicion
	direccion = p_direccion.normalized()
	color_proyectil = p_color
	dano = p_dano
	es_penetrante = p_penetrante
	
	# Rotar el proyectil hacia donde vuela
	rotation = direccion.angle()
	
	# Aplicar el color Neón a la figura y a las partículas
	if is_node_ready():
		_aplicar_estilo()

func _aplicar_estilo() -> void:
	if polygon_2d:
		polygon_2d.color = color_proyectil
	if particles_2d:
		particles_2d.modulate = color_proyectil
		particles_2d.emitting = true

# --- MANEJO DE COLISIONES ---

func _on_body_entered(body: Node2D) -> void:
	_procesar_impacto(body)

func _on_area_entered(area: Area2D) -> void:
	_procesar_impacto(area)

func _procesar_impacto(objetivo: Node2D) -> void:
	# Verificar si el objeto golpeado pertenece al grupo "enemigos"
	if objetivo.is_in_group("enemigos"):
		# Aplicar daño si el enemigo tiene la función recibir_dano
		if objetivo.has_method("recibir_dano"):
			objetivo.recibir_dano(dano)
		
		# Si no es un disparo penetrante (ej: Quark), se destruye al chocar
		if not es_penetrante:
			queue_free()
	
	# Si choca contra una pared o cobertura del mapa (TileMap)
	elif objetivo is TileMap or objetivo.is_in_group("paredes"):
		queue_free()

func _on_screen_exited() -> void:
	# Eliminar proyectil al salir de la vista de la cámara para liberar memoria
	queue_free()
