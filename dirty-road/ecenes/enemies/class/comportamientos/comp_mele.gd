## MELEE — persigue a objetivo() (jugador o árbol) y pega al llegar.
## Parámetros (Inspector del Enemigo → grupo "Melee"):
## melee_radio, melee_recarga, melee_mult_persecucion,
## melee_margen_arbol (opcional).
extends ComportamientoEnemigo

var radio_ataque: float = 30.0
var recarga: float = 1.0
var mult_persecucion: float = 1.0
## Alcance extra SOLO contra el árbol: el tronco bloquea antes de
## llegar a su centro, así que muerde desde fuera.
var margen_arbol: float = 14.0

var _t: float = 0.0


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	radio_ataque = _f("melee_radio", radio_ataque)
	recarga = _f("melee_recarga", recarga)
	mult_persecucion = _f("melee_mult_persecucion", mult_persecucion)
	margen_arbol = _f("melee_margen_arbol", margen_arbol)
	_t = 0.0


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	_t -= delta
	var obj := e.objetivo()
	if obj == null:
		e.detener()
		return
	var radio := radio_ataque + (margen_arbol if _es_arbol(obj) else 0.0)
	if e.distancia_a(obj) > radio:
		e.mover_hacia(obj.global_position, mult_persecucion)
	else:
		e.detener()
		# Si el daño por contacto automático está activo
		# (dano_al_tocar), el comp solo posiciona: evita doble daño.
		if _t <= 0.0 and not e.dano_al_tocar:
			if e.atacar_objetivo(obj):
				_t = recarga


func debug_dibujar_en(enemigo: Enemigo) -> void:
	enemigo.draw_arc(Vector2.ZERO, radio_ataque + margen_arbol, 0.0, TAU, 32,
			Color(0.847, 0.106, 0.376, 0.5), 1.5)   # magenta paleta
