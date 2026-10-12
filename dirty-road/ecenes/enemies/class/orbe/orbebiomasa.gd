class_name OrbeBiomasa
extends Node2D
## Orbe de biomasa del escenario (reemplaza a la clase interna OrbeInterno).
##
## Cualidades:
##  • Aparece con un salto en arco y se asienta en el suelo.
##  • NO se apilan: los orbes quietos se repelen suavemente entre sí.
##  • Flotan con pulso y sombra pegada al suelo.
##  • Calidad por valor: común (<3), rara (3-5), épica (6+): más grande,
##    con anillos y destellos orbitando.
##  • Imán con aceleración progresiva y estela.
##  • Si el jugador murió esperan atenuados en el suelo.
##  • Parpadean y se encogen antes de desaparecer (sin cortes bruscos).
##  • Al recogerse sueltan un destello (anillo + chispas).
##  • Un solo Tween activo por vez: las animaciones no se pisan.
##
## Propiedades configurables por el enemigo ANTES de add_child().

enum Calidad { COMUN, RARA, EPICA }

# ── Configurables (las rellena Enemigo._soltar_orbes) ──
var valor: float = 1.0
var color_orbe: Color = Color("00ff7f")
var radio: float = 6.0
var iman_radio: float = 90.0
var iman_velocidad: float = 300.0
## Segundos en el suelo antes de caducar (0 = nunca).
var vida_util: float = 25.0
## Si es true, persigue al jugador desde CUALQUIER distancia (no solo dentro
## de iman_radio). Lo usan los orbes que sueltan los enemigos al cerrar la
## oleada, para que vuelen hacia el jugador.
var auto_iman: bool = false
## Retraso (s) antes de empezar a perseguir: así los orbes llegan en cascada.
var retraso_iman: float = 0.0

# ── Ajustes internos ──
const ESCALA_CALIDAD: Array[float] = [1.0, 1.3, 1.7]
const ALTURA_SALTO: float = 14.0
const TIEMPO_PARPADEO: float = 4.0
const SEP_PERIODO: float = 0.1     # cada cuánto recalcula la separación
const SEP_FUERZA: float = 70.0     # px/s de empuje entre orbes pegados
const SEP_DISTANCIA: float = 2.4   # × radio visual
const ESTELA_MAX: int = 8
const ALPHA_ESPERANDO: float = 0.55

var calidad: Calidad = Calidad.COMUN

var _jugador: Node2D = null
var _tween: Tween = null
var _t: float = 0.0
var _fase: float = 0.0
var _aparicion: float = 1.0   # 0..1 escala visual
var _salto: float = 0.0       # 0..1 progreso del arco de aparición
var _apareciendo: bool = false
var _caducando: bool = false
var _imantado: bool = false
var _esperando: bool = false
var _vel_iman: float = 0.0
var _vel_sep: Vector2 = Vector2.ZERO
var _t_sep: float = 0.0
var _estela: Array[Vector2] = []


func _ready() -> void:
	add_to_group("orbe")
	z_index = 20
	_fase = randf() * TAU
	_t_sep = randf() * SEP_PERIODO  # desfasa el cálculo entre orbes
	calidad = _calcular_calidad()
	_aparecer()


func _calcular_calidad() -> Calidad:
	if valor >= 6.0:
		return Calidad.EPICA
	if valor >= 3.0:
		return Calidad.RARA
	return Calidad.COMUN


func _radio_visual() -> float:
	return radio * ESCALA_CALIDAD[calidad]


# ── Ciclo ─────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_t += delta
	_gestionar_caducidad()
	_actualizar_alpha()
	_actualizar_estela()
	queue_redraw()

	if _caducando or _apareciendo:
		return
	if not _buscar_jugador():
		return

	# Con el jugador muerto: espera en el suelo, sin imantarse.
	if not _jugador_vivo():
		_esperando = true
		_imantado = false
		_vel_iman = 0.0
		_separar(delta)
		return
	_esperando = false

	# Auto-imán (orbes de fin de oleada): persigue desde cualquier distancia.
	if auto_iman and not _imantado:
		retraso_iman -= delta
		if retraso_iman <= 0.0:
			_imantado = true

	var d: float = global_position.distance_to(_jugador.global_position)
	if _imantado or d <= iman_radio:
		_imantado = true  # una vez imantado, persigue hasta alcanzarlo
		_vel_iman = move_toward(_vel_iman, iman_velocidad, iman_velocidad * 4.0 * delta)
		global_position = global_position.move_toward(_jugador.global_position, _vel_iman * delta)
		if d <= _radio_visual() + 10.0:
			_recoger()
	else:
		_separar(delta)


func _buscar_jugador() -> bool:
	if _jugador == null or not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node2D
		if _jugador == null:
			_jugador = get_tree().get_first_node_in_group("player") as Node2D
	return _jugador != null


func _jugador_vivo() -> bool:
	if _jugador == null:
		return false
	# El jugador expone esta_muerto(); se acepta también esta_vivo() por si acaso.
	if _jugador.has_method("esta_muerto"):
		return not bool(_jugador.call("esta_muerto"))
	if _jugador.has_method("esta_vivo"):
		return bool(_jugador.call("esta_vivo"))
	return true


## Fuerza el auto-imán: el orbe vuela al jugador desde CUALQUIER distancia.
## Lo usa el WaveManager al cerrar la oleada para recoger los orbes sueltos.
func atraer_al_jugador(retraso: float = 0.0) -> void:
	if _caducando:
		return
	auto_iman = true
	retraso_iman = maxf(0.0, retraso)


# ── Aparición / caducidad (un solo Tween a la vez) ────

