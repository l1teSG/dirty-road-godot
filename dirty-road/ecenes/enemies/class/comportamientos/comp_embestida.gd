## EMBESTIDA — acecha, apunta (telegrafía), carga y pega con daño extra.
## Parámetros (Inspector → grupo "Embestida"):
## embestida_alcance, embestida_tiempo_apuntado, embestida_mult_carga,
## embestida_tiempo_carga, embestida_descanso, embestida_mult_dano,
## embestida_vel_patrulla, embestida_telegrafiar.
extends ComportamientoEnemigo

enum Estado { ACECHANDO, PREPARANDO, CARGANDO, ENFRIANDO }

var _estado: int = Estado.ACECHANDO
var _t: float = 0.0
var _dir_carga: Vector2 = Vector2.RIGHT


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	_t -= delta
	var obj := e.objetivo()
	if obj == null:
		e.detener()
		_estado = Estado.ACECHANDO
		return

	match _estado:
		Estado.ACECHANDO:
			if e.distancia_a(obj) <= _f("embestida_alcance", 380.0):
				_dir_carga = e.dir_a(obj)
				if _b("embestida_telegrafiar", true):
					_estado = Estado.PREPARANDO
					_t = _f("embestida_tiempo_apuntado", 1.0)
				else:
					_estado = Estado.CARGANDO
					_t = _f("embestida_tiempo_carga", 0.45)
			else:
				e.mover_hacia(obj.global_position, _f("embestida_vel_patrulla", 0.6))
		Estado.PREPARANDO:
			# Telegrafía: quieto un instante antes de la carga.
			e.detener()
			if _t <= 0.0:
				_dir_carga = e.dir_a(obj)
				_estado = Estado.CARGANDO
				_t = _f("embestida_tiempo_carga", 0.45)
		Estado.CARGANDO:
			# Multiplicador temporal por la API: nunca se toca e.speed.
			e.mover_en(_dir_carga, _f("embestida_mult_carga", 2.6))
			if _impacto(obj):
				e.detener()
				_golpear(obj)
				_estado = Estado.ENFRIANDO
				_t = _f("embestida_descanso", 1.2)
			elif _t <= 0.0:
				_estado = Estado.ENFRIANDO
				_t = _f("embestida_descanso", 1.2) * 0.5
		Estado.ENFRIANDO:
			e.detener()
			if _t <= 0.0:
				_estado = Estado.ACECHANDO


## Daño de carga: e.damage escalado por embestida_mult_dano, con la
## misma cadena de compatibilidad (recibir_danio / take_damage).
func _golpear(obj: Node2D) -> void:
	var mult := _f("embestida_mult_dano", 1.5)
	if not e._hacer_danio(obj, e.damage * mult):
		e.atacar_objetivo(obj)


## Impacto: cerca del centro del objetivo O empastado contra su
## cuerpo (truco: el tronco frena al jefe antes del centro).
func _impacto(obj: Node2D) -> bool:
	return e.distancia_a(obj) <= e.radio_contacto + 8.0 or e._chocando_con(obj)


func debug_dibujar_en(enemigo: Enemigo) -> void:
	var c := Color(1.0, 0.9, 0.2, 0.35) if _estado == Estado.CARGANDO \
			else Color(1.0, 0.4, 0.7, 0.25)
	enemigo.draw_arc(Vector2.ZERO, _f("embestida_alcance", 380.0), 0.0, TAU, 48, c, 1.0)
