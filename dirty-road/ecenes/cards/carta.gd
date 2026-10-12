class_name CartaDefinicion
extends PanelContainer

signal carta_elegida(info: InfoMejora)

var _info_actual: InfoMejora
var _config: CartasConfig

var _icono: CartaIcono
var _nombre_label: Label
var _chip_rareza: PanelContainer
var _chip_rareza_label: Label
var _desc_label: RichTextLabel
var _boton_comprar: Button
var _estilo: StyleBoxFlat
var _margin: MarginContainer
var _vbox: VBoxContainer
var _color_rareza: Color = Color("7fdcb0")

## Grosor del borde/glow por rareza.
const GROSOR_RAREZA: Dictionary = {
	"Común": 2, "Rara": 3, "Épica": 4, "Legendaria": 5,
}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

## Construye la UI a partir del config (llamado por ConstructorCartas).
func construir(config: CartasConfig) -> void:
	_config = config if config != null else CartasConfig.new()

	custom_minimum_size = _config.tamano_carta

	_estilo = StyleBoxFlat.new()
	_estilo.bg_color = _config.color_fondo
	_estilo.set_corner_radius_all(12)
	_estilo.set_border_width_all(2)
	_estilo.border_color = _color_rareza
	_estilo.shadow_color = Color(0, 0, 0, 0.5)
	_estilo.shadow_size = 6
	add_theme_stylebox_override("panel", _estilo)

	_margin = MarginContainer.new()
	var m: int = _config.margen_carta
	_margin.add_theme_constant_override("margin_top", m)
	_margin.add_theme_constant_override("margin_bottom", m)
	_margin.add_theme_constant_override("margin_left", m)
	_margin.add_theme_constant_override("margin_right", m)
	add_child(_margin)

	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 10)
	_margin.add_child(_vbox)

	# 1. Figura vectorial
	_icono = CartaIcono.new()
	_icono.custom_minimum_size = Vector2(0, _config.alto_figura)
	_icono.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_child(_icono)

	# 2. Nombre
	_nombre_label = Label.new()
	_nombre_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nombre_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre_label.add_theme_font_override("font", _config.fuente_nombre)
	_nombre_label.add_theme_font_size_override("font_size", _config.tam_nombre)
	_vbox.add_child(_nombre_label)

	# 3. Chip de rareza
	_chip_rareza = PanelContainer.new()
	_chip_rareza.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_chip_rareza_label = Label.new()
	_chip_rareza_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chip_rareza_label.add_theme_font_override("font", _config.fuente_rareza)
	_chip_rareza_label.add_theme_font_size_override("font_size", _config.tam_rareza)
	_chip_rareza.add_child(_chip_rareza_label)
	_vbox.add_child(_chip_rareza)

	# 4. Descripción (sabor + Mejora), con BBCode.
	_desc_label = RichTextLabel.new()
	_desc_label.bbcode_enabled = true
	_desc_label.fit_content = true
	_desc_label.scroll_active = false
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc_label.add_theme_font_override("normal_font", _config.fuente_desc)
	_desc_label.add_theme_font_override("bold_font", _config.fuente_nombre)
	_desc_label.add_theme_font_size_override("normal_font_size", _config.tam_desc)
	_desc_label.add_theme_font_size_override("bold_font_size", _config.tam_desc)
	_vbox.add_child(_desc_label)

	# 5. Botón de compra (con el coste)
	_boton_comprar = Button.new()
	_boton_comprar.custom_minimum_size = Vector2(0, maxi(int(_config.tam_boton * 3), 44))
	_boton_comprar.add_theme_font_override("font", _config.fuente_boton)
	_boton_comprar.add_theme_font_size_override("font_size", _config.tam_boton)
	_boton_comprar.pressed.connect(_on_comprar_presionado)
	_vbox.add_child(_boton_comprar)

	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


## Se le inyectan los datos puros
func inyectar_datos(info: InfoMejora, orbes_jugador: int) -> void:
	_info_actual = info
	_color_rareza = _config.color_de(info.rareza)
	var grosor: int = int(GROSOR_RAREZA.get(info.rareza, 2))

	_estilo.border_color = _color_rareza
	_estilo.set_border_width_all(grosor)
	_estilo.shadow_size = 4 + grosor * 2
	_estilo.shadow_color = Color(_color_rareza.r, _color_rareza.g, _color_rareza.b, 0.18)

	_nombre_label.text = (info.nombre if not info.nombre.is_empty() else info.id).to_upper()
	_nombre_label.add_theme_color_override("font_color", _color_rareza)

	var chip_estilo := StyleBoxFlat.new()
	chip_estilo.bg_color = _color_rareza
	chip_estilo.set_corner_radius_all(9)
	chip_estilo.content_margin_left = 14.0
	chip_estilo.content_margin_right = 14.0
	chip_estilo.content_margin_top = 4.0
	chip_estilo.content_margin_bottom = 4.0
	_chip_rareza.add_theme_stylebox_override("panel", chip_estilo)
	_chip_rareza_label.text = info.rareza.to_upper()
	_chip_rareza_label.add_theme_color_override("font_color", Color("071a0e"))

	_desc_label.text = _formato_descripcion(info.descripcion, _color_rareza)

	if not info.figura_texto.is_empty():
		_icono.mostrar_figura(info.figura_texto, _color_rareza)

	_boton_comprar.text = "ELEGIR  ·  🌱 %d" % info.costo_orbes
	_boton_comprar.disabled = orbes_jugador < info.costo_orbes
	_estilizar_boton()

