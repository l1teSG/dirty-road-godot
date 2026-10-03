extends Node

# ---------------------------------------------------------------------------
# EducationManager — Autoload por script (res://scripts/education/EducationManager.gd)
#
# - Crea el popup en _ready(), sin depender de settings.
# - NO busca EducationSettings en _ready() (el Autoload arranca antes que la
#   escena; ahí la búsqueda siempre falla).
# - Detecta el nodo settings de 3 formas:
#     1) señal node_added (por grupo O por tipo de script)
#     2) búsqueda por grupo en cada evento
#     3) búsqueda por tipo (nodo con EducationSettings.gd aunque le falte
#        el grupo → se agrega al grupo solo)
# - Si no existe ningún nodo, crea uno TEMPORAL con valores por defecto
#   (EducationSettings_Auto) para que popups y teclas de debug funcionen.
#
# API para WaveManager / nivel / jugador:
#   set_data(data), start_run(), stop_run(),
#   on_stage_started(idx), on_wave_started(), on_wave_ended(),
#   on_enemy_encountered(enemy_id), on_boss_defeated(idx),
#   show_wave_break(), show_death(), on_player_died(), show_survival_fact(),
#   get_discovered(), load_discovered(data)
# ---------------------------------------------------------------------------

const SETTINGS_GROUP: String = "education_settings"

enum PopupVariant { WAVE_BREAK, DEATH, ENEMY_CARD, SURVIVAL }

const FALLBACK_ENEMY: Dictionary = {
	"name": "Contaminación",
	"represents": "Una amenaza para el ecosistema.",
	"facts": ["Cada forma de contaminación afecta el equilibrio natural."]
}

var settings: EducationSettings = null

# ── DATOS (set_data o embebidos en el nodo settings) ──
var _wave_break_messages: Array = []
var _death_messages: Array = []
var _survival_facts: Array = []
var _stages: Array = []
var _enemy_index: Dictionary = {}   # enemy_id -> índice de etapa

# ── ESTADO ──
var _popup: EducationPopup = null
var _survival_timer: Timer = null
var _bags: Dictionary = {}
var _last: Dictionary = {}
var _stage_queues: Dictionary = {}
var _enemy_queues: Dictionary = {}
var _seen_enemies: Dictionary = {}       # descubiertos en esta partida
var _discovered_enemies: Dictionary = {} # enciclopedia (persistente)
var _enemy_last_shown: Dictionary = {}   # enemy_id -> oleada del último dato
var current_stage: int = -1
var _wave_counter: int = 0
var _announced_stage: int = -1
var _running: bool = false
var _auto_settings: EducationSettings = null  # temporal creado en runtime


func _ready() -> void:
	randomize()

	# El popup se crea SIEMPRE, sin depender de settings.
	_popup = EducationPopup.new()
	_popup.manager = self
	add_child(_popup)

	_survival_timer = Timer.new()
	_survival_timer.wait_time = 120.0
	_survival_timer.one_shot = false
	_survival_timer.timeout.connect(_on_survival_timeout)
	add_child(_survival_timer)

	# El Autoload arranca ANTES de que exista la escena: no buscamos aquí.
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_late_initial_check")

	print("[EducationManager] Autoload listo. Esperando nodo EducationSettings de la escena…")


func _late_initial_check() -> void:
	if settings == null:
		_ensure_settings()


func _on_node_added(node: Node) -> void:
	if not node is EducationSettings:
		return

	# Ignora el nodo temporal que creamos nosotros.
	if node == _auto_settings:
		return

	# Un nodo real de la escena siempre reemplaza al temporal.
	if _auto_settings != null:
		_auto_settings.queue_free()
		_auto_settings = null

	_apply_settings(node)


## Búsqueda perezosa con reintentos. Devuelve true si hay settings válidos.
func _ensure_settings() -> bool:
	if settings != null and is_instance_valid(settings) and settings.is_inside_tree():
		return true

	settings = null

	# 1) Búsqueda por grupo.
	var nodes := get_tree().get_nodes_in_group(SETTINGS_GROUP)

	if not nodes.is_empty():
		_apply_settings(nodes[0])
		return true

	# 2) Búsqueda por tipo: el nodo tiene el script pero le falta el grupo.
	var found := _find_settings_node()

	if found != null:
		if not found.is_in_group(SETTINGS_GROUP):
			found.add_to_group(SETTINGS_GROUP)
			push_warning(
				"[EducationManager] El nodo '" + found.name
				+ "' tiene EducationSettings.gd pero le faltaba el grupo '"
				+ SETTINGS_GROUP + "' → agregado automáticamente."
			)

		_apply_settings(found)
		return true

	# 3) No existe: crear uno temporal con valores por defecto.
	_create_runtime_settings()
	return settings != null


