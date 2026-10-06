class_name Enemigo
extends CharacterBody2D

## ══════════════════════════════════════════════════════════
##  ENEMIGO — Clase principal (ESCENA + GD), integrada al WaveManager.
##
##  CONTRATO:
##  • Jugador y Árbol los identifica el WAVE MANAGER (por grupos) y
##    los inyecta aquí antes de add_child. Esta clase NO busca nada:
##    solo los recibe y expone objetivo().
##  • El WaveManager escala life / speed / damage ANTES de add_child;
##    en _ready la vida actual arranca como life (ya escalada).
##  • Esta clase entra al grupo 'enemigos' (debug y sistemas).
##  • Los comportamientos son SOLO .gd (lógica); sus parámetros se
##    configuran en el Inspector y se inyectan al iniciar.
## ══════════════════════════════════════════════════════════

signal murio(enemigo: Enemigo)
signal recibo_danio(cantidad: float)

# Registro: tipo → .gd del comportamiento (solo lógica, sin escena).
const COMPORTAMIENTOS: Dictionary = {
	"melee": "res://ecenes/enemies/class/comportamientos/comp_melee.gd",
	"enjambre": "res://ecenes/enemies/class/comportamientos/comp_enjambre.gd",
	"rango": "res://ecenes/enemies/class/comportamientos/comp_rango.gd",
	"torreta": "res://ecenes/enemies/class/comportamientos/comp_torreta.gd",
	"embestida": "res://ecenes/enemies/class/comportamientos/comp_embestida.gd",
}

@export_group("Comportamiento")
## Tipo de comportamiento básico. Sus parámetros se ajustan en
## los grupos de abajo (Melee, Enjambre, Rango...).
@export_enum("melee", "enjambre", "rango", "torreta", "embestida")
var comportamiento_tipo: String = "melee"
## Opcional: un .gd propio que extienda ComportamientoEnemigo.
@export var comportamiento_personalizado: GDScript

@export_group("Depuración")
## Dibuja el radio del comportamiento activo sobre el enemigo.
@export var debug_dibujar: bool = false

@export_group("Estadísticas")
## Vida MÁXIMA. El WaveManager la escala por oleada (`life`).
@export var life: float = 20.0
## Velocidad base. El WaveManager la escala por etapa (`speed`).
@export var speed: float = 90.0
## Daño de contacto/ataque. El WaveManager lo escala por etapa (`damage`).
@export var damage: float = 5.0
@export_range(0.0, 4.0) var velocidad_multiplicador: float = 1.0
## Daño automático al tocar al objetivo (lo activa p. ej. el enjambre).
@export var dano_al_tocar: bool = false
@export var radio_contacto: float = 22.0
@export_range(0.1, 3.0) var periodo_contacto: float = 0.8
@export var recompensa: int = 1

@export_group("Objetivo (jugador / árbol)")
## Si es true (Talador, Motosierra...), ignora al jugador y va
## directo al árbol mientras exista.
@export var anti_estructura: bool = false
## Si el jugador queda a más de esta distancia, el enemigo vuelve al
## árbol (0 = persigue al jugador a cualquier distancia).
@export var rango_aggro: float = 0.0

@export_group("Melee")
@export var melee_radio: float = 30.0
@export var melee_recarga: float = 1.0
@export_range(0.1, 3.0) var melee_mult_persecucion: float = 1.0

@export_group("Enjambre")
@export_range(0.1, 3.0) var enjambre_vel_extra: float = 1.35
@export var enjambre_radio_rodeo: float = 55.0
@export var enjambre_reeleccion: float = 1.2
@export var enjambre_tambalear: float = 6.0

@export_group("Rango")
@export var rango_distancia: float = 220.0
@export var rango_margen: float = 40.0
@export var rango_recarga: float = 1.6
@export_range(0.0, 2.0) var rango_vel_strafe: float = 0.5
@export_range(0.0, 45.0) var rango_dispersion: float = 0.0

