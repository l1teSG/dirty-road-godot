class_name ClassProyectil
extends Area2D

@export var sped: float = 400.0
@export var vida_util: float = 2.0
@onready var visual: Node2D = $hoja  

var positionEnemi: Vector2 = Vector2.ZERO
var _destruyendo: bool = false

func _ready() -> void:
	if positionEnemi != Vector2.ZERO:
		rotation = positionEnemi.angle()

	var timer = get_tree().create_timer(vida_util)
	timer.timeout.connect(_destruir)

func _physics_process(delta: float) -> void:
	if not _destruyendo:
		shoot(positionEnemi, delta)

func shoot(dir: Vector2, delta: float) -> void:
	global_position += delta * sped * dir

func _on_body_entered(body: Node2D) -> void:
	print("Colisión con: ", body.name, " grupos: ", body.get_groups())
	if body.is_in_group('enemi') and not _destruyendo:
		if body.has_method('take_hit'):
			body.take_hit(10)
		_destruir()

func _destruir() -> void:
	if _destruyendo:
		return
	_destruyendo = true

	set_deferred('monitoring', false)
	set_deferred('monitorable', false)

	if has_node('CollisionShape2D'):
		$CollisionShape2D.set_deferred('disabled', true)

	if has_node('CPUParticles2D'):
		$CPUParticles2D.emitting = false

	await _animar_impacto()
	queue_free()

func _animar_impacto() -> void:
	var objetivo = visual if visual else self
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(objetivo, 'scale', objetivo.scale * 1.8, 0.25)
	tween.tween_property(objetivo, 'modulate:a', 0.0, 0.25)
	await tween.finished
