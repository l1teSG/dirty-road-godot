## TORRETA — se planta y escupe ráfagas a distancia.
## Parámetros (Inspector → grupo "Torreta"):
## torreta_alcance, torreta_recarga, torreta_balas,
## torreta_separacion, torreta_dispersion. Marca la trayectoria antes
## de cada ráfaga (línea de mira).
extends ComportamientoEnemigo

var _t: float = 0.0
var _balas_restantes: int = 0
var _t_bala: float = 0.0


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	# Primera ráfaga tras un ciclo completo (da tiempo al aviso).
	_t = _f("torreta_recarga", 1.2)


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	_t -= delta
	var obj := e.objetivo()
	if obj == null:
		e.detener()
		e.ocultar_mira()
		return

	# La torreta no persigue: se planta.
	e.detener()
	if e.distancia_a(obj) > _f("torreta_alcance", 600.0):
		e.ocultar_mira()
		return

	if _balas_restantes > 0:
		# Ráfaga en curso: balas espaciadas.
		e.ocultar_mira()
		_t_bala -= delta
		if _t_bala <= 0.0:
			_disparar(obj)
			_balas_restantes -= 1
			_t_bala = _f("torreta_separacion", 0.12)
	elif _t <= 0.0:
		# Empieza una ráfaga nueva.
		e.ocultar_mira()
		_balas_restantes = int(_f("torreta_balas", 3.0))
		_t_bala = 0.0
		_t = maxf(_f("torreta_recarga", 2.2), 0.05)
	elif _t <= _f("aviso_disparo", 0.35):
		# Aviso: marca la trayectoria antes de la ráfaga.
		e.mostrar_mira((obj.global_position - _origen().global_position).normalized())
	else:
		e.ocultar_mira()


func _origen() -> Node2D:
	return e.boca if e.boca != null and is_instance_valid(e.boca) else e


func _disparar(obj: Node2D) -> void:
	var origen: Node2D = _origen()
	var disp := deg_to_rad(_f("torreta_dispersion", 6.0))
	var dir := (obj.global_position - origen.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	dir = dir.rotated(randf_range(-disp, disp))
	e.disparar_desde(origen, origen.global_position + dir * 300.0)


func debug_dibujar_en(enemigo: Enemigo) -> void:
	enemigo.draw_arc(Vector2.ZERO, _f("torreta_alcance", 600.0), 0.0, TAU, 48,
			Color(0.847, 0.106, 0.376, 0.3), 1.0)