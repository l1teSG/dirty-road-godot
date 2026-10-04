class_name EducationPopup
extends CanvasLayer

# ---------------------------------------------------------------------------
# EducationPopup v6.1 - Temas por tipo de mensaje + fix de desbordamiento
# Lo crea EducationManager (Autoload): EducationPopup.new().
# Toda la configuración se lee del nodo EducationSettings (manager.settings).
#
# Fix v6.1 (texto fuera de la tarjeta / del chip):
#  - Título y etapa sin autowrap (se miden como UNA línea).
#  - Altura del chip con font.get_height() (ascendente + descendente).
#  - Anchos con ceilf() + holgura para evitar wraps por redondeo.
#
# API:
#   enqueue(text, variant, duration = 3.5, subtitle = "", icon = "")
#   signal popup_finished
#
# Depuración (solo builds debug):
#   F9 = mensaje de prueba | F10 = invertir posición | F11 = ciclar estilo
# ---------------------------------------------------------------------------

signal popup_finished

enum PopupStyle { CARD, SUBTITLES }

const SLIDE_TIME: float = 0.35
const MIN_DURATION: float = 0.5

# Layout manual (píxeles)
const PAD_X: float = 18.0
const PAD_TOP: float = 10.0
const PAD_BOTTOM: float = 12.0
const LINE_SEP: float = 4.0
const HEIGHT_BUFFER: float = 6.0
const BADGE_GAP: float = 12.0

const DEFAULT_TITLES: Dictionary = {
	0: "Dato Ambiental",
	1: "Reflexión",
	2: "Nueva Amenaza",
	3: "¿Sabías qué?"
}

var manager: Node = null

var _panel: Panel
var _badge_panel: Panel
var _badge_icon: BadgeIcon
var _chip_panel: Panel
var _sub_label: Label
var _title_label: Label
var _body_label: Label

var _queue: Array = []
var _busy: bool = false
var _test_index: int = 0

var _top_override: int = -1
var _style_override: int = -1
var _warned_no_settings: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("education_popup")

	if get_tree().get_nodes_in_group("education_popup").size() > 1:
		push_warning(
			"[EducationPopup] ¡Hay más de una instancia en el árbol! "
			+ "Elimina el nodo popupManager antiguo de la escena del nivel."
		)

	_build_ui()
	_log("cargado | id=%d" % get_instance_id())


func _build_ui() -> void:
	_panel = Panel.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_badge_panel = Panel.new()
	_badge_panel.visible = false
	_badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_badge_panel)

	_badge_icon = BadgeIcon.new()
	_badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_panel.add_child(_badge_icon)

	_chip_panel = Panel.new()
	_chip_panel.visible = false
	_chip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_chip_panel)

	_sub_label = _make_label()
	_title_label = _make_label()
	_body_label = _make_label()

	# FIX: título y etapa se miden como UNA sola línea. Con autowrap activo
	# y un ancho exacto al texto, Godot bajaba la última palabra a una 2ª
	# línea y el texto se salía del chip / de la tarjeta.
	_sub_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	_panel.add_child(_sub_label)
	_panel.add_child(_title_label)
	_panel.add_child(_body_label)


func _make_label() -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.visible = false
	return label


# ───────────────────────── CONFIGURACIÓN ─────────────────────────

func _cfg() -> EducationSettings:
	if not is_instance_valid(manager):
		return null

	var node = manager.settings

	if node == null or not is_instance_valid(node):
		return null

	return node


func _opt(prop: String, fallback: Variant) -> Variant:
	var m := _cfg()

	if m == null:
		return fallback

	var v: Variant = m.get(prop)

	return fallback if v == null else v


func _is_top() -> bool:
	if _top_override != -1:
		return _top_override == 1

	var m := _cfg()

	if m == null:
		return false

	return m.toast_on_top


func _style_of(variant: int) -> int:
	if _style_override != -1:
		return _style_override

	var m := _cfg()

	if m == null:
		return 0

	match variant:
		0:
			return m.style_wave_break
		1:
			return m.style_death
		2:
			return m.style_enemy_card
		3:
			return m.style_survival

	return 0


func _variant_color(variant: int, m: EducationSettings) -> Color:
	match variant:
		0:
			return m.color_wave_break
		1:
			return m.color_death
		2:
			return m.color_enemy_card
		3:
			return m.color_survival

	return m.card_border_color


