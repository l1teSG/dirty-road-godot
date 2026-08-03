extends Node
## Handles player respawn after death.
##
## This node is fully independent from the player's health logic. It only
## knows two things: when the player died (via a signal) and where the
## fixed respawn point is. It waits an exportable amount of time and then
## asks the player to respawn at that point.
##
## It emits its own signals when a respawn sequence starts and finishes,
## so other systems (e.g. a future UI countdown) can react without any
## changes to this script.

## Reference to the player that will be respawned.
## Must be assigned manually from the editor.
@export var jugador: Node2D

## Fixed point where the player will respawn.
## Must be assigned manually from the editor.
@export var punto_respawn: Marker2D

## Time, in seconds, to wait between death and respawn.
## Exposed in the Inspector so designers can tune it without touching code.
@export var tiempo_respawn: float = 2.0

## Emitted right when the respawn sequence starts, after the player dies.
## Carries the wait time so a future UI could show a countdown.
signal respawn_iniciado(tiempo_espera: float)

## Emitted right after the player has been repositioned and restored.
signal respawn_finalizado


func _ready() -> void:
	if jugador == null:
		push_warning("RespawnManager: falta asignar la referencia al jugador")
		return

	if not jugador.has_signal("died"):
		push_warning("RespawnManager: el jugador asignado no tiene la señal 'died'")
		return

	jugador.died.connect(_on_jugador_died)


## Called automatically when the player's "died" signal is emitted.
func _on_jugador_died() -> void:
	if punto_respawn == null:
		push_warning("RespawnManager: falta asignar el punto de respawn")
		return

	respawn_iniciado.emit(tiempo_respawn)

	await get_tree().create_timer(tiempo_respawn).timeout

	jugador.respawn_at(punto_respawn.global_position)

	respawn_finalizado.emit()
