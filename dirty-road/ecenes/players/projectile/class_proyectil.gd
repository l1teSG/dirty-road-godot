class_name ClassProyectil
extends Area2D

## Grupos que cuentan como enemigo: 'enemigos' (clase Enemigo
## nueva) y 'enemi' (enemigos viejos, mientras sigan existiendo).
const GRUPOS_ENEMIGO: Array[String] = ["enemigos", "enemi"]

## Daño por defecto. El jugador lo sobreescribe con set("dano", ...) para
## incluir críticos y mejoras. Antes era una constante y se ignoraba.
@export var dano: float = 10.0

@export var sped: float = 400.0
@export var vida_util: float = 2.0
## Nº de enemigos ADICIONALES que puede atravesar (0 = se destruye al 1º).
@export var perforacion: int = 0
@onready var visual: Node2D = $hoja

var positionEnemi: Vector2 = Vector2.ZERO
var _destruyendo: bool = false
var _perforados: int = 0
var _golpeados: Dictionary = {}

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
	if _destruyendo or not _es_enemigo(body):
		return

	# Evita golpear dos veces al mismo enemigo mientras lo atraviesa.
	var id := body.get_instance_id()
	if _golpeados.has(id):
		return
	_golpeados[id] = true

	_dañar_enemigo(body)

	if _perforados < maxi(perforacion, 0):
		_perforados += 1
		return
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
	var d := dano
	if SaveManager != null:
		var cat := str(enemigo.get("categoria"))
		if cat == "toxico":
			d *= 1.0 + SaveManager.get_stat("jugador.danio_toxico", 0.0)
		elif cat == "acuatico":
			d *= 1.0 + SaveManager.get_stat("jugador.danio_acuaticos", 0.0)
		elif cat == "elite":
			d *= 1.0 + SaveManager.get_stat("jugador.danio_elite", 0.0)
	if enemigo.has_method("recibir_danio"):
		if _metodo_tiene_n_args(enemigo, "recibir_danio", 2):
			enemigo.call("recibir_danio", d, self)
		else:
			enemigo.call("recibir_danio", d)
	elif enemigo.has_method("take_hit"):
		enemigo.call("take_hit", d)
	elif enemigo.has_method("take_damage"):
		enemigo.call("take_damage", roundi(d))
	_aplicar_efectos(enemigo)


## Efectos "hook" de las cartas al impactar (quemadura, ralentizar, aturdir).
func _aplicar_efectos(enemigo: Node2D) -> void:
	if SaveManager == null:
		return
	var quem := SaveManager.get_stat("jugador.danio_continuo", 0.0)
	if quem > 0.0 and enemigo.has_method("aplicar_quemadura"):
		enemigo.call("aplicar_quemadura", 4.0 * quem, 2.0)
	var ral := SaveManager.get_stat("jugador.ralentizar", 0.0)
	if ral > 0.0 and enemigo.has_method("aplicar_ralentizado"):
		enemigo.call("aplicar_ralentizado", clampf(ral, 0.0, 0.6), 1.2)
	var stu := maxf(SaveManager.get_stat("jugador.paralizar", 0.0), SaveManager.get_stat("jugador.aturdir", 0.0))
	if stu > 0.0 and randf() < clampf(stu * 0.5, 0.0, 0.5) and enemigo.has_method("aplicar_aturdimiento"):
		enemigo.call("aplicar_aturdimiento", 0.35)

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
