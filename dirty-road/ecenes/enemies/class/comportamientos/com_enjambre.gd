## ENJAMBRE — rápido: rodea a objetivo(), tambalea y muerde.
## Parámetros (grupo "Enjambre"): enjambre_vel_extra,
## enjambre_radio_rodeo, enjambre_reeleccion, enjambre_tambalear,
## enjambre_margen_arbol (opcional).
extends ComportamientoEnemigo

var vel_extra: float = 1.35
var radio_rodeo: float = 55.0
var reeleccion: float = 1.2   # también es la cadencia de mordisco
var tambalear: float = 6.0
## Alcance extra del mordisco contra el árbol.
var margen_arbol: float = 10.0

var _sentido: int = 1
var _t_reeleccion: float = 0.0
var _fase: float = 0.0
var _t: float = 0.0


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	vel_extra = _f("enjambre_vel_extra", vel_extra)
	radio_rodeo = _f("enjambre_radio_rodeo", radio_rodeo)
	reeleccion = _f("enjambre_reeleccion", reeleccion)
	tambalear = _f("enjambre_tambalear", tambalear)
	margen_arbol = _f("enjambre_margen_arbol", margen_arbol)
	_sentido = 1 if randf() < 0.5 else -1
	_fase = randf() * TAU
	_t = 0.0
	_t_reeleccion = 0.0


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	var obj := e.objetivo()
	if obj == null:
		e.detener()
		return
	_t -= delta
	_t_reeleccion -= delta
	if _t_reeleccion <= 0.0:
		_t_reeleccion = reeleccion
		if randf() < 0.5:
			_sentido = -_sentido
	_fase += delta * tambalear
	var al_objetivo := e.dir_a(obj)
	var dist := e.distancia_a(obj)
	if dist > radio_rodeo * 1.3:
		# Lejos: entra en línea recta, más rápido.
		e.mover_hacia(obj.global_position, vel_extra)
	elif dist < radio_rodeo * 0.6:
		# Demasiado pegado: se despega rodeando.
		e.mover_en((al_objetivo.orthogonal() * _sentido - al_objetivo).normalized(), vel_extra)
	else:
		# En el anillo: orbita con vaivén senoidal.
		var tangente := al_objetivo.orthogonal() * _sentido
		var vaiven := al_objetivo * sin(_fase) * 0.45
		e.mover_en((tangente + vaiven).normalized(), vel_extra)
	# Mordisco al rozar (contra el árbol muerde desde el margen).
	var alcance_mordisco := e.radio_contacto + 6.0 \
			+ (margen_arbol if _es_arbol(obj) else 0.0)
	if dist <= alcance_mordisco and _t <= 0.0 and not e.dano_al_tocar:
		if e.atacar_objetivo(obj):
			_t = maxf(reeleccion, 0.6)
