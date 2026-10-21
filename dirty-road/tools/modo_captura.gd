extends CanvasLayer

## ══════════════════════════════════════════════════════════
##  MODO CAPTURA / TRAILER (herramienta de desarrollo)
##
##  Sirve para montar escenas a mano —sin oleadas ni combate— y
##  tomar capturas y vídeo:
##   · Elegir CUALQUIER enemigo normal o jefe de las 10 etapas.
##   · Colocarlos donde quieras: clic selecciona, arrastrar/teclas mueve.
##   · Congelar su IA para que no se muevan ni ataquen.
##   · Ocultar HUD y al jugador (modo foto) para tomas limpias.
##   · Cámara libre (paneo + zoom) para encuadrar.
##   · Tecla C → PNG; tecla R → secuencia de frames para vídeo.
##
##  Solo existe en builds de depuración. No guarda partida, no toca
##  el WaveManager real (lo pone en modo debug y sin spawns).
##
##  Atajos:
##   F2        abrir/cerrar el panel
##   Clic izq  seleccionar / mover el enemigo bajo el cursor
##   Flechas   mover el seleccionado a pasos finos
##   Supr      borrar seleccionado      D  duplicar seleccionado
##   C         captura PNG              R  grabar/parar vídeo
##   F         modo foto (oculta HUD)   G  congelar/descongelar IA
##   ESPACIO   play/pausa de la simulación (tiempo)
##   + / -     zoom de la cámara libre  WASD paneo (cámara libre)
##
##  El vídeo se guarda como secuencia PNG en `user://videos/<nombre>/`
##  y se convierte con `tools/montaje_video.sh`.
##
##  AUTOMÁTICO (por argumentos tras `--`, para generar capturas de los docs):
##   --mc-panel          abre el panel al arrancar
##   --mc-auto=SEG       espera SEG s, guarda un PNG y cierra
##   --mc-oleada=N       fuerza la oleada N (y su etapa)
##   --mc-cartas         abre la interfaz de cartas antes de capturar
##   Ej.: godot "res://demo/level 1/niviel1.tscn" -- --mc-oleada=10 --mc-auto=12
## ══════════════════════════════════════════════════════════

const GRUPO_ENEMIGOS := "enemigos"
const VEL_PANEO := 900.0

@export var tecla_abrir: Key = KEY_F2
@export var carpeta_capturas: String = "user://capturas/modo"
@export var carpeta_video: String = "user://videos"
@export var fps_grabacion: int = 30

# ── Estado ──
var _abierto: bool = false
var _congelado: bool = false
var _foto: bool = false
var _ocultar_jugador: bool = false
var _camara_libre: bool = false
var _grabando: bool = false
var _frame: int = 0
var _t_frame: float = 0.0
var _t: float = 0.0

var _seleccionado: Node2D = null
var _arrastrando: bool = false
var _reabrir_cartas: bool = false
var _t_cartas: float = 0.0

# ── Nodos ──
var _panel: PanelContainer
var _lbl_info: Label
var _opc_etapa: OptionButton
var _opc_enemigos: OptionButton
var _opc_jefes: OptionButton
var _btn_congelar: Button
var _btn_foto: Button
var _btn_jugador: Button
var _btn_camara: Button
var _btn_grabar: Button
var _btn_play: Button
var _marcador: Node2D

# ── Catálogo ──
var _enemigos: Array = []        # PackedScene
var _nombres_enemigos: Array = []
var _jefes: Array = []           # PackedScene
var _nombres_jefes: Array = []
var _wm: Node = null
var _jugador: Node2D = null
var _cam: Camera2D = null
var _cam_jugador: Camera2D = null


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 160
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(carpeta_capturas))
	_jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	_construir()
	_construir_marcador()
	set_process(true)
	if _tiene_arg("mc-panel"):
		call_deferred("abrir")
	# --captura-oleada=N: fuerza esa oleada (se aplica YA, antes del
	# iniciar_oleada diferido del WaveManager).
	var oleada := _arg_valor("mc-oleada")
	if oleada != "":
		_forzar_oleada(int(oleada))
	# --captura-auto=<seg>: espera y guarda un PNG solo (para generar capturas
	# de los docs sin interactuar). Abre el panel si además hay --modo-captura.
	var auto := _arg_valor("mc-auto")
	if auto != "":
		call_deferred("_autocaptura", float(auto), _tiene_arg("mc-panel"))
	# --mc-cartas: abre la interfaz de cartas (aunque no haya --mc-auto).
	if _tiene_arg("mc-cartas"):
		_silenciar_educacion()
		call_deferred("_abrir_cartas_diferido")


