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
##
## NOTE: this is typed as Node2D only so the Inspector's node picker can
## restrict what gets dropped here. The "died" signal and "respawn_at"
## method actually belong to the player's own script (e.g. quark.gd), not
## to Node2D itself. Because of that, they are accessed dynamically below
## (via connect-by-string and call()) instead of "jugador.died.connect(...)"
## or "jugador.respawn_at(...)", which would fail to compile: GDScript
## resolves member access on typed variables against the *declared* type,
## and Node2D has neither of those members.
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

## Prevents overlapping respawn sequences if "died" fires more than once
## (e.g. the player keeps taking damage while already waiting to respawn).
var _esperando_respawn: bool = false


func _ready() -> void:
	if jugador == null:
		push_warning("RespawnManager: falta asignar la referencia al jugador")
		return

	if punto_respawn == null:
		push_warning("RespawnManager: falta asignar el punto de respawn")

	if not jugador.has_signal("died"):
		push_warning("RespawnManager: el jugador asignado no tiene la señal 'died'")
		return

	# Conexión por nombre de señal (String) en vez de "jugador.died.connect(...)":
	# evita el error de compilación que ocurriría al acceder a "died" sobre
	# una variable tipada estáticamente como Node2D.
	jugador.connect("died", _on_jugador_died)


## Called automatically when the player's "died" signal is emitted.
func _on_jugador_died() -> void:
	if _esperando_respawn:
		return

	if punto_respawn == null:
		push_warning("RespawnManager: falta asignar el punto de respawn")
		return

	if not is_instance_valid(jugador) or not jugador.has_method("respawn_at"):
		push_warning("RespawnManager: el jugador no tiene el método 'respawn_at'")
		return

	_esperando_respawn = true

	# Teletransporta al jugador (ya invisible) de inmediato al punto de
	# respawn. Como el jugador sigue en el árbol de escena (no se
	# deshabilita su process_mode), la Camera2D que lo sigue hará un
	# paneo suave hacia la base durante la espera del temporizador,
	# creando el efecto cinemático de respawn.
	jugador.global_position = punto_respawn.global_position

	respawn_iniciado.emit(tiempo_respawn)

	await get_tree().create_timer(tiempo_respawn).timeout

	# El jugador podría haber sido liberado de la escena mientras esperábamos.
	if is_instance_valid(jugador):
		# call() en vez de "jugador.respawn_at(...)": evita el error de
		# compilación por el mismo motivo que la conexión de la señal.
		jugador.call("respawn_at", punto_respawn.global_position)

	_esperando_respawn = false
	respawn_finalizado.emit()