## Busca en la escena actual un nodo cuyo script sea EducationSettings.
func _find_settings_node() -> EducationSettings:
	var scene := get_tree().current_scene

	if scene == null:
		return null

	return _find_recursive(scene)


func _find_recursive(n: Node) -> EducationSettings:
	if n is EducationSettings and n != _auto_settings:
		return n

	for c in n.get_children():
		var r := _find_recursive(c)

		if r != null:
			return r

	return null


## Red de seguridad: popups y debugger funcionan aunque falte el nodo.
func _create_runtime_settings() -> void:
	if _auto_settings != null and is_instance_valid(_auto_settings):
		settings = _auto_settings
		return

	push_warning(
		"[EducationManager] No encontré ningún nodo EducationSettings en la escena. " +
		"Creé uno TEMPORAL con valores por defecto ('EducationSettings_Auto'). " +
		"Los parámetros del editor NO se aplicarán hasta que agregues el nodo a la " +
		"escena: nodo con script EducationSettings.gd y grupo '" + SETTINGS_GROUP + "'."
	)

	var n := EducationSettings.new()
	n.name = "EducationSettings_Auto"
	_auto_settings = n

	# Hijo del Autoload: sobrevive cambios de escena y no da errores de timing.
	add_child(n)
	_apply_settings(n)


func _apply_settings(node: Node) -> void:
	if settings == node:
		return

	settings = node as EducationSettings

	# Si el nodo guarda datos embebidos, cárgalos (opcional).
	var general = settings.get("general")
	var stages = settings.get("stages")

	if general is Dictionary and stages is Array and not (stages as Array).is_empty():
		set_data({"general": general, "stages": stages})

	if _survival_timer != null:
		_survival_timer.wait_time = maxf(settings.survival_interval, 5.0)

		if _running:
			_survival_timer.start()

	if bool(settings.get("debug_log")):
		print(
			"[EducationManager] EducationSettings conectado: ",
			settings.get_path(),
			" | etapas=",
			_stages.size()
		)


# ───────────── DATOS ─────────────

func set_data(data: Dictionary) -> void:
	var general: Dictionary = data.get("general", {})

	_wave_break_messages = general.get("wave_break", [])
	_death_messages = general.get("death", [])
	_survival_facts = general.get("survival", [])
	_stages = data.get("stages", [])

	_rebuild_enemy_index()
	_clear_queues()
	_bags.clear()
	_last.clear()

	_log(
		"Datos cargados: %d etapas, %d wave_break, %d death, %d survival"
		% [
			_stages.size(),
			_wave_break_messages.size(),
			_death_messages.size(),
			_survival_facts.size()
		]
	)


# ───────────── API: FLUJO DE JUEGO ─────────────

func start_run() -> void:
	_ensure_settings()

	_seen_enemies.clear()
	_enemy_last_shown.clear()
	_clear_queues()
	_announced_stage = -1
	_running = true

	if _survival_timer != null:
		_survival_timer.start()

	_log("Partida iniciada.")


func stop_run() -> void:
	_running = false

	if _survival_timer != null:
		_survival_timer.stop()


func on_stage_started(stage_index: int) -> void:
	if not _ensure_settings():
		return

	current_stage = stage_index

	if stage_index < 0 or _stages.is_empty():
		return

	# Evita el doble mensaje cuando la etapa se anuncia dos veces
	# (señal + llamada directa del nivel).
	if stage_index == _announced_stage:
		return

	_announced_stage = stage_index

	if _popup == null:
		return

	var idx: int = clampi(stage_index, 0, _stages.size() - 1)
	var info: Dictionary = _stages[idx]
	var theme: String = str(info.get("theme", ""))
	var intro: String = str(info.get("intro", ""))

	if intro == "":
		return

	var text := "ETAPA %d: %s\n%s" % [stage_index + 1, theme, intro]

	_popup.enqueue(text, PopupVariant.ENEMY_CARD, _duration(true), _stage_caption(idx))


func on_wave_started() -> void:
	_ensure_settings()
	_wave_counter += 1


func on_wave_ended() -> void:
	if not _ensure_settings():
		return

	if _popup == null:
		return

	var pick := _pick_message(_wave_break_messages, "facts")

	if str(pick["text"]) == "":
		return

	_popup.enqueue(
		str(pick["text"]),
		PopupVariant.WAVE_BREAK,
		_duration(false),
		str(pick["subtitle"])
	)


func on_enemy_encountered(enemy_id: String) -> void:
	if not _ensure_settings():
		return

	if not _enemy_index.has(enemy_id):
		_log("Enemigo sin datos educativos: " + enemy_id)
		return

	if _popup == null:
		return

	# Primera vez que el jugador lo conoce: ficha completa.
	if not _discovered_enemies.has(enemy_id):
		_discovered_enemies[enemy_id] = true
		_seen_enemies[enemy_id] = true

		var enemy := _get_enemy(enemy_id)
		var ename: String = str(enemy.get("name", "Contaminación"))
		var represents: String = str(enemy.get("represents", ""))
		var fact: String = _next_enemy_fact(enemy_id, enemy)

		if fact != "":
			var text := "%s\n%s  ·  %s" % [ename, represents, fact]

			_popup.enqueue(
				text,
				PopupVariant.ENEMY_CARD,
				_duration(true),
				_stage_caption(_enemy_index[enemy_id]),
				ename.substr(0, 1).to_upper()
			)

		_enemy_last_shown[enemy_id] = _wave_counter
		return

	# Ya conocido: dato nuevo cada enemy_repeat_waves oleadas.
	var repeat_waves: int = (
		settings.enemy_repeat_waves if settings != null else 3
	)
	var last: int = int(_enemy_last_shown.get(enemy_id, 0))

	if _wave_counter - last < repeat_waves:
		return

	var info := _get_enemy(enemy_id)
	var new_fact: String = _next_enemy_fact(enemy_id, info)

	if new_fact == "":
		return

	var name2: String = str(info.get("name", "Contaminación"))
	var text2 := "%s\n%s" % [name2, new_fact]

	_popup.enqueue(
		text2,
		PopupVariant.ENEMY_CARD,
		_duration(true),
		_stage_caption(_enemy_index[enemy_id]),
		name2.substr(0, 1).to_upper()
	)

	_enemy_last_shown[enemy_id] = _wave_counter


func on_boss_defeated(stage_index: int = -1) -> void:
	if not _ensure_settings():
		return

	var idx: int = current_stage if stage_index < 0 else stage_index

	if idx < 0 or idx >= _stages.size():
		return

	if _popup == null:
		return

	var msg: String = str(_stages[idx].get("boss_defeated", ""))

	if msg == "":
		return

	_popup.enqueue(msg, PopupVariant.WAVE_BREAK, _duration(true), _stage_caption(idx))


# ───────────── API: MENSAJES DIRECTOS ─────────────

func show_wave_break() -> void:
	if not _ensure_settings():
		return

	if _popup == null or _wave_break_messages.is_empty():
		return

	# Dato general: sin etapa (decisión de diseño).
	_popup.enqueue(
		_next_from_bag("general_wave_break", _wave_break_messages),
		PopupVariant.WAVE_BREAK,
		_duration(false)
	)


func show_death() -> void:
	if not _ensure_settings():
		return

	if _popup == null or _death_messages.is_empty():
		return

	_popup.enqueue(
		_next_from_bag("general_death", _death_messages),
		PopupVariant.DEATH,
		_duration(true)
	)


func on_player_died() -> void:
	if not _ensure_settings():
		return

	if _popup == null:
		return

	var pick := _pick_message(_death_messages, "death")

	if str(pick["text"]) == "":
		return

	_popup.enqueue(
		str(pick["text"]),
		PopupVariant.DEATH,
		_duration(true),
		str(pick["subtitle"])
	)


