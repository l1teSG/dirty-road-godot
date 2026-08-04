extends CanvasLayer

# Variables de control de estado
var entrada_finalizada: bool = false

# Tween para la secuencia de entrada
var tween_entrada: Tween

# Referencias a nodos clave
@onready var titulo_label: Label = $Contenedor/CenterContainer/VBoxContainer/Label
@onready var boton_reinicio: Button = $Contenedor/CenterContainer/VBoxContainer/nuevaPartida
@onready var boton_salir: Button = $Contenedor/CenterContainer/VBoxContainer/salir
@onready var fondo_overlay: ColorRect = $Contenedor/ColorRect
@onready var particulas: CPUParticles2D = $Contenedor/CPUParticles2D

# Configuración de tiempos
const DURACION_PARCIAL_FONDO := 0.6          # Se usa en fase 1
const DURACION_PAUSA_ANTES_TEXTO := 0.15      # Pausa entre fondo y texto
const DURACION_APARICION_TEXTO := 1.2
const DURACION_PAUSA_ANTES_BOTONES := 0.2
const DURACION_APARICION_BOTONES := 0.9
const RETRASO_ESCALONADO_BOTON := 0.2         # 0.2s entre el primer y segundo botón

# Offset inicial para animación del texto
const OFFSET_Y_TEXTO := 20.0
const ESCALA_INICIAL_TEXTO := 1.3


func _ready() -> void:
	# ── 0. Ocultar / opacar todo al inicio ─────────────────────────
	_estado_inicial_oculto()

	# Pequeño retraso en frames para garantizar que los nodos están listos
	await get_tree().process_frame

	# ── Fase 1: Revelado gradual del fondo (color oscuro) ──────────
	# El fondo ya está negro en la escena; simplemente hacemos fade de su modulate
	# para que el negro pierda opacidad progresivamente y asome la escena.
	fondo_overlay.modulate.a = 1.0
	tween_entrada = create_tween()
	tween_entrada.set_parallel(true)
	tween_entrada.tween_property(fondo_overlay, "modulate:a", 0.0, DURACION_PARCIAL_FONDO)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween_entrada.finished

	# Pequeña pausa visual entre fondo y texto
	await get_tree().create_timer(DURACION_PAUSA_ANTES_TEXTO, false).timeout

	# ── Fase 2: Aparición dramática del texto principal ────────────
	_animar_texto_principal()

	# Esperar a que termine la animación del texto
	await tween_entrada.finished

	# Pequeña pausa antes de los botones
	await get_tree().create_timer(DURACION_PAUSA_ANTES_BOTONES, false).timeout

	# ── Fase 3: Revelado escalonado de botones ────────────────────
	_animar_botones()

	# Esperar a que acaben todos los botones
	await tween_entrada.finished

	# Marcar entrada como completada
	entrada_finalizada = true

	# Habilitar interacción con los botones
	boton_reinicio.disabled = false
	boton_salir.disabled = false
	boton_reinicio.mouse_filter = Control.MOUSE_FILTER_STOP
	boton_salir.mouse_filter = Control.MOUSE_FILTER_STOP


# ─────────────────────────────────────────────────────────────────────
# Configuración inicial: todo oculto / opaco
# ─────────────────────────────────────────────────────────────────────
func _estado_inicial_oculto() -> void:
	# Título
	if titulo_label:
		titulo_label.modulate.a = 0.0
		titulo_label.scale = Vector2(ESCALA_INICIAL_TEXTO, ESCALA_INICIAL_TEXTO)
		# Mover ligeramente hacia arriba para poder animar bajada
		titulo_label.position.y -= OFFSET_Y_TEXTO * 1.5

	# Botones
	if boton_reinicio:
		boton_reinicio.modulate.a = 0.0
		boton_reinicio.disabled = true
		boton_reinicio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if boton_salir:
		boton_salir.modulate.a = 0.0
		boton_salir.disabled = true
		boton_salir.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Fondo
	if fondo_overlay:
		fondo_overlay.modulate.a = 1.0  # inicialmente opaco (ya negro)

	# Partículas: empezar opacas pero visibles (o apagarlas temporalmente)
	if particulas:
		particulas.modulate.a = 0.0
		# Podríamos pausarlas, pero las dejamos funcionando (transparentes)


