extends Node

enum PopupVariant { WAVE_BREAK, DEATH, ENEMY_CARD, SURVIVAL }

@export var survival_interval: float = 120.0
## Probabilidad (0-1) de que un mensaje sea de la temática de la etapa actual
@export_range(0.0, 1.0) var stage_mix_ratio: float = 0.4
## Oleadas mínimas entre dos datos nuevos de un mismo enemigo ya conocido
@export var enemy_repeat_waves: int = 3

const FALLBACK_ENEMY: Dictionary = {
	"name": "Contaminación",
	"represents": "Una amenaza para el ecosistema.",
	"facts": ["Cada forma de contaminación afecta el equilibrio natural."]
}

var _popup: CanvasLayer

# ───────────── DATOS (se reciben con set_data) ─────────────
# Formato:
# {
#   "general": {
#       "wave_break": [String],
#       "death": [String],
#       "survival": [String]
#   },
#   "stages": [
#       {
#           "theme": String, "intro": String,
#           "facts": [String], "death": [String],
#           "boss_defeated": String, "action": String,
#           "enemies": {
#               enemy_id: { "name", "represents", "facts": [..] o "fact": "..", "action"? }
#           }
#       },
#       ...
#   ]
# }
# Los jefes van dentro de "enemies" como cualquier otro enemigo.
var _wave_break_messages: Array = []
var _death_messages: Array = []
var _survival_facts: Array = []
var _stages: Array = []
var _enemy_index: Dictionary = {}   # enemy_id -> índice de etapa (se calcula solo)

# ───────────── ESTADO INTERNO ─────────────
var _wave_queue: Array = []
var _death_queue: Array = []
var _survival_queue: Array = []
var _last_wave_message: String = ""
var _last_death_message: String = ""
var _last_survival_fact: String = ""

var _stage_queues: Dictionary = {}       # "tipo_etapa" -> Array
var _enemy_queues: Dictionary = {}       # enemy_id -> Array
var _seen_enemies: Dictionary = {}       # solo esta partida
var _discovered_enemies: Dictionary = {} # enciclopedia (no se borra al reiniciar)
var _enemy_last_shown: Dictionary = {}   # enemy_id -> número de oleada

var current_stage: int = 0
var _wave_counter: int = 0
var _survival_timer: Timer


func _ready() -> void:
	randomize()

	var popup_script = load("res://scripts/education/EducationPopup.gd")
	_popup = popup_script.new()
	add_child(_popup)

	_survival_timer = Timer.new()
	_survival_timer.wait_time = survival_interval
	_survival_timer.one_shot = false
	_survival_timer.timeout.connect(_on_survival_timeout)
	add_child(_survival_timer)


# ───────────── API: DATOS ─────────────

## Carga TODO el contenido: listas generales + etapas (con enemigos).
## Las claves que falten se tratan como vacías.
func set_data(data: Dictionary) -> void:
	var general: Dictionary = data.get("general", {})
	_wave_break_messages = general.get("wave_break", [])
	_death_messages = general.get("death", [])
	_survival_facts = general.get("survival", [])
	_stages = data.get("stages", [])
	_clear_queues()
	_rebuild_enemy_index()


## Añade o reemplaza una sola etapa (útil para cargar etapas bajo demanda).
func set_stage(index: int, stage: Dictionary) -> void:
	if index < 0:
		return
	while _stages.size() <= index:
		_stages.append({})
	_stages[index] = stage
	_stage_queues.clear()
	_enemy_queues.clear()
	_rebuild_enemy_index()


func get_stage(index: int) -> Dictionary:
	if index < 0 or index >= _stages.size():
		return {}
	return _stages[index]


func get_stage_count() -> int:
	return _stages.size()


## Enemigos (y jefe) de una etapa: {enemy_id: info}
func get_stage_enemies(index: int) -> Dictionary:
	return get_stage(index).get("enemies", {})


func has_enemy(enemy_id: String) -> bool:
	return _enemy_index.has(enemy_id)


## Índice de la etapa a la que pertenece el enemigo (-1 si no existe)
func get_enemy_stage(enemy_id: String) -> int:
	return _enemy_index.get(enemy_id, -1)


func get_enemy_data(enemy_id: String) -> Dictionary:
	if _enemy_index.has(enemy_id):
		return _stages[_enemy_index[enemy_id]]["enemies"][enemy_id]
	return FALLBACK_ENEMY


## Para la enciclopedia: {enemy_id: info} de lo descubierto
func get_discovered_enemies() -> Dictionary:
	var res: Dictionary = {}
	for id in _discovered_enemies.keys():
		res[id] = get_enemy_data(id)
	return res


func _rebuild_enemy_index() -> void:
	_enemy_index.clear()
	for i in _stages.size():
		var enemies: Dictionary = _stages[i].get("enemies", {})
		for id in enemies.keys():
			if _enemy_index.has(id):
				push_warning("EducationManager: enemy_id duplicado '%s' (etapas %d y %d)" % [id, _enemy_index[id] + 1, i + 1])
			_enemy_index[id] = i


func _clear_queues() -> void:
	_wave_queue.clear()
	_death_queue.clear()
	_survival_queue.clear()
	_stage_queues.clear()
	_enemy_queues.clear()


