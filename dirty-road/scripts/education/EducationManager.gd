extends Node

# ---------------------------------------------------------------------------
# EducationManager — Autoload por script (res://scripts/education/EducationManager.gd)
#
# - Crea el popup en _ready(), sin depender de settings.
# - Detecta el nodo settings por grupo, por tipo, o crea uno TEMPORAL.
# - Si el nodo settings no trae etapas embebidas, usa EducationDataStages.
# - NUNCA crashea por propiedades ausentes en EducationSettings (usa .get()).
# - Resolución de ids tolerante: normaliza tildes/espacios/guiones por ambos
#   lados, alias por nombre visible y coincidencia por contención.
# - F9: carta de prueba para verificar que el popup funciona.
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

## Reemitida desde el popup: la cola de mensajes quedó vacía.
signal popup_finished

const FALLBACK_ENEMY: Dictionary = {
	"name": "Contaminación",
	"represents": "Una amenaza para el ecosistema.",
	"facts": ["Cada forma de contaminación afecta el equilibrio natural."]
}

var settings: EducationSettings = null

# ── DATOS ──
var _wave_break_messages: Array = []
var _death_messages: Array = []
var _survival_facts: Array = []
var _stages: Array = []
var _enemy_index: Dictionary = {}   # id normalizado -> índice de etapa
var _alias_index: Dictionary = {}   # nombre visible normalizado -> id normalizado

# ── ESTADO ──
var _popup: EducationPopup = null
var _survival_timer: Timer = null
var _bags: Dictionary = {}
var _last: Dictionary = {}
var _seen_enemies: Dictionary = {}       # descubiertos EN ESTA PARTIDA
var _discovered_enemies: Dictionary = {} # enciclopedia (persistente)
var _enemy_last_shown: Dictionary = {}   # enemy_id -> oleada del último dato
var current_stage: int = -1
var _wave_counter: int = 0
var _announced_stage: int = -1
var _running: bool = false
var _auto_settings: EducationSettings = null


func _ready() -> void:
	randomize()

	_popup = EducationPopup.new()
	_popup.manager = self
	add_child(_popup)
	_popup.popup_finished.connect(_on_popup_finished)

	_survival_timer = Timer.new()
	_survival_timer.wait_time = 120.0
	_survival_timer.one_shot = false
	_survival_timer.timeout.connect(_on_survival_timeout)
	add_child(_survival_timer)

	get_tree().node_added.connect(_on_node_added)
	call_deferred("_late_initial_check")

	print("[EducationManager] Autoload listo. Esperando nodo EducationSettings de la escena…")


func _late_initial_check() -> void:
	if settings == null:
		_ensure_settings()


func _on_node_added(node: Node) -> void:
	if not node is EducationSettings:
		return

	if node == _auto_settings:
		return

	if _auto_settings != null:
		_auto_settings.queue_free()
		_auto_settings = null

	_apply_settings(node)


func _ensure_settings() -> bool:
	if settings != null and is_instance_valid(settings) and settings.is_inside_tree():
		return true

	settings = null

	var nodes := get_tree().get_nodes_in_group(SETTINGS_GROUP)

	if not nodes.is_empty():
		_apply_settings(nodes[0])
		return true

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

	_create_runtime_settings()
	return settings != null


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


func _create_runtime_settings() -> void:
	if _auto_settings != null and is_instance_valid(_auto_settings):
		settings = _auto_settings
		return

	push_warning(
		"[EducationManager] No encontré ningún nodo EducationSettings en la escena. " +
		"Creé uno TEMPORAL ('EducationSettings_Auto') con EducationDataStages como contenido."
	)

	var n := EducationSettings.new()
	n.name = "EducationSettings_Auto"
	_auto_settings = n
	add_child(n)
	_apply_settings(n)


func _apply_settings(node: Node) -> void:
	if settings == node:
		return

	settings = node as EducationSettings

	var general = settings.get("general")
	var stages = settings.get("stages")

	if stages is Array and not (stages as Array).is_empty():
		set_data({
			"general": general if general is Dictionary else {},
			"stages": stages
		})
	else:
		set_data({
			"general": general if general is Dictionary else {},
			"stages": EducationDataStages.get_data()
		})

	_survival_timer.wait_time = maxf(float(_cfg("survival_interval", 120.0)), 5.0)

	if _running:
		_survival_timer.start()

	if bool(_cfg("debug_log", true)):
		print(
			"[EducationManager] EducationSettings conectado: ",
			settings.get_path(),
			" | etapas=",
			_stages.size()
		)


# ───────────── LECTURA SEGURA DE CONFIG ─────────────
## Nunca accedemos directo a settings.prop: si EducationSettings no define
## la propiedad, .get() devuelve null (sin error) y usamos el default.

func _cfg(key: String, def: Variant) -> Variant:
	if settings != null and is_instance_valid(settings):
		var v = settings.get(key)

		if v != null:
			return v

	return def


# ───────────── DATOS ─────────────