func _icon_setting_of(variant: int, m: EducationSettings) -> String:
	match variant:
		0:
			return str(_opt("icon_wave_break", "hoja"))
		1:
			return str(_opt("icon_death", "calavera"))
		2:
			return str(_opt("icon_enemy_card", "alerta"))
		3:
			return str(_opt("icon_survival", "bomba"))

	return "hoja"


# Tema visual del tipo de mensaje. Devuelve:
# chip_fondo, chip_texto, chip_borde, fondo, borde, cuerpo
func _theme_of(variant: int, m: EducationSettings) -> Dictionary:
	var suffix := ""

	match variant:
		0:
			suffix = "wave"
		1:
			suffix = "death"
		2:
			suffix = "enemy"
		3:
			suffix = "survival"

	if not bool(_opt("usar_temas_por_tipo", true)):
		var accent: Color = m.card_border_color

		if m.card_use_variant_color:
			accent = _variant_color(variant, m)

		return {
			"chip_fondo": accent,
			"chip_texto": Color(0.03, 0.08, 0.05),
			"chip_borde": accent,
			"fondo": m.card_background_color,
			"borde": accent,
			"cuerpo": m.card_text_color
		}

	return {
		"chip_fondo": Color(_opt("tema_%s_chip_fondo" % suffix, Color(0, 1, 0.5))),
		"chip_texto": Color(_opt("tema_%s_chip_texto" % suffix, Color(0.03, 0.08, 0.05))),
		"chip_borde": Color(_opt("tema_%s_chip_borde" % suffix, Color(0, 1, 0.5))),
		"fondo": Color(_opt("tema_%s_fondo" % suffix, Color(0.05, 0.12, 0.08))),
		"borde": Color(_opt("tema_%s_borde" % suffix, Color(0, 1, 0.5))),
		"cuerpo": Color(_opt("tema_%s_texto" % suffix, Color(0.91, 0.96, 0.91)))
	}


# ───────────────────────── API ─────────────────────────

func enqueue(
	text: String,
	variant: int,
	duration: float = 3.5,
	subtitle: String = "",
	icon: String = ""
) -> void:
	var m := _cfg()

	if m == null:
		if not _warned_no_settings:
			_warned_no_settings = true
			push_warning(
				"[EducationPopup] Mensaje descartado: no hay un nodo "
				+ "EducationSettings válido en la escena."
			)
		return

	if text.strip_edges() == "":
		return

	variant = clampi(variant, 0, 3)

	_log(
		"enqueue variant=%d subtitle='%s' icon='%s' texto='%s'"
		% [variant, subtitle, icon, text.substr(0, 30)]
	)

	_queue.append({
		"text": text,
		"variant": variant,
		"duration": duration,
		"subtitle": subtitle,
		"icon": icon
	})

	if not _busy:
		_run_queue()


func _run_queue() -> void:
	_busy = true

	while not _queue.is_empty():
		var item: Dictionary = _queue.pop_front()
		await _display(item)

	_busy = false
	popup_finished.emit()


# ───────────────────────── MOSTRAR ─────────────────────────