# ───────────── API: FLUJO DE JUEGO ─────────────

func start_run() -> void:
	_seen_enemies.clear()
	_enemy_last_shown.clear()
	_clear_queues()
	_wave_counter = 0
	_survival_timer.start()


func stop_run() -> void:
	_survival_timer.stop()


func on_stage_started(stage_index: int) -> void:
	if stage_index < 0:
		return
	current_stage = stage_index
	var info: Dictionary = _stage_data()
	if info.is_empty():
		return
	var text: String = "ETAPA %d: %s\n%s" % [stage_index + 1, info.get("theme", ""), info.get("intro", "")]
	_popup.enqueue(text, PopupVariant.ENEMY_CARD, 4.0)


func on_wave_ended() -> void:
	_wave_counter += 1
	var msg: String = _mix(_wave_queue, _wave_break_messages, "_last_wave_message", "wave", "facts")
	if msg != "":
		_popup.enqueue(msg, PopupVariant.WAVE_BREAK, 3.5)


func on_enemy_encountered(enemy_id: String) -> void:
	var info: Dictionary = get_enemy_data(enemy_id)

	if not _seen_enemies.has(enemy_id):
		_seen_enemies[enemy_id] = true
		_discovered_enemies[enemy_id] = true
		_enemy_last_shown[enemy_id] = _wave_counter
		var text: String = "%s\n%s\n%s" % [
			info.get("name", "?"), info.get("represents", ""), _next_enemy_fact(enemy_id, info)]
		_popup.enqueue(text, PopupVariant.ENEMY_CARD, 4.0)
		return

	var ultimo: int = _enemy_last_shown.get(enemy_id, 0)
	if _wave_counter - ultimo < enemy_repeat_waves:
		return
	if _enemy_facts(info).size() <= 1:
		return
	_enemy_last_shown[enemy_id] = _wave_counter
	var text2: String = "%s\n%s" % [info.get("name", "?"), _next_enemy_fact(enemy_id, info)]
	_popup.enqueue(text2, PopupVariant.ENEMY_CARD, 4.0)


func on_boss_defeated(stage_index: int = -1) -> void:
	var info: Dictionary = _stage_data(stage_index)
	if info.is_empty():
		return
	var text: String = info.get("boss_defeated", "")
	if info.has("action"):
		text += "\nTú puedes: " + info["action"]
	if text != "":
		_popup.enqueue(text, PopupVariant.WAVE_BREAK, 5.0)


func on_player_died() -> void:
	stop_run()
	var msg: String = _mix(_death_queue, _death_messages, "_last_death_message", "death", "death")
	if msg != "":
		_popup.enqueue(msg, PopupVariant.DEATH, 3.5)
		await _popup.popup_finished


# ───────────── INTERNO ─────────────

func _on_survival_timeout() -> void:
	var fact: String = _mix(_survival_queue, _survival_facts, "_last_survival_fact", "survival", "facts")
	if fact != "":
		_popup.enqueue(fact, PopupVariant.SURVIVAL, 3.5)


func _stage_data(idx: int = -1) -> Dictionary:
	if _stages.is_empty():
		return {}
	if idx < 0:
		idx = current_stage
	return _stages[clampi(idx, 0, _stages.size() - 1)]


func _mix(queue: Array, source: Array, last_prop: String, kind: String, key: String) -> String:
	if randf() < stage_mix_ratio:
		var s: String = _draw_stage(kind, key)
		if s != "":
			return s
	return _draw(queue, source, last_prop)


func _draw_stage(kind: String, key: String) -> String:
	if _stages.is_empty():
		return ""
	var idx: int = clampi(current_stage, 0, _stages.size() - 1)
	var info: Dictionary = _stages[idx]
	var pool: Array = info.get(key, [])
	if pool.is_empty():
		return ""

	var qk: String = "%s_%d" % [kind, idx]
	var queue: Array = _stage_queues.get(qk, [])
	if queue.is_empty():
		queue.append_array(pool)
		queue.shuffle()
	var picked: String = queue.pop_front()
	_stage_queues[qk] = queue
	return "ETAPA %d · %s\n%s" % [idx + 1, info.get("theme", ""), picked]


func _enemy_facts(info: Dictionary) -> Array:
	if info.has("facts"):
		return info["facts"]
	return [info.get("fact", "")]


func _next_enemy_fact(enemy_id: String, info: Dictionary) -> String:
	var facts: Array = _enemy_facts(info)
	if facts.is_empty():
		return ""
	var queue: Array = _enemy_queues.get(enemy_id, [])
	if queue.is_empty():
		queue.append_array(facts)
		queue.shuffle()
	var picked: String = queue.pop_front()
	_enemy_queues[enemy_id] = queue
	return picked


func _draw(queue: Array, source: Array, last_property_name: String) -> String:
	if source.is_empty():
		return ""
	if queue.is_empty():
		queue.append_array(source)
		queue.shuffle()
		var last_value = get(last_property_name)
		if queue.size() > 1 and queue[0] == last_value:
			var tmp = queue[0]
			queue[0] = queue[1]
			queue[1] = tmp

	var picked: String = queue.pop_front()
	set(last_property_name, picked)
	return picked
