extends Control

@onready var buttonCreateGame = $ColorRect/VBoxContainer/HBoxContainer/newGame
var counterGames = 0 #10
var OnlimitGame = false

func _on_new_game_button_down() -> void:
	var  newButton = Button.new()
	var nameButton = Time.get_date_string_from_system()
	
	
	newButton.text = nameButton
	%gameContainer.add_child(newButton)
	
	if %gameContainer.get_child_count() >= 10:
		OnlimitGame = true
		buttonCreateGame.disabled = OnlimitGame
	else:
		OnlimitGame = false
		buttonCreateGame.disabled = OnlimitGame


func _on_change_game_button_down() -> void:
	DisplayServer.file_dialog_show("Cargar Partida", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.save ; Partidas"], func(s, p, i): pass)
