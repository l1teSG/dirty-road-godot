extends CanvasLayer

## ══════════════════════════════════════════════════════════
##  MENÚ DE DEPURACIÓN (hijo del jugador / Quark).
##
##  Se abre desde un botón en pantalla o con una tecla (F1 por defecto).
##  Es un overlay que NO pausa el juego: puedes ver y controlar las
##  oleadas en vivo.
##
##  TODO lo configurable está expuesto como @export, así que se puede
##  ajustar desde el Inspector de Godot sin tocar código: qué botones
##  aparecen, sus etiquetas, columnas, tecla, fondo, estado inicial e
##  incluso qué líneas de información se muestran.
## ══════════════════════════════════════════════════════════

@export_category("General")
## Si está en false, el menú no se crea (útil para builds de producción).
## Además solo se crea en builds de depuración (OS.is_debug_build()).
@export var activo: bool = true
## Tecla para abrir/cerrar el menú.
@export var tecla_abrir: Key = KEY_F1
## Abrir el menú automáticamente al empezar la partida.
@export var abrir_al_iniciar: bool = false
## Columnas de la parrilla de botones.
@export_range(1, 4) var columnas_botones: int = 3

@export_category("Aspecto")
@export var etq_boton_flotante: String = "🐞"
@export var etq_titulo: String = "DEPURACIÓN"
@export_range(0.0, 1.0, 0.05) var opacidad_fondo: float = 0.55
@export var ancho_panel: int = 560

@export_category("Botones visibles")
@export var btn_oleada: bool = true
@export var btn_matar: bool = true
@export var btn_spawn: bool = true
@export var btn_etapa: bool = true
@export var btn_inmortal: bool = true
@export var btn_matar_jefe: bool = true
@export var btn_spawn_10: bool = true
@export var btn_cerrar: bool = true

@export_category("Etiquetas de botones")
@export var etq_oleada: String = "Oleada +"
@export var etq_matar: String = "Matar"
@export var etq_spawn: String = "Spawn"
@export var etq_etapa_mas: String = "Etapa +"
@export var etq_etapa_menos: String = "Etapa -"
@export var etq_spawn_10: String = "+10 spawns"
@export var etq_inmortal: String = "Inmortal"
@export var etq_matar_jefe: String = "Matar jefe"
@export var etq_cerrar: String = "Cerrar"

@export_category("Estado inicial")
## Estado del modo inmortal al abrir el menú.
@export var inmortal_inicial: bool = false

@export_category("Elegir y spawnear")
## Muestra la fila con selectores de enemigo y jefe para spawnear uno concreto.
@export var btn_elegir: bool = true
@export var etq_elegir_enemigo: String = "Elegir enemigo"
@export var etq_elegir_jefe: String = "Elegir jefe"
@export var etq_spawn_elegido: String = "Spawnear enemigo"
@export var etq_spawn_jefe: String = "Spawnear jefe"

@export_category("Info mostrada")
@export var info_enemigos: bool = true
@export var info_jefe: bool = true
@export var info_jugador: bool = true
@export var info_biomasa: bool = true
@export var info_fps: bool = true

# ── Estado interno ──
var inmortal: bool = false

var _abierto: bool = false
var _contenedor: Control
var _panel: PanelContainer
var _texto: RichTextLabel
var _btn_inmortal: Button
var _wm: Node = null
var _jugador: Node2D = null
var _t: float = 0.0

var _opc_enemigos: OptionButton = null
var _opc_jefes: OptionButton = null
var _rutas_enemigos: Array = []
var _rutas_jefes: Array = []


func _ready() -> void:
	if not activo or not OS.is_debug_build():
		set_process(false)
		return
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	_jugador = get_parent() as Node2D
	inmortal = inmortal_inicial
	_construir()
	set_process(true)
	if abrir_al_iniciar:
		call_deferred("_abrir")


