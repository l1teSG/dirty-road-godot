class_name EnemigoCerebro
extends AIController2D

# --- PROPIEDADES REQUERIDAS POR EL PLUGIN ---
enum ControlModes { AI, HUMAN, Heuristic }
@export var control_mode: ControlModes = ControlModes.AI

# Referencia al cuerpo de la marioneta
@onready var cuerpo: EnemigoBase = get_parent() as EnemigoBase

var recompensa_acumulada: float = 0.0
var esta_muerto: bool = false

# ---------------------------------------------------------
# 1. ¿QUÉ VE LA IA? (Observaciones)
# ---------------------------------------------------------
func get_obs() -> Dictionary:
	var jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	var dir_jugador := Vector2.ZERO
	var dist_jugador := 0.0

	if is_instance_valid(jugador) and is_instance_valid(cuerpo):
		dir_jugador = (jugador.global_position - cuerpo.global_position).normalized()
		dist_jugador = cuerpo.global_position.distance_to(jugador.global_position) / 1000.0

	var obs: Array[float] = [
		dir_jugador.x,
		dir_jugador.y,
		dist_jugador,
		cuerpo.vida_actual / cuerpo.vida_maxima
	]
	return {"obs": obs}

# ---------------------------------------------------------
# 2. EL MAPA DE ACCIONES
# ---------------------------------------------------------
func get_action_space() -> Dictionary:
	return {
		"movement": {
			"size": 2,
			"action_type": "continuous"
		}
	}

# ---------------------------------------------------------
# 3. ¿QUÉ DECIDE HACER LA IA? (Acciones)
# ---------------------------------------------------------
func set_action(action: Dictionary) -> void:
	if not is_instance_valid(cuerpo) or esta_muerto:
		return

	if action.has("movement"):
		var move_dir = Vector2(action.movement[0], action.movement[1])
		cuerpo.vector_movimiento = move_dir

	if action.has("shoot"):
		cuerpo.intentando_disparar = action.shoot[0] > 0.5

# ---------------------------------------------------------
# 4. RECOMPENSAS
# ---------------------------------------------------------
func get_reward() -> float:
	var recompensa_actual = recompensa_acumulada
	recompensa_acumulada = 0.0 
	return recompensa_actual

func otorgar_recompensa(valor: float) -> void:
	recompensa_acumulada += valor

func get_done() -> bool:
	return esta_muerto

func reset() -> void:
	esta_muerto = false
	recompensa_acumulada = 0.0
	if is_instance_valid(cuerpo):
		cuerpo.reiniciar_estado()
