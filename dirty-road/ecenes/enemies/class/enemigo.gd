class_name Enemigo
extends CharacterBody2D

## ══════════════════════════════════════════════════════════
##  ENEMIGO — Clase principal (ESCENA + GD), integrada al WaveManager.
##
##  CONTRATO:
##  • Jugador y Árbol los identifica el WAVE MANAGER (por grupos) y
##    los inyecta antes de add_child(). Este script NO los exporta.
##    CINTURÓN DE SEGURIDAD: si algo llega nulo, se auto-repara por
##    grupos cada frame mientras falte algo — nunca queda sin objetivo.
##  • life / speed / damage llegan YA escalados por oleada/etapa;
##    la vida actual se deriva en _ready() (vida = life).
##  • OBJETIVO por TIPO (objetivo_tipo), en orden de precedencia:
##    1) anti_estructura → árbol siempre (jefes).
##    2) peel activo     → jugador (le pegaste hace poco).
##    3) "arbol"         → estructura.  "jugador" → el jugador.
##    4) "mixto"         → jugador, salvo que el árbol esté a menos de
##       dist_jugador × sesgo_jugador, o que ya esté pegado al tronco.
##    5) rango_aggro vencido → de vuelta al árbol.
##    6) resto           → jugador.
##  "auto" se resuelve en _ready por arquetipo: melee/torreta/embestida→árbol;
##  enjambre/rango→jugador.
##  • Ciclo por frame: aggro/furia → reset de órdenes → _mecanica()
##    (del extend) → _comp.pensar() → move_and_slide() → contacto.
##  • Los comportamientos (comp_*.gd) SOLO dictan órdenes con la API:
##    objetivo(), distancia_a(), dir_a(), mover_hacia(), mover_en(),
##    detener(), atacar_objetivo(obj), disparar_desde(nodo, dir).
##    NUNCA lean e.jugador directo: usen e.objetivo().
##  • CONTACTO: daña al JUGADOR al tocarlo (danio_contacto o el flag
##    viejo dano_al_tocar) y MORDISQUEA el tronco si este bloquea
##    (pasando self como fuente: el log del árbol nombra al mordedor).
##  • FURIA (jefes): al bajar del umbral de vida, más rápido y más daño,
##    con parpadeo magenta. WaveUI lee porcentaje_vida() para la barra.
##  • NOMBRE FLOTANTE: aparece al spawn y se oculta con el primer golpe.
##    DAÑO FLOTANTE: número con pop de entrada que sube y se desvanece.
##    Blanco sin contorno ni sombra por defecto; TODO desde el Inspector.
##  • DROPS: al morir suelta orbes. Si `orbe_escena` queda VACÍA se usa
##    el ORBE INTERNO (OrbeInterno), construido 100% por código: sin
##    dependencia de escenas. Imán hacia el jugador + recogida.
## ══════════════════════════════════════════════════════════

signal recibo_danio(cantidad: float)
signal murio(enemigo: Enemigo)

# Registro: tipo → .gd del comportamiento (solo lógica, sin escena).
const COMPORTAMIENTOS: Dictionary = {
	"melee":"res://ecenes/enemies/class/comportamientos/comp_mele.gd" ,
	"enjambre": "res://ecenes/enemies/class/comportamientos/com_enjambre.gd",
	"rango": "res://ecenes/enemies/class/comportamientos/comp_rango.gd",
	"torreta":"res://ecenes/enemies/class/comportamientos/comp_torreta.gd" ,
	"embestida": "res://ecenes/enemies/class/comportamientos/comp_embestida.gd",
}

# ───────────── ESTADÍSTICAS ─────────────

## Vida base. El WaveManager la escala por oleada ANTES de add_child.
@export var life: float = 20.0
## Velocidad base (px/s). El WaveManager la escala por etapa.
@export var speed: float = 90.0
## Daño de contacto/ataque. El WaveManager lo escala por etapa.
@export var damage: float = 5.0
@export_range(0.0, 4.0) var velocidad_multiplicador: float = 1.0

@export_group("Movilidad")
## Activa la movilidad dinámica (orbita/zigzag/micro-dash/separación).
@export var movilidad: bool = true
## Oscilación de rumbo (zigzag) en grados.
@export_range(0.0, 90.0) var mov_zigzag_grados: float = 12.0
## Frecuencia del zigzag (ciclos/seg).
@export_range(0.0, 8.0) var mov_zigzag_freq: float = 2.5
## Componente tangencial: >0 orbita en un sentido, <0 en el otro (strafe).
@export_range(-1.5, 1.5) var mov_orbita: float = 0.0
## Multiplicador de velocidad de los acelerones (1 = sin dash).
@export_range(1.0, 3.0) var mov_dash_mult: float = 1.0
## Frecuencia de los micro-dashes (0 = nunca).
@export_range(0.0, 4.0) var mov_dash_freq: float = 0.0
@export_range(0.0, 200.0) var mov_separacion_radio: float = 42.0
@export_range(0.0, 3.0) var mov_separacion_fuerza: float = 0.8


# ───────────── CONTACTO ─────────────

## LEGADO: daño automático al tocar al jugador (lo activa p. ej. el enjambre).
## Si danio_contacto == 0 y esto está activo, el contacto pega `damage`
## cada `periodo_contacto` segundos.
@export var dano_al_tocar: bool = false
## Daño de contacto NUEVO (0 = usa el flag viejo dano_al_tocar).
@export var danio_contacto: float = 0.0
## Radio de la hurtbox de contacto y alcance del golpe directo.
@export var radio_contacto: float = 22.0
## Segundos entre daños por contacto (flag viejo y mordisco al árbol).
@export_range(0.1, 3.0) var periodo_contacto: float = 1.0

# ───────────── COMPORTAMIENTO ─────────────

@export_enum("melee", "enjambre", "rango", "torreta", "embestida") var comportamiento_tipo: String = "melee"
## Script personalizado (opcional). Si va vacío se usa el registro.
@export var comportamiento_personalizado: GDScript

