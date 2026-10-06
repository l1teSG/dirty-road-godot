class_name ClassProyectil
extends Area2D

## Grupos que cuentan como enemigo: 'enemigos' (clase Enemigo
## nueva) y 'enemi' (enemigos viejos, mientras sigan existiendo).
const GRUPOS_ENEMIGO: Array[String] = ["enemigos", "enemi"]

const DANO: float = 10.0

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
	if _es_enemigo(body) and not _destruyendo:
		_dañar_enemigo(body)
		_destruir()

func _es_enemigo(nodo: Node2D) -> bool:
	for grupo in GRUPOS_ENEMIGO:
		if nodo.is_in_group(grupo):
			return true
	return false

## Respeta el contrato de cada enemigo:
## • Nuevo (Enemigo.gd): recibir_danio(cantidad) — 1 argumento.
## • Viejo: recibir_danio(cantidad, fuente) — 2 argumentos.
## • Viejo: take_hit(int) / take_damage(int).
func _dañar_enemigo(enemigo: Node2D) -> void:
	if enemigo.has_method("recibir_danio"):
		if _metodo_tiene_n_args(enemigo, "recibir_danio", 2):
			enemigo.call("recibir_danio", DANO, self)
		else:
			enemigo.call("recibir_danio", DANO)
	elif enemigo.has_method("take_hit"):
		enemigo.call("take_hit", DANO)
	elif enemigo.has_method("take_damage"):
		enemigo.call("take_damage", roundi(DANO))

## Cuenta los argumentos de un método (para no romper firmas viejas).
func _metodo_tiene_n_args(nodo: Node, metodo: String, n: int) -> bool:
	for m in nodo.get_method_list():
		if m.get("name", "") == metodo:
			return (m.get("args", []) as Array).size() == n
	return false

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
