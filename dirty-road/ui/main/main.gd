extends Control

## Menú principal: título, subtítulo y acciones (CONTINUAR / NUEVA PARTIDA / SALIR).

@onready var fondo_oscuro: ColorRect = $Fondo/ColorRect
@onready var btn_continuar: Button = $Centro/Columna/Menu/jugar
@onready var btn_nueva_partida: Button = $Centro/Columna/Menu/nuevaPartida
@onready var btn_salir: Button = $Centro/Columna/Menu/salir
@onready var creditos_label: Label = $CreditosLabel
@onready var titulo: Label = $Centro/Columna/Titulo
@onready var columna: Control = $Centro/Columna

const RUTA_NIVEL := "res://demo/level 1/niviel1.tscn"
const DURACION_ENTRADA := 0.8


func _ready() -> void:
	# Estilo (tema global) + título + hover.
	EstiloUI.titulo(titulo, 130, EstiloUI.NEON)
	EstiloUI.aplicar_hover_a($Centro/Columna/Menu)

	# El menú ahora va a la SELECCIÓN DE PARTIDAS (múltiples slots).
	btn_continuar.text = "JUGAR"
	btn_continuar.disabled = false
	btn_nueva_partida.visible = false

	var menu: VBoxContainer = $Centro/Columna/Menu
	var btn_ajustes := Button.new()
	btn_ajustes.name = "ajustes"
	btn_ajustes.text = "AJUSTES"
	btn_ajustes.focus_mode = Control.FOCUS_NONE
	menu.add_child(btn_ajustes)
	var salir := menu.get_node_or_null("salir")
	if salir != null:
		menu.move_child(btn_ajustes, salir.get_index())
	EstiloUI.boton_menu(btn_ajustes, 40)

	for b in [btn_continuar, btn_nueva_partida, btn_salir, btn_ajustes]:
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_boton_pressed.bind(b))

	# Animación de entrada.
	columna.modulate.a = 0.0
	creditos_label.modulate.a = 0.0
	_animar_entrada()


func _on_boton_pressed(boton: Button) -> void:
	match boton.name:
		"jugar":
			_ir_a("res://ui/slots/slots.tscn")
		"ajustes":
			_ir_a("res://ui/ajustes/ajustes.tscn")
		"nuevaPartida":
			_ir_a("res://ui/slots/slots.tscn")
		"salir":
			_salir()


## Transición con fundido a otra escena.
func _ir_a(ruta: String) -> void:
	_deshabilitar()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): get_tree().change_scene_to_file(ruta))


func _abrir_nivel() -> void:
	_deshabilitar()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): get_tree().change_scene_to_file(RUTA_NIVEL))


func _salir() -> void:
	_deshabilitar()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): get_tree().quit())


func _deshabilitar() -> void:
	for b in $Centro/Columna/Menu.get_children():
		if b is Button:
			b.disabled = true


## Animación de entrada del menú.
func _animar_entrada() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(columna, "modulate:a", 1.0, DURACION_ENTRADA)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(creditos_label, "modulate:a", 0.6, DURACION_ENTRADA)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
