## EMBESTIDA — telegrafía, carga a máxima velocidad y golpea fuerte.
## Pensada para jefes anti_estructura: objetivo() devuelve el árbol
## y carga contra él; el golpe conecta por distancia O por choque
## contra el tronco (aunque el cuerpo lo frene antes del centro).
## Parámetros (grupo "Embestida"): embestida_alcance,
## embestida_preparacion, embestida_mult_velocidad,
## embestida_danio_extra, embestida_enfriamiento,
## embestida_duracion (opcional).
extends ComportamientoEnemigo

enum Estado { ACECHANDO, PREPARANDO, CARGANDO, ENFRIANDO }

var alcance: float = 320.0
var preparacion: float = 0.5
var mult_velocidad: float = 3.0
var danio_extra: float = 0.0
var enfriamiento: float = 2.0
var duracion_carga: float = 1.2

var _estado: int = Estado.ACECHANDO
var _t: float = 0.0
var _dir_carga: Vector2 = Vector2.ZERO


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	alcance = _f("embestida_alcance", alcance)
	preparacion = _f("embestida_preparacion", preparacion)
	mult_velocidad = _f("embestida_mult_velocidad", mult_velocidad)
	danio_extra = _f("embestida_danio_extra", danio_extra)
	enfriamiento = _f("embestida_enfriamiento", enfriamiento)
	duracion_carga = _f("embestida_duracion", duracion_carga)
	_estado = Estado.ACECHANDO
	_t = 0.0


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
			# Persigue despacio hasta entrar en distancia de carga.
			if e.distancia_a(obj) <= alcance:
				_estado = Estado.PREPARANDO
				_t = preparacion
				e.detener()
			else:
				e.mover_hacia(obj.global_position, 0.8)
		Estado.PREPARANDO:
			# Telegrafía: quieto un instante antes de la carga.
			e.detener()
			if _t <= 0.0:
				_dir_carga = e.dir_a(obj)
				_estado = Estado.CARGANDO
				_t = duracion_carga
		Estado.CARGANDO:
			# Multiplicador temporal por la API: nunca se toca e.speed.
			e.mover_en(_dir_carga, mult_velocidad)
			if _impacto(obj):
				e.detener()
				e.atacar_objetivo(obj, e.damage + danio_extra)
				_estado = Estado.ENFRIANDO
				_t = enfriamiento
			elif _t <= 0.0:
				_estado = Estado.ENFRIANDO
				_t = enfriamiento * 0.5
		Estado.ENFRIANDO:
			e.detener()
			if _t <= 0.0:
				_estado = Estado.ACECHANDO


## Impacto: cerca del centro del objetivo O empastado contra su
## cuerpo (truco: el tronco frena al jefe antes del centro).
func _impacto(obj: Node2D) -> bool:
	return e.distancia_a(obj) <= e.radio_contacto + 8.0 or _choco_con(obj)


func debug_dibujar_en(enemigo: Enemigo) -> void:
	var c := Color(1.0, 0.9, 0.2, 0.35) if _estado == Estado.CARGANDO \
			else Color(1.0, 0.4, 0.7, 0.25)
	enemigo.draw_arc(Vector2.ZERO, alcance, 0.0, TAU, 48, c, 1.0)