func _nuevo_tween() -> Tween:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	return _tween


func _aparecer() -> void:
	_apareciendo = true
	_aparicion = 0.0
	_salto = 0.0
	var destino: Vector2 = global_position + Vector2.from_angle(randf() * TAU) * randf_range(10.0, 28.0)

	var tw := _nuevo_tween().set_parallel(true)
	tw.tween_property(self, "global_position", destino, 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_salto", 1.0, 0.4)
	tw.tween_property(self, "_aparicion", 1.0, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func(): _apareciendo = false)


func _gestionar_caducidad() -> void:
	if vida_util <= 0.0 or _caducando:
		return
	if _t >= vida_util:
		_caducando = true
		_nuevo_tween().tween_property(self, "_aparicion", 0.0, 0.3)
		_tween.tween_callback(queue_free)


func _actualizar_alpha() -> void:
	var alpha: float = ALPHA_ESPERANDO if _esperando else 1.0
	if vida_util > 0.0 and not _caducando and (vida_util - _t) < TIEMPO_PARPADEO:
		alpha *= 0.4 + 0.6 * absf(sin(_t * 12.0))
	modulate.a = alpha


# ── Separación: los orbes quietos no se apilan ────────

func _separar(delta: float) -> void:
	_t_sep -= delta
	if _t_sep <= 0.0:
		_t_sep = SEP_PERIODO
		_vel_sep = _calcular_empuje()
	if _vel_sep != Vector2.ZERO:
		global_position += _vel_sep * delta


func _calcular_empuje() -> Vector2:
	var empuje := Vector2.ZERO
	var min_d: float = _radio_visual() * SEP_DISTANCIA
	for n in get_tree().get_nodes_in_group("orbe"):
		var otro := n as OrbeBiomasa
		if otro == null or otro == self or otro._caducando or otro._apareciendo:
			continue
		var v: Vector2 = global_position - otro.global_position
		var d: float = v.length()
		if d >= min_d:
			continue
		if d < 0.01:  # exactamente encima: dirección aleatoria
			v = Vector2.from_angle(randf() * TAU)
			d = 0.01
		empuje += v / d * (1.0 - d / min_d)
	return empuje * SEP_FUERZA


# ── Estela del imán ───────────────────────────────────

func _actualizar_estela() -> void:
	if _imantado:
		_estela.append(global_position)
		if _estela.size() > ESTELA_MAX:
			_estela.pop_front()
	elif not _estela.is_empty():
		_estela.pop_front()


# ── Recogida ──────────────────────────────────────────

func _recoger() -> void:
	var cantidad: int = maxi(1, roundi(valor))
	BiomasaManager.sumar(cantidad)

	if OS.has_feature("mobile") and SaveManager != null \
			and bool(SaveManager.get_ajuste("vibracion", true)):
		Input.vibrate_handheld(12)

	var escena := get_tree().current_scene
	if escena != null:
		var fx := EfectoRecogida.new()
		fx.color = color_orbe
		fx.radio = _radio_visual()
		escena.add_child(fx)
		fx.global_position = global_position
	queue_free()


# ── Dibujo ────────────────────────────────────────────

func _draw() -> void:
	var r: float = _radio_visual() * _aparicion
	if r <= 0.01:
		return

	var asentado: bool = not _apareciendo
	var salto: float = -sin(_salto * PI) * ALTURA_SALTO
	var flota: float = sin(_t * 3.0 + _fase) * 1.5 if asentado else 0.0
	var c := Vector2(0.0, salto + flota)

	# Sombra pegada al suelo (no sigue el salto).
	draw_set_transform(Vector2(0.0, r * 0.9), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, r, Color(0.0, 0.0, 0.0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Estela del imán.
	for i in _estela.size():
		var f: float = float(i + 1) / float(_estela.size())
		draw_circle(to_local(_estela[i]), r * f * 0.7, Color(color_orbe, 0.35 * f))

	# Halo con pulso + anillos según calidad.
	var pulso: float = 1.0 + sin(_t * 5.0 + _fase) * 0.08
	draw_arc(c, (r + 2.0) * pulso, 0.0, TAU, 24, Color(color_orbe, 0.35), 2.0)
	if calidad >= Calidad.RARA:
		draw_arc(c, (r + 5.0) * pulso, 0.0, TAU, 28, Color(color_orbe, 0.2), 1.5)

	# Cuerpo y núcleo.
	draw_circle(c, r, color_orbe)
	draw_circle(c, r * 0.45, Color(1.0, 1.0, 1.0, 0.9))

	# Épicos: destellos orbitando.
	if calidad == Calidad.EPICA:
		for i in 3:
			var ang: float = _t * 2.0 + float(i) * TAU / 3.0
			draw_circle(c + Vector2.from_angle(ang) * r * 1.9, 1.6, Color(1.0, 1.0, 1.0, 0.9))


# ── Destello de recogida ──────────────────────────────

class EfectoRecogida extends Node2D:
	var color: Color = Color.WHITE
	var radio: float = 6.0
	var _p: float = 0.0

	func _ready() -> void:
		z_index = 25
		var tw := create_tween()
		tw.tween_property(self, "_p", 1.0, 0.3).set_ease(Tween.EASE_OUT)
		tw.tween_callback(queue_free)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var a: float = 1.0 - _p
		draw_arc(Vector2.ZERO, radio * (1.0 + _p * 3.0), 0.0, TAU, 24, Color(color, a), 2.0)
		for i in 6:
			var ang: float = TAU * float(i) / 6.0
			draw_circle(Vector2.from_angle(ang) * radio * (1.0 + _p * 4.0), 1.5 * a + 0.5, Color(1.0, 1.0, 1.0, a))
