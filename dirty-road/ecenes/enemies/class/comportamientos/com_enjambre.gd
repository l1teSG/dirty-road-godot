## ENJAMBRE — rápido, rodea a su objetivo por un flanco y muerde.
## Parámetros (Inspector → grupo "Enjambre"):
## enjambre_vel_extra, enjambre_radio_rodeo, enjambre_reeleccion,
## enjambre_tambalear. (enjambre_margen_arbol es opcional: si no
## existe como export, cae al defecto.)
extends ComportamientoEnemigo

var _t: float = 0.0
var _t_flanco: float = 0.0
var _angulo_flanco: float = 0.0


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	_angulo_flanco = randf() * TAU


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	_t -= delta
	_t_flanco -= delta
	if _t_flanco <= 0.0:
		# Reelige flanco de rodeo cada tanto (enjambre impredecible).
		_t_flanco = _f("enjambre_reeleccion", 1.2)
		_angulo_flanco = randf() * TAU

	var obj := e.objetivo()
	if obj == null:
		e.detener()
		return

	var margen := _f("enjambre_margen_arbol", 14.0) if obj == e.arbol else 0.0
	var alcance := _f("melee_radio", 30.0) + margen
	var rodeo := _f("enjambre_radio_rodeo", 55.0)
	var d := e.distancia_a(obj)

	if d > alcance + rodeo:
		# Lejos: corre hacia el objetivo con velocidad extra.
		e.mover_hacia(obj.global_position, _f("enjambre_vel_extra", 1.35))
		return

	if d > alcance:
		# Cerca: entra en curva por el flanco, con tambaleo orgánico.
		var dir_objetivo := e.dir_a(obj)
		var a := dir_objetivo.angle() + _angulo_flanco
		var punto := obj.global_position + Vector2.RIGHT.rotated(a) * rodeo
		var t := Time.get_ticks_msec() * 0.001
		punto += dir_objetivo.orthogonal() \
				* sin(t * _f("enjambre_tambalear", 6.0)) * 6.0
		e.mover_hacia(punto, _f("enjambre_vel_extra", 1.35))
		return

	e.detener()
	if e.dano_al_tocar:
		return
	if _t <= 0.0 and e.atacar_objetivo(obj):
		_t = maxf(_f("melee_recarga", 1.0), 0.05)


func debug_dibujar_en(enemigo: Enemigo) -> void:
	enemigo.draw_arc(Vector2.ZERO, _f("enjambre_radio_rodeo", 55.0),
			0.0, TAU, 40, Color(0.0, 1.0, 0.5, 0.25), 1.0)