@export_group("Melee")
@export var melee_radio: float = 26.0
@export_range(0.1, 3.0) var melee_recarga: float = 1.0
@export_range(0.1, 3.0) var melee_mult_persecucion: float = 1.0
## Margen extra de alcance contra el árbol (el tronco bloquea antes).
@export var melee_margen_arbol: float = 14.0

@export_group("Enjambre")
@export_range(0.1, 3.0) var enjambre_recarga: float = 0.8
@export var enjambre_separacion: float = 26.0

@export_group("Rango")
## Distancia a la que se planta y dispara.
@export var rango_distancia: float = 220.0
@export var rango_margen: float = 40.0
@export var rango_recarga: float = 1.6
@export var rango_vel_proyectil: float = 220.0
@export var boca: Marker2D

@export_group("Torreta")
@export var torreta_alcance: float = 260.0
@export var torreta_recarga: float = 1.2
@export var torreta_vel_proyectil: float = 200.0

@export_group("Embestida")
@export_range(0.1, 3.0) var embestida_mult_dano: float = 1.5
@export var embestida_vel_patrulla: float = 60.0
## Segundos de telegrafiado antes de la carga.
@export_range(0.0, 2.0) var embestida_telegrafiar: float = 0.6

@export_group("Disparo")
## Proyectil usado por disparar_desde() (rango/torreta). Si es null
## se usa el rombo neón interno (ProyectilDefecto).
@export var proyectil: PackedScene

# ───────────── OBJETIVO: JUGADOR O ÁRBOL ─────────────

## Jefes: ignoran al jugador y van directo al árbol mientras exista.
@export var anti_estructura: bool = false
## Categoría educativa del enemigo (para efectos de cartas): "" , "toxico", "acuatico", "elite".
@export var categoria: String = ""
## Si el jugador queda a más de esta distancia, el enemigo vuelve al
## árbol (0 = desactivado).
@export var rango_aggro: float = 320.0

## LEGADO: el sistema mixto (rol + sesgo) lo reemplaza. Se conserva para no
## romper escenas viejas; ya no decide el objetivo.
@export var aggro_dinamico: bool = true
## Margen anti-parpadeo del aggro (px).
@export var aggro_histeresis: float = 40.0

@export_category("Objetivo — proximidad al árbol")
## Si un cazador queda pegado al tronco (a menos de arbol_cerca_distancia)
## se pone a asediarlo, aunque prefiera al jugador.
@export var cambiar_a_arbol_cerca: bool = true
@export var arbol_cerca_distancia: float = 90.0
## Histéresis anti-parpadeo (px) para volver al jugador.
@export var arbol_cerca_histeresis: float = 30.0

@export_category("Objetivo — por TIPO")
## A quién persigue ESTE tipo de enemigo:
##  • auto   → se decide por arquetipo (melee/torreta/embestida→árbol;
##             enjambre/rango→jugador).
##  • jugador→ siempre a ti (si mueres, pasa al árbol).
##  • arbol  → siempre a la estructura.
##  • mixto  → el más cercano con sesgo (ver sesgo_jugador).
@export_enum("auto", "jugador", "arbol", "mixto") var objetivo_tipo: String = "auto"
## Sesgo hacia el jugador (solo en modo "mixto"): el árbol solo roba el aggro
## si está a menos de `dist_jugador × sesgo_jugador`. < 1 favorece al jugador.
@export_range(0.1, 1.5) var sesgo_jugador: float = 0.65
## Al recibir daño, el enemigo cambia a perseguirte estos segundos (peel).
## Nunca aplica a jefes (anti_estructura).
@export var peel_duracion: float = 3.0

@export_group("Furia (jefes)")
## Se activa al bajar de esta fracción de vida (0.4 = 40%).
@export_range(0.05, 1.0) var furia_umbral_vida: float = 0.4
@export_range(1.0, 3.0) var furia_mult_velocidad: float = 1.35
@export_range(1.0, 3.0) var furia_mult_danio: float = 1.3

# ───────────── NOMBRE FLOTANTE ─────────────

@export_group("Nombre flotante")
@export var mostrar_nombre: bool = true
## Vacío = usa el nombre del nodo. Sobrescribe desde el WaveManager.
@export var nombre_texto: String = ""
@export var fuente_nombre: Font
@export var tamano_nombre: int = 10
@export var color_nombre: Color = Color.WHITE
@export var offset_nombre: Vector2 = Vector2(0, -30)

# ───────────── DAÑO FLOTANTE ─────────────

@export_group("Daño flotante")
@export var mostrar_danio_flotante: bool = true
@export var fuente_danio: Font
@export var tamano_danio: int = 13
@export var color_danio: Color = Color.WHITE
@export var offset_danio: Vector2 = Vector2(0, -18)
@export var subida_danio: float = 26.0
@export var duracion_danio: float = 0.7

# ───────────── TEXTO NÍTIDO (ZOOM) ─────────────

@export_group("Texto nítido (zoom)")
## Calcula solo la escala para rasterizar 1:1 con los píxeles de
## pantalla (nítido siempre, con cualquier zoom de cámara).
@export var texto_nitido_auto: bool = true
## Multiplicador manual del tamaño (el único usado si auto = off).
@export_range(0.5, 4.0) var texto_escala_extra: float = 1.0

# ───────────── DEPURACIÓN ─────────────

@export_group("Depuración")
## Dibuja los radios del comportamiento y de cambio de objetivo.
@export var debug_dibujar: bool = false

# ───────────── DROPS / ORBES ─────────────