func _construir() -> void:
	# ── Botón flotante para abrir ──
	var btn := Button.new()
	btn.text = etq_boton_flotante
	btn.focus_mode = Control.FOCUS_NONE
	btn.anchor_left = 1.0
	btn.anchor_top = 0.0
	btn.anchor_right = 1.0
	btn.anchor_bottom = 0.0
	btn.offset_left = -150.0
	btn.offset_top = 12.0
	btn.offset_right = -106.0
	btn.offset_bottom = 56.0
	btn.tooltip_text = "Menú de depuración (%s)" % OS.get_keycode_string(tecla_abrir)
	btn.pressed.connect(_toggle)
	add_child(btn)

	# ── Fondo + ventana ──
	_contenedor = Control.new()
	_contenedor.set_anchors_preset(Control.PRESET_FULL_RECT)
	_contenedor.mouse_filter = Control.MOUSE_FILTER_STOP
	_contenedor.visible = false
	add_child(_contenedor)

	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, opacidad_fondo)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_contenedor.add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_contenedor.add_child(centro)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(ancho_panel, 0)
	centro.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_panel.add_child(vb)

	var titulo := Label.new()
	titulo.text = etq_titulo
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 34)
	vb.add_child(titulo)

	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.fit_content = true
	_texto.custom_minimum_size = Vector2(ancho_panel - 20, 230)
	_texto.scroll_active = false
	vb.add_child(_texto)

	var grilla := GridContainer.new()
	grilla.columns = columnas_botones
	grilla.add_theme_constant_override("h_separation", 8)
	grilla.add_theme_constant_override("v_separation", 8)
	vb.add_child(grilla)

	if btn_oleada:
		_boton(grilla, etq_oleada, _siguiente)
	if btn_matar:
		_boton(grilla, etq_matar, _matar_todos)
	if btn_spawn:
		_boton(grilla, etq_spawn, _spawnear)
	if btn_etapa:
		_boton(grilla, etq_etapa_mas, func(): _ir_a_etapa(1))
		_boton(grilla, etq_etapa_menos, func(): _ir_a_etapa(-1))
	if btn_spawn_10:
		_boton(grilla, etq_spawn_10, _spawn_10)
	if btn_inmortal:
		_btn_inmortal = _boton(grilla, _texto_inmortal(), _toggle_inmortal)
	if btn_matar_jefe:
		_boton(grilla, etq_matar_jefe, _matar_jefe)
	if btn_cerrar:
		_boton(grilla, etq_cerrar, _cerrar)

	if btn_elegir:
		_construir_elegir(vb)


func _construir_elegir(vb: VBoxContainer) -> void:
	var separador := HSeparator.new()
	vb.add_child(separador)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)

	var l_enem := Label.new()
	l_enem.text = etq_elegir_enemigo
	grid.add_child(l_enem)
	var l_jefe := Label.new()
	l_jefe.text = etq_elegir_jefe
	grid.add_child(l_jefe)

	_opc_enemigos = OptionButton.new()
	_opc_enemigos.focus_mode = Control.FOCUS_NONE
	_opc_enemigos.custom_minimum_size = Vector2(340, 40)
	grid.add_child(_opc_enemigos)
	_boton(grid, etq_spawn_elegido, func(): _spawn_elegido(false))

	_opc_jefes = OptionButton.new()
	_opc_jefes.focus_mode = Control.FOCUS_NONE
	_opc_jefes.custom_minimum_size = Vector2(340, 40)
	grid.add_child(_opc_jefes)
	_boton(grid, etq_spawn_jefe, func(): _spawn_elegido(true))


