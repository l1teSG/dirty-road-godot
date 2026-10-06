## RANGO — mantiene la distancia de objetivo() y le dispara.
## Funciona igual contra el jugador (kitea) que contra el árbol
## (asedio: se planta a distancia y dispara al tronco).
## Parámetros (grupo "Rango"): rango_distancia, rango_margen,
## rango_recarga, rango_vel_strafe, rango_dispersion.
extends ComportamientoEnemigo

var distancia_ideal: float = 220.0
var margen: float = 40.0
var recarga: float = 1.6
var vel_strafe: float = 0.5
var dispersion_grados: float = 6.0

var _t: float = 0.0
var _sentido: int = 1


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	distancia_ideal = _f("rango_distancia", distancia_ideal)
	margen = _f("rango_margen", margen)
	recarga = _f("rango_recarga", recarga)
	vel_strafe = _f("rango_vel_strafe", vel_strafe)
	dispersion_grados = _f("rango_dispersion", dispersion_grados)
	_t = 0.4   # primer disparo casi inmediato
	_sentido = 1 if randf() < 0.5 else -1


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	_t -= delta
	var obj := e.objetivo()
	if obj == null:
		e.detener()
		return
	var dist := e.distancia_a(obj)
	var dir := e.dir_a(obj)
	# Posicionamiento en la banda [ideal - margen, ideal + margen].
	if dist > distancia_ideal + margen:
		e.mover_hacia(obj.global_position, 1.0)
	elif dist < distancia_ideal - margen:
		e.mover_en(-dir, 1.0)                                  # retrocede
	else:
		e.mover_en(dir.orthogonal() * _sentido, vel_strafe)    # strafea
	# Disparo: primer argumento NODO (boca o el propio enemigo),
	# nunca un Vector2. El daño lo decide e (escalado).
	if _t <= 0.0 and dist <= distancia_ideal + margen * 2.0:
		var d := dir.rotated(deg_to_rad(randf_range(-dispersion_grados, dispersion_grados)))
		e.disparar_desde(_origen_disparo(), d)
		_t = recarga


func debug_dibujar_en(enemigo: Enemigo) -> void:
	enemigo.draw_arc(Vector2.ZERO, distancia_ideal + margen, 0.0, TAU, 48,
			Color(0.0, 1.0, 0.5, 0.3), 1.0)
	enemigo.draw_arc(Vector2.ZERO, distancia_ideal - margen, 0.0, TAU, 48,
			Color(0.0, 1.0, 0.5, 0.3), 1.0)