## Abre las cartas y, si el juego las cierra (p. ej. al empezar la oleada),
## vuelve a abrirlas: así la captura siempre las muestra.
func _abrir_cartas_diferido() -> void:
	_reabrir_cartas = true
	_aplicar_wm_debug()
	await get_tree().create_timer(1.0).timeout
	_abrir_cartas()


func _cartas_abiertas() -> bool:
	var cartas := _buscar_cartas()
	return cartas != null and bool(cartas.get("visible"))


func _buscar_cartas() -> Node:
	var cartas := get_tree().get_first_node_in_group("cartas")
	if cartas != null:
		return cartas
	var jug := get_tree().get_first_node_in_group("jugador")
	return jug.get_node_or_null("Cartas") if jug != null else null


## ¿Se pasó el argumento `--nombre` (o `--nombre=valor`)? Tras `--`.
func _tiene_arg(nombre: String) -> bool:
	return _arg_valor(nombre) != ""


## Valor de `--nombre=valor` (o "1" si solo aparece `--nombre`); "" si no está.
func _arg_valor(nombre: String) -> String:
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("--"):
			s = s.substr(2)
		var partes := s.split("=", true, 1)
		if partes[0] == nombre:
			return partes[1] if partes.size() == 2 else "1"
	return ""


## Espera `seg` segundos y guarda un PNG (automatización de capturas).
## Deja la oleada normal en marcha (con HUD) para capturas de gameplay;
## si además hay `--modo-captura`, abre el panel y detiene los spawns.
func _autocaptura(seg: float, abrir_panel: bool) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(carpeta_capturas))
	_silenciar_educacion()
	if abrir_panel:
		abrir()
	else:
		_marcar_debug_sin_guardar()
	if _tiene_arg("mc-cartas"):
		await get_tree().create_timer(0.5).timeout
		_abrir_cartas()
	await get_tree().create_timer(maxf(seg, 0.1)).timeout
	await _guardar_png(carpeta_capturas)
	get_tree().quit()


## Deja el WaveManager en marcha pero sin guardar ni imprimir (capturas).
func _marcar_debug_sin_guardar() -> void:
	if _wm == null:
		_wm = get_tree().get_first_node_in_group("wave_manager")
	if _wm == null:
		return
	_wm.set("debug_activo", true)
	_wm.set("debug_no_guardar", true)
	_wm.set("debug_imprimir_info", false)


func _silenciar_educacion() -> void:
	var edu := get_node_or_null("/root/EducationManager")
	if edu != null and edu.has_method("stop_run"):
		edu.call("stop_run")


## Fuerza una oleada concreta (y su etapa) vía los overrides debug del
## WaveManager. Igual que `--captura-oleada` de tools/capturar.gd.
func _forzar_oleada(oleada: int) -> void:
	if _wm == null:
		_wm = get_tree().get_first_node_in_group("wave_manager")
	if _wm == null:
		return
	_wm.set("debug_activo", true)
	_wm.set("debug_oleada_inicial", oleada)
	_wm.set("debug_spawnear_enemigos", true)
	_wm.set("debug_sin_limite_tiempo", true)
	_wm.set("debug_no_guardar", true)
	_wm.set("debug_imprimir_info", false)


## Abre la interfaz de cartas/mejoras (para capturarla en los docs).
func _abrir_cartas() -> void:
	var cartas := _buscar_cartas()
	if cartas != null and cartas.has_method("_mostrar_interfaz_mejoras"):
		cartas.call("_mostrar_interfaz_mejoras")
		print("[ModoCaptura] UI de cartas abierta (", cartas.name, ")")
	else:
		push_warning("[ModoCaptura] no encontré la UI de cartas.")


# ───────────── UI ─────────────

func _construir() -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.position = Vector2(12, 12)
	_panel.custom_minimum_size = Vector2(520, 0)
	add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_panel.add_child(vb)

	var titulo := Label.new()
	titulo.text = "MODO CAPTURA / TRAILER"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	EstiloUI.titulo(titulo, 30)
	vb.add_child(titulo)

	_lbl_info = Label.new()
	_lbl_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_info.add_theme_font_size_override("font_size", 18)
	vb.add_child(_lbl_info)

	vb.add_child(HSeparator.new())

	# ── Spawn ──
	var g1 := GridContainer.new()
	g1.columns = 2
	g1.add_theme_constant_override("h_separation", 8)
	g1.add_theme_constant_override("v_separation", 6)
	vb.add_child(g1)
	g1.add_child(_etiqueta("Etapa"))
	_opc_etapa = OptionButton.new()
	_opc_etapa.focus_mode = Control.FOCUS_NONE
	_opc_etapa.custom_minimum_size = Vector2(320, 40)
	_opc_etapa.item_selected.connect(func(_i: int): _refrescar_enemigos())
	g1.add_child(_opc_etapa)

	g1.add_child(_etiqueta("Enemigo"))
	_opc_enemigos = OptionButton.new()
	_opc_enemigos.focus_mode = Control.FOCUS_NONE
	_opc_enemigos.custom_minimum_size = Vector2(320, 40)
	g1.add_child(_opc_enemigos)

	g1.add_child(_etiqueta("Jefe"))
	_opc_jefes = OptionButton.new()
	_opc_jefes.focus_mode = Control.FOCUS_NONE
	_opc_jefes.custom_minimum_size = Vector2(320, 40)
	g1.add_child(_opc_jefes)

	var g2 := GridContainer.new()
	g2.columns = 3
	g2.add_theme_constant_override("h_separation", 8)
	g2.add_theme_constant_override("v_separation", 6)
	vb.add_child(g2)
	_boton(g2, "Spawnear enemigo", _spawn_enemigo)
	_boton(g2, "Spawnear jefe", _spawn_jefe)
	_boton(g2, "×5 enemigos", _spawn_5)
	_boton(g2, "Duplicar sel.", _duplicar)
	_boton(g2, "Borrar sel.", func(): _borrar_seleccionado())
	_boton(g2, "Limpiar todo", _limpiar)

	vb.add_child(HSeparator.new())

	# ── Toggles ──
	var g3 := GridContainer.new()
	g3.columns = 2
	g3.add_theme_constant_override("h_separation", 8)
	g3.add_theme_constant_override("v_separation", 6)
	vb.add_child(g3)
	_btn_congelar = _boton(g3, "Congelar IA: OFF", _toggle_congelar)
	_btn_foto = _boton(g3, "Modo foto: OFF", _toggle_foto)
	_btn_jugador = _boton(g3, "Ocultar jugador: OFF", _toggle_jugador)
	_btn_camara = _boton(g3, "Cámara libre: OFF", _toggle_camara)
	_btn_play = _boton(g3, "Play/Pausa (ESPACIO)", _toggle_tiempo)

	vb.add_child(HSeparator.new())

	# ── Captura ──
	var g4 := GridContainer.new()
	g4.columns = 3
	g4.add_theme_constant_override("h_separation", 8)
	g4.add_theme_constant_override("v_separation", 6)
	vb.add_child(g4)
	_boton(g4, "📷 Guardar PNG (C)", func(): _guardar_png(carpeta_capturas))
	_btn_grabar = _boton(g4, "● Grabar (R)", _toggle_grabar)
	_boton(g4, "Cerrar (F2)", cerrar)

	var ayuda := Label.new()
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.add_theme_font_size_override("font_size", 15)
	ayuda.add_theme_color_override("font_color", EstiloUI.APAGADO)
	ayuda.text = "Clic = seleccionar/arrastrar · Flechas = mover 1px · D = duplicar · Supr = borrar · G = congelar · F = modo foto · SPACE = pausa · +/− y WASD = cámara libre"
	vb.add_child(ayuda)


func _etiqueta(txt: String) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 18)
	return l


func _boton(padre: Node, txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 40)
	b.pressed.connect(cb)
	padre.add_child(b)
	return b


func _construir_marcador() -> void:
	_marcador = MarcadorSeleccion.new()
	_marcador.visible = false
	var escena := get_tree().current_scene
	if escena != null:
		escena.add_child.call_deferred(_marcador)


# ───────────── CATÁLOGO ─────────────

func _refrescar_catalogo() -> void:
	_wm = get_tree().get_first_node_in_group("wave_manager")
	if _wm == null:
		return
	_opc_etapa.clear()
	_enemigos.clear()
	_jefes.clear()
	for i in _wm.get("etapas").size():
		_opc_etapa.add_item("Etapa %d" % (i + 1))
	_refrescar_enemigos()
	_poblar_jefes()