func _boton(padre: Node, etiqueta: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = etiqueta
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(170, 44)
	b.pressed.connect(cb)
	padre.add_child(b)
	return b


func _texto_inmortal() -> String:
	return "%s: %s" % [etq_inmortal, ("ON" if inmortal else "OFF")]


func _process(delta: float) -> void:
	if not _abierto:
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.25
	if _wm == null or not is_instance_valid(_wm):
		_wm = get_tree().get_first_node_in_group("wave_manager")
	_actualizar()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == tecla_abrir:
			_toggle()


# ───────────── ABRIR / CERRAR ─────────────

func _toggle() -> void:
	if _abierto:
		_cerrar()
	else:
		_abrir()


func _abrir() -> void:
	if _contenedor == null:
		return
	_abierto = true
	_contenedor.visible = true
	_wm = get_tree().get_first_node_in_group("wave_manager")
	_poblar_opciones()
	_actualizar()


func _cerrar() -> void:
	if _contenedor == null:
		return
	_abierto = false
	_contenedor.visible = false


# ───────────── ACCIONES ─────────────

func _siguiente() -> void:
	if _wm == null:
		return
	if bool(_wm.get("en_descanso")):
		_wm.call("terminar_descanso")
	else:
		_wm.call("_cerrar_oleada", 0.0)


func _matar_todos() -> void:
	for e in get_tree().get_nodes_in_group("enemigos"):
		if is_instance_valid(e) and e.has_method("recibir_danio"):
			e.call("recibir_danio", 1.0e12)


func _matar_jefe() -> void:
	if _wm == null:
		return
	var j = _wm.get("jefe_actual")
	if j != null and is_instance_valid(j) and j.has_method("recibir_danio"):
		j.call("recibir_danio", 1.0e12)


func _spawnear() -> void:
	if _wm != null and _wm.has_method("_spawnear_siguiente_enemigo"):
		_wm.call("_spawnear_siguiente_enemigo")


func _spawn_10() -> void:
	for i in 10:
		_spawnear()


# ───────────── ELEGIR Y SPAWNEAR ─────────────

func _poblar_opciones() -> void:
	if _opc_enemigos == null or _opc_jefes == null:
		return
	if _wm == null or not is_instance_valid(_wm):
		return
	var etapas: Array = _wm.get("etapas")
	_rutas_enemigos.clear()
	_rutas_jefes.clear()
	_opc_enemigos.clear()
	_opc_jefes.clear()
	for i in etapas.size():
		var et = etapas[i]
		var enem: Array = et.get("enemigos")
		if enem != null:
			for cfg in enem:
				var esc := cfg.get("escena") as PackedScene
				if esc == null:
					continue
				_rutas_enemigos.append(esc)
				_opc_enemigos.add_item("E%d · %s" % [i + 1, esc.resource_path.get_file().get_basename()])
		var jefe := et.get("jefe_escena") as PackedScene
		if jefe != null:
			_rutas_jefes.append(jefe)
			_opc_jefes.add_item("E%d · %s" % [i + 1, jefe.resource_path.get_file().get_basename()])


func _spawn_elegido(es_jefe: bool) -> void:
	var lista: Array = _rutas_jefes if es_jefe else _rutas_enemigos
	var opc: OptionButton = _opc_jefes if es_jefe else _opc_enemigos
	if opc == null or lista.is_empty():
		return
	var idx := clampi(opc.selected, 0, lista.size() - 1)
	var esc: PackedScene = lista[idx]
	if esc == null:
		return
	var escena := get_tree().current_scene
	if escena == null:
		return
	var e := esc.instantiate() as Node2D
	if e == null:
		return
	var base := _jugador.global_position if _jugador != null and is_instance_valid(_jugador) else Vector2.ZERO
	e.global_position = base + Vector2(randf_range(-70.0, 70.0), randf_range(-70.0, 70.0))
	escena.call_deferred("add_child", e)


func _ir_a_etapa(delta: int) -> void:
	if _wm == null:
		return
	var etapas: Array = _wm.get("etapas")
	if etapas == null or etapas.is_empty():
		return
	var idx := clampi(int(_wm.get("etapa_actual_idx")) + delta, 0, etapas.size() - 1)
	var por := maxi(int(_wm.get("oleadas_por_etapa")), 1)
	_wm.set("oleada_actual", idx * por + 1)
	_wm.set("etapa_actual_idx", -1)  # fuerza _iniciar_etapa
	_wm.call("iniciar_oleada")


func _toggle_inmortal() -> void:
	inmortal = not inmortal
	if _btn_inmortal != null:
		_btn_inmortal.text = _texto_inmortal()


# ───────────── PANEL ─────────────

func _actualizar() -> void:
	if _texto == null:
		return
	if _wm == null or not is_instance_valid(_wm):
		_texto.text = "[b]%s[/b]\n[color=#ff8080]Sin WaveManager en escena.[/color]" % etq_titulo
		return

	var etapas: Array = _wm.get("etapas")
	var idx: int = int(_wm.get("etapa_actual_idx"))
	var oleada: int = int(_wm.get("oleada_actual"))
	var por: int = maxi(int(_wm.get("oleadas_por_etapa")), 1)
	var pos: int = ((oleada - 1) % por) + 1
	var descanso: bool = bool(_wm.get("en_descanso"))
	var t: int = int(_wm.get("tiempo_restante"))
	var vivos: int = int(_wm.get("enemigos_vivos"))
	var por_tipo: Dictionary = _wm.get("_enemigos_vivos_por_tipo")

	var nombre := "—"
	if idx >= 0 and idx < etapas.size():
		nombre = str(etapas[idx].get("nombre"))

	var lineas: Array[String] = []
	if info_fps:
		lineas.append("(FPS %d)   %s: %s" % [Engine.get_frames_per_second(), etq_inmortal, ("SÍ" if inmortal else "no")])
	lineas.append("[b]%s[/b]" % nombre)
	lineas.append("Oleada [b]%d[/b] (pos %d/%d)   %s  t=%ds" % [oleada, pos, por, ("DESCANSO" if descanso else "COMBATE"), t])

	if info_enemigos:
		var tipos := ""
		if por_tipo != null:
			for k in por_tipo.keys():
				tipos += "\n   · %s ×%d" % [str(k).get_file().get_basename(), int(por_tipo[k])]
		lineas.append("Vivos: [b]%d[/b]%s" % [vivos, tipos])

	if info_jefe:
		var jefe := "—"
		var j = _wm.get("jefe_actual")
		if j != null and is_instance_valid(j):
			jefe = "%s  %.0f%%" % [str(_wm.get("_nombre_jefe")), 100.0 * float(j.get("vida_actual")) / maxf(float(j.get("life")), 1.0)]
		lineas.append("Jefe: %s" % jefe)

	var extra := ""
	if info_jugador and _jugador != null and is_instance_valid(_jugador):
		var lmax := float(SaveManager.get_vida_maxima()) if SaveManager != null else float(_jugador.get("vida_maxima"))
		extra = "   Jugador: %.0f / %.0f" % [float(_jugador.get("life")), lmax]
	if info_biomasa:
		var biomasa := int(BiomasaManager.get("contador")) if BiomasaManager != null else 0
		extra += "   Biomasa: %d" % biomasa
	if extra != "":
		lineas.append(extra.strip_edges())

	_texto.text = "\n".join(lineas)