@export_group("Drops (Orbes)")
## OPCIONAL: escena de orbe personalizada. Si queda VACÍA se usa el
## orbe INTERNO (OrbeInterno), creado 100% por código: cero escenas.
@export var orbe_escena: PackedScene
## Cantidad mínima/máxima de orbes por muerte.
@export var orbes_min: int = 1
@export var orbes_max: int = 1
## Dispersión (px) para que no caigan todos en el mismo punto exacto.
@export var radio_dispersion_orbes: float = 15.0
## ── Solo aplica al orbe interno ──
## Valor que entrega cada orbe al recogerse (lo recibe el método del jugador).
@export var orbe_valor: float = 1.0
@export var orbe_color: Color = Color("00ff7f")
@export_range(2.0, 16.0) var orbe_radio: float = 6.0
## Radio en el que el orbe se "imanta" y vuela hacia el jugador.
@export var orbe_iman_radio: float = 90.0
@export var orbe_iman_velocidad: float = 300.0
## Segundos en el suelo antes de desaparecer solo (0 = nunca caduca).
@export var orbe_vida_util: float = 25.0

# ───────────── ESTADO ─────────────

var vida_actual: float = 20.0
## Inyectados por el WaveManager (auto-reparados por grupos si faltan).
var jugador: Node2D = null
var arbol: Node2D = null

var _comp: ComportamientoEnemigo = null
var _vel_deseada: Vector2 = Vector2.ZERO
## Componente de animación (si la escena lo trae). Ver AnimacionEnemigo.gd.
var _anim_fx: Node = null
## Estado interno de la movilidad.
var _fase_mov: float = 0.0
var _fase_dash: float = 0.0
var _t_sep: float = 0.0
var _sep_vec: Vector2 = Vector2.ZERO
var _objetivo_es_arbol: bool = false
## Segundos restantes de "peel" (te persigue tras pegarle).
var _peel_t: float = 0.0
## Empuje externo (ondas de raíces del árbol): se suma al movimiento.
var _empuje_vel: Vector2 = Vector2.ZERO
var _empuje_t: float = 0.0
var _golpeado: bool = false
var _muriente: bool = false
# ── Efectos de estado (cartas) ──
var _slow_t: float = 0.0
var _slow_factor: float = 1.0
var _stun_t: float = 0.0
var _burn_t: float = 0.0
var _burn_dps: float = 0.0
var _burn_acum: float = 0.0
var _burn_tick: float = 0.0
var _en_furia: bool = false
var _tween_furia: Tween = null
var _t_contacto: float = 0.0
var _t_mordisco: float = 0.0

var _label_nombre: TextoFlotante = null
var _ajustes_nombre: LabelSettings = null
var _ajustes_danio: LabelSettings = null


# ───────────── CICLO PRINCIPAL ─────────────

const ANIM_SCRIPT := preload("res://ecenes/enemies/class/AnimacionEnemigo.gd")


func _ready() -> void:
	add_to_group("enemigos")
	vida_actual = life   # life llega YA escalado por el WaveManager.
	_resolver_objetivo_tipo()
	_instalar_comportamiento()
	_mostrar_nombre()
	# Animación: si la escena no la trae, se crea sola (todos los enemigos animan).
	if get_node_or_null("Animacion") == null:
		var anim := ANIM_SCRIPT.new()
		anim.name = "Animacion"
		add_child(anim)
	_anim_fx = get_node_or_null("Animacion")


## Aviso de ataque al componente de animación (si existe). Se llama en cada
## golpe/disparo/contacto para disparar el "pulso" de ataque visual.
func _fx_ataque() -> void:
	if _anim_fx != null and _anim_fx.has_method("pulso_ataque"):
		_anim_fx.call("pulso_ataque")


func _physics_process(delta: float) -> void:
	# Un enemigo muriendo solo reproduce su pop de muerte: no actúa.
	if _muriente:
		return
	_resolver_referencias_fallback()
	_actualizar_efectos(delta)
	if _muriente:
		return  # murió por quemadura dentro de _actualizar_efectos()

	# Las órdenes se dictan CADA frame: parten de cero.
	_vel_deseada = Vector2.ZERO

	# 1) Aggro + furia ANTES de que el comportamiento pregunte.
	_actualizar_aggro(delta)
	_actualizar_furia()

	# 2) Mecánica del enemigo concreto (extends Enemigo), si existe.
	_mecanica(delta)

	# 3) Comportamiento instalado (o fallback melee).
	if _comp != null:
		_comp.pensar(self, delta)

	# 3.5) Movilidad dinámica (orbita/zigzag/micro-dash/separación).
	_aplicar_movilidad(delta)

	# 4) Movimiento + empuje externo (ondas de raíces del árbol).
	velocity = _vel_deseada * _velocidad_actual()
	if _empuje_t > 0.0:
		_empuje_t -= delta
		velocity += _empuje_vel
		if _empuje_t <= 0.0:
			_empuje_vel = Vector2.ZERO
	move_and_slide()

	# 5) Contacto DESPUÉS de move_and_slide().
	_actualizar_contacto(delta)
	# El daño enemigo→ÁRBOL lo gestiona el Area2D del propio árbol (shape de
	# detección agrandada). Aquí no se duplica para no golpear dos veces.
	# _actualizar_mordisco(delta)

	if debug_dibujar:
		queue_redraw()


## Sobrecárgala en los enemigos concretos (extends Enemigo).
func _mecanica(_delta: float) -> void:
	pass


func _draw() -> void:
	if not debug_dibujar:
		return
	if _comp != null and _comp.has_method("debug_dibujar_en"):
		_comp.call("debug_dibujar_en", self)
	if cambiar_a_arbol_cerca and _estructura_viva():
		draw_arc(Vector2.ZERO, arbol_cerca_distancia, 0.0, TAU, 48,
				Color(0.0, 1.0, 0.5, 0.35), 1.0)


# ───────────── REFERENCIAS (cinturón de seguridad) ─────────────

func _resolver_referencias_fallback() -> void:
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	if arbol == null or not is_instance_valid(arbol):
		arbol = get_tree().get_first_node_in_group("arbol") as Node2D


func _estructura_viva() -> bool:
	if arbol == null or not is_instance_valid(arbol):
		return false
	if "esta_destruido" in arbol and bool(arbol.get("esta_destruido")):
		return false
	return true