@export_group("Torreta")
@export var torreta_alcance: float = 600.0
@export var torreta_recarga: float = 2.2
@export var torreta_balas: int = 3
@export var torreta_separacion: float = 0.12
@export_range(0.0, 45.0) var torreta_dispersion: float = 6.0

@export_group("Embestida")
@export var embestida_alcance: float = 340.0
@export var embestida_tiempo_apuntado: float = 0.7
@export_range(1.0, 6.0) var embestida_mult_carga: float = 3.2
@export var embestida_tiempo_carga: float = 0.9
@export var embestida_descanso: float = 1.1
@export_range(1.0, 4.0) var embestida_mult_dano: float = 2.0
@export_range(0.1, 2.0) var embestida_vel_patrulla: float = 0.6
@export var embestida_telegrafiar: bool = true

@export_group("Ataque a distancia")
## Escena de proyectil (puede faltar: se usa uno interno mientras tanto).
@export var proyectil: PackedScene
@export var velocidad_proyectil: float = 220.0
## Multiplicador del daño de proyectil sobre `damage` (así el
## escalado del WaveManager también afecta a los disparos).
@export_range(0.1, 4.0) var mult_dano_proyectil: float = 1.0

@export_group("Referencias internas")
## Nodo visual (FiguraConstructor). Vacío = autodetección entre los hijos.
@export var figura: Node2D
## Punto de salida de proyectiles. Vacío = autodetección del hijo "Boca".
@export var boca: Node2D

# Referencias que SOLO inyecta el WaveManager (identifica por grupos).
# No se buscan aquí: sin WaveManager, el enemigo se queda quieto.
var jugador: Node2D = null
var arbol: Node2D = null

# ───────────── ESTADO ─────────────
var vida: float                   # vida ACTUAL (life ya vino escalada)
var _comp = null                  # comportamiento (duck typing)
var _t_contacto: float = 0.0
var _muerto: bool = false
var _avisos: Dictionary = {}      # clave -> true (avisar solo una vez)


# ───────────── COMPATIBILIDAD DE NOMBRES ─────────────
## Por si una escena vieja guardó overrides con los nombres antiguos.
func _set(propiedad: StringName, valor: Variant) -> bool:
	match propiedad:
		"vida_max":
			life = valor
			return true
		"velocidad":
			speed = valor
			return true
		"dano_contacto":
			damage = valor
			return true
	return false

func _get(propiedad: StringName) -> Variant:
	match propiedad:
		"vida_max":
			return life
		"velocidad":
			return speed
		"dano_contacto":
			return damage
	return null


# ───────────── CICLO DE VIDA ─────────────

func _ready() -> void:
	add_to_group("enemigos")   # contrato WaveManager: debug y sistemas lo buscan aquí
	vida = life                # el WaveManager ya escaló life ANTES de add_child
	_resolver_referencias_internas()
	_cargar_comportamiento()
	_listo()
	_al_spawnear()


func _physics_process(delta: float) -> void:
	if _muerto:
		return
	_mecanica(delta)              # 1) mecánica del enemigo concreto (extends)
	if _comp != null:
		_comp.pensar(self, delta) # 2) órdenes del comportamiento
	move_and_slide()              # 3) ejecutar
	_danio_por_contacto(delta)    # 4) contacto automático


func _process(_delta: float) -> void:
	if debug_dibujar:
		queue_redraw()


func _draw() -> void:
	if debug_dibujar and _comp != null and _comp.has_method("debug_dibujar_en"):
		_comp.debug_dibujar_en(self)


# ───────────── REFERENCIAS INTERNAS (figura y boca) ─────────────

func _resolver_referencias_internas() -> void:
	# FIGURA
	if figura != null and not is_instance_valid(figura):
		figura = null
	if figura == null:
		var f := get_node_or_null("FiguraConstructor")
		if f is FiguraConstructor:
			figura = f
	if figura == null:
		for hijo in get_children():
			if hijo is FiguraConstructor:
				figura = hijo
				break
	if figura != null and not (figura is FiguraConstructor):
		_avisar_una_vez("figura_tipo",
			"[Enemigo] %s: la figura asignada no usa el script FiguraConstructor." % name)
	# BOCA
	if boca != null and not is_instance_valid(boca):
		boca = null
	if boca == null:
		boca = get_node_or_null("Boca") as Node2D


