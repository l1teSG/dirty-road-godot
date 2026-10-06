## TORRETA — quieta, dispara a objetivo() dentro del alcance.
## Parámetros (grupo "Torreta"): torreta_cadencia, torreta_alcance.
extends ComportamientoEnemigo

var cadencia: float = 1.6
var alcance: float = 280.0

var _t: float = 0.0


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	cadencia = _f("torreta_cadencia", cadencia)
	alcance = _f("torreta_alcance", alcance)
	_t = 0.3


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	_t -= delta
	var obj := e.objetivo()
	e.detener()   # no se mueve nunca
	if obj == null:
		return
	if e.distancia_a(obj) <= alcance and _t <= 0.0:
		e.disparar_desde(_origen_disparo(), e.dir_a(obj))
		_t = cadencia


func debug_dibujar_en(enemigo: Enemigo) -> void:
	enemigo.draw_arc(Vector2.ZERO, alcance, 0.0, TAU, 64,
			Color(0.0, 1.0, 0.5, 0.3), 1.0)