# ───────────── OBJETIVO: JUGADOR O ÁRBOL ─────────────

## Sistema mixto (rol + sesgo + peel). Precedencia:
##  1) Jefes (anti_estructura) → árbol.
##  2) Peel activo (le pegaste) → jugador.
##  3) Asediador → árbol.
##  4) Cazador → jugador, salvo que el árbol esté a < dist_jugador×sesgo
##     o que el enemigo ya esté pegado al tronco (asedio clásico).
##  5) Aggro vencido (jugador muy lejos) → árbol.
##  6) Default → jugador.
func objetivo() -> Node2D:
	var arb: Node2D = arbol if _estructura_viva() else null
	var jug: Node2D = null
	if jugador != null and is_instance_valid(jugador):
		jug = jugador
	# Jugador MUERTO → no cuenta como objetivo: los enemigos van al árbol
	# (o a nada si el árbol ya cayó) durante la espera de respawn.
	if jug != null and jug.has_method("esta_muerto") and jug.esta_muerto():
		jug = null

	# 1) Jefes: árbol siempre mientras exista.
	if anti_estructura and arb != null:
		return arb

	# Nada de nada.
	if jug == null and arb == null:
		return null
	# Solo queda uno.
	if jug == null:
		return arb
	if arb == null:
		return jug

	# 2) PEEL: si le pegaste hace poco, te persigue (recompensa la habilidad).
	if _peel_t > 0.0:
		return jug

	# 3) Rol por TIPO de enemigo (determinista, sin azar).
	if objetivo_tipo == "arbol":
		return arb
	if objetivo_tipo == "jugador":
		return jug

	# 4) Mixto: prefiere al JUGADOR. El árbol solo le roba el aggro si
	#    está significativamente más cerca (sesgo_jugador < 1) o si ya
	#    está pegado al tronco (asedio clásico con histéresis).
	var d_jug := global_position.distance_to(jug.global_position)
	var d_arb := global_position.distance_to(arb.global_position)
	var umbral := d_jug * sesgo_jugador
	if cambiar_a_arbol_cerca and d_arb < arbol_cerca_distancia:
		_objetivo_es_arbol = true
	elif _objetivo_es_arbol:
		if umbral + aggro_histeresis < d_arb \
				and d_arb > arbol_cerca_distancia + arbol_cerca_histeresis:
			_objetivo_es_arbol = false
	elif d_arb + aggro_histeresis < umbral:
		_objetivo_es_arbol = true
	if _objetivo_es_arbol:
		return arb

	# 5) Aggro vencido: el jugador se alejó demasiado → árbol.
	if rango_aggro > 0.0 and d_jug > rango_aggro:
		return arb

	# 6) Por defecto: jugador.
	return jug


## Resuelve "auto" por arquetipo (comportamiento_tipo). Los jefes ya van al
## árbol por anti_estructura, así que esto solo aplica a enemigos normales.
## Pesados/lentos asedian la estructura; rápidos persiguen al jugador.
func _resolver_objetivo_tipo() -> void:
	if objetivo_tipo != "auto":
		return
	objetivo_tipo = "arbol" if comportamiento_tipo in ["melee", "torreta", "embestida"] else "jugador"


## Refresca la regla de objetivo (se llama 1× por frame) y el reloj del peel.
func _actualizar_aggro(delta: float) -> void:
	if _peel_t > 0.0:
		_peel_t -= delta
	objetivo()


# ───────────── FURIA (JEFES) ─────────────

func _actualizar_furia() -> void:
	if _en_furia or not anti_estructura:
		return
	if vida_actual <= 0.0 or vida_actual > life * furia_umbral_vida:
		return
	_en_furia = true
	print("[Enemigo] ☠ FURIA activada en %s (vida <= %.0f%%)"
			% [name, furia_umbral_vida * 100.0])
	if _tween_furia != null and _tween_furia.is_valid():
		_tween_furia.kill()
	_tween_furia = create_tween().set_loops()
	_tween_furia.tween_property(self, "self_modulate", Color("d81b60"), 0.22)
	_tween_furia.tween_property(self, "self_modulate", Color.WHITE, 0.22)


func porcentaje_vida() -> float:
	if life <= 0.0:
		return 0.0
	return clampf(vida_actual / life, 0.0, 1.0)


# ───────────── MULTIPLICADORES ACTUALES ─────────────

func _velocidad_actual() -> float:
	if _stun_t > 0.0:
		return 0.0
	var v := speed * velocidad_multiplicador
	if _en_furia:
		v *= furia_mult_velocidad
	return v * _slow_factor


# ───────────── EFECTOS DE ESTADO (cartas) ─────────────

func _actualizar_efectos(delta: float) -> void:
	if _slow_t > 0.0:
		_slow_t -= delta
		if _slow_t <= 0.0:
			_slow_factor = 1.0
	if _stun_t > 0.0:
		_stun_t -= delta
	if _burn_t > 0.0:
		_burn_t -= delta
		_burn_acum += _burn_dps * delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = 0.25
			var d := _burn_acum
			_burn_acum = 0.0
			if d > 0.0 and vida_actual > 0.0 and not _muriente:
				vida_actual = maxf(0.0, vida_actual - d)
				if vida_actual <= 0.0:
					_morir()
	else:
		_burn_acum = 0.0


func aplicar_ralentizado(pct: float, duracion: float) -> void:
	_slow_factor = minf(_slow_factor, 1.0 - clampf(pct, 0.0, 0.9))
	_slow_t = maxf(_slow_t, duracion)


func aplicar_aturdimiento(duracion: float) -> void:
	_stun_t = maxf(_stun_t, duracion)


func aplicar_quemadura(dps: float, duracion: float) -> void:
	_burn_dps = maxf(_burn_dps, dps)
	_burn_t = maxf(_burn_t, duracion)


