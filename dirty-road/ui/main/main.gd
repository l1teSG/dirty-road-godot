extends Control

# Usamos '@onready' pero validaremos que no sean nulos
@onready var ui_controles = $"." 
@onready var fondo_oscuro = $CanvasLayer/ColorRect
@onready var btn_continuar = $VBoxContainer/VBoxContainer/jugar

func _ready():
	
	if btn_continuar:
		btn_continuar.pressed.connect(_on_continuar_pressed)
		$VBoxContainer/VBoxContainer/salir.pressed.connect(_on_continuar_pressed)
		$VBoxContainer/VBoxContainer/nuevaPartida.pressed.connect(_on_continuar_pressed)
	else:
		print("¡Advertencia! No se encontró el botón 'Btn_Continuar' en la ruta especificada.")

func _on_continuar_pressed():
	# Validación de seguridad para evitar el error de "rp_target is null"
	if not ui_controles or not fondo_oscuro:
		print("Error crítico: 'ui_controles' o 'fondo_oscuro' es nulo. Revisa los nombres de tus nodos.")
		return
		
	btn_continuar.disabled = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Animaciones
	tween.tween_property(ui_controles, "modulate:a", 0.0, 0.3)
	tween.tween_property(fondo_oscuro, "color:a", 0.0, 1.5)
	
	tween.chain().tween_callback(_iniciar_juego)

func _iniciar_juego():
	
	queue_free()


func _on_salir_button_down() -> void:
	get_tree().quit()
