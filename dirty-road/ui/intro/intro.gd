extends Control

@onready var titulo = $Label
@onready var esporas = $CPUParticles2D

func _ready() -> void:
	# Estado inicial: El título empieza invisible en su tamaño real
	titulo.modulate.a = 0.0
	titulo.scale = Vector2(1.0, 1.0)
	self.modulate.a = 1.0
	
	# Configuramos para que las partículas nazcan exactamente a lo ancho y alto del Label
	esporas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	esporas.emission_rect_extents = titulo.size / 2.0
	esporas.global_position = titulo.global_position + (titulo.size / 2.0)
	
	ejecutar_intro()

func ejecutar_intro() -> void:
	var tween = create_tween()
	
	# --- FASE 1: LAS ESPORAS FLOTAN ALREDEDOR DEL TEXTO (1.5 segundos) ---
	tween.tween_interval(1.5)
	
	# --- FASE 2: CONDENSACIÓN SOBRE LA PALABRA ---
	tween.tween_callback(func() -> void:
		esporas.speed_scale = 1.0
		
		var tween_creacion = create_tween()
		tween_creacion.tween_property(titulo, "modulate:a", 1.0, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	)
	
	# El título se mantiene formado y brillante en pantalla (1.5 segundos)
	tween.tween_interval(1.5)
	
	# --- FASE 3: EL TÍTULO SE DESVANECE Y LAS ESPORAS SE DISIPAN ---
	tween.tween_callback(func() -> void:
		# Cortamos la emisión de nuevas partículas para que el remanente se disuelva con elegancia
		esporas.emitting = false
		
		var tween_salida = create_tween().set_parallel(true)
		tween_salida.tween_property(titulo, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN_OUT)
		# Fundimos la opacidad general de las partículas para que se desvanezcan junto con el texto
		tween_salida.tween_property(esporas, "modulate:a", 0.0, 0.8)
	)
	
	# Breve pausa dramática (0.3 segundos)
	tween.tween_interval(0.3)
	
	# --- FASE 4: TRANSICIÓN A NEGRO ---
	tween.tween_callback(func() -> void:
		var tween_transicion = create_tween()
		tween_transicion.tween_property(self, "modulate:a", 0.0, 0.8)
	)
	
	# Esperamos a que termine el fundido negro
	tween.tween_interval(0.8)
	
	# --- FASE 5: CAMBIO DE ESCENA ---
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://ui/main/main.tscn")
	)