## Empuje externo (lo llama el árbol con sus ondas de raíces). Se suma al
## movimiento durante `duracion`; el empuje gana aun estando aturdido.
func aplicar_empuje(dir: Vector2, fuerza: float, duracion: float = 0.25) -> void:
	if dir == Vector2.ZERO or fuerza <= 0.0:
		return
	_empuje_vel = dir.normalized() * fuerza
	_empuje_t = maxf(_empuje_t, duracion)


func _mult_danio_actual() -> float:
	return furia_mult_danio if _en_furia else 1.0


# ───────────── API PARA COMPORTAMIENTOS ─────────────

func distancia_a(n: Node2D) -> float:
	if n == null:
		return INF
	return global_position.distance_to(n.global_position)


func dir_a(n: Node2D) -> Vector2:
	if n == null:
		return Vector2.ZERO
	return (n.global_position - global_position).normalized()


func mover_hacia(punto: Vector2, mult: float = 1.0) -> void:
	_vel_deseada = (punto - global_position).normalized() * clampf(mult, 0.0, 3.0)


func mover_en(dir: Vector2, mult: float = 1.0) -> void:
	_vel_deseada = dir.normalized() * clampf(mult, 0.0, 3.0)


func detener(_freno: float = 1.0) -> void:
	_vel_deseada = Vector2.ZERO


## Golpe directo. Devuelve true si conectó.
func atacar_objetivo(obj: Node2D = null) -> bool:
	var t: Node2D = obj
	if t == null:
		t = objetivo()
	if t == null:
		return false
	var d := damage * _mult_danio_actual()
	if t.has_method("recibir_danio"):
		t.call("recibir_danio", d)
		_fx_ataque()
		return true
	if t.has_method("take_damage"):
		t.call("take_damage", d)
		_fx_ataque()
		return true
	return false


## Golpe con cantidad explícita (lo usa comp_embestida para su daño de carga).
func _hacer_danio(obj: Node2D, cantidad: float) -> bool:
	if obj == null:
		return false
	if obj.has_method("recibir_danio"):
		obj.call("recibir_danio", cantidad)
		_fx_ataque()
		return true
	if obj.has_method("take_damage"):
		obj.call("take_damage", cantidad)
		_fx_ataque()
		return true
	return false


## Dispara desde un nodo (normalmente `self`) hacia `dir`. La escena
## define `proyectil`; si es null, usa el rombo neón interno.
func disparar_desde(origen: Node2D, dir: Vector2) -> bool:
	if origen == null:
		return false
	var escena := get_tree().current_scene
	if escena == null:
		return false
	var p: Node2D = null
	if proyectil != null:
		p = proyectil.instantiate() as Node2D
	else:
		p = ProyectilDefecto.new()
	if p == null:
		return false
	escena.add_child(p)
	p.global_position = origen.global_position
	var d := dir.normalized()
	if "velocidad" in p:
		p.set("velocidad", rango_vel_proyectil if comportamiento_tipo == "rango" else torreta_vel_proyectil)
	if p.has_method("configurar"):
		p.call("configurar", d, damage * _mult_danio_actual())
	_fx_ataque()
	return true


# ───────────── MOVILIDAD ─────────────
## Aplica orbita (strafe), zigzag, micro-dash y separación a la orden de
## movimiento del comportamiento. Funciona para TODOS los enemigos.
func _aplicar_movilidad(delta: float) -> void:
	if not movilidad:
		return
	if _vel_deseada.length_squared() < 0.0001:
		return

	_fase_mov += delta * mov_zigzag_freq
	_fase_dash += delta

	var mag := _vel_deseada.length()
	var dir := _vel_deseada.normalized()

	if mov_zigzag_grados > 0.0:
		dir = dir.rotated(deg_to_rad(sin(_fase_mov * TAU) * mov_zigzag_grados))

	if absf(mov_orbita) > 0.001:
		dir = (dir + dir.orthogonal() * mov_orbita).normalized()

	if mov_dash_mult > 1.0 and mov_dash_freq > 0.0:
		if sin(_fase_dash * mov_dash_freq * TAU) > 0.5:
			mag *= mov_dash_mult

	if mov_separacion_fuerza > 0.0 and mov_separacion_radio > 0.0:
		_t_sep -= delta
		if _t_sep <= 0.0:
			_t_sep = 0.2
			_sep_vec = _separacion_vec()
		dir = (dir + _sep_vec).normalized()

	_vel_deseada = dir * mag


## Repulsión contra enemigos cercanos (se recalcula cada 0.2 s, muestreo capado).
func _separacion_vec() -> Vector2:
	var suma := Vector2.ZERO
	var r := mov_separacion_radio
	var r2 := r * r
	var revisados := 0
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e == self or not (e is Node2D):
			continue
		var d: Vector2 = global_position - (e as Node2D).global_position
		var l2 := d.length_squared()
		if l2 > 0.01 and l2 < r2:
			suma += d / l2
		revisados += 1
		if revisados >= 60:
			break
	return suma * mov_separacion_fuerza


# ───────────── CONTACTO Y MORDISCO ─────────────

func _actualizar_contacto(delta: float) -> void:
	_t_contacto -= delta
	if _t_contacto > 0.0:
		return
	if jugador == null or not is_instance_valid(jugador):
		return
	# Daño por contacto al JUGADOR (nuevo flag o el legacy).
	if global_position.distance_to(jugador.global_position) <= radio_contacto \
			or _chocando_con(jugador):
		var d := 0.0
		if danio_contacto > 0.0:
			d = danio_contacto * _mult_danio_actual()
		elif dano_al_tocar:
			d = damage * _mult_danio_actual()
		if d > 0.0 and jugador.has_method("recibir_danio"):
			jugador.call("recibir_danio", d, self)
			_t_contacto = periodo_contacto
			_fx_ataque()


