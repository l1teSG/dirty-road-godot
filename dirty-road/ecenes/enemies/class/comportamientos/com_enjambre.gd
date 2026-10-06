## ENJAMBRE — rápido, rodea a su objetivo, tambalea y muerde.
## Parámetros: vel_extra, radio_rodeo, reeleccion, tambalear.
extends ComportamientoEnemigo

var vel_extra: float = 1.35
var radio_rodeo: float = 55.0
var reeleccion: float = 1.2
var tambalear: float = 6.0

var _sentido: int = 1
var _t_reeleccion: float = 0.0
var _fase: float = 0.0
var _t: float = 0.0


func configurar(datos: Dictionary) -> void:
	vel_extra = datos.get("vel_extra", vel_extra)
	radio_rodeo = datos.get("radio_rodeo", radio_rodeo)
	reeleccion = datos.get("reeleccion", reeleccion)
	tambalear = datos.get("tambalear", tambalear)


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	_sentido = 1 if randf() < 0.5 else -1
	_fase = randf() * TAU
	_t_reeleccion = randf_range(reeleccion * 0.5, reeleccion)


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	var obj := e.objetivo()
	if obj == null:
		e.detener()
		return

	_fase += delta * tambalear
	_t -= delta

	# Reelección: a veces invierte el sentido del rodeo.
	_t_reeleccion -= delta
	if _t_reeleccion <= 0.0:
		_t_reeleccion = reeleccion
		if randf() < 0.4:
			_sentido = -_sentido

	# Dirección al objetivo + tangencial (rodear) + ondulación.
	var dir: Vector2 = e.dir_a(obj)
	var tangente: Vector2 = Vector2(-dir.y, dir.x) * float(_sentido)
	var osc: float = sin(_fase) * 0.35
	var rumbo: Vector2 = (dir + tangente * (0.85 + osc)).normalized()
	# vel_extra es multiplicador de velocity: NO toca e.speed escalada.
	e.mover_en(rumbo, vel_extra)

	# Mordisco por contacto (daño = e.damage escalado).
	if e.distancia_a(obj) <= e.radio_contacto + 6.0 and _t <= 0.0:
		if e.atacar_objetivo():
			_t = 0.6
