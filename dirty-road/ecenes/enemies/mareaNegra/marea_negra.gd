class_name MareaNegra
extends enemigoNuevo

## ------------------------------------------------------------
## Enemigo Tanque "Marea Negra"
## Avanza lentamente hacia el Árbol, lo ataca en rango y es
## resistente al empuje.
## ------------------------------------------------------------

# Variables exportables (ajustables en Inspector)
@export var velocidad_movimiento: float = 40.0
@export var resistencia_knockback: float = 0.85   # Absorbe el 85% del empuje recibido
@export var fuerza_friccion_knockback: float = 350.0

# Estado interno
var vector_knockback: Vector2 = Vector2.ZERO

func _ready() -> void:
	super()

	# Registrar en el grupo de enemigos (usa "enemi" como el resto del proyecto)
	add_to_group("enemi")

	# Forzar perfil de Tanque sobreescribiendo parámetros heredados
	life = 300
	danio_ataque = 25
	tiempo_recarga = 2.5
	distancia_ataque = 35.0
	distancia_urgencia_arbol = 2000.0   # Prioridad absoluta al Árbol
	distancia_max_aggro = 50.0          # Rango de aggro ultra reducido
	tiempo_aggro = 0.5                  # Pierde el aggro del jugador casi de inmediato


func _physics_process(delta: float) -> void:
	# Ejecuta comportamiento base (animación, selección de objetivo, evaluación de ataque)
	super(delta)

	# Lógica de desplazamiento físico hacia el objetivo
	if is_instance_valid(objetivo):
		var dist: float = global_position.distance_to(objetivo.global_position)
		if dist > distancia_ataque:
			var direccion: Vector2 = (objetivo.global_position - global_position).normalized()
			velocity = (direccion * velocidad_movimiento) + vector_knockback
		else:
			# Dentro del rango de ataque -> detiene el avance
			velocity = vector_knockback
	else:
		# Sin objetivo válido, detener movimiento
		velocity = vector_knockback

	# Amortiguar el knockback progresivamente
	vector_knockback = vector_knockback.move_toward(Vector2.ZERO, fuerza_friccion_knockback * delta)

	# Aplicar movimiento en el motor de físicas 2D
	move_and_slide()


func recibir_danio(cantidad: int, atacante: Node2D = null) -> void:
	# Aplicar knockback reducido por la resistencia del tanque
	if atacante != null and is_instance_valid(atacante):
		var dir_empuje: Vector2 = (global_position - atacante.global_position).normalized()
		vector_knockback = dir_empuje * (80.0 * (1.0 - resistencia_knockback))

	# Delegar el resto del daño (resta de vida, comprobación de muerte,
	# emisión de biomasa y eliminación) al método base
	super(cantidad, atacante)


func take_hit(damage: int = 10) -> void:
	recibir_danio(damage)