func _refrescar_enemigos() -> void:
	_opc_enemigos.clear()
	_enemigos.clear()
	_nombres_enemigos.clear()
	if _wm == null:
		return
	var etapas: Array = _wm.get("etapas")
	var idx := clampi(_opc_etapa.selected, 0, etapas.size() - 1)
	if idx < 0 or idx >= etapas.size():
		return
	var enem: Array = etapas[idx].get("enemigos")
	if enem == null:
		return
	for cfg in enem:
		var esc := cfg.get("escena") as PackedScene
		if esc == null:
			continue
		_enemigos.append(esc)
		_opc_enemigos.add_item(_nombre_de(esc))


func _poblar_jefes() -> void:
	_opc_jefes.clear()
	_jefes.clear()
	if _wm == null:
		return
	for et in _wm.get("etapas"):
		var jefe := et.get("jefe_escena") as PackedScene
		if jefe == null:
			continue
		_jefes.append(jefe)
		_opc_jefes.add_item(_nombre_de(jefe))


func _nombre_de(esc: PackedScene) -> String:
	return esc.resource_path.get_file().get_basename()


# ───────────── ABRIR / CERRAR ─────────────

func abrir() -> void:
	_refrescar_catalogo()
	_panel.visible = true
	_abierto = true
	_aplicar_wm_debug()


func cerrar() -> void:
	_panel.visible = false
	_abierto = false


func _toggle() -> void:
	if _abierto:
		cerrar()
	else:
		abrir()


## Deja el WaveManager en modo "no hace nada": sin spawns, sin reloj, sin guardar.
func _aplicar_wm_debug() -> void:
	if _wm == null:
		_wm = get_tree().get_first_node_in_group("wave_manager")
	if _wm == null:
		return
	_wm.set("debug_activo", true)
	_wm.set("debug_spawnear_enemigos", false)
	_wm.set("debug_sin_limite_tiempo", true)
	_wm.set("debug_no_guardar", true)
	_wm.set("debug_imprimir_info", false)
	var edu := get_node_or_null("/root/EducationManager")
	if edu != null and edu.has_method("stop_run"):
		edu.call("stop_run")


# ───────────── SPAWN / EDICIÓN ─────────────

func _spawn_enemigo() -> void:
	var idx := clampi(_opc_enemigos.selected, 0, _enemigos.size() - 1)
	if _enemigos.is_empty():
		return
	_spawn(_enemigos[idx])


func _spawn_jefe() -> void:
	var idx := clampi(_opc_jefes.selected, 0, _jefes.size() - 1)
	if _jefes.is_empty():
		return
	_spawn(_jefes[idx])


func _spawn(esc: PackedScene) -> void:
	var escena := get_tree().current_scene
	if escena == null or esc == null:
		return
	var e := esc.instantiate() as Node2D
	if e == null:
		return
	e.global_position = _centro_vista()
	escena.add_child.call_deferred(e)
	_llamar_diferido(func():
		if _congelado:
			_aplicar_congelado(e, true)
		_seleccionar(e))


func _duplicar() -> void:
	if _seleccionado == null or not is_instance_valid(_seleccionado):
		return
	var esc := load(_ruta_de(_seleccionado)) as PackedScene
	if esc == null:
		return
	var escena := get_tree().current_scene
	var e := esc.instantiate() as Node2D
	if e == null:
		return
	e.global_position = _seleccionado.global_position + Vector2(80, 0)
	escena.add_child.call_deferred(e)
	if _congelado:
		_llamar_diferido(func(): _aplicar_congelado(e, true))


func _ruta_de(nodo: Node) -> String:
	if nodo.scene_file_path != "":
		return nodo.scene_file_path
	return ""


func _borrar_seleccionado() -> void:
	if _seleccionado != null and is_instance_valid(_seleccionado):
		_seleccionado.queue_free()
	_seleccionado = null
	_marcador.visible = false


func _limpiar() -> void:
	for e in get_tree().get_nodes_in_group(GRUPO_ENEMIGOS):
		if is_instance_valid(e):
			e.queue_free()
	_seleccionado = null
	_marcador.visible = false


func _seleccionar(e: Node2D) -> void:
	_seleccionado = e
	_marcador.visible = e != null


