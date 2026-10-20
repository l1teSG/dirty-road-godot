extends Node

## ══════════════════════════════════════════════════════════
##  REPRODUCTOR DE TRAILER (modo dirigido por guion)
##
##  Lee un guion JSON y lo ejecuta paso a paso, sin input, de forma
##  determinista (ideal para grabar con el Movie Maker a fps fijos).
##
##  Uso:
##    godot "res://demo/level 1/niviel1.tscn" -- --trailer=/ruta/guion.json
##
##  Formato del guion:
##  {
##    "nombre": "general",
##    "fps": 60,
##    "duracion": 42.0,
##    "pasos": [ { "t": 0.0, "accion": "hud", "valor": false }, ... ]
##  }
##
##  Acciones:
##    hud           valor(bool)                     — muestra/oculta el HUD
##    pantalla      valor("menu"|"ajustes"|"off")   — overlay de menús
##    titulo        texto, sub, dur                 — rótulo centrado con fade
##    fundido       color("negro"|"blanco"), dur    — funde la pantalla
##    camara        pos[dx,dy], zoom, dur, ease     — mueve la cámara (pos rel. al Árbol)
##    encuadrar     objetivo("jugador"|"arbol"|"jefe"), zoom, dur
##    spawn         escena, pos[dx,dy], congelado   — instancia una escena
##    formacion     escena, n, radio, pos[dx,dy], congelado
##    matar         — mata al último jefe spawneado (o a todos si valor=1)
##    matar_todos   —
##    slowmo        valor(float), dur               — cámara lenta temporal
##    cartas        valor(bool)                     — abre/cierra la UI de cartas
##    popup_edu     valor(bool)                     — muestra/oculta el popup educativo
##    pausar_ia     valor(bool)                     — congela/descongela la IA
##    fin           — corta el trailer aquí
##
##  Solo se activa en builds de depuración y si se pasa --trailer.
## ══════════════════════════════════════════════════════════

const GRUPO_ENEMIGOS := "enemigos"
const NIVEL_HUD := 0
const NIVEL_OVERLAY := 140
const NIVEL_FADE := 145
const NIVEL_TITULO := 146

@export var activo: bool = true

var _pasos: Array = []
var _t: float = 0.0
var _idx: int = 0
var _duracion: float = 0.0
var _jugador: Node2D = null
var _arbol: Node2D = null
var _wm: Node = null
var _cam: Camera2D = null
var _cam_base: Camera2D = null
var _zoom_base: float = 1.6

var _ui: CanvasLayer
var _fade: ColorRect
var _titulo: Label
var _subtitulo: Label
var _overlay: CanvasLayer
var _hud_visible: bool = true
var _slowmo_tw: Tween
var _fin: bool = false
var _listo: bool = false
var _vis_original: Dictionary = {}
var _popups_edu: Array = []


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	var ruta := _arg_valor("trailer")
	if ruta.is_empty():
		set_process(false)
		return
	var guion := _cargar_guion(ruta)
	if guion.is_empty():
		push_warning("[Trailer] guion vacío o ilegible: %s" % ruta)
		set_process(false)
		return
	_pasos = guion.get("pasos", [])
	_pasos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("t", 0.0)) < float(b.get("t", 0.0)))
	_construir_overlays()
	call_deferred("_preparar")


func _arg_valor(nombre: String) -> String:
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("--"):
			s = s.substr(2)
		var p := s.split("=", true, 1)
		if p[0] == nombre:
			return p[1] if p.size() == 2 else "1"
	return ""