# ── Descripción: sabor + "Mejora" destacada ──────────────────────────────

func _formato_descripcion(texto: String, color: Color) -> String:
	var sabor := texto
	var mejora := ""
	var idx := texto.find("Mejora:")
	if idx >= 0:
		sabor = texto.substr(0, idx).strip_edges()
		mejora = texto.substr(idx + "Mejora:".length()).strip_edges()

	var partes: Array[String] = []
	if not sabor.is_empty():
		partes.append("[color=#%s]%s[/color]" % [_config.color_sabor.to_html(false), _negritas(sabor, color)])
	if not mejora.is_empty():
		partes.append("[b][color=#%s]MEJORA[/color][/b]  [color=#%s]%s[/color]" % [
			color.to_html(false), _config.color_sabor.to_html(false), _negritas(mejora, color)])
	return "\n\n".join(partes)

## Escapa '[' y convierte **negrita** en texto destacado: color de rareza + glow.
func _negritas(s: String, color: Color) -> String:
	var src := s.replace("[", "[lb]")
	var apertura := "[b][color=#%s][outline_size=%d][outline_color=#%s]" % [
		color.to_html(false), _config.bold_outline_size, _config.bold_outline.to_html(false)]
	var cierre := "[/outline_color][/outline_size][/color][/b]"
	var out := ""
	var i := 0
	var abierto := false
	while i < src.length():
		if i + 1 < src.length() and src[i] == "*" and src[i + 1] == "*":
			out += cierre if abierto else apertura
			abierto = not abierto
			i += 2
		else:
			out += src[i]
			i += 1
	if abierto:
		out += cierre
	return out

# ── Botón ─────────────────────────────────────────────────────────────────

func _estilizar_boton() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("123024")
	normal.set_corner_radius_all(8)
	normal.set_border_width_all(2)
	normal.border_color = _color_rareza
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(_color_rareza.r, _color_rareza.g, _color_rareza.b, 0.22)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(_color_rareza.r, _color_rareza.g, _color_rareza.b, 0.35)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.border_color = Color(0.4, 0.45, 0.42)
	disabled.bg_color = Color(0.10, 0.13, 0.11)

	_boton_comprar.add_theme_stylebox_override("normal", normal)
	_boton_comprar.add_theme_stylebox_override("hover", hover)
	_boton_comprar.add_theme_stylebox_override("pressed", pressed)
	_boton_comprar.add_theme_stylebox_override("disabled", disabled)
	_boton_comprar.add_theme_color_override("font_color", _config.color_texto)
	_boton_comprar.add_theme_color_override("font_hover_color", _color_rareza)
	_boton_comprar.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.52))

func _on_hover(entrando: bool) -> void:
	pivot_offset = size * 0.5
	z_index = 1 if entrando else 0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE * (1.04 if entrando else 1.0), 0.12)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_comprar_presionado() -> void:
	if _info_actual:
		carta_elegida.emit(_info_actual)


## Refresca si se puede comprar con la biomasa actual (multi-compra).
func actualizar_compra(orbes_jugador: int) -> void:
	if _info_actual == null:
		return
	_boton_comprar.disabled = orbes_jugador < _info_actual.costo_orbes


## Animación de entrada (escalonada desde GestorCartas).
func animar_entrada(delay: float = 0.0) -> void:
	pivot_offset = size * 0.5
	modulate.a = 0.0
	scale = Vector2(0.85, 0.85)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.22).set_delay(delay)
	tw.tween_property(self, "scale", Vector2.ONE, 0.28).set_delay(delay)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Animación al comprar (pop + destello).
func animar_seleccion() -> void:
	pivot_offset = size * 0.5
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * 1.12, 0.10)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.14)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var tw2 := create_tween()
	tw2.tween_property(self, "modulate", Color(1.4, 1.4, 1.4, 1.0), 0.08)
	tw2.tween_property(self, "modulate", Color.WHITE, 0.16)
