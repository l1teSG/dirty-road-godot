extends CharacterBody2D

# ── Parámetros de movimiento ──────────────────────────
@export var speed: float = 80.0
@export var rango_deteccion: float = 250.0
@export var distancia_ataque: float = 50.0
@export var danio_ataque: int = 5
@export var tiempo_recarga: float = 2.0

# ── Control interno ───────────────────────────────────
var puede_atacar: bool = true
var objetivo: Node2D = null
var tiempo_anim: float = randf() * 10.0


func _physics_process(delta: float) -> void:
	# Desactivado: no se ejecuta ninguna lógica de movimiento, búsqueda de
	# objetivos ni ataques. El enemigo permanece completamente estático e
	# inofensivo.
	velocity = Vector2.ZERO
	move_and_slide()


func _animar_cuerpo(delta: float) -> void:
	tiempo_anim += delta * 6.0
	var deformacion = sin(tiempo_anim) * 0.04
	scale.x = 1.0 + deformacion
	scale.y = 1.0 - deformacion


func _seleccionar_objetivo() -> void:
	# Desactivado: no se selecciona ningún objetivo.
	pass


func _mover_hacia_objetivo() -> void:
	# Desactivado: no se mueve hacia ningún objetivo.
	pass


func _ejecutar_ataque() -> void:
	# Desactivado: no se ejecuta ningún ataque.
	pass
