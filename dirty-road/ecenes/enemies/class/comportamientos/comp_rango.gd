## RANGO — mantiene la distancia ideal, strafea y dispara.
## Parámetros (Inspector → grupo "Rango"):
## rango_distancia, rango_margen, rango_recarga, rango_vel_strafe,
## rango_dispersion. Antes de disparar marca la trayectoria (línea de mira).
extends ComportamientoEnemigo

var _t: float = 0.0
var _t_strafe: float = 0.0
var _lado: int = 1


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	_lado = 1 if randf() < 0.5 else -1
	# Primera ráfaga tras un ciclo completo (da tiempo al aviso).
	_t = _f("rango_recarga", 1.6)


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	_t -= delta
	_t_strafe -= delta
	if _t_strafe <= 0.0:
		_t_strafe = randf_range(1.0, 2.5)
		_lado = -_lado

	var obj := e.objetivo()
	if obj == null:
		e.detener()
		e.ocultar_mira()
		return

	var ideal := _f("rango_distancia", 220.0)
	var margen := _f("rango_margen", 40.0)
	var d := e.distancia_a(obj)

	if d > ideal + margen:
		# Demasiado lejos: acércate.
		e.mover_hacia(obj.global_position)
	elif d < ideal - margen:
		# Demasiado cerca: retrocede (punto simétrico tras de mí).
		e.mover_hacia(e.global_position * 2.0 - obj.global_position)
	else:
		# En banda: strafe lateral.
		var perp := (obj.global_position - e.global_position).orthogonal().normalized()
		e.mover_en(perp * float(_lado), _f("rango_vel_strafe", 0.5))

	# Disparo con aviso (línea de mira en los últimos instantes).
	var en_rango := d <= ideal + margen
	if en_rango and _t <= 0.0:
		e.ocultar_mira()
		_disparar(obj)
		_t = maxf(_f("rango_recarga", 1.6), 0.05)
	elif en_rango and _t <= _f("aviso_disparo", 0.35):
		e.mostrar_mira((obj.global_position - _origen().global_position).normalized())
	else:
		e.ocultar_mira()


func _origen() -> Node2D:
	return e.boca if e.boca != null and is_instance_valid(e.boca) else e


func _disparar(obj: Node2D) -> void:
	var origen: Node2D = _origen()
	var disp := deg_to_rad(_f("rango_dispersion", 0.0))
	var dir := (obj.global_position - origen.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	dir = dir.rotated(randf_range(-disp, disp))
	e.disparar_desde(origen, origen.global_position + dir * 300.0)


func debug_dibujar_en(enemigo: Enemigo) -> void:
	var ideal := _f("rango_distancia", 220.0)
	var margen := _f("rango_margen", 40.0)
	enemigo.draw_arc(Vector2.ZERO, ideal + margen, 0.0, TAU, 48,
			Color(0.0, 1.0, 0.5, 0.2), 1.0)
	enemigo.draw_arc(Vector2.ZERO, maxf(ideal - margen, 0.0), 0.0, TAU, 48,
			Color(0.847, 0.106, 0.376, 0.2), 1.0)