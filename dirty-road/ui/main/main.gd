extends Control

@onready var fondo_oscuro: ColorRect = $CanvasLayer/ColorRect
@onready var btn_continuar: Button = $VBoxContainer/VBoxContainer/jugar
@onready var btn_salir: Button = $VBoxContainer/VBoxContainer/salir
@onready var btn_nueva_partida: Button = $VBoxContainer/VBoxContainer/nuevaPartida

const RUTA_NIVEL := "res://demo/level 1/niviel1.tscn"


func _ready() -> void:
	if btn_continuar == null or btn_salir == null or btn_nueva_partida == null or fondo_oscuro == null:
		push_error("MenuPrincipal: falta algún nodo, revisa las rutas @onready")
		return

	btn_continuar.pressed.connect(_on_continuar_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)
	btn_nueva_partida.pressed.connect(_on_nueva_partida_pressed)

	# desactiva "Continuar" si no hay partida guardada
	btn_continuar.disabled = not SaveManager.hay_partida_guardada()


func _on_continuar_pressed() -> void:
	if not SaveManager.cargar_partida():
		push_warning("No se pudo cargar la partida guardada")
		return

	_transicion_y_cambiar_escena(RUTA_NIVEL)


func _on_nueva_partida_pressed() -> void:
	SaveManager.nueva_partida()
	_transicion_y_cambiar_escena(RUTA_NIVEL)


func _on_salir_pressed() -> void:
	get_tree().quit()


func _transicion_y_cambiar_escena(ruta: String) -> void:
	btn_continuar.disabled = true
	btn_nueva_partida.disabled = true
	btn_salir.disabled = true

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(fondo_oscuro, "color:a", 0.0, 1.5)
	tween.chain().tween_callback(func():
		get_tree().change_scene_to_file(ruta)
	)
