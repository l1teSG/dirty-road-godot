extends Node

## ══════════════════════════════════════════════════════════
##  CAPTURA DE PANTALLA / MODO FOTO (herramienta de desarrollo)
##
##  · Tecla C  → guarda un PNG del viewport en `carpeta`.
##  · Tecla V  → alterna el MODO FOTO (oculta/muestra todos los CanvasLayer
##               para tomas limpias sin HUD).
##  · `auto_cada_seg` > 0 → captura automática cada N segundos.
##
##  No interfiere con el juego (solo se activa si `activo`).
## ══════════════════════════════════════════════════════════

@export var activo: bool = true
## Si > 0, captura automáticamente cada N segundos. 0 = solo con la tecla C.
@export var auto_cada_seg: float = 0.0
@export var modo_foto_al_iniciar: bool = false
@export var carpeta: String = "user://capturas"

var _t: float = 0.0
var _modo_foto: bool = false


func _ready() -> void:
	if not activo or not OS.is_debug_build():
		set_process(false)
		set_process_unhandled_input(false)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(carpeta))
	_modo_foto = modo_foto_al_iniciar
	if _modo_foto:
		_aplicar_modo_foto(true)


func _process(delta: float) -> void:
	if auto_cada_seg <= 0.0:
		return
	_t += delta
	if _t >= auto_cada_seg:
		_t = 0.0
		capturar()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				capturar()
			KEY_V:
				_alternar_modo_foto()


func capturar() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		push_warning("[Captura] no se pudo obtener la imagen del viewport.")
		return
	var ts := Time.get_datetime_string_from_system().replace(":", "-")
	var ruta := "%s/captura_%s.png" % [carpeta, ts]
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