func set_data(data: Dictionary) -> void:
	var general: Dictionary = data.get("general", {})

	_wave_break_messages = general.get("wave_break", [])
	_death_messages = general.get("death", [])
	_survival_facts = general.get("survival", [])
	_stages = data.get("stages", [])

	if _stages.is_empty():
		_stages = EducationDataStages.get_data()

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


# ───────────── NORMALIZACIÓN DE IDS ─────────────
## 'Excavadora_Tóxica.tscn' → 'excavadoratoxica'
## 'Nube de Gas'            → 'nubedegas' (alias del id 'nubegas')

func _normalizar_id(s: String) -> String:
	var t := s.to_lower()

	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		t = t.replace(par[0], par[1])

	var out := ""

	for c in t:
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c

	return out


## Resuelve un id crudo (derivado del nombre de escena) contra los datos.
## Orden: exacto → alias por nombre → contención (más larga gana).
func _resolver_enemy_id(raw: String) -> String:
	var nid := _normalizar_id(raw)

	if nid == "":
		return ""

	if _enemy_index.has(nid):
		return nid

	if _alias_index.has(nid):
		return _alias_index[nid]

	# Red de seguridad: 'jefe_excavadora' contiene 'excavadora', etc.
	var mejor := ""

	for key in _enemy_index.keys():
		var k := str(key)

		if k.length() < 5:
			continue

		if nid.contains(k) or k.contains(nid):
			if k.length() > mejor.length():
				mejor = k

	return mejor


func _rebuild_enemy_index() -> void:
	_enemy_index.clear()
	_alias_index.clear()

	for i in _stages.size():
		var enemies: Dictionary = _stages[i].get("enemies", {})

		for id in enemies.keys():
			var nid := _normalizar_id(str(id))

			if _enemy_index.has(nid):
				push_warning(
					"[EducationManager] enemy_id duplicado '%s' (etapas %d y %d)"
					% [nid, _enemy_index[nid] + 1, i + 1]
				)

			_enemy_index[nid] = i

			# Alias por nombre visible: permite encontrar al enemigo aunque
			# la escena se llame distinto a la llave pero igual al nombre.
			var nname := _normalizar_id(str(enemies[id].get("name", "")))

			if nname != "" and not _alias_index.has(nname):
				_alias_index[nname] = nid

	if bool(_cfg("debug_log", true)):
		print("[EducationManager] Ids educativos disponibles: ", _enemy_index.keys())


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


## ¿Hay mensajes educativos mostrándose o en cola? Lo usa el nivel para
## no pisar el cartel de "HORDA" con un popup (p. ej. "ETAPA 1").
func esta_mostrando() -> bool:
	if _popup == null or not is_instance_valid(_popup):
		return false
	if _popup.has_method("esta_ocupado"):
		return bool(_popup.call("esta_ocupado"))
	return false


func _on_popup_finished() -> void:
	popup_finished.emit()


func on_stage_started(stage_index: int) -> void:
	if not _ensure_settings() or _popup == null:
		return

	current_stage = stage_index

	if stage_index < 0 or _stages.is_empty():
		return

	if _announced_stage == stage_index:
		return

	_announced_stage = stage_index

	var info := _current_stage()

	if info.is_empty():
		return

	var intro: String = str(info.get("intro", ""))

	if intro == "":
		return

	var theme: String = str(info.get("theme", ""))
	var text := "ETAPA %d: %s\n%s" % [stage_index + 1, theme, intro]

	_popup.enqueue(text, PopupVariant.ENEMY_CARD, _duration(true), _stage_caption(stage_index))


func on_wave_started() -> void:
	_ensure_settings()
	_wave_counter += 1


func on_wave_ended() -> void:
	if not _ensure_settings() or _popup == null:
		return

	var pick := _pick_message(_wave_break_messages, "facts")

	if str(pick["text"]) == "":
		return

	_popup.enqueue(
		str(pick["text"]),
		PopupVariant.WAVE_BREAK,
		_duration(true),
		str(pick["subtitle"])
	)


func on_enemy_encountered(raw_id: String) -> void:
	if not _ensure_settings() or _popup == null:
		return

	var enemy_id := _resolver_enemy_id(raw_id)

	if enemy_id == "":
		push_warning(
			"[EducationManager] Enemigo sin datos educativos: '"
			+ raw_id + "' (normalizado '" + _normalizar_id(raw_id)
			+ "'). Ids disponibles: " + str(_enemy_index.keys())
		)
		return

	var enemy := _get_enemy(enemy_id)
	var idx_etapa: int = _enemy_index[enemy_id]

	# PRIMERA VEZ EN ESTA PARTIDA: ficha completa. (Se repite cada partida
	# a propósito; la enciclopedia usa _discovered_enemies aparte.)
	if not _seen_enemies.has(enemy_id):
		_seen_enemies[enemy_id] = true
		_discovered_enemies[enemy_id] = true

		var ename: String = str(enemy.get("name", "Contaminación"))
		var represents: String = str(enemy.get("represents", ""))
		var fact: String = _next_enemy_fact(enemy_id, enemy)

		if fact != "":
			_popup.enqueue(
				"%s\n%s  ·  %s" % [ename, represents, fact],
				PopupVariant.ENEMY_CARD,
				_duration(true),
				_stage_caption(idx_etapa),
				ename.substr(0, 1).to_upper()
			)

		_enemy_last_shown[enemy_id] = _wave_counter
		return

	# Ya visto: dato nuevo cada enemy_repeat_waves oleadas.
	var repeat_waves: int = int(_cfg("enemy_repeat_waves", 3))
	var last: int = int(_enemy_last_shown.get(enemy_id, 0))

	if _wave_counter - last < repeat_waves:
		return

	if _enemy_facts(enemy).size() <= 1:
		return

	var new_fact: String = _next_enemy_fact(enemy_id, enemy)

	if new_fact == "":
		return

	var nombre: String = str(enemy.get("name", "Contaminación"))

	_popup.enqueue(
		"%s\n%s" % [nombre, new_fact],
		PopupVariant.ENEMY_CARD,
		_duration(true),
		_stage_caption(idx_etapa),
		nombre.substr(0, 1).to_upper()
	)

	_enemy_last_shown[enemy_id] = _wave_counter


