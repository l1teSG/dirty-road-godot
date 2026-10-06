## RANGO — mantiene la distancia ideal de su objetivo y le dispara.
## Parámetros: distancia_ideal, margen, recarga, vel_strafe, dispersion_grados.
extends ComportamientoEnemigo

var distancia_ideal: float = 220.0
var margen: float = 40.0
var recarga: float = 1.6
var vel_strafe: float = 0.5
var dispersion_grados: float = 0.0

var _t: float = 0.0
var _sentido: int = 1


func configurar(datos: Dictionary) -> void:
	distancia_ideal = datos.get("distancia_ideal", distancia_ideal)
	margen = datos.get("margen", margen)
	recarga = datos.get("recarga", recarga)
	vel_strafe = datos.get("vel_strafe", vel_strafe)
	dispersion_grados = datos.get("dispersion_grados", dispersion_grados)


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	_sentido = 1 if randf() < 0.5 else -1
	_t = randf_range(0.0, recarga)   # desincronizar ráfagas del enjambre de enemigos


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	var obj := e.objetivo()
	if obj == null:
		e.detener()
		return
	_t -= delta

	# Gira el strafe de vez en cuando.
	if randf() < delta * 0.2:
		_sentido = -_sentido

	var dist: float = e.distancia_a(obj)
	var dir: Vector2 = e.dir_a(obj)
	var tangente: Vector2 = Vector2(-dir.y, dir.x) * float(_sentido)

	var rumbo := Vector2.ZERO
	if dist > distancia_ideal + margen:
		rumbo = dir                        # acercarse
	elif dist < distancia_ideal - margen:
		rumbo = -dir                       # retirarse
	rumbo = (rumbo + tangente * vel_strafe).normalized()
	if rumbo != Vector2.ZERO:
		e.mover_en(rumbo)
	else:
		e.detener()

	# Disparo con dispersión (daño = e.damage * mult_dano_proyectil).
	if _t <= 0.0 and dist <= distancia_ideal + margen * 2.0:
		_t = recarga
		var dispersion: float = deg_to_rad(dispersion_grados)
		var origen: Vector2 = e.punto_salida()
		var dir_disp: Vector2 = (obj.global_position - origen).normalized() \
				.rotated(randf_range(-dispersion, dispersion))
		e.disparar_desde(origen, origen + dir_disp * 120.0)


func debug_dibujar_en(enemigo: Enemigo) -> void:
	var c := Color(0.0, 1.0, 0.5, 0.35)
	enemigo.draw_arc(Vector2.ZERO, distancia_ideal, 0.0, TAU, 40, c, 1.5)
	enemigo.draw_arc(Vector2.ZERO, distancia_ideal - margen, 0.0, TAU, 40, c, 1.0)
	enemigo.draw_arc(Vector2.ZERO, distancia_ideal + margen, 0.0, TAU, 40, c, 1.0)
