class_name DashComponent
extends Node
## Estado del dash: duración, cooldown e i-frames.
## No mueve al jugador: el dueño lee 'activo', 'direccion' y 'velocidad'.

signal iniciado
signal terminado

var velocidad: float = 600.0
var duracion: float = 0.15
var cooldown: float = 0.8
var invulnerable: bool = true

var activo: bool = false
var direccion: Vector2 = Vector2.RIGHT

var _restante: float = 0.0
var _enfriamiento: float = 0.0


func configurar(vel: float, dur: float, cd: float, inv: bool) -> void:
	velocidad = vel
	duracion = dur
	cooldown = cd
	invulnerable = inv


func intentar(dir: Vector2, direccion_respaldo: Vector2 = Vector2.RIGHT) -> bool:
	if activo or _enfriamiento > 0.0:
		return false
	direccion = dir.normalized() if dir != Vector2.ZERO else direccion_respaldo
	activo = true
	_restante = duracion
	_enfriamiento = cooldown
	iniciado.emit()
	return true


func actualizar(delta: float) -> void:
	if _enfriamiento > 0.0:
		_enfriamiento -= delta
	if activo:
		_restante -= delta
		if _restante <= 0.0:
			activo = false
			terminado.emit()


func cancelar() -> void:
	if activo:
		activo = false
		terminado.emit()


func es_invulnerable() -> bool:
	return activo and invulnerable


## 0.0 = recién usado, 1.0 = listo. Útil para un indicador en la UI.
func progreso_cooldown() -> float:
	return 1.0 - clampf(_enfriamiento / maxf(cooldown, 0.001), 0.0, 1.0)