# ─────────────────────────────────────────────────────────────────────
# Animación de aparición del texto principal
# ─────────────────────────────────────────────────────────────────────
func _animar_texto_principal() -> void:
	if not titulo_label:
		return

	var pos_base_y: float = titulo_label.position.y + OFFSET_Y_TEXTO * 1.5
	# Reubicamos al principio: lo movemos arriba para que baje
	titulo_label.position.y = pos_base_y - OFFSET_Y_TEXTO
	titulo_label.modulate.a = 0.0
	titulo_label.scale = Vector2(ESCALA_INICIAL_TEXTO, ESCALA_INICIAL_TEXTO)

	tween_entrada = create_tween()
	tween_entrada.set_parallel(true)

	# Opacidad: de 0 a 1
	tween_entrada.tween_property(titulo_label, "modulate:a", 1.0, DURACION_APARICION_TEXTO)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Escala: de 1.3 a 1.0 con efecto rebote (TRANS_BACK)
	tween_entrada.tween_property(titulo_label, "scale", Vector2.ONE, DURACION_APARICION_TEXTO)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Posición: desplazar hacia abajo (caída) de forma suave
	tween_entrada.tween_property(titulo_label, "position:y", pos_base_y, DURACION_APARICION_TEXTO)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# También hacemos fade en las partículas (pueden empezar ahora)
	if particulas:
		tween_entrada.tween_property(particulas, "modulate:a", 1.0, DURACION_APARICION_TEXTO * 0.8)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(0.3)


# ─────────────────────────────────────────────────────────────────────
# Animación de aparición de botones (escalonada)
# ─────────────────────────────────────────────────────────────────────
func _animar_botones() -> void:
	tween_entrada = create_tween()
	tween_entrada.set_parallel(false)  # serie para retraso escalonado

	# Primer botón (Reiniciar)
	if boton_reinicio:
		boton_reinicio.modulate.a = 0.0
		# Pequeño desplazamiento inicial para animarlo
		var pos_original_y = boton_reinicio.position.y
		boton_reinicio.position.y += 10.0
		tween_entrada.tween_callback(func():
			boton_reinicio.disabled = false
			boton_reinicio.mouse_filter = Control.MOUSE_FILTER_STOP
		)
		tween_entrada.set_parallel(true)
		tween_entrada.tween_property(boton_reinicio, "modulate:a", 1.0, DURACION_APARICION_BOTONES)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween_entrada.tween_property(boton_reinicio, "position:y", pos_original_y, DURACION_APARICION_BOTONES)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Segundo botón (Salir) con retraso escalonado
	tween_entrada.chain().tween_interval(RETRASO_ESCALONADO_BOTON)
	if boton_salir:
		boton_salir.modulate.a = 0.0
		var pos_original_y2 = boton_salir.position.y
		boton_salir.position.y += 10.0
		tween_entrada.set_parallel(true)
		tween_entrada.tween_property(boton_salir, "modulate:a", 1.0, DURACION_APARICION_BOTONES)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween_entrada.tween_property(boton_salir, "position:y", pos_original_y2, DURACION_APARICION_BOTONES)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Al terminar la parte visual, dejamos los botones habilitados
	tween_entrada.chain().tween_callback(func():
		if boton_reinicio:
			boton_reinicio.mouse_filter = Control.MOUSE_FILTER_STOP
			boton_reinicio.disabled = false
		if boton_salir:
			boton_salir.mouse_filter = Control.MOUSE_FILTER_STOP
			boton_salir.disabled = false
	)


# ── Señales de botones (sin cambios) ─────────────────────────────────

func _on_nueva_partida_button_down() -> void:
	get_tree().change_scene_to_file('res://demo/level 1/niviel1.tscn')


func _on_salir_button_down() -> void:
	get_tree().change_scene_to_file('res://ui/main/main.tscn')
