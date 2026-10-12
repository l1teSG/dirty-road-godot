extends Node

## ══════════════════════════════════════════════════════════
##  CAPTURA DE PANTALLA / MODO FOTO (herramienta de desarrollo)
##
##  INTERACTIVO:
##   · Tecla C  → guarda un PNG en `user://capturas/`.
##   · Tecla V  → alterna MODO FOTO (oculta el HUD y popups).
##   · `auto_cada_seg` > 0 → captura automática cada N s.
##
##  AUTOMÁTICO (por argumentos de línea de comandos, tras `--`):
##   --captura-oleada=N     fuerza esa oleada (y su etapa) vía debug
##   --captura-espera=S     segundos de calentamiento antes de la foto
##   --captura-salida=RUTA  ruta del PNG de salida
##   --captura-salir        cierra el juego tras la foto
##   Ej.: godot "res://demo/level 1/niviel1.tscn" -- --captura-oleada=41 \
##              --captura-espera=5 --captura-salida=/tmp/e5.png --captura-salir
##
##  No interfiere con el juego (solo si `activo`).
## ══════════════════════════════════════════════════════════

@export var activo: bool = true
@export var auto_cada_seg: float = 0.0
@export var modo_foto_al_iniciar: bool = false
@export var carpeta: String = "user://capturas"

var _t: float = 0.0
var _t_foto: float = 0.0
var _modo_foto: bool = false

# ── Piloto automático (mueve al jugador para capturas con acción) ──
var _piloto: bool = false
var _radio_obj: float = 190.0
var _t_dash: float = 2.0
var _t_super: float = 6.0


func _ready() -> void:
	if not activo or not OS.is_debug_build():
		set_process(false)
		set_process_unhandled_input(false)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(carpeta))
	_modo_foto = modo_foto_al_iniciar
	if _modo_foto:
		_aplicar_modo_foto(true)
	_procesar_args()


# ───────────── AUTOMÁTICO ─────────────

func _procesar_args() -> void:
	var cfg := _parsear_args(OS.get_cmdline_user_args())
	if not cfg.has("captura-oleada"):
		return
	# Modo foto (sin HUD/popups) y sin mensajes educativos.
	_modo_foto = true
	_aplicar_modo_foto(true)
	_silenciar_educacion()
	_configurar_wave_manager(int(cfg["captura-oleada"]))
	# El jugador ronda el árbol salvo que se pida quieto.
	_piloto = not cfg.has("captura-quieto")
	var espera := float(cfg.get("captura-espera", "3"))
	await get_tree().create_timer(espera).timeout
	if cfg.has("captura-grabar"):
		# Modo grabación: no capturamos aquí; el Movie Maker graba la ventana.
		return
	var salida := str(cfg.get("captura-salida", ""))
	_guardar_en(salida)
	if cfg.has("captura-salir"):
		_soltar_piloto()
		get_tree().quit()


func _parsear_args(args: PackedStringArray) -> Dictionary:
	var cfg := {}
	for a in args:
		var s := String(a)
		if s.begins_with("--"):
			s = s.substr(2)
		var partes := s.split("=", true, 1)
		cfg[partes[0]] = partes[1] if partes.size() == 2 else "1"
	return cfg


func _silenciar_educacion() -> void:
	var edu := get_node_or_null("/root/EducationManager")
	if edu != null and edu.has_method("stop_run"):
		edu.call("stop_run")


func _configurar_wave_manager(oleada: int) -> void:
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm == null:
		push_warning("[Captura] no encontré el WaveManager.")
		return
	wm.set("debug_activo", true)
	wm.set("debug_oleada_inicial", oleada)
	wm.set("debug_spawnear_enemigos", true)
	wm.set("debug_sin_limite_tiempo", true)
	wm.set("debug_no_guardar", true)
	wm.set("debug_imprimir_info", false)
	print("[Captura] oleada forzada a %d (etapa %d)" % [oleada, (oleada - 1) / 10 + 1])


# ───────────── INTERACTIVO ─────────────

func _process(delta: float) -> void:
	if _piloto:
		_pilotar(delta)
	# En modo foto, re-oculta cada 0.2 s: así caen los CanvasLayer creados
	# DESPUÉS (banner de etapa, popups educativos...).
	if _modo_foto:
		_t_foto -= delta
		if _t_foto <= 0.0:
			_t_foto = 0.2
			_aplicar_modo_foto(true)
	if auto_cada_seg > 0.0:
		_t += delta
		if _t >= auto_cada_seg:
			_t = 0.0
			capturar()


# ───────────── PILOTO ─────────────

## Ronda al árbol dentro de un radio, con dash y súper ocasionales para que
## las capturas/vídeo tengan movimiento.
func _pilotar(delta: float) -> void:
	var jug := get_tree().get_first_node_in_group("jugador") as Node2D
	var arb := get_tree().get_first_node_in_group("arbol") as Node2D
	if jug == null or not is_instance_valid(jug) or arb == null:
		return
	var v: Vector2 = jug.global_position - arb.global_position
	var d: float = v.length()
	var tang: Vector2 = v.normalized().orthogonal() if d > 0.5 else Vector2.RIGHT
	var radial := Vector2.ZERO
	if d > _radio_obj + 30.0:
		radial = -v.normalized()
	elif d < _radio_obj - 30.0:
		radial = v.normalized()
	var dir := (tang + radial * 0.9).normalized()
	_aplicar_dir(dir)

	_t_dash -= delta
	if _t_dash <= 0.0:
		_t_dash = randf_range(2.5, 4.5)
		if jug.has_method("_on_mega_pressed"):
			jug.call("_on_mega_pressed")
	_t_super -= delta
	if _t_super <= 0.0:
		_t_super = randf_range(9.0, 15.0)
		if jug.has_method("_on_super_pressed"):
			jug.call("_on_super_pressed")


func _aplicar_dir(dir: Vector2) -> void:
	_set_accion("ui_right", dir.x > 0.38)
	_set_accion("ui_left", dir.x < -0.38)
	_set_accion("ui_down", dir.y > 0.38)
	_set_accion("ui_up", dir.y < -0.38)


func _set_accion(accion: String, on: bool) -> void:
	if on:
		Input.action_press(accion)
	else:
		Input.action_release(accion)


func _soltar_piloto() -> void:
	_piloto = false
	for a in ["ui_right", "ui_left", "ui_up", "ui_down"]:
		Input.action_release(a)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				capturar()
			KEY_V:
				_alternar_modo_foto()


func capturar() -> void:
	var ts := Time.get_datetime_string_from_system().replace(":", "-")
	_guardar_en("%s/captura_%s.png" % [carpeta, ts])


func _guardar_en(ruta: String) -> void:
	if ruta.is_empty():
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		push_warning("[Captura] no se pudo obtener la imagen del viewport.")
		return
	DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
	var err := img.save_png(ruta)
	if err == OK:
		print("[Captura] guardada: ", ProjectSettings.globalize_path(ruta))
	else:
		push_warning("[Captura] error %d al guardar %s" % [err, ruta])


func _alternar_modo_foto() -> void:
	_modo_foto = not _modo_foto
	_aplicar_modo_foto(_modo_foto)


func _aplicar_modo_foto(ocultar: bool) -> void:
	for cl in _canvas_layers(get_tree().root):
		cl.visible = not ocultar
	print("[Captura] modo foto ", "ON (HUD oculto)" if ocultar else "OFF")


func _canvas_layers(nodo: Node) -> Array:
	var out: Array = []
	for c in nodo.get_children():
		if c is CanvasLayer:
			out.append(c)
		out.append_array(_canvas_layers(c))
	return out