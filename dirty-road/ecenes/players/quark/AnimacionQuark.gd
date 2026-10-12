class_name AnimacionQuark
extends Node
## Toda la animación procedural de Quark: pulso del núcleo, squash al moverse,
## sombra, flash de golpe y feedback visual del dash.
##
## Cada parte tiene su propia fase de tiempo (antes compartían una sola
## variable y se pisaban) y el núcleo combina pulso + movimiento en UNA
## sola escritura de escala.
##
## "Game feel": ajusta las constantes de abajo.

const VEL_PULSO: float = 5.0
const AMP_PULSO: float = 0.12
const LUZ_PUNTA_BASE: float = 1.8
const LUZ_PUNTA_AMP: float = 0.5

const FREC_PASO: float = 10.0      # fase de caminata (rad/s)
const AMP_BOB: float = 2.0         # rebote vertical del cuerpo (px)
const FREC_SOMBRA: float = 12.0
const UMBRAL_MOVIMIENTO: float = 10.0
const ALPHA_DASH: float = 0.5
## Amplitud del squash de impacto (golpe / aterrizaje del dash).
const AMP_SQUASH: float = 0.22

var _jugador: CharacterBody2D = null
var _cuerpo: Polygon2D = null
var _interior: Polygon2D = null
var _nucleo: Polygon2D = null
var _sombra: Polygon2D = null
var _luz_punta: PointLight2D = null

var _cuerpo_escala0: Vector2 = Vector2.ONE
var _interior_escala0: Vector2 = Vector2.ONE
var _nucleo_escala0: Vector2 = Vector2.ONE
var _cuerpo_color0: Color = Color.WHITE
var _nucleo_color0: Color = Color.WHITE

var _fase_pulso: float = 0.0
var _fase_paso: float = 0.0
var _fase_sombra: float = 0.0
var _factor_pulso: float = 1.0
var _extra_nucleo: float = 0.0
var _offset_vertical: float = 0.0
## Squash de impacto (0..1). Se integra en el objetivo de escala del cuerpo
## para no pelearse con el lerp de cada frame ni con los tweens de flash.
var _squash: float = 0.0

var _tween_flash: Tween = null
var _tween_dash: Tween = null


func configurar(jugador: CharacterBody2D, cuerpo: Polygon2D, interior: Polygon2D,
		nucleo: Polygon2D, sombra: Polygon2D, luz_punta: PointLight2D) -> void:
	_jugador = jugador
	_cuerpo = cuerpo
	_interior = interior
	_nucleo = nucleo
	_sombra = sombra
	_luz_punta = luz_punta

	if _cuerpo != null:
		_cuerpo_escala0 = _cuerpo.scale
		_cuerpo_color0 = _cuerpo.modulate
	if _interior != null:
		_interior_escala0 = _interior.scale
	if _nucleo != null:
		_nucleo_escala0 = _nucleo.scale
		_nucleo_color0 = _nucleo.modulate


func actualizar(delta: float) -> void:
	if _jugador == null:
		return
	var moviendo: bool = _jugador.velocity.length() > UMBRAL_MOVIMIENTO
	if moviendo:
		_fase_paso += delta * FREC_PASO

	_animar_pulso(delta)
	_animar_cuerpo(delta, moviendo)
	_animar_nucleo(delta, moviendo)
	_animar_sombra(delta, moviendo)


func _animar_pulso(delta: float) -> void:
	_fase_pulso += delta * VEL_PULSO
	_factor_pulso = 1.0 + sin(_fase_pulso) * AMP_PULSO
	if _luz_punta != null:
		_luz_punta.energy = LUZ_PUNTA_BASE + sin(_fase_pulso * 2.0) * LUZ_PUNTA_AMP


func _animar_cuerpo(delta: float, moviendo: bool) -> void:
	if _cuerpo == null:
		return

	var objetivo: Vector2 = _cuerpo_escala0
	var bob: float = 0.0
	if moviendo:
		var dir_x: float = absf(_jugador.velocity.normalized().x)
		objetivo = Vector2(_cuerpo_escala0.x + dir_x * 0.15, _cuerpo_escala0.y - dir_x * 0.08)
		bob = sin(_fase_paso) * AMP_BOB

	# Squash de impacto (golpe / aterrizaje tras el dash): ancho y bajo,
	# decae solo. Integrado aquí para que el lerp no lo pise.
	_squash = maxf(0.0, _squash - delta * 5.0)
	if _squash > 0.0:
		var s: float = _squash * _squash
		objetivo = Vector2(
			objetivo.x * (1.0 + s * AMP_SQUASH),
			objetivo.y * (1.0 - s * AMP_SQUASH * 0.8))

	_cuerpo.scale = _cuerpo.scale.lerp(objetivo, delta * 12.0)
	if _interior != null:
		_interior.scale = _interior.scale.lerp(_interior_escala0 * (objetivo / _cuerpo_escala0), delta * 12.0)

	_offset_vertical = lerpf(_offset_vertical, bob, delta * 10.0)
	_cuerpo.position.y = _offset_vertical


func _animar_nucleo(delta: float, moviendo: bool) -> void:
	if _nucleo == null:
		return
	var extra_objetivo: float = (0.1 + sin(_fase_paso * 1.3) * 0.08) if moviendo else 0.0
	_extra_nucleo = lerpf(_extra_nucleo, extra_objetivo, delta * 10.0)
	_nucleo.scale = _nucleo_escala0 * (_factor_pulso + _extra_nucleo)

	var rot_objetivo: float = (sin(_fase_paso * 0.5) * 0.1) if moviendo else 0.0
	_nucleo.rotation = lerpf(_nucleo.rotation, rot_objetivo, delta * 6.0)


func _animar_sombra(delta: float, moviendo: bool) -> void:
	if _sombra == null:
		return
	if moviendo:
		_fase_sombra += delta * FREC_SOMBRA
		_sombra.scale.x = 1.0 - sin(_fase_sombra) * 0.1
	else:
		_sombra.scale = _sombra.scale.lerp(Vector2.ONE, delta * 10.0)


# ── Feedback ──────────────────────────────────────────

func flash_golpe(color: Color, duracion: float) -> void:
	_matar(_tween_flash)
	if _cuerpo != null:
		_cuerpo.modulate = color
	if _nucleo != null:
		_nucleo.modulate = color
	# Squash de impacto: el golpe se siente en el cuerpo, no solo en el color.
	_squash = 1.0

	_tween_flash = create_tween().set_parallel(true)
	if _cuerpo != null:
		_tween_flash.tween_property(_cuerpo, "modulate", _cuerpo_color0, duracion)
	if _nucleo != null:
		_tween_flash.tween_property(_nucleo, "modulate", _nucleo_color0, duracion)


## Semitransparente durante el dash: señala que hay i-frames.
func set_dash(activo: bool) -> void:
	if _jugador == null:
		return
	_matar(_tween_dash)
	_tween_dash = create_tween()
	_tween_dash.tween_property(_jugador, "modulate:a", ALPHA_DASH if activo else 1.0, 0.05)
	# Al aterrizar el dash: squash breve (recuperación), no solo el fundido.
	if not activo:
		_squash = maxf(_squash, 0.7)


func _matar(t: Tween) -> void:
	if t != null and t.is_valid():
		t.kill()