func _cargar_guion(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	var datos = JSON.parse_string(txt)
	return datos if datos is Dictionary else {}


# ───────────── PREPARACIÓN ─────────────

func _preparar() -> void:
	_jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	_arbol = get_tree().get_first_node_in_group("arbol") as Node2D
	_wm = get_tree().get_first_node_in_group("wave_manager")
	# Sin oleadas ni guardado, y sin mensajes educativos.
	if _wm != null:
		_wm.set("debug_activo", true)
		_wm.set("debug_spawnear_enemigos", false)
		_wm.set("debug_sin_limite_tiempo", true)
		_wm.set("debug_no_guardar", true)
		_wm.set("debug_imprimir_info", false)
	var edu := get_node_or_null("/root/EducationManager")
	if edu != null and edu.has_method("stop_run"):
		edu.call("stop_run")
	# El jugador y el Árbol no deben morir durante el trailer.
	if _jugador != null:
		_jugador.set("life", 100000.0)
		if "vida_maxima" in _jugador:
			_jugador.set("vida_maxima", 100000.0)
	if _arbol != null:
		_arbol.set("life", 100000.0)
	# Cámara propia del trailer.
	_cam_base = _jugador.get_node_or_null("Camera2D") as Camera2D if _jugador != null else get_viewport().get_camera_2d()
	_zoom_base = float(_cam_base.zoom.x) if _cam_base != null else 1.6
	_cam = Camera2D.new()
	_cam.name = "CamTrailer"
	_cam.zoom = Vector2.ONE * _zoom_base
	_cam.global_position = _origen() if _arbol != null else Vector2.ZERO
	get_tree().current_scene.add_child(_cam)
	_cam.make_current()
	_duracion = float(_pasos[-1].get("t", 0.0)) + 4.0 if not _pasos.is_empty() else 6.0
	# El popup educativo se oculta por defecto (acción "popup_edu" para mostrarlo).
	_popups_edu = _buscar_popups_edu()
	_set_popup_edu(false)
	# Recuerda el estado original de cada CanvasLayer para poder restaurarlo:
	# sin esto, mostrar el "HUD" forzaría a verse la PAUSA o las cartas.
	for cl in _canvas_layers(get_tree().root):
		if str(cl.name).begins_with("Trailer") or _popups_edu.has(cl):
			continue
		_vis_original[cl] = cl.visible
	_listo = true
	print("[Trailer] guion con %d pasos · duración ~%.1fs" % [_pasos.size(), _duracion])


func _origen() -> Vector2:
	return _arbol.global_position if _arbol != null and is_instance_valid(_arbol) else Vector2.ZERO


func _mundo(pos: Array) -> Vector2:
	if pos.size() < 2:
		return _origen()
	return _origen() + Vector2(float(pos[0]), float(pos[1]))


# ───────────── OVERLAYS (fade, títulos, menús) ─────────────

func _construir_overlays() -> void:
	_ui = CanvasLayer.new()
	_ui.name = "TrailerUI"
	_ui.layer = NIVEL_FADE
	add_child(_ui)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fade)

	var tl := CanvasLayer.new()
	tl.name = "TrailerTitulo"
	tl.layer = NIVEL_TITULO
	add_child(tl)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(vb)
	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_titulo.modulate.a = 0.0
	EstiloUI.titulo(_titulo, 92)
	vb.add_child(_titulo)
	_subtitulo = Label.new()
	_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitulo.modulate.a = 0.0
	_subtitulo.add_theme_font_size_override("font_size", 34)
	_subtitulo.add_theme_color_override("font_color", EstiloUI.VERDE_CLARO)
	vb.add_child(_subtitulo)

	_overlay = CanvasLayer.new()
	_overlay.name = "TrailerOverlay"
	_overlay.layer = NIVEL_OVERLAY
	add_child(_overlay)


# ───────────── BUCLE ─────────────

func _process(delta: float) -> void:
	if not _listo or _fin or _pasos.is_empty():
		return
	# Reloj sin escalar: la cámara lenta no debe frenar la línea de tiempo.
	_t += delta / maxf(Engine.time_scale, 0.0001)
	while _idx < _pasos.size() and float(_pasos[_idx].get("t", 0.0)) <= _t:
		_ejecutar(_pasos[_idx])
		_idx += 1
	if _idx >= _pasos.size() and _t > _duracion:
		_terminar()


func _ejecutar(paso: Dictionary) -> void:
	match str(paso.get("accion", "")):
		"esperar":
			pass
		"fin":
			_terminar()
		"hud":
			_set_hud(bool(paso.get("valor", true)))
		"pantalla":
			_set_pantalla(str(paso.get("valor", "")))
		"titulo":
			_set_titulo(str(paso.get("texto", "")), str(paso.get("sub", "")), float(paso.get("dur", 2.4)))
		"fundido":
			_set_fundido(str(paso.get("color", "negro")), float(paso.get("dur", 0.8)), bool(paso.get("salir", false)))
		"camara":
			_mover_camara(paso)
		"encuadrar":
			_encuadrar(paso)
		"spawn":
			_spawn(str(paso.get("escena", "")), paso.get("pos", []), bool(paso.get("congelado", false)))
		"formacion":
			_formacion(paso)
		"matar":
			_matar()
		"matar_todos":
			_matar_todos()
		"slowmo":
			_slowmo(float(paso.get("valor", 1.0)), float(paso.get("dur", 1.0)))
		"popup_edu":
			_set_popup_edu(bool(paso.get("valor", true)))
		"cartas":
			_cartas(bool(paso.get("valor", true)))
		"pausar_ia":
			_pausar_ia(bool(paso.get("valor", true)))
		_:
			pass