func on_boss_defeated(stage_index: int = -1) -> void:
	if not _ensure_settings() or _popup == null:
		return

	var idx: int = current_stage if stage_index < 0 else stage_index

	if idx < 0 or idx >= _stages.size():
		return

	var msg: String = str(_stages[idx].get("boss_defeated", ""))

	if msg == "":
		return

	_popup.enqueue(msg, PopupVariant.WAVE_BREAK, _duration(true), _stage_caption(idx))


# ───────────── API: MENSAJES DIRECTOS ─────────────

func show_wave_break() -> void:
	if not _ensure_settings() or _popup == null or _wave_break_messages.is_empty():
		return

	_popup.enqueue(
		_next_from_bag("general_wave_break", _wave_break_messages),
		PopupVariant.WAVE_BREAK,
		_duration(true)
	)


func show_death() -> void:
	if not _ensure_settings() or _popup == null or _death_messages.is_empty():
		return

	_popup.enqueue(
		_next_from_bag("general_death", _death_messages),
		PopupVariant.DEATH,
		_duration(true)
	)


func on_player_died() -> void:
	if not _ensure_settings() or _popup == null:
		return

	var pick := _pick_message(_death_messages, "death")

	_popup.enqueue(
		str(pick["text"]),
		PopupVariant.DEATH,
		_duration(true),
		str(pick["subtitle"])
	)


func show_survival_fact() -> void:
	if not _ensure_settings() or _popup == null or _survival_facts.is_empty():
		return

	_popup.enqueue(
		_next_from_bag("general_survival", _survival_facts),
		PopupVariant.SURVIVAL,
		_duration(false)
	)


func _on_survival_timeout() -> void:
	if _running:
		show_survival_fact()


# ───────────── DEBUG: F9 = carta de prueba ─────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F9:
			print("[EducationManager] F9 → prueba de popup")
			_popup.enqueue(
				"PRUEBA\nSi ves esta carta, el popup funciona y el problema era el id del enemigo.",
				PopupVariant.ENEMY_CARD,
				4.0,
				"TEST"
			)


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

		for id in enemies.keys():
			if _normalizar_id(str(id)) == enemy_id:
				return enemies[id]

	return FALLBACK_ENEMY


func _enemy_facts(info: Dictionary) -> Array:
	if info.has("facts"):
		return info["facts"]

	if info.has("fact"):
		return [info["fact"]]

	return []


func _next_enemy_fact(enemy_id: String, info: Dictionary) -> String:
	return _next_from_bag("enemy_" + enemy_id, _enemy_facts(info))


func _pick_message(general_pool: Array, stage_field: String) -> Dictionary:
	var st := _current_stage()
	var stage_pool: Array = st.get(stage_field, []) if not st.is_empty() else []
	var ratio: float = float(_cfg("stage_mix_ratio", 0.4))

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


func _next_from_bag(key: String, pool: Array) -> String:
	if pool.is_empty():
		return ""

	var bag: Array = _bags.get(key, [])

	if bag.is_empty():
		bag = pool.duplicate()
		bag.shuffle()

	var item: String = str(bag.pop_back())
	_bags[key] = bag
	_last[key] = item
	return item


func _stage_caption(stage_index: int = -1) -> String:
	var idx: int = current_stage if stage_index < 0 else stage_index

	if idx < 0 or idx >= _stages.size():
		return ""

	var base := "ETAPA %d" % (idx + 1)
	var theme: String = str(_stages[idx].get("theme", "")).strip_edges()

	if bool(_cfg("stage_caption_include_theme", true)) and theme != "":
		return base + ": " + theme

	return base


func _duration(long: bool) -> float:
	if long:
		return float(_cfg("enemy_duration", 5.5))

	return float(_cfg("message_duration", 4.0))


func _clear_queues() -> void:
	_bags.clear()
	_last.clear()


func _log(msg: String) -> void:
	if bool(_cfg("debug_log", true)):
		print("[EducationManager] ", msg)