## Para mecánicas futuras (invocar, se divide): la criatura nueva
## hereda las referencias inyectadas, sin buscar nada por su cuenta.
func heredar_referencias_a(criatura: Node) -> void:
	if criatura == null:
		return
	if "jugador" in criatura and jugador != null:
		criatura.set("jugador", jugador)
	if "arbol" in criatura and arbol != null:
		criatura.set("arbol", arbol)


# ───────────── GANCHOS PARA LAS MECÁNICAS (extends) ─────────────

## Se llama una vez en _ready, antes de _al_spawnear.
func _listo() -> void: pass
## Se llama cada frame físico, antes del comportamiento.
func _mecanica(_delta: float) -> void: pass
## Se llama al aparecer en escena.
func _al_spawnear() -> void: pass
## Se llama tras recibir daño.
func _al_recibir_danio(_cantidad: float) -> void: pass
## Se llama cuando el contacto automático alcanza al objetivo.
func _al_tocar_jugador() -> void: pass
## Se llama justo antes de morir (dividirse, explotar, invocar...).
func _al_morir() -> void: pass


# ───────────── OBJETIVO: JUGADOR O ÁRBOL ─────────────

## A quién perseguir: el jugador si existe y está dentro del aggro;
## en caso contrario (o si es anti-estructura), el árbol.
func objetivo() -> Node2D:
	# Limpieza perezosa: si una referencia quedó liberada, se suelta.
	if jugador != null and not is_instance_valid(jugador):
		jugador = null
	if arbol != null and not is_instance_valid(arbol):
		arbol = null
	if anti_estructura:
		return arbol if arbol != null else jugador
	if jugador != null and (rango_aggro <= 0.0 or distancia_a(jugador) <= rango_aggro):
		return jugador
	return arbol


func distancia_a(nodo: Node2D) -> float:
	if nodo == null:
		return INF
	return global_position.distance_to(nodo.global_position)


func dir_a(nodo: Node2D) -> Vector2:
	if nodo == null:
		return Vector2.ZERO
	return (nodo.global_position - global_position).normalized()


# ───────────── API PARA LOS COMPORTAMIENTOS ─────────────

func velocidad_efectiva() -> float:
	return speed * velocidad_multiplicador


func mover_hacia(punto: Vector2, multiplicador: float = 1.0) -> void:
	var dir := (punto - global_position).normalized()
	velocity = dir * velocidad_efectiva() * multiplicador


func mover_en(dir: Vector2, multiplicador: float = 1.0) -> void:
	velocity = dir.normalized() * velocidad_efectiva() * multiplicador


func detener(freno: float = 10.0) -> void:
	velocity = velocity.move_toward(
		Vector2.ZERO, velocidad_efectiva() * freno * get_physics_process_delta_time())


## Golpe de contacto contra el objetivo actual (jugador O árbol).
## Usa e.damage: ya viene escalado por el WaveManager.
func atacar_objetivo() -> bool:
	var obj := objetivo()
	if obj == null or distancia_a(obj) > radio_contacto:
		return false
	if obj.has_method("recibir_danio"):
		obj.recibir_danio(damage)
		return true
	if obj.has_method("recibir_dano"):
		obj.recibir_dano(damage)
		return true
	_avisar_una_vez("objetivo_metodo",
		"[Enemigo] %s: el objetivo no tiene recibir_danio(). No recibe daño." % name)
	return false


## Origen de los proyectiles: el nodo Boca si existe, si no el centro.
func punto_salida() -> Vector2:
	if boca != null and is_instance_valid(boca):
		return boca.global_position
	return global_position