func _terminar() -> void:
	if _fin:
		return
	_fin = true
	print("[Trailer] fin del guion a %.2fs" % _t)
	get_tree().quit()


# ───────────── ACCIONES ─────────────

func _set_hud(on: bool) -> void:
	_hud_visible = on
	for cl in _canvas_layers(get_tree().root):
		if str(cl.name).begins_with("Trailer"):
			continue
		if _popups_edu.has(cl):
			continue
		cl.visible = bool(_vis_original.get(cl, true)) if on else false


func _set_pantalla(cual: String) -> void:
	for c in _overlay.get_children():
		c.queue_free()
	if cual == "" or cual == "off":
		return
	var ruta := ""
	match cual:
		"menu": ruta = "res://ui/main/main.tscn"
		"ajustes": ruta = "res://ui/ajustes/ajustes.tscn"
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		return
	var esc := load(ruta) as PackedScene
	if esc == null:
		return
	var nodo := esc.instantiate()
	_overlay.add_child(nodo)


func _set_titulo(texto: String, sub: String, dur: float) -> void:
	_titulo.text = texto
	_subtitulo.text = sub
	for n in [_titulo, _subtitulo]:
		n.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_titulo, "modulate:a", 1.0, 0.4)
	tw.tween_property(_subtitulo, "modulate:a", 1.0, 0.5)
	tw.set_parallel(false)
	tw.tween_interval(maxf(dur - 0.9, 0.2))
	tw.set_parallel(true)
	tw.tween_property(_titulo, "modulate:a", 0.0, 0.5)
	tw.tween_property(_subtitulo, "modulate:a", 0.0, 0.5)


func _set_fundido(color: String, dur: float, salir: bool) -> void:
	var c := Color(0, 0, 0, 1) if color == "negro" else Color(1, 1, 1, 1)
	var tw := create_tween()
	if salir:
		_fade.color = c
		tw.tween_property(_fade, "color:a", 0.0, dur)
	else:
		_fade.color = Color(c.r, c.g, c.b, 0.0)
		tw.tween_property(_fade, "color:a", 1.0, dur)


func _mover_camara(paso: Dictionary) -> void:
	if _cam == null:
		return
	var dest := _mundo(paso.get("pos", []))
	var zoom := float(paso.get("zoom", _cam.zoom.x))
	var dur := float(paso.get("dur", 1.5))
	var ease := str(paso.get("ease", "out"))
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cam, "global_position", dest, dur)\
		.set_trans(Tween.TRANS_SINE).set_ease(_ease(ease))
	tw.tween_property(_cam, "zoom", Vector2.ONE * zoom, dur)\
		.set_trans(Tween.TRANS_SINE).set_ease(_ease(ease))


func _encuadrar(paso: Dictionary) -> void:
	var objetivo := str(paso.get("objetivo", "arbol"))
	var pos := _origen()
	match objetivo:
		"jugador":
			if _jugador != null:
				pos = _jugador.global_position
		"jefe":
			var j := _ultimo_jefe()
			if j != null:
				pos = j.global_position
		_:
			pos = _origen()
	var zoom := float(paso.get("zoom", _cam.zoom.x if _cam != null else _zoom_base))
	var dur := float(paso.get("dur", 1.5))
	if _cam == null:
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_cam, "global_position", pos, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_cam, "zoom", Vector2.ONE * zoom, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _ease(nombre: String) -> Tween.EaseType:
	match nombre:
		"in": return Tween.EASE_IN
		"in_out": return Tween.EASE_IN_OUT
		_: return Tween.EASE_OUT