## Marca el enemigo como congelado (IA detenida). Usa process_mode para
## que también se detengan sus hijos (Ataques del jefe, proyectiles…).
func _aplicar_congelado(e: Node, estado: bool) -> void:
	if e == null or not is_instance_valid(e):
		return
	e.process_mode = Node.PROCESS_MODE_DISABLED if estado else Node.PROCESS_MODE_INHERIT
	if estado and e is CharacterBody2D:
		(e as CharacterBody2D).velocity = Vector2.ZERO


func _toggle_congelar() -> void:
	_congelado = not _congelado
	for e in get_tree().get_nodes_in_group(GRUPO_ENEMIGOS):
		_aplicar_congelado(e, _congelado)
	_btn_congelar.text = "Congelar IA: %s" % ("ON" if _congelado else "OFF")


# ───────────── MODO FOTO / JUGADOR ─────────────

func _toggle_foto() -> void:
	_foto = not _foto
	_aplicar_foto()
	_btn_foto.text = "Modo foto: %s" % ("ON" if _foto else "OFF")


func _aplicar_foto() -> void:
	for cl in _canvas_layers(get_tree().root):
		if cl == self:
			continue
		cl.visible = not _foto


func _toggle_jugador() -> void:
	_ocultar_jugador = not _ocultar_jugador
	_aplicar_jugador()
	_btn_jugador.text = "Ocultar jugador: %s" % ("ON" if _ocultar_jugador else "OFF")


func _aplicar_jugador() -> void:
	var j := _jugador if _jugador != null and is_instance_valid(_jugador) else get_tree().get_first_node_in_group("jugador")
	if j is CanvasItem:
		(j as CanvasItem).visible = not _ocultar_jugador


func _canvas_layers(nodo: Node) -> Array:
	var out: Array = []
	for c in nodo.get_children():
		if c is CanvasLayer:
			out.append(c)
		out.append_array(_canvas_layers(c))
	return out


# ───────────── CÁMARA LIBRE ─────────────

func _toggle_camara() -> void:
	_camara_libre = not _camara_libre
	if _camara_libre:
		if _cam == null:
			_cam = Camera2D.new()
			_cam.name = "CamaraCaptura"
			_cam.zoom = Vector2.ONE * 2.0
			get_tree().current_scene.add_child(_cam)
			var j := get_tree().get_first_node_in_group("jugador") as Node2D
			if j != null:
				_cam.global_position = j.global_position
		_cam.make_current()
	else:
		if _cam_jugador == null and _jugador != null:
			_cam_jugador = _jugador.get_node_or_null("Camera2D") as Camera2D
		if _cam_jugador != null:
			_cam_jugador.make_current()
	_btn_camara.text = "Cámara libre: %s" % ("ON" if _camara_libre else "OFF")


func _pilotar_camara(delta: float) -> void:
	if _cam == null or not is_instance_valid(_cam):
		return
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		dir.x += 1
	if Input.is_key_pressed(KEY_W):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		dir.y += 1
	if dir != Vector2.ZERO:
		_cam.global_position += dir.normalized() * VEL_PANEO * delta / _cam.zoom.x


# ───────────── TIEMPO ─────────────

func _toggle_tiempo() -> void:
	var arbol := get_tree()
	arbol.paused = not arbol.paused
	_btn_play.text = "Play (ESPACIO)" if arbol.paused else "Pausa (ESPACIO)"


func _spawn_5() -> void:
	for i in 5:
		_spawn_enemigo()


# ───────────── CAPTURA ─────────────

func _guardar_png(carpeta: String) -> void:
	var ts := Time.get_datetime_string_from_system().replace(":", "-")
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	var ruta := "%s/captura_%s.png" % [carpeta, ts]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ruta.get_base_dir()))
	var err := img.save_png(ruta)
	print("[ModoCaptura] PNG ", ProjectSettings.globalize_path(ruta) if err == OK else "error %d" % err)


func _toggle_grabar() -> void:
	_grabando = not _grabando
	if _grabando:
		_frame = 0
		_t_frame = 0.0
		print("[ModoCaptura] grabando a %d FPS…" % fps_grabacion)
	else:
		print("[ModoCaptura] grabación detenida (%d frames)." % _frame)
	_btn_grabar.text = "■ Parar (R)" if _grabando else "● Grabar (R)"


func _procesar_grabacion(delta: float) -> void:
	_t_frame += delta
	var paso := 1.0 / float(maxi(fps_grabacion, 1))
	if _t_frame < paso:
		return
	_t_frame = 0.0
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	var dir := "%s/grabacion_%s" % [carpeta_video, Time.get_datetime_string_from_system().replace(":", "-")]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	img.save_png("%s/frame_%05d.png" % [dir, _frame])
	_frame += 1