func _display(item: Dictionary) -> void:
	var m := _cfg()

	if m == null:
		return

	var variant: int = item["variant"]
	var style: int = _style_of(variant)
	var is_card: bool = style == PopupStyle.CARD

	var raw: String = item["text"]
	var title: String = ""
	var body: String = raw
	var nl := raw.find("\n")

	if nl != -1:
		title = raw.substr(0, nl).strip_edges()
		body = raw.substr(nl + 1).strip_edges()
	elif is_card or m.subtitles_show_default_title:
		title = str(DEFAULT_TITLES.get(variant, ""))

	_apply_style(is_card, variant, m)

	var caption: String = str(item.get("subtitle", ""))
	var custom_icon: String = str(item.get("icon", "")).strip_edges()
	var vp: Vector2 = get_viewport().get_visible_rect().size

	var ratio: float = (
		m.card_width_ratio
		if is_card
		else m.subtitles_width_ratio
	)

	var max_width: float = (
		m.card_max_width
		if is_card
		else m.subtitles_max_width
	)

	var width: float = clampf(vp.x * ratio, 200.0, vp.x - 24.0)

	if max_width > 0.0:
		width = minf(width, max_width)

	# ── Insignia circular ──
	var icon_setting: String = (
		custom_icon
		if custom_icon != ""
		else _icon_setting_of(variant, m)
	)

	var kind: int = _kind_of(icon_setting)
	var show_badge: bool = (
		bool(_opt("badge_enabled", true))
		and kind != BadgeIcon.NONE
		and (is_card or bool(_opt("badge_show_on_subtitles", false)))
	)

	var badge_d: float = float(_opt("badge_size", 54.0))

	if not is_card:
		badge_d *= float(_opt("badge_subtitle_scale", 0.72))

	var text_x: float = PAD_X
	var text_width: float = width - PAD_X * 2.0

	if show_badge:
		text_x = PAD_X + badge_d + BADGE_GAP
		text_width = maxf(width - text_x - PAD_X, 60.0)

	# Qué Labels se muestran y con qué texto.
	if is_card:
		_sub_label.text = caption
		_sub_label.visible = m.card_show_stage and caption != ""

		_title_label.text = title
		_title_label.visible = m.card_show_title and title != ""

		_body_label.text = body
		_body_label.visible = m.card_show_body and body != ""

		_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_body_label.max_lines_visible = (
			m.card_max_body_lines
			if m.card_max_body_lines > 0
			else -1
		)
	else:
		var parts := PackedStringArray()

		if m.subtitles_show_stage and caption != "":
			parts.append(caption)

		if m.subtitles_show_title and title != "":
			parts.append(title)

		if m.subtitles_show_body and body != "":
			parts.append(body)

		var content := "\n".join(parts)

		if (
			m.subtitles_max_characters > 0
			and content.length() > m.subtitles_max_characters
		):
			content = (
				content.substr(
					0,
					maxi(m.subtitles_max_characters - 1, 0)
				).strip_edges()
				+ "…"
			)

		_sub_label.visible = false
		_title_label.visible = false
		_chip_panel.visible = false

		_body_label.text = content
		_body_label.visible = content != ""
		_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_body_label.max_lines_visible = (
			m.subtitles_max_lines
			if m.subtitles_max_lines > 0
			else -1
		)

	if (
		not _sub_label.visible
		and not _title_label.visible
		and not _body_label.visible
	):
		return

	# ── Medición y colocación manual (anti popup gigante) ──
	var y: float = PAD_TOP

	if is_card:
		# Fila 1: chip del título + etapa a la derecha.
		var chip_w: float = 0.0
		var chip_h: float = 0.0
		var cap_en_fila: bool = false

		if _title_label.visible:
			var tfont: Font = _title_label.get_theme_font("font")
			var tfs: int = _title_label.get_theme_font_size("font_size")
			var title_w: float = tfont.get_string_size(
				title, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs
			).x
			var px: float = float(_opt("chip_pad_x", 10.0))
			var py: float = float(_opt("chip_pad_y", 4.0))

			# FIX: altura REAL de la línea (get_height incluye ascendente
			# y descendente); antes se usaba solo el tamaño de fuente y el
			# glifo sobresalía del chip. ceilf() + 2 px de holgura evita
			# wraps por redondeo.
			chip_w = ceilf(title_w) + px * 2.0 + 2.0
			chip_h = tfont.get_height(tfs) + py * 2.0

			_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_chip_panel.position = Vector2(text_x, y)
			_chip_panel.size = Vector2(chip_w, chip_h)
			_chip_panel.visible = true
			_title_label.position = Vector2(text_x + px, y)
			_title_label.size = Vector2(ceilf(title_w) + 2.0, chip_h)
		else:
			_chip_panel.visible = false

		if _sub_label.visible:
			var cfont: Font = _sub_label.get_theme_font("font")
			var cfs: int = _sub_label.get_theme_font_size("font_size")
			var cap_w: float = cfont.get_string_size(
				caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cfs
			).x
			var cap_h: float = cfont.get_height(cfs)

			if _title_label.visible and cap_w + 12.0 + chip_w <= text_width:
				cap_en_fila = true
				_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				_sub_label.position = Vector2(
					text_x + text_width - ceilf(cap_w) - 4.0,
					y + (chip_h - cap_h) * 0.5
				)
				_sub_label.size = Vector2(ceilf(cap_w) + 4.0, cap_h)
				y += maxf(chip_h, cap_h)
			else:
				if _title_label.visible:
					y += chip_h + LINE_SEP

				_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				_sub_label.position = Vector2(text_x, y)
				_sub_label.size = Vector2(text_width, cap_h)
				y += cap_h

		if _title_label.visible and not cap_en_fila and not _sub_label.visible:
			y += chip_h

		y += LINE_SEP + 2.0

		if _body_label.visible:
			y = _place(_body_label, text_x, text_width, y)
	else:
		if _body_label.visible:
			y = _place(_body_label, text_x, text_width, y)

	var panel_h: float = y - LINE_SEP + PAD_BOTTOM

	if show_badge:
		panel_h = maxf(panel_h, badge_d + 8.0)

	panel_h = minf(panel_h, vp.y * 0.8)

	# Insignia: toma el color del tema del tipo de mensaje.
	if show_badge:
		var theme_dict := _theme_of(variant, m)
		var badge_accent: Color = (
			Color(theme_dict["borde"])
			if bool(_opt("badge_use_variant_color", true))
			else m.badge_border_color
		)

		var bs := StyleBoxFlat.new()
		bs.bg_color = m.badge_background_color
		bs.border_color = badge_accent
		bs.set_border_width_all(int(float(_opt("badge_border_width", 2.0))))
		bs.set_corner_radius_all(int(badge_d * 0.5))

		_badge_panel.add_theme_stylebox_override("panel", bs)
		_badge_panel.size = Vector2(badge_d, badge_d)
		_badge_panel.position = Vector2(PAD_X, (panel_h - badge_d) * 0.5)

		_badge_icon.size = _badge_panel.size
		_badge_icon.configure(kind, badge_accent, m.badge_background_color, custom_icon)
		_badge_panel.visible = true
	else:
		_badge_panel.visible = false

	var top: bool = _is_top()
	var start_y: float = (-panel_h - 20.0) if top else (vp.y + 20.0)
	var end_y: float = (
		m.top_margin
		if top
		else vp.y - panel_h - m.bottom_margin
	)

	_panel.size = Vector2(width, panel_h)
	_panel.position = Vector2((vp.x - width) * 0.5, start_y)
	_panel.modulate.a = 0.0
	_panel.visible = true

	_log(
		"mostrar | variant=%d | estilo=%s | pos=%s | icono=%s | alto=%.0f | ancho=%.0f"
		% [
			variant,
			_style_name(style),
			"TOP" if top else "BOTTOM",
			"sí" if show_badge else "no",
			panel_h,
			width
		]
	)

	var tween_in := create_tween().set_parallel(true)

	tween_in.tween_property(
		_panel,
		"position:y",
		end_y,
		SLIDE_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tween_in.tween_property(_panel, "modulate:a", 1.0, SLIDE_TIME)

	await tween_in.finished

	var visible_duration: float = maxf(float(item["duration"]), MIN_DURATION)
	await get_tree().create_timer(visible_duration, true).timeout

	var tween_out := create_tween().set_parallel(true)

	tween_out.tween_property(
		_panel,
		"position:y",
		start_y,
		SLIDE_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	tween_out.tween_property(_panel, "modulate:a", 0.0, SLIDE_TIME)

	await tween_out.finished

	_panel.visible = false


func _place(label: Label, x: float, wrap_width: float, y: float) -> float:
	var h := _measure_height(label, label.text, wrap_width)
	label.position = Vector2(x, y)
	label.size = Vector2(wrap_width, h)
	return y + h + LINE_SEP


func _measure_height(label: Label, text: String, wrap_width: float) -> float:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	var max_lines: int = (
		label.max_lines_visible
		if label.max_lines_visible > 0
		else -1
	)

	var s := font.get_multiline_string_size(
		text,
		label.horizontal_alignment,
		wrap_width,
		font_size,
		max_lines
	)

	return maxf(s.y + HEIGHT_BUFFER, float(font_size))


# ───────────────────────── ESTILOS ─────────────────────────

func _apply_style(is_card: bool, variant: int, m: EducationSettings) -> void:
	if is_card:
		var t := _theme_of(variant, m)

		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(t["fondo"])
		card_style.border_color = Color(t["borde"])
		card_style.set_border_width_all(int(m.card_border_width))
		card_style.set_corner_radius_all(int(m.card_corner_radius))
		card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
		card_style.shadow_size = m.card_shadow_size

		_panel.add_theme_stylebox_override("panel", card_style)

		var chip_style := StyleBoxFlat.new()
		chip_style.bg_color = Color(t["chip_fondo"])
		chip_style.border_color = Color(t["chip_borde"])
		chip_style.set_border_width_all(int(float(_opt("chip_borde_grosor", 2.0))))
		chip_style.set_corner_radius_all(int(float(_opt("chip_radio", 10.0))))

		_chip_panel.add_theme_stylebox_override("panel", chip_style)

		_sub_label.add_theme_color_override(
			"font_color",
			Color(Color(t["borde"]), 0.9)
		)
		_title_label.add_theme_color_override(
			"font_color",
			Color(t["chip_texto"])
		)
		_body_label.add_theme_color_override(
			"font_color",
			Color(t["cuerpo"])
		)

		_sub_label.add_theme_font_size_override(
			"font_size",
			m.card_stage_font_size
		)
		_title_label.add_theme_font_size_override(
			"font_size",
			m.card_title_font_size
		)
		_body_label.add_theme_font_size_override(
			"font_size",
			m.card_body_font_size
		)

		for label in [_sub_label, _title_label, _body_label]:
			label.add_theme_constant_override("outline_size", 0)

		return

	_body_label.add_theme_color_override(
		"font_color",
		m.subtitles_text_color
	)
	_body_label.add_theme_font_size_override(
		"font_size",
		m.subtitles_font_size
	)
	_body_label.add_theme_constant_override(
		"outline_size",
		m.subtitles_outline_size
	)
	_body_label.add_theme_color_override(
		"font_outline_color",
		m.subtitles_outline_color
	)

	if m.subtitles_background_enabled:
		var sub_style := StyleBoxFlat.new()
		sub_style.bg_color = m.subtitles_background_color
		sub_style.set_corner_radius_all(6)

		_panel.add_theme_stylebox_override("panel", sub_style)
	else:
		_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())


func _kind_of(icon_setting: String) -> int:
	match icon_setting.to_lower().strip_edges():
		"hoja", "leaf":
			return BadgeIcon.LEAF
		"calavera", "skull", "muerte":
			return BadgeIcon.SKULL
		"alerta", "warning", "enemigo", "peligro":
			return BadgeIcon.WARNING
		"bomba", "bombilla", "bulb", "idea":
			return BadgeIcon.BULB
		"nada", "none", "-":
			return BadgeIcon.NONE
		_:
			return BadgeIcon.TEXT


func _style_name(style: int) -> String:
	return "TARJETA" if style == PopupStyle.CARD else "SUBTÍTULOS"


# ───────────────────────── DEPURACIÓN ─────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if _cfg() == null:
		return

	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_F9:
			var variant: int = _test_index % 4
			_test_index += 1

			enqueue(
				"Mensaje de prueba\nVariante %d con estilo %s."
				% [variant, _style_name(_style_of(variant))],
				variant,
				3.0,
				"ETAPA 1"
			)

		KEY_F10:
			_top_override = 0 if _is_top() else 1

			_log(
				"Override de posición -> %s"
				% ("TOP" if _is_top() else "BOTTOM")
			)

		KEY_F11:
			if _style_override == -1:
				_style_override = PopupStyle.CARD
			elif _style_override == PopupStyle.CARD:
				_style_override = PopupStyle.SUBTITLES
			else:
				_style_override = -1

			_log(
				"Override de estilo -> %s"
				% (
					"CONFIGURACIÓN"
					if _style_override == -1
					else _style_name(_style_override)
				)
			)


func _log(msg: String) -> void:
	var m := _cfg()

	if m != null and m.debug_log:
		print("[EducationPopup] ", msg)


# ---------------------------------------------------------------------------
# Insignia circular: dibuja el icono del tipo de mensaje con polígonos,
# a juego con la estética low-poly del juego.
# ---------------------------------------------------------------------------
class BadgeIcon extends Control:

	const LEAF := 0
	const SKULL := 1
	const WARNING := 2
	const BULB := 3
	const TEXT := 4
	const NONE := 5

	var kind: int = LEAF
	var icon_color: Color = Color(0.0, 1.0, 0.5)
	var bg_color: Color = Color(0.012, 0.09, 0.05)
	var text_icon: String = ""

	func configure(
		p_kind: int,
		p_color: Color,
		p_bg: Color,
		p_text: String = ""
	) -> void:
		kind = p_kind
		icon_color = p_color
		bg_color = p_bg
		text_icon = p_text
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5

		match kind:
			LEAF:
				_draw_leaf(c, r)
			SKULL:
				_draw_skull(c, r)
			WARNING:
				_draw_warning(c, r)
			BULB:
				_draw_bulb(c, r)
			TEXT:
				_draw_text()
			_:
				pass

	func _draw_leaf(c: Vector2, r: float) -> void:
		var rx := r * 0.66
		var ry := r * 0.40
		var pts := PackedVector2Array()

		for i in 14:
			var a := TAU * float(i) / 14.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(-PI / 4.0))

		draw_colored_polygon(pts, icon_color)

		var tip := Vector2(rx, 0).rotated(-PI / 4.0)
		draw_line(c - tip * 0.85, c + tip * 0.85, bg_color, 1.5)

	func _draw_skull(c: Vector2, r: float) -> void:
		draw_circle(c + Vector2(0.0, -r * 0.12), r * 0.52, icon_color)
		draw_rect(
			Rect2(c + Vector2(-r * 0.28, r * 0.30), Vector2(r * 0.56, r * 0.20)),
			icon_color
		)
		draw_circle(c + Vector2(-r * 0.21, -r * 0.14), r * 0.13, bg_color)
		draw_circle(c + Vector2(r * 0.21, -r * 0.14), r * 0.13, bg_color)
		draw_circle(c + Vector2(0.0, r * 0.06), r * 0.08, bg_color)
		draw_line(
			c + Vector2(-r * 0.10, r * 0.30),
			c + Vector2(-r * 0.10, r * 0.50),
			bg_color,
			1.5
		)
		draw_line(
			c + Vector2(r * 0.10, r * 0.30),
			c + Vector2(r * 0.10, r * 0.50),
			bg_color,
			1.5
		)

	func _draw_warning(c: Vector2, r: float) -> void:
		var tri := PackedVector2Array([
			c + Vector2(0.0, -r * 0.62),
			c + Vector2(r * 0.64, r * 0.50),
			c + Vector2(-r * 0.64, r * 0.50)
		])
		draw_colored_polygon(tri, icon_color)

		var lw := maxf(2.0, r * 0.11)
		draw_line(
			c + Vector2(0.0, -r * 0.30),
			c + Vector2(0.0, r * 0.10),
			bg_color,
			lw
		)
		draw_circle(c + Vector2(0.0, r * 0.32), maxf(1.5, r * 0.07), bg_color)

	func _draw_bulb(c: Vector2, r: float) -> void:
		draw_circle(c + Vector2(0.0, -r * 0.10), r * 0.40, icon_color)
		draw_rect(
			Rect2(c + Vector2(-r * 0.16, r * 0.26), Vector2(r * 0.32, r * 0.12)),
			icon_color
		)
		draw_rect(
			Rect2(c + Vector2(-r * 0.10, r * 0.42), Vector2(r * 0.20, r * 0.06)),
			icon_color
		)
		draw_line(
			c + Vector2(0.0, r * 0.02),
			c + Vector2(0.0, r * 0.24),
			bg_color,
			1.5
		)

		for a: float in [-PI / 2.0 - 0.55, -PI / 2.0, -PI / 2.0 + 0.55]:
			var dir := Vector2(cos(a), sin(a))
			draw_line(
				c + dir * (r * 0.60),
				c + dir * (r * 0.84),
				icon_color,
				1.5
			)

	func _draw_text() -> void:
		var f: Font = ThemeDB.fallback_font

		if f == null or text_icon == "":
			return

		var fs := int(minf(size.x, size.y) * 0.55)
		var h := f.get_height(fs)
		var pos := Vector2(0.0, (size.y - h) * 0.5 + f.get_ascent(fs))

		f.draw_string(
			get_canvas_item(),
			pos,
			text_icon,
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			fs,
			icon_color
		)
