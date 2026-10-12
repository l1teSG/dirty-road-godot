extends Control

## ══════════════════════════════════════════════════════════
##  SELECCIÓN DE PARTIDAS (hasta 5 slots). Grande y táctil (móvil).
##  Fondo shader del menú principal. Muestra cada slot con
##  oleada/etapa/biomasa/fecha/tiempo y permite JUGAR / NUEVA / BORRAR.
## ══════════════════════════════════════════════════════════

const RUTA_NIVEL := "res://demo/level 1/niviel1.tscn"
const RUTA_MENU := "res://ui/main/main.tscn"
const RUTA_SHADER := "res://ui/main/fondo.gdshader"
const CONFIRMACION := preload("res://ui/confirmacion.gd")

var _lista: VBoxContainer
var _confirm = null
var _pendiente: int = 0


func _ready() -> void:
	_construir()
	_refrescar()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load(RUTA_SHADER)
	fondo.material = mat
	fondo.visible = bool(SaveManager.get_ajuste("fondo_shader", true))
	add_child(fondo)

	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.04, 0.03, 0.72)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	centro.add_child(col)

	var titulo := Label.new()
	titulo.text = "PARTIDAS"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	EstiloUI.titulo(titulo, 84, EstiloUI.NEON)
	col.add_child(titulo)

	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 12)
	col.add_child(_lista)

	var volver := Button.new()
	volver.text = "VOLVER"
	volver.custom_minimum_size = Vector2(320, 72)
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.focus_mode = Control.FOCUS_NONE
	EstiloUI.boton_menu(volver, 36)
	volver.pressed.connect(_ir_al_menu)
	col.add_child(volver)

	_confirm = CONFIRMACION.new()
	add_child(_confirm)
	_confirm.confirmado.connect(_on_confirmar)


func _refrescar() -> void:
	for c in _lista.get_children():
		c.queue_free()
	for s in SaveManager.listar_slots():
		_lista.add_child(_tarjeta(s))


func _tarjeta(s: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 140)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	panel.add_child(hb)

	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 30)
	if bool(s["existe"]):
		lbl.text = "SLOT %d\nOleada %d · Etapa %d · 🌱 %d\n%s · %s" % [
			int(s["slot"]), int(s["horda"]), int(s["etapa"]), int(s["biomasa"]),
			_formatear_tiempo(float(s["tiempo"])), str(s["fecha"])]
		lbl.add_theme_color_override("font_color", EstiloUI.TEXTO)
	else:
		lbl.text = "SLOT %d\n— VACÍO —" % int(s["slot"])
		lbl.add_theme_color_override("font_color", EstiloUI.APAGADO)
	hb.add_child(lbl)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)

	var b_jugar := Button.new()
	b_jugar.text = "JUGAR" if bool(s["existe"]) else "NUEVA"
	b_jugar.custom_minimum_size = Vector2(200, 76)
	b_jugar.focus_mode = Control.FOCUS_NONE
	EstiloUI.boton_menu(b_jugar, 28)
	b_jugar.pressed.connect(_on_jugar.bind(int(s["slot"]), bool(s["existe"])))
	hb.add_child(b_jugar)

	if bool(s["existe"]):
		var b_borrar := Button.new()
		b_borrar.text = "BORRAR"
		b_borrar.custom_minimum_size = Vector2(180, 76)
		b_borrar.focus_mode = Control.FOCUS_NONE
		EstiloUI.boton_menu(b_borrar, 28, false)
		b_borrar.pressed.connect(_pedir_borrar.bind(int(s["slot"])))
		hb.add_child(b_borrar)

	return panel


func _formatear_tiempo(seg: float) -> String:
	var t := int(maxf(seg, 0.0))
	return "%02d:%02d" % [int(t / 60), t % 60]


func _on_jugar(slot: int, existe: bool) -> void:
	if existe:
		SaveManager.cargar_slot(slot)
	else:
		SaveManager.nueva_partida_slot(slot)
	get_tree().change_scene_to_file(RUTA_NIVEL)


func _pedir_borrar(slot: int) -> void:
	_pendiente = slot
	_confirm.abrir(
		"¿Borrar la partida del slot %d? Esta acción no se puede deshacer." % slot,
		"BORRAR", "CANCELAR", true
	)


func _on_confirmar() -> void:
	if _pendiente > 0:
		SaveManager.borrar_slot(_pendiente)
		_pendiente = 0
		_refrescar()


func _ir_al_menu() -> void:
	get_tree().change_scene_to_file(RUTA_MENU)