func _actualizar_mordisco(delta: float) -> void:
	_t_mordisco -= delta
	if _t_mordisco > 0.0:
		return
	# Solo los enemigos "de contacto" muerden el tronco de forma genérica.
	# Los melee lo atacan con su comportamiento (comp_mele) → evita doble daño.
	if not dano_al_tocar and danio_contacto <= 0.0:
		return
	if not _estructura_viva():
		return
	# Muerde el tronco si este bloquea el camino o está en rango.
	if global_position.distance_to(arbol.global_position) <= radio_contacto + 8.0 \
			or _chocando_con(arbol):
		# Se pasa `self` como FUENTE: el log de diagnóstico del árbol
		# ('debug_danio_entrante') puede nombrar al mordedor exacto.
		if arbol.has_method("recibir_danio"):
			arbol.call("recibir_danio", damage * _mult_danio_actual(), self)
			_t_mordisco = periodo_contacto


## ¿Chocó contra `obj` en el último move_and_slide()?
func _chocando_con(obj: Node2D) -> bool:
	if obj == null:
		return false
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c == null:
			continue
		var col := c.get_collider()
		if col == obj:
			return true
		# Soporta objetivos cuyo cuerpo físico es un HIJO (p. ej. el árbol:
		# raíz Area2D con el StaticBody2D del tronco dentro) → así el
		# enemigo que empuja el tronco cuenta como "chocando con el árbol".
		if col is Node and obj.is_ancestor_of(col):
			return true
	return false


# ───────────── DAÑO / MUERTE ─────────────

func recibir_danio(cantidad: float) -> void:
	_aplicar_danio(cantidad)
	# PEEL: al golpearlo TÚ (o un efecto tuyo), te hace caso unos segundos.
	# Nunca aplica a jefes.
	if not anti_estructura:
		_peel_t = maxf(_peel_t, peel_duracion)


## Daño de fuentes AMBIENTALES (espinas del árbol, auras): no provoca peel,
## porque no eres tú atacando. Así las espinas no echan a los enemigos del
## tronco. Mismo contrato de vida que recibir_danio().
func recibir_danio_ambiental(cantidad: float) -> void:
	_aplicar_danio(cantidad)


func _aplicar_danio(cantidad: float) -> void:
	if vida_actual <= 0.0:
		return
	vida_actual = maxf(0.0, vida_actual - cantidad)
	emit_signal("recibo_danio", cantidad)
	_mostrar_danio_flotante(cantidad)
	_ocultar_nombre()
	if vida_actual <= 0.0:
		_morir()


func _soltar_orbes(auto_iman: bool = false) -> void:
	var escena_actual := get_tree().current_scene
	if escena_actual == null:
		return

	# Cantidad robusta: normaliza min/max y sortea dentro del rango.
	var desde := mini(orbes_min, orbes_max)
	var hasta := maxi(orbes_min, orbes_max)
	var cantidad := randi_range(desde, hasta)

	for i in range(cantidad):
		var orbe: Node2D = null
		if orbe_escena != null:
			# Override opcional: usa TU escena si está configurada.
			orbe = orbe_escena.instantiate() as Node2D
		else:
			# Sin escena: orbe construido 100% por código (OrbeInterno).
			var interno := OrbeBiomasa.new()
			interno.valor = orbe_valor * _stat("jugador.orbes_valor", 1.0)
			interno.color_orbe = orbe_color
			interno.radio = orbe_radio
			interno.iman_radio = orbe_iman_radio * _stat("jugador.orbes_radio", 1.0)
			interno.iman_velocidad = orbe_iman_velocidad
			interno.vida_util = orbe_vida_util
			interno.auto_iman = auto_iman
			if auto_iman:
				interno.retraso_iman = randf() * 0.35
			orbe = interno
		if orbe == null:
			continue

		# Dispersión para que no caigan apilados.
		var offset := Vector2.ZERO
		if cantidad > 1:
			offset = Vector2(
				randf_range(-radio_dispersion_orbes, radio_dispersion_orbes),
				randf_range(-radio_dispersion_orbes, radio_dispersion_orbes))
		orbe.global_position = global_position + offset

		# A la escena principal (desligado del enemigo, que va a morir).
		escena_actual.call_deferred("add_child", orbe)


## Lee un stat del jugador desde SaveManager (con fallback seguro).
func _stat(ruta: String, defecto: float) -> float:
	if SaveManager == null:
		return defecto
	return SaveManager.get_stat(ruta, defecto)


## Muerte "de limpieza" al cerrar la oleada: suelta orbes que persiguen al
## jugador y se apaga con un pop. NO emite 'murio' (no cuenta como baja ni
## dispara fichas educativas).
func morir_por_fin_de_oleada() -> void:
	if _muriente:
		return
	_muriente = true
	_soltar_orbes(true)
	print("[Enemigo] '%s': fin de oleada → suelta orbes auto-imán y desaparece." % name)
	remove_from_group("enemigos")
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_property(self, "scale", scale * 0.6, 0.25)
	tw.chain().tween_callback(queue_free)


func _morir() -> void:
	if _muriente:
		return
	_muriente = true
	if AudioManager != null and AudioManager.has_method("reproducir"):
		AudioManager.call("reproducir", "muerte", -6.0)
	if _tween_furia != null and _tween_furia.is_valid():
		_tween_furia.kill()

	# Soltar el loot antes de desaparecer
	_soltar_orbes()

	_detonar_si_toca()

	murio.emit(self)   # UN argumento: firma corregida con WaveManager.

	# Pop de muerte: squash + fundido antes de liberar (mismo patrón que
	# morir_por_fin_de_oleada). El WaveManager cuenta las bajas al salir del
	# árbol, así que este retardo de ~0.27 s es despreciable.
	remove_from_group("enemigos")
	if _anim_fx != null and is_instance_valid(_anim_fx):
		_anim_fx.set_physics_process(false)
	velocity = Vector2.ZERO
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", scale * Vector2(1.22, 0.72), 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.22).set_delay(0.05)
	tw.chain().tween_callback(queue_free)


