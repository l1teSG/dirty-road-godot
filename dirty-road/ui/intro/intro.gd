extends Control

## Pantalla de inicio: título + subtítulo con esporas, y transición al menú.

@onready var titulo: Label = $Centro/VBox/Titulo
@onready var subtitulo: Label = $Centro/VBox/Subtitulo
@onready var esporas: CPUParticles2D = $Esporas


func _ready() -> void:
	EstiloUI.titulo(titulo, 180, EstiloUI.NEON)

	# Estado inicial.
	titulo.modulate.a = 0.0
	titulo.scale = Vector2(0.86, 0.86)
	subtitulo.modulate.a = 0.0
	self.modulate.a = 1.0

	_centrar_esporas.call_deferred()
	_ejecutar_intro()


func _centrar_esporas() -> void:
	await get_tree().process_frame
	if titulo == null:
		return
	titulo.pivot_offset = titulo.size * 0.5
	esporas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	esporas.global_position = titulo.global_position + titulo.size * 0.5
	esporas.emission_rect_extents = titulo.size * 0.5


func _ejecutar_intro() -> void:
	await get_tree().process_frame

	# 1. Aparición del título (fade + escala con rebote).
	titulo.pivot_offset = titulo.size * 0.5
	var t1 := create_tween().set_parallel(true)
	t1.tween_property(titulo, "modulate:a", 1.0, 0.9)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t1.tween_property(titulo, "scale", Vector2.ONE, 1.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t1.finished

	# 2. Subtítulo.
	var t2 := create_tween()
	t2.tween_property(subtitulo, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	await t2.finished

	# 3. Mantener.
	await get_tree().create_timer(1.6).timeout

	# 4. Salida (título + subtítulo).
	var t3 := create_tween().set_parallel(true)
	t3.tween_property(titulo, "modulate:a", 0.0, 0.6)
	t3.tween_property(subtitulo, "modulate:a", 0.0, 0.6)
	esporas.emitting = false
	await t3.finished

	# 5. Fundido general y transición al menú.
	var t4 := create_tween()
	t4.tween_property(self, "modulate:a", 0.0, 0.5)
	await t4.finished
	get_tree().change_scene_to_file("res://ui/main/main.tscn")