func show_survival_fact() -> void:
	if not _ensure_settings():
		return

	if _popup == null or _survival_facts.is_empty():
		return

	# "¿Sabías qué?" general: sin etapa, siempre.
	_popup.enqueue(
		_next_from_bag("general_survival", _survival_facts),
		PopupVariant.SURVIVAL,
		_duration(false)
	)


func _on_survival_timeout() -> void:
	if not _running:
		return

	show_survival_fact()


# ───────────── PERSISTENCIA (SaveManager) ─────────────

func get_discovered() -> Dictionary:
	return _discovered_enemies.duplicate()


func load_discovered(data: Dictionary) -> void:
	_discovered_enemies = data.duplicate()


# ───────────── HELPERS ─────────────

func _current_stage() -> Dictionary:
	if _stages.is_empty() or current_stage < 0:
		return {}

	return _stages[clampi(current_stage, 0, _stages.size() - 1)]


func _get_enemy(enemy_id: String) -> Dictionary:
	if _enemy_index.has(enemy_id):
		var enemies: Dictionary = _stages[_enemy_index[enemy_id]].get("enemies", {})

		if enemies.has(enemy_id):
			return enemies[enemy_id]

	return FALLBACK_ENEMY


func _enemy_facts(info: Dictionary) -> Array:
	if info.has("facts"):
		return info["facts"]

	if info.has("fact"):
		return [info["fact"]]

	return []


func _next_enemy_fact(enemy_id: String, info: Dictionary) -> String:
	return _next_from_bag("enemy_" + enemy_id, _enemy_facts(info))


## Mezcla contenido general con el de la etapa actual (stage_mix_ratio).
func _pick_message(general_pool: Array, stage_field: String) -> Dictionary:
	var st := _current_stage()
	var stage_pool: Array = st.get(stage_field, []) if not st.is_empty() else []
	var ratio: float = 0.4 if settings == null else settings.stage_mix_ratio

	if not stage_pool.is_empty() and (general_pool.is_empty() or randf() < ratio):
		return {
			"text": _next_from_bag(
				"etapa_%s_%d" % [stage_field, current_stage],
				stage_pool
			),
			"subtitle": _stage_caption()
		}

	return {
		"text": _next_from_bag("general_%s" % stage_field, general_pool),
		"subtitle": ""
	}


## Bolsa mezclada: no repite hasta agotar el pool y evita repetir el último.
func _next_from_bag(key: String, pool: Array) -> String:
	if pool.is_empty():
		return ""

	var bag: Array = _bags.get(key, [])

	if bag.is_empty():
		bag = pool.duplicate()
		bag.shuffle()

		if bag.size() > 1 and str(bag.back()) == str(_last.get(key, "")):
			var tmp = bag[0]
			bag[0] = bag[bag.size() - 1]
			bag[bag.size() - 1] = tmp

	var item: String = str(bag.pop_back())
	_bags[key] = bag
	_last[key] = item
	return item


## "ETAPA N" o "ETAPA N: tema" (respeta stage_caption_include_theme).
func _stage_caption(stage_index: int = -1) -> String:
	var idx: int = current_stage if stage_index < 0 else stage_index

	if idx < 0 or idx >= _stages.size():
		return ""

	var base := "ETAPA %d" % (idx + 1)
	var theme: String = str(_stages[idx].get("theme", "")).strip_edges()
	var include_theme: bool = (
		settings != null and settings.stage_caption_include_theme
	)

	if include_theme and theme != "":
		return base + ": " + theme

	return base


func _duration(long: bool) -> float:
	if settings != null and is_instance_valid(settings):
		return settings.enemy_duration if long else settings.message_duration

	return 5.5 if long else 4.0


func _rebuild_enemy_index() -> void:
	_enemy_index.clear()

	for i in _stages.size():
		var enemies: Dictionary = _stages[i].get("enemies", {})

		for id in enemies.keys():
			if _enemy_index.has(id):
				push_warning(
					"EducationManager: enemy_id duplicado '%s' (etapas %d y %d)"
					% [id, _enemy_index[id] + 1, i + 1]
				)

			_enemy_index[id] = i


func _clear_queues() -> void:
	_stage_queues.clear()
	_enemy_queues.clear()


func _log(msg: String) -> void:
	if settings != null and is_instance_valid(settings) and settings.debug_log:
		print("[EducationManager] ", msg)