## Destino de proyectiles/invocaciones: la escena actual (donde el
## WaveManager agrega a los enemigos) o, si no hay, el padre.
func _contenedor_salida() -> Node:
	var cs := get_tree().current_scene
	return cs if cs != null else get_parent()


func disparar_hacia(punto: Vector2) -> void:
	disparar_desde(punto_salida(), punto)


## Dispara desde `punto` hacia `hacia`.
func disparar_desde(punto: Vector2, hacia: Vector2) -> void:
	var dano_final := damage * mult_dano_proyectil
	# PROYECTIL REAL (si la escena ya existe).
	if proyectil != null:
		var p := proyectil.instantiate()
		_contenedor_salida().add_child(p)
		p.global_position = punto
		var dir := (hacia - punto).normalized()
		if p is Node2D:
			p.rotation = dir.angle()
		p.set("direccion", dir)
		p.set("velocidad", velocidad_proyectil)
		p.set("dano", dano_final)   # daño ya escalado por el WaveManager
		return
	# PROYECTIL INTERNO (mientras la escena no exista): rombo neón por código.
	_avisar_una_vez("proyectil",
		"[Enemigo] %s: sin escena de proyectil. Usando proyectil interno." % name)
	var pr := ProyectilDefecto.new()
	pr.direccion = (hacia - punto).normalized()
	pr.velocidad = velocidad_proyectil
	pr.dano = dano_final
	pr.color_proyectil = Color("00ff7f")
	_contenedor_salida().add_child(pr)
	pr.global_position = punto
	pr.rotation = pr.direccion.angle()


# ───────────── DAÑO Y MUERTE ─────────────

func recibir_danio(cantidad: float) -> void:
	if _muerto:
		return
	vida -= cantidad
	recibo_danio.emit(cantidad)
	_al_recibir_danio(cantidad)
	_flash_danio()
	if vida <= 0.0:
		morir()


func morir() -> void:
	if _muerto:
		return
	_muerto = true
	_al_morir()
	murio.emit(self)
	queue_free()   # el WaveManager contabiliza la baja con tree_exited


func _flash_danio() -> void:
	if figura == null or not is_instance_valid(figura):
		return
	var tw := create_tween()
	figura.modulate = Color(1.0, 0.35, 0.35)
	tw.tween_property(figura, "modulate", Color.WHITE, 0.15)


# ───────────── COMPORTAMIENTO: carga e inyección de parámetros ─────────────

## Los parámetros del grupo del tipo elegido, listos para inyectar.
func _datos_comportamiento() -> Dictionary:
	match comportamiento_tipo:
		"enjambre":
			return {
				"vel_extra": enjambre_vel_extra,
				"radio_rodeo": enjambre_radio_rodeo,
				"reeleccion": enjambre_reeleccion,
				"tambalear": enjambre_tambalear,
			}
		"rango":
			return {
				"distancia_ideal": rango_distancia,
				"margen": rango_margen,
				"recarga": rango_recarga,
				"vel_strafe": rango_vel_strafe,
				"dispersion_grados": rango_dispersion,
			}
		"torreta":
			return {
				"alcance": torreta_alcance,
				"recarga": torreta_recarga,
				"balas_porrafaga": torreta_balas,
				"separacion": torreta_separacion,
				"dispersion_grados": torreta_dispersion,
			}
		"embestida":
			return {
				"alcance_deteccion": embestida_alcance,
				"tiempo_apuntado": embestida_tiempo_apuntado,
				"mult_carga": embestida_mult_carga,
				"tiempo_carga": embestida_tiempo_carga,
				"tiempo_descanso": embestida_descanso,
				"mult_dano_carga": embestida_mult_dano,
				"vel_patrulla": embestida_vel_patrulla,
				"telegrafiar": embestida_telegrafiar,
			}
		_:  # melee
			return {
				"radio_ataque": melee_radio,
				"recarga": melee_recarga,
				"mult_persecucion": melee_mult_persecucion,
			}


