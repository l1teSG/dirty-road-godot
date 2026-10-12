## MELEE — persigue a objetivo() (jugador o árbol) y pega al llegar.
## Parámetros (Inspector del Enemigo → grupo "Melee"):
## melee_radio, melee_recarga, melee_mult_persecucion,
## melee_margen_arbol (alcance extra contra el tronco).
extends ComportamientoEnemigo

var _t: float = 0.0


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	_t -= delta
	var obj := e.objetivo()
	if obj == null:
		e.detener()
		return

	# Contra el árbol el tronco bloquea antes del centro: margen extra.
	var margen := _f("melee_margen_arbol", 14.0) if obj == e.arbol else 0.0
	var alcance := _f("melee_radio", 30.0) + margen

	if e.distancia_a(obj) > alcance:
		# Persigue; el sprint extra solo aplica persiguiendo al jugador.
		var mult := _f("melee_mult_persecucion", 1.0) if obj == e.jugador else 1.0
		e.mover_hacia(obj.global_position, mult)
		return

	e.detener()
	# Petróleo y compañía ya pegan solos por contacto (dano_al_tocar):
	# no duplicar el golpe.
	if e.dano_al_tocar:
		return
	if _t <= 0.0 and e.atacar_objetivo(obj):
		_t = maxf(_f("melee_recarga", 1.0), 0.05)


func debug_dibujar_en(enemigo: Enemigo) -> void:
	var r := _f("melee_radio", 30.0) + _f("melee_margen_arbol", 14.0)
	enemigo.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(0.0, 1.0, 0.5, 0.35), 1.0)
