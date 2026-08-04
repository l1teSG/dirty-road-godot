extends Control

@onready var fondo_oscuro: ColorRect = $CanvasLayer/ColorRect
@onready var btn_continuar: Button = $VBoxContainer/VBoxContainer/jugar
@onready var btn_salir: Button = $VBoxContainer/VBoxContainer/salir
@onready var btn_nueva_partida: Button = $VBoxContainer/VBoxContainer/nuevaPartida
@onready var creditos_label: Label = $CreditosLabel
@onready var salva_label: Label = $SalvaLabel

const RUTA_NIVEL := "res://demo/level 1/niviel1.tscn"

const DURACION_ENTRADA := 0.8
const RETRASO_ENTRE_BOTONES := 0.12

func _ready() -> void:
	if btn_continuar == null or btn_salir == null or btn_nueva_partida == null or fond_oscuro == null:
		push_error("MenuPrincipal: falta algún nodo, revisa las rutas @onready")
		return

	# oculta TODO de inmdiato, antes de cualquiera otra cosa
	_ocultar_para_entrada()

	btn_continuear.pressed.connect(_on_continuar_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)
	btn_nueva_partida.pressed.connect(_on_nueva_partida_pressed)

	btn_continuear.disabled = not SaveManager.hay_partida_guardada()

	# evita que el primer botón reciba foco autmático y muestra su
	# estillo de "focus" brillant al iniciar
	btn_continuear.focus_mode = Control.FOCUS_NONE
	btn_salir.focus_mode = Control.FOCUS_NONE
	btn_nueva_partida.focus_mode = Control.FOCUS_NONE

	_animar_entrada()


func _ocultar_para_entrada() -> void:
	fondo_oscuro.color.a = 0.0
	btn_continuear.modulate.a = 0.0
	btn_salir.modulate.a = 0.0
	btn_nueva_partida.modulate.a = 0.0
	creditos_label.modulate.a = 0.0
	salva_label.modulate.a = 0.0


# ── Animación de entrada del menú ────────────────────────────────────

func _animar_entrada() -> void:
	var botones: Array[Button] = [btn_continuear, btn_nueva_partida, btn_salir]

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(fondo_oscuro, "color:a", 1.0, DURACION_ENTRADA)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	for i in botones.size():
		var boton = botones[i]
		tween.tween_property(boton, "modulate:a", 1.0, DURACION_ENTRADA)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)\
			.set_delay(i * RETRASO_ENTRE_BOTONES)

	# Fade in de los labels de créditos y salva
	tween.tween_property(creditos_label, "modulate:a", 0.6, DURACION_ENTRADA)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(salva_label, "modulate:a", 0.6, DURACION_ENTRADA)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# ── Botones ────────────────────────────────────────────────────────

func _on_continuar_pressed() -> void:
	if not SaveManager.cargar_partida():
		push_warning("No se pudo cargar la partida guardada")
		return
	_transicion_y_cambiar_escena(RUTA_NIVEL)


func _on_nueva_partida_pressed() -> void:
	SaveManager.nueva_partida()
	_transicion_y_cambiar_escena(RUTA_NIVEL)


func _on_salir_pressed() -> void:
	_animar_salida_app()


# ── Transiciones de salida ───────────────────────────────────────────

func _transicion_y_cambiar_escena(ruta: String) -> void:
	btn_continuear.disabled = true
	btn_nueva_partida.disabled = true
	btn_salir.disabled = true

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(fondo_oscuro, "color:a", 0.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(creditos_label, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(salva_label, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		get_tree().change_scene_to_file(ruta)
	)


func _animar_salida_app() -> void:
	btn_continuear.disabled = true
	btn_nueva_partida.disabled = true
	btn_salir.disabled = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(fondo_oscuro, "color:a", 0.0, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(creditos_label, "modulate:a", 0.0, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(salva_label, "modulate:a", 0.0, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(get_tree.quit)