func _cargar_comportamiento() -> void:
	# 1) Script personalizado del Inspector.
	var script: GDScript = comportamiento_personalizado
	# 2) Archivo del registro, SOLO si ya existe en disco.
	if script == null:
		var ruta: String = COMPORTAMIENTOS.get(comportamiento_tipo, "")
		if ruta != "" and ResourceLoader.exists(ruta):
			script = load(ruta)
			if script == null or not script.can_instantiate():
				_avisar_una_vez("comp_" + comportamiento_tipo,
					"[Enemigo] %s: '%s' existe pero no se pudo instanciar." % [name, ruta])
				script = null
	# 3) Melee interno: nunca falla.
	if script == null:
		_avisar_una_vez("comp_fallback_" + comportamiento_tipo,
			"[Enemigo] %s: comportamiento '%s' no disponible todavía. Usando melee interno."
			% [name, comportamiento_tipo])
		_comp = CompDefecto.new()
	else:
		_comp = script.new()
	# Inyección de parámetros ANTES de iniciar(): así _listo() ve los valores finales.
	if _comp != null and _comp.has_method("configurar"):
		_comp.configurar(_datos_comportamiento())
	if _comp != null and _comp.has_method("iniciar"):
		_comp.iniciar(self)


# ───────────── INTERNOS ─────────────

func _danio_por_contacto(delta: float) -> void:
	if not dano_al_tocar:
		return
	var obj := objetivo()
	if obj == null:
		return
	_t_contacto -= delta
	if _t_contacto > 0.0 or distancia_a(obj) > radio_contacto:
		return
	_t_contacto = periodo_contacto
	if damage > 0.0:
		if obj.has_method("recibir_danio"):
			obj.recibir_danio(damage)
		elif obj.has_method("recibir_dano"):
			obj.recibir_dano(damage)
	_al_tocar_jugador()


func _avisar_una_vez(clave: String, mensaje: String) -> void:
	if _avisos.has(clave):
		return
	_avisos[clave] = true
	push_warning(mensaje)


# ───────────── SUSTITUTOS INTERNOS (mientras no existan los recursos) ─────────────

## Comportamiento melee interno: persigue y ataca por contacto.
class CompDefecto:
	extends RefCounted

	var radio_ataque := 30.0
	var recarga := 1.0
	var _t := 0.0

	func configurar(datos: Dictionary) -> void:
		for clave in datos:
			if clave in self:
				set(clave, datos[clave])

	func iniciar(_e: Enemigo) -> void: pass

	func pensar(e: Enemigo, delta: float) -> void:
		var obj := e.objetivo()
		if obj == null:
			e.detener(); return
		_t -= delta
		if e.distancia_a(obj) > radio_ataque:
			e.mover_hacia(obj.global_position)
		else:
			e.detener()
			if _t <= 0.0 and e.atacar_objetivo():
				_t = recarga


## Proyectil interno: rombo neón construido por código.
## Golpea a lo primero que toque (jugador o árbol): es detección de
## impacto, no identificación de objetivo.
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

	func _ready() -> void:
		var vis := Polygon2D.new()
		vis.polygon = PackedVector2Array([
			Vector2(7, 0), Vector2(-4, 4), Vector2(-2, 0), Vector2(-4, -4)])
		vis.color = color_proyectil
		add_child(vis)
		var cola := Polygon2D.new()
		cola.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(-11, 2), Vector2(-8, 0), Vector2(-11, -2)])
		cola.color = Color(color_proyectil.r, color_proyectil.g, color_proyectil.b, 0.4)
		add_child(cola)

	func _physics_process(delta: float) -> void:
		if _golpeado:
			return
		_t += delta
		if _t > vida_util:
			queue_free()
			return
		position += direccion * velocidad * delta
		for grupo in ["jugador", "arbol"]:
			var j := get_tree().get_first_node_in_group(grupo)
			if j is Node2D and global_position.distance_to(j.global_position) <= radio_golpe:
				_golpeado = true
				if j.has_method("recibir_danio"):
					j.recibir_danio(dano)
				elif j.has_method("recibir_dano"):
					j.recibir_dano(dano)
				queue_free()
				return
