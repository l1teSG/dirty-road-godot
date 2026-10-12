extends CanvasLayer

@onready var info: Label = $Contenedor/Centro/Panel/VBox/Info
@onready var panel: PanelContainer = $Contenedor/Centro/Panel


func _ready() -> void:
	var titulo := get_node_or_null("Contenedor/Centro/Panel/VBox/Titulo")
	if titulo is Label:
		EstiloUI.titulo(titulo, 72, EstiloUI.NEON)
	EstiloUI.aplicar_hover_a($Contenedor/Centro/Panel/VBox)

	# Botón AJUSTES (overlay, sin salir de la partida).
	var vbox := get_node_or_null("Contenedor/Centro/Panel/VBox")
	if vbox is VBoxContainer:
		var b := Button.new()
		b.name = "ajustes"
		b.text = "AJUSTES"
		b.focus_mode = Control.FOCUS_NONE
		EstiloUI.boton_menu(b, 28)
		b.pressed.connect(_abrir_ajustes)
		vbox.add_child(b)
		var salir := vbox.get_node_or_null("salir")
		if salir != null:
			vbox.move_child(b, salir.get_index())


func _abrir_ajustes() -> void:
	var escena := load("res://ui/ajustes/ajustes.tscn") as PackedScene
	if escena == null:
		return
	var inst := escena.instantiate()
	inst.set("volver_a_menu", false)
	inst.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(inst)


## Abre la pausa: refresca la info de la partida y congela el juego de verdad.
func abrir() -> void:
	var horda := int(SaveManager.get_horda()) if SaveManager != null else 1
	var biomasa := int(BiomasaManager.contador) if BiomasaManager != null else 0
	if info != null:
		info.text = "OLEADA %d   ·   🌱 %d" % [horda, biomasa]
	visible = true
	get_tree().paused = true
	_animar_entrada()


## Animación de entrada del panel (pop + fade). Corre estando en pausa.
func _animar_entrada() -> void:
	if panel == null:
		return
	panel.pivot_offset = panel.size * 0.5
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.86, 0.86)
	var tw := create_tween().set_parallel(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.34)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_button_button_down() -> void:
	# Continuar: desvanecimiento deslizándose hacia abajo (1.0 s)
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($Contenedor, "modulate:a", 0.0, 1.0)
	tween.tween_property($Contenedor, "position:y", $Contenedor.position.y + 60, 1.0)

	await tween.finished

	self.visible = false
	# Restaurar valores originales para la próxima vez que se abra la pausa
	$Contenedor.modulate.a = 1.0
	$Contenedor.position.y -= 60

	# Reanudar la partida al final, cuando el menú ya se fue.
	# (Si tu script del jugador ya despausa con Esc, esta línea no estorba.)
	get_tree().paused = false


func _on_nueva_partida_button_down() -> void:
	# Ir a la selección de partidas (slots). Despausar antes de cambiar de escena.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/slots/slots.tscn")


func _on_salir_button_down() -> void:
	# Salir: deslizamiento hacia la izquierda con desvanecimiento (1.0 s)
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property($Contenedor, "modulate:a", 0.0, 1.0)
	tween.tween_property($Contenedor, "position:x", $Contenedor.position.x - 150, 1.0)

	await tween.finished

	# Salir NO borra la partida (querés poder "Continuar" desde el menú);
	# solo despausa antes de cambiar de escena para que el menú no cargue congelado.
	get_tree().paused = false
	get_tree().change_scene_to_file('res://ui/main/main.tscn')
