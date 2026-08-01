extends ColorRect

func _ready():
	iniciar_animacion_color()

func iniciar_animacion_color():
	# Creamos un tween que se repita infinitamente
	var tween = create_tween().set_loops()
	
	# Transición hacia un tono ligeramente más vivo (duración: 3 segundos)
	tween.tween_property(self, "color", Color("#0d1f17"), 3.0)
	
	# Regresa al tono abisal base (duración: 3 segundos)
	tween.tween_property(self, "color", Color("#050a08"), 3.0)