## "Bomba de Semillas": probabilidad de explosión en área al morir.
func _detonar_si_toca() -> void:
	if SaveManager == null:
		return
	var prob := SaveManager.get_stat("jugador.detonar_prob", 0.0)
	if prob <= 0.0 or randf() > prob:
		return
	var escena := get_tree().current_scene
	if escena == null:
		return
	var radio := 110.0
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e != self and e is Node2D and e.global_position.distance_to(global_position) <= radio:
			if e.has_method("recibir_danio"):
				e.call("recibir_danio", 45.0)
	var vis := Node2D.new()
	vis.z_index = 60
	var r := radio
	vis.draw.connect(func() -> void:
		vis.draw_circle(Vector2.ZERO, r, Color(1.0, 0.6, 0.15, 0.45))
		vis.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(1, 1, 1, 0.8), 3.0))
	vis.global_position = global_position
	vis.scale = Vector2(0.3, 0.3)
	escena.add_child(vis)
	var tw := vis.create_tween()
	tw.set_parallel(true)
	tw.tween_property(vis, "scale", Vector2.ONE, 0.3)
	tw.tween_property(vis, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(vis.queue_free)


# ───────────── COMPORTAMIENTO: carga e inyección de parámetros ─────────────

## Los parámetros del grupo del tipo elegido, listos para inyectar.
func _datos_comportamiento() -> Dictionary:
	if comportamiento_tipo == "melee":
		return {
			"radio_ataque": melee_radio,
			"recarga": melee_recarga,
			"mult_persecucion": melee_mult_persecucion,
		}
	if comportamiento_tipo == "enjambre":
		return {
			"radio_ataque": melee_radio,
			"recarga": enjambre_recarga,
			"separacion": enjambre_separacion,
		}
	if comportamiento_tipo == "rango":
		return {
			"distancia": rango_distancia,
			"margen": rango_margen,
			"recarga": rango_recarga,
		}
	if comportamiento_tipo == "torreta":
		return {
			"alcance": torreta_alcance,
			"recarga": torreta_recarga,
		}
	if comportamiento_tipo == "embestida":
		return {
			"mult_dano": embestida_mult_dano,
			"vel_patrulla": embestida_vel_patrulla,
			"telegrafiar": embestida_telegrafiar,
		}
	return {}


func _instalar_comportamiento() -> void:
	_comp = null
	var script_comp: GDScript = comportamiento_personalizado

	# Registro COMPORTAMIENTOS por el dropdown (si no hay script a mano).
	if script_comp == null:
		var ruta: String = String(COMPORTAMIENTOS.get(comportamiento_tipo, ""))
		var existe := ruta != "" and ResourceLoader.exists(ruta)
		print("[Enemigo] %s → tipo='%s' → ruta='%s' → existe=%s"
				% [name, comportamiento_tipo, ruta, existe])
		if existe:
			script_comp = load(ruta) as GDScript

	# Diagnóstico del resultado.
	if script_comp != null:
		print("[Enemigo] ✅ comportamiento '%s' instalado en %s"
				% [comportamiento_tipo, name])
	else:
		printerr("[Enemigo] ❌ '%s' NO cargó (ruta inexistente o script que no compila) → FALLBACK melee en %s"
				% [comportamiento_tipo, name])

	# Instalación (o melee interno para que nunca quede quieto).
	if script_comp != null:
		_comp = script_comp.new() as ComportamientoEnemigo
	else:
		_comp = ComportamientoMeleeFallback.new()
	if _comp == null:
		printerr("[Enemigo] ❌ el script de '%s' no es un ComportamientoEnemigo" % comportamiento_tipo)
		_comp = ComportamientoMeleeFallback.new()
	_comp.iniciar(self)


# ───────────── TEXTO: NOMBRE Y DAÑO FLOTANTE ─────────────

func _crear_label(texto: String, ajustes: LabelSettings) -> TextoFlotante:
	var l := TextoFlotante.new()
	l.label_settings = ajustes
	l.text = texto
	l.z_index = 100
	# LINEAR explícito: anula un filtro Nearest global del proyecto
	# (típico en pixel-art) que difumina o pixela los glifos.
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return l


func _construir_ajustes_nombre() -> LabelSettings:
	var a := LabelSettings.new()
	if fuente_nombre != null:
		a.font = fuente_nombre
	a.font_size = tamano_nombre
	a.font_color = color_nombre
	a.outline_size = 0
	a.shadow_color = Color(1.0, 1.0, 1.0, 0.0)
	a.shadow_offset = Vector2.ZERO
	return a


func _construir_ajustes_danio() -> LabelSettings:
	var a := LabelSettings.new()
	if fuente_danio != null:
		a.font = fuente_danio
	a.font_size = tamano_danio
	a.font_color = color_danio
	a.outline_size = 0
	a.shadow_color = Color(1.0, 1.0, 1.0, 0.0)
	a.shadow_offset = Vector2.ZERO
	return a


## Escala que compensa el zoom de cámara y el estirado del viewport,
## para que el glifo se rasterice 1:1 con los píxeles de pantalla.
func _escala_texto_pantalla() -> float:
	if not texto_nitido_auto:
		return texto_escala_extra
	var escala := 1.0
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.zoom.y > 0.0001:
		escala = 1.0 / cam.zoom.y
	var factor := get_viewport().get_final_transform().get_scale().y
	if factor > 0.0001:
		escala /= factor
	return maxf(0.01, escala * texto_escala_extra)


func _texto_nombre() -> String:
	if not nombre_texto.is_empty():
		return nombre_texto
	return String(name)


func _mostrar_nombre() -> void:
	if not mostrar_nombre:
		return
	if _ajustes_nombre == null:
		_ajustes_nombre = _construir_ajustes_nombre()
	var l := _crear_label(_texto_nombre(), _ajustes_nombre)
	_label_nombre = l
	add_child(l)  # hijo del enemigo: se mueve con él
	l.reset_size()
	l.pivot_offset = l.size * 0.5
	l.escala_pantalla = _escala_texto_pantalla()
	l.position = offset_nombre - l.size * 0.5
	# Animación de entrada (pop + fundido).
	l.pop = 0.4
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(l, "pop", 1.0, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Se oculta para siempre con el PRIMER golpe recibido.
func _ocultar_nombre() -> void:
	if _golpeado or _label_nombre == null:
		return
	_golpeado = true
	var tw := _label_nombre.create_tween()
	tw.tween_property(_label_nombre, "modulate:a", 0.0, 0.2)
	tw.tween_callback(_label_nombre.hide)


func _mostrar_danio_flotante(cantidad: float) -> void:
	if not mostrar_danio_flotante or get_tree().current_scene == null:
		return
	if _ajustes_danio == null:
		_ajustes_danio = _construir_ajustes_danio()
	var l := _crear_label(str(roundi(cantidad)), _ajustes_danio)
	get_tree().current_scene.add_child(l)
	l.reset_size()
	# Nace centrado sobre el enemigo (vive en la escena para sobrevivir
	# a la muerte del enemigo).
	l.pivot_offset = l.size * 0.5
	l.escala_pantalla = _escala_texto_pantalla()
	l.global_position = ((global_position + offset_danio) - l.size * 0.5).round()
	l.pop = 0.4
	var tw := l.create_tween()
	tw.tween_property(l, "pop", 1.0, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "global_position:y", l.global_position.y - subida_danio, duracion_danio) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, duracion_danio) \
			.set_delay(duracion_danio * 0.4)
	tw.tween_callback(l.queue_free)


# ───────────── FALLBACK MELEE INTERNO ─────────────
## Si el comportamiento configurado no carga (script faltante, nombre
## erróneo), este melee interno sostiene al enemigo para que NUNCA
## quede quieto flotando sin hacer nada.

class ComportamientoMeleeFallback extends ComportamientoEnemigo:
	var _t: float = 0.0
	var _radio: float = 30.0

	func iniciar(enemigo: Enemigo) -> void:
		e = enemigo
		_radio = maxf(30.0, enemigo.radio_contacto)

	func pensar(enemigo: Enemigo, delta: float) -> void:
		e = enemigo
		_t -= delta
		var obj := e.objetivo()
		if obj == null:
			e.detener()
			return
		if e.distancia_a(obj) > _radio:
			e.mover_hacia(obj.global_position)
		else:
			e.detener()
			if _t <= 0.0 and e.atacar_objetivo(obj):
				_t = e.periodo_contacto


# ───────────── LABEL NÍTIDO (nombre y daño flotante) ─────────────
## Rasteriza el texto 1:1 con la pantalla (anula zoom y escala
## heredada). Control no tiene global_scale: se usa `scale` y se
## neutraliza a mano la del padre si lo hay.

class TextoFlotante extends Label:
	## Escala final deseada en pantalla; la calcula el enemigo según el zoom.
	var escala_pantalla: float = 1.0
	## Factor del pop de entrada (1.0 = tamaño normal).
	var pop: float = 1.0

	func _process(_delta: float) -> void:
		var s := pop * escala_pantalla
		var padre := get_parent() as Node2D
		if padre != null and absf(padre.global_scale.x) > 0.0001:
			s /= absf(padre.global_scale.x)
		scale = Vector2.ONE * s


# ───────────── PROYECTIL INTERNO (rombo neón) ─────────────
## Se usa cuando la escena no define `proyectil`. Golpea una vez al
## jugador o al árbol, con la misma cadena de compatibilidad.

class ProyectilDefecto:
	extends Node2D

	var direccion := Vector2.RIGHT
	var velocidad := 220.0
	var dano := 4.0
	var color_proyectil: Color = Color("00ff7f")
	var vida_util := 3.0
	var radio_golpe := 20.0
	var _t := 0.0
	var _golpeado := false

	func configurar(dir: Vector2, dano_nuevo: float) -> void:
		direccion = dir.normalized()
		dano = dano_nuevo
		rotation = direccion.angle()

	func _ready() -> void:
		var vis := Polygon2D.new()
		vis.polygon = PackedVector2Array([
			Vector2(7, 0), Vector2(-4, 4), Vector2(-2, 0), Vector2(-4, -4)])
		vis.color = color_proyectil
		add_child(vis)
		var cola := Polygon2D.new()
		cola.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(-10, 2), Vector2(-10, -2)])
		cola.color = Color(color_proyectil.r, color_proyectil.g, color_proyectil.b, 0.4)
		add_child(cola)

	func _physics_process(delta: float) -> void:
		position += direccion * velocidad * delta
		_t += delta
		if _t > vida_util:
			queue_free()
			return
		if _golpeado:
			return
		# Impacto contra jugador o árbol (una sola vez).
		for grupo in ["jugador", "arbol"]:
			for n in get_tree().get_nodes_in_group(grupo):
				var obj := n as Node2D
				if obj == null:
					continue
				if global_position.distance_to(obj.global_position) <= radio_golpe:
					if obj.has_method("recibir_danio"):
						obj.call("recibir_danio", dano)
					elif obj.has_method("take_damage"):
						obj.call("take_damage", dano)
					_golpeado = true
					queue_free()
					return


# ───────────── ORBE INTERNO (drop sin escena) ─────────────
## Orbe construido 100% por código: círculo neón con pulso de entrada,
## imán hacia el jugador cuando se acerca y recogida al tocarlo.
## TODO el juego de la economía vive en _recoger(): ahí se conecta a
## tu sistema real (XP, curación, recursos...).
# ═══════════════════════════════════════════════════════════
#  PARCHE para Enemigo.gd
#  Reemplaza COMPLETA la clase interna `OrbeInterno` (al final del
#  archivo, desde "class OrbeInterno:" hasta el final) por esta.
#  El resto de Enemigo.gd queda igual.
# ═══════════════════════════════════════════════════════════
