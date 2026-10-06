## MELEE — persigue su objetivo (jugador o árbol) y pega por contacto.
## Parámetros: radio_ataque, recarga, mult_persecucion.
extends ComportamientoEnemigo

var radio_ataque: float = 30.0
var recarga: float = 1.0
var mult_persecucion: float = 1.0

var _t: float = 0.0


func configurar(datos: Dictionary) -> void:
	radio_ataque = datos.get("radio_ataque", radio_ataque)
	recarga = datos.get("recarga", recarga)
	mult_persecucion = datos.get("mult_persecucion", mult_persecucion)


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	_t = 0.0


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	var obj := e.objetivo()
	if obj == null:
		e.detener()
		return
	_t -= delta
	if e.distancia_a(obj) > radio_ataque:
		e.mover_hacia(obj.global_position, mult_persecucion)
	else:
		e.detener()
		# atacar_objetivo usa e.damage: ya viene escalado por oleada.
		if _t <= 0.0 and e.atacar_objetivo():
			_t = recarga


func debug_dibujar_en(enemigo: Enemigo) -> void:
	enemigo.draw_arc(Vector2.ZERO, radio_ataque, 0.0, TAU, 32,
			Color(0.847, 0.106, 0.376, 0.5), 1.5)   # magenta paleta
