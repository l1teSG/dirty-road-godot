class_name enemigoNuevo
extends CharacterBody2D

var tiempo_anim: float = randf() * 10.0
var life: int = 30  # ajusta a la vida que quieras

# ── Parámetros de ataque (editable desde Inspector) ──
@export_category("Parámetros de Ataque")
@export var distancia_ataque: float = 100.0
@export var danio_ataque: int = 10
@export var tiempo_recarga: float = 1.5
@export var requiere_linea_vision: bool = false

# ── Control interno ───────────────────────────────────
var puede_atacar: bool = true
var objetivo: Node2D = null

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

func _physics_process(delta: float) -> void:
	animar_cuerpo_enemigo(delta)

func take_hit(damage: int = 10) -> void:
	life -= damage
	if life <= 0:
		var label = get_tree().current_scene.find_child("TextoBiomasa", true, false)
		if label:
			BiomasaManager.emitir_biomasa(global_position, label.global_position, label.get_node("/root").find_child("ui", true, false))
		self.queue_free()

# ── Método principal de ataque ────────────────────────
func evaluar_y_ejecutar_ataque() -> void:
	if not is_instance_valid(objetivo):
		return

	if not puede_atacar:
		return

	var distancia = global_position.distance_to(objetivo.global_position)
	if distancia > distancia_ataque:
		return

	# Si se requiere línea de visión, podrías implementar un raycast aquí
	# (por simplicidad, se omite en este ejemplo)

	# Ejecutar ataque según el tipo de objetivo
	if objetivo.has_method("take_damage"):
		objetivo.take_damage(danio_ataque)
	elif objetivo.has_method("recibir_danio"):
		objetivo.recibir_danio(danio_ataque)

	# Iniciar recarga
	puede_atacar = false
	await get_tree().create_timer(tiempo_recarga).timeout
	puede_atacar = true