# ───────────── INPUT ─────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == tecla_abrir:
			_toggle()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_C: _guardar_png(carpeta_capturas)
			KEY_R: _toggle_grabar()
			KEY_F: _toggle_foto()
			KEY_G: _toggle_congelar()
			KEY_SPACE: _toggle_tiempo()
			KEY_D: _duplicar()
			KEY_DELETE: _borrar_seleccionado()
			KEY_PLUS, KEY_EQUAL: _zoom_camara(1.1)
			KEY_MINUS: _zoom_camara(1.0 / 1.1)
			KEY_LEFT: _mover_sel(Vector2.LEFT)
			KEY_RIGHT: _mover_sel(Vector2.RIGHT)
			KEY_UP: _mover_sel(Vector2.UP)
			KEY_DOWN: _mover_sel(Vector2.DOWN)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_on_clic(mb.position)
			else:
				_arrastrando = false
	elif event is InputEventMouseMotion and _arrastrando:
		if _seleccionado != null and is_instance_valid(_seleccionado):
			_seleccionado.global_position = _mundo_desde_pantalla((event as InputEventMouseMotion).position)


func _on_clic(pantalla: Vector2) -> void:
	var mundo := _mundo_desde_pantalla(pantalla)
	var mejor: Node2D = null
	var mejor_d := 90.0
	for e in get_tree().get_nodes_in_group(GRUPO_ENEMIGOS):
		if not is_instance_valid(e):
			continue
		var d: float = (e as Node2D).global_position.distance_to(mundo)
		if d < mejor_d:
			mejor_d = d
			mejor = e
	if mejor != null:
		_seleccionar(mejor)
		_arrastrando = true
	elif _seleccionado != null and is_instance_valid(_seleccionado):
		_seleccionado.global_position = mundo
	else:
		_seleccionar(null)
		_marcador.visible = false


func _mover_sel(dir: Vector2) -> void:
	if _seleccionado != null and is_instance_valid(_seleccionado):
		_seleccionado.global_position += dir * 2.0


func _zoom_camara(factor: float) -> void:
	if _cam != null and is_instance_valid(_cam):
		_cam.zoom = (_cam.zoom * factor).clamp(Vector2.ONE * 0.3, Vector2.ONE * 8.0)


func _mundo_desde_pantalla(pantalla: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * pantalla


func _centro_vista() -> Vector2:
	return _mundo_desde_pantalla(get_viewport().get_visible_rect().size * 0.5)


func _llamar_diferido(cb: Callable) -> void:
	get_tree().create_timer(0.05).timeout.connect(cb)


# ───────────── LOOP ─────────────

func _process(delta: float) -> void:
	if _reabrir_cartas and not _cartas_abiertas():
		_t_cartas -= delta
		if _t_cartas <= 0.0:
			_t_cartas = 0.5
			_abrir_cartas()
	if _abierto:
		_t -= delta
		if _t <= 0.0:
			_t = 0.2
			_refrescar_info()
	if _camara_libre:
		_pilotar_camara(delta)
	if _grabando:
		_procesar_grabacion(delta)
	if _mini_marcador_visible():
		_marcador.visible = true
		_marcador.queue_redraw()
		_marcador.global_position = _seleccionado.global_position


func _mini_marcador_visible() -> bool:
	return _seleccionado != null and is_instance_valid(_seleccionado)


func _refrescar_info() -> void:
	if _lbl_info == null:
		return
	var vivos := get_tree().get_nodes_in_group(GRUPO_ENEMIGOS).size()
	var sel := "—"
	if _seleccionado != null and is_instance_valid(_seleccionado):
		sel = _nombre_de_instancia(_seleccionado)
	_lbl_info.text = "Vivos: %d   ·   Sel: %s\nGrabando: %s (%d frames)" % [
		vivos, sel, ("sí" if _grabando else "no"), _frame]


func _nombre_de_instancia(n: Node) -> String:
	if n.scene_file_path != "":
		return n.scene_file_path.get_file().get_basename()
	return n.name


# ── Marcador de selección (aro en el mundo) ──
class MarcadorSeleccion extends Node2D:
	func _draw() -> void:
		draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 40, Color("99ff33"), 3.0, true)
		draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 40, Color("99ff33", 0.35), 2.0, true)
