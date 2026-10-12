class_name AnimacionEnemigo
extends Node

## ══════════════════════════════════════════════════════════
##  ANIMACIÓN ENEMIGO — componente reutilizable (hijo de cada enemigo).
##  Anima la figura procedural (squash & stretch, bob, orientación) según
##  el movimiento real y los eventos de combate. NO pisa la animación
##  interna de capas del FiguraConstructor: transforma el nodo completo.
##
##  Estados cubiertos:
##   • Idle       → respiración suave
##   • Movimiento → estiramiento en la dirección de avance + bob + orientación
##   • Ataque     → pulso de estirón (lo dispara Enemigo._fx_ataque)
##   • Golpe      → flash blanco + encogida (lo dispara la señal recibo_danio)
##   • Furia      → bob más rápido + leve aumento de escala
## ══════════════════════════════════════════════════════════

const UMBRAL_MOV := 12.0
const FREC_PASO := 11.0
const AMP_BOB := 1.6

var _e: CharacterBody2D = null
var _fig: Node2D = null
var _esc0: Vector2 = Vector2.ONE
var _pos0: Vector2 = Vector2.ZERO

var _fase := 0.0
var _pulso := 0.0
var _facing := 1.0
var _furia := 0.0
var _flash: Tween = null
var _mod0: Color = Color.WHITE


func _ready() -> void:
	_e = get_parent() as CharacterBody2D
	_fig = _e.get_node_or_null("FiguraConstructor") as Node2D
	if _fig != null:
		_esc0 = _fig.scale
		_pos0 = _fig.position
		_mod0 = _fig.modulate
	if _e.has_signal("recibo_danio"):
		_e.connect("recibo_danio", _on_golpe)


func _physics_process(delta: float) -> void:
	if _fig == null or not is_instance_valid(_fig) or _e == null:
		return

	var vel := _e.velocity
	var moviendo := vel.length() > UMBRAL_MOV
	_fase += delta * (FREC_PASO if moviendo else 3.0)

	var objetivo := _esc0
	var bob := sin(_fase) * 0.6
	if moviendo:
		var dir := vel.normalized()
		var dx := absf(dir.x)
		objetivo = Vector2(_esc0.x * (1.0 + dx * 0.08), _esc0.y * (1.0 - dx * 0.05))
		bob = sin(_fase) * AMP_BOB
		if absf(dir.x) > 0.2:
			_facing = signf(dir.x)

	# Furia (jefes): un pelín más intensa.
	var fur := 0.0
	if _e.get("_en_furia") == true:
		fur = 1.0
		_fase += delta * 5.0
	_furia = lerpf(_furia, fur, delta * 4.0)
	objetivo *= 1.0 + _furia * 0.03

	# Pulso de ataque: estirón breve y vuelta.
	_pulso = maxf(0.0, _pulso - delta * 4.5)
	var estiron := _pulso * _pulso
	objetivo = Vector2(
		objetivo.x * (1.0 + estiron * 0.16),
		objetivo.y * (1.0 - estiron * 0.09))

	# Se interpola SOLO la magnitud (positiva) y la orientación se aplica
	# después con el signo: así el flip no colapsa la escala al mirar a la izq.
	var actual := _fig.scale.abs()
	var destino := Vector2(absf(objetivo.x), absf(objetivo.y))
	actual = actual.lerp(destino, delta * 14.0)
	_fig.scale = Vector2(actual.x * _facing, actual.y)

	var pos := _pos0
	pos.y += bob
	_fig.position = _fig.position.lerp(pos, delta * 12.0)


## Lo llama Enemigo._fx_ataque() en cada golpe/disparo/contacto.
func pulso_ataque() -> void:
	_pulso = 1.0


func _on_golpe(_cantidad: float = 0.0) -> void:
	if _fig == null or not is_instance_valid(_fig):
		return
	if _flash != null and _flash.is_valid():
		_flash.kill()
	_fig.modulate = Color(3.2, 3.2, 3.2, 1.0)
	# Encogida breve al recibir daño.
	_fig.scale = Vector2(_fig.scale.x * 1.08, _fig.scale.y * 0.9)
	_flash = create_tween()
	_flash.tween_property(_fig, "modulate", _mod0, 0.16)