func _spawn(escena: String, pos: Array, congelado: bool) -> Node2D:
	if escena.is_empty() or not ResourceLoader.exists(escena):
		push_warning("[Trailer] escena inexistente: %s" % escena)
		return null
	var esc := load(escena) as PackedScene
	var e := esc.instantiate() as Node2D
	if e == null:
		return null
	e.global_position = _mundo(pos)
	get_tree().current_scene.add_child(e)
	if congelado:
		_llamar_diferido(func() -> void: _congelar(e, true))
	return e


func _formacion(paso: Dictionary) -> void:
	var escena := str(paso.get("escena", ""))
	var n := int(paso.get("n", 6))
	var radio := float(paso.get("radio", 180.0))
	var centro := _mundo(paso.get("pos", []))
	var congelado := bool(paso.get("congelado", true))
	for i in n:
		var ang := TAU * float(i) / float(maxi(n, 1))
		var p := centro + Vector2(cos(ang), sin(ang)) * radio
		var esc := load(escena) as PackedScene if ResourceLoader.exists(escena) else null
		if esc == null:
			continue
		var e := esc.instantiate() as Node2D
		e.global_position = p
		get_tree().current_scene.add_child(e)
		if congelado:
			_llamar_diferido(func() -> void: _congelar(e, true))


func _matar() -> void:
	for e in get_tree().get_nodes_in_group(GRUPO_ENEMIGOS):
		if is_instance_valid(e) and e.has_method("recibir_danio"):
			e.call("recibir_danio", 1.0e12)
			break


func _matar_todos() -> void:
	for e in get_tree().get_nodes_in_group(GRUPO_ENEMIGOS):
		if is_instance_valid(e) and e.has_method("recibir_danio"):
			e.call("recibir_danio", 1.0e12)


func _slowmo(valor: float, dur: float) -> void:
	if _slowmo_tw != null and _slowmo_tw.is_valid():
		_slowmo_tw.kill()
	_slowmo_tw = create_tween()
	_slowmo_tw.tween_property(Engine, "time_scale", valor, 0.25)
	_slowmo_tw.tween_interval(maxf(dur, 0.1))
	_slowmo_tw.tween_property(Engine, "time_scale", 1.0, 0.25)


func _cartas(on: bool) -> void:
	var cartas := get_tree().get_first_node_in_group("cartas")
	if cartas == null and _jugador != null:
		cartas = _jugador.get_node_or_null("Cartas")
	if cartas == null:
		return
	if on and cartas.has_method("_mostrar_interfaz_mejoras"):
		cartas.call("_mostrar_interfaz_mejoras")
	elif not on and cartas.has_method("_cerrar_interfaz"):
		cartas.call("_cerrar_interfaz")


## CanvasLayers del sistema educativo (el popup vive bajo /root/EducationManager).
func _buscar_popups_edu() -> Array:
	var out: Array = []
	var em := get_node_or_null("/root/EducationManager")
	if em != null:
		for c in em.get_children():
			if c is CanvasLayer:
				out.append(c)
	var escena := get_tree().current_scene
	if escena != null:
		var n := escena.get_node_or_null("popopManger/CanvasLayer")
		if n is CanvasLayer:
			out.append(n)
	return out


func _set_popup_edu(on: bool) -> void:
	for cl in _popups_edu:
		if is_instance_valid(cl):
			cl.visible = on


func _pausar_ia(on: bool) -> void:
	for e in get_tree().get_nodes_in_group(GRUPO_ENEMIGOS):
		_congelar(e, on)


func _congelar(e: Node, estado: bool) -> void:
	if e == null or not is_instance_valid(e):
		return
	e.process_mode = Node.PROCESS_MODE_DISABLED if estado else Node.PROCESS_MODE_INHERIT
	if estado and e is CharacterBody2D:
		(e as CharacterBody2D).velocity = Vector2.ZERO


func _ultimo_jefe() -> Node2D:
	if _wm == null:
		return null
	var j = _wm.get("jefe_actual")
	return j if j is Node2D and is_instance_valid(j) else null


func _canvas_layers(nodo: Node) -> Array:
	var out: Array = []
	for c in nodo.get_children():
		if c is CanvasLayer:
			out.append(c)
		out.append_array(_canvas_layers(c))
	return out


func _llamar_diferido(cb: Callable) -> void:
	get_tree().create_timer(0.05).timeout.connect(cb)
