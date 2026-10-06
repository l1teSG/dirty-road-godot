class_name Enemigo
extends CharacterBody2D

## ══════════════════════════════════════════════════════════
##  ENEMIGO — Clase principal (ESCENA + GD), integrada al WaveManager.
##
##  CONTRATO:
##  • Jugador y Árbol los identifica el WAVE MANAGER (por grupos) y
##    los inyecta antes de add_child(). Este script NO los exporta.
##    CINTURÓN DE SEGURIDAD: si algo llega nulo (orden de _ready,
##    prueba suelta, jefe por otra vía), se auto-repara por grupos
##    cada frame mientras falte algo — nunca queda sin objetivo.
##  • life / speed / damage llegan YA escalados por oleada/etapa.
##  • El ciclo por frame: reset de órdenes → _mecanica() (del extend)
##    → _comp.pensar() (comportamiento) → move_and_slide() → contacto.
##  • Los comportamientos (comp_*.gd) SOLO dictan órdenes con la API:
##    objetivo(), distancia_a(), dir_a(), mover_hacia(), mover_en(),
##    detener(), atacar_objetivo(), disparar_desde().
##    NUNCA lean e.jugador directo: usen e.objetivo() (así el jefe
##    embiste al árbol y la nube asedia el árbol de lejos).
##  • CONTACTO: si el tronco bloquea el camino, el enemigo lo muerde
##    (además de dañar al jugador por proximidad, si dano_al_tocar).
##  • NOMBRE FLOTANTE: aparece al spawn con animación de entrada y
##    se oculta con el primer golpe. DAÑO FLOTANTE: número con pop
##    de entrada que luego sube y se desvanece. Centrado exacto a
##    cualquier zoom: pivote en el centro LOCAL del Label (size*0.5)
##    y position = centro_deseado - size*0.5. Blanco sin contorno.
## ══════════════════════════════════════════════════════════

signal recibo_danio(cantidad: float)
signal murio(enemigo: Enemigo)

# ───────────── ESTADÍSTICAS ─────────────

## Vida base. El WaveManager la escala por oleada ANTES de add_child.
@export var life: float = 20.0
## Velocidad base (px/s). El WaveManager la escala por etapa.
@export var speed: float = 90.0
## Daño de contacto/ataque. El WaveManager lo escala por etapa.
@export var damage: float = 5.0
@export_range(0.0, 4.0) var velocidad_multiplicador: float = 1.0
## Daño automático al tocar al objetivo (lo activa p. ej. el Petróleo).
@export var dano_al_tocar: bool = false
## Radio de la hurtbox de contacto y alcance del golpe directo.
@export var radio_contacto: float = 22.0
## Segundos entre daños por contacto.
@export_range(0.1, 3.0) var periodo_contacto: float = 1.0
## Recompensa al morir.
@export var recompensa: int = 1

## Si es true (jefes anti-estructura), ignora al jugador y va directo
## al árbol. El daño por contacto sigue funcionando.
@export var anti_estructura: bool = false
## Si el objetivo queda a más de esta distancia, el enemigo vuelve al
## árbol (0 = persigue al jugador a cualquier distancia).
@export var rango_aggro: float = 0.0

# ───────────── REFERENCIAS (OPCIONAL) ─────────────

## Visual poligonal (FiguraConstructor). Vacío = se autodetecta como
## hijo con ese nombre o script.
@export var figura: Node2D
## Marker2D de salida de proyectiles. Vacío = el centro del enemigo.
@export var boca: Node2D
## Escena de proyectil propia. Vacía = usa el proyectil interno.
@export var proyectil: PackedScene

# ───────────── COMPORTAMIENTO ─────────────

@export_category("Comportamiento")
## Lógica que dicta las órdenes cada frame (comp_*.gd).
@export_enum("melee", "enjambre", "rango", "torreta", "embestida") var comportamiento_tipo: String = "melee"
## Script personalizado (opcional). Si va vacío se usa el registro.
@export var comportamiento_personalizado: GDScript
## Dibuja los radios de contacto/persecución del enemigo.
@export var debug_dibujar: bool = false

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
@export_range(0.0, 45.0) var rango_dispersion: float = 6.0

@export_group("Torreta")
@export var torreta_cadencia: float = 1.6
@export var torreta_alcance: float = 280.0

@export_group("Embestida")
@export var embestida_alcance: float = 320.0
@export var embestida_preparacion: float = 0.5
@export_range(1.0, 6.0) var embestida_mult_velocidad: float = 3.0
@export var embestida_danio_extra: float = 0.0
@export var embestida_enfriamiento: float = 2.0

# ───────────── NOMBRE FLOTANTE ─────────────

@export_category("Nombre flotante")
## Muestra el nombre sobre el enemigo al aparecer. Se oculta con el
## primer golpe que recibe.
@export var mostrar_nombre: bool = true
## Texto a mostrar. Vacío = se deriva del nombre de la escena
## (Excavadora_Toxica.tscn → "Excavadora Toxica").
@export var nombre_mostrado: String = ""
## Fuente personalizada (.ttf/.otf). Vacía = la fuente por defecto.
@export var fuente_nombre: Font
## Tamaño aproximado EN PÍXELES DE PANTALLA (con zoom compensado).
@export var tamano_fuente_nombre: int = 13
@export var color_nombre: Color = Color("ffffff")
## Grosor del borde alrededor del nombre (0 = sin borde).
@export_range(0, 12) var contorno_nombre: int = 0
@export var sombra_nombre: bool = false
@export var mayusculas_nombre: bool = false
@export_enum("pop", "ninguna") var entrada_nombre: String = "pop"
## Altura sobre el enemigo. Negativa = arriba. 0 = automática
## según radio_contacto.
@export var altura_nombre: float = 0.0

# ───────────── DAÑO FLOTANTE ─────────────

@export_category("Daño flotante")
## Número flotante con el daño recibido en cada golpe.
@export var mostrar_danio: bool = true
## Fuente personalizada (.ttf/.otf). Vacía = la fuente por defecto.
@export var fuente_danio: Font
## Tamaño aproximado EN PÍXELES DE PANTALLA (con zoom compensado).
@export var tamano_fuente_danio: int = 15
@export var color_danio: Color = Color("ffffff")
## Grosor del borde alrededor de los números (0 = sin borde).
@export_range(0, 12) var contorno_danio: int = 0
@export var sombra_danio: bool = false
@export_enum("pop", "ninguna") var entrada_danio: String = "pop"
## Cuánto sube el número mientras se desvanece (px).
@export var subida_danio: float = 14.0
## Segundos que vive el número flotante.
@export var duracion_numero: float = 0.7

# ───────────── ESTADO INTERNO ─────────────

const COMPORTAMIENTOS: Dictionary = {
	"melee": "res://ecenes/enemies/class/comportamientos/comp_melee.gd",
	"enjambre": "res://ecenes/enemies/class/comportamientos/comp_enjambre.gd",
	"rango": "res://ecenes/enemies/class/comportamientos/comp_rango.gd",
	"torreta": "res://ecenes/enemies/class/comportamientos/comp_torreta.gd",
	"embestida": "res://ecenes/enemies/class/comportamientos/comp_embestida.gd",
}

var vida: float
var jugador: Node2D = null
var arbol: Node2D = null
var _comp: Node = null
var _t_contacto: float = 0.0
var _muerto: bool = false
var _vel_deseada: Vector2 = Vector2.ZERO
var _recarga_interna: float = 0.0
var _aviso_comp: bool = false
var _fallback_aviso: bool = false

var _etiqueta_nombre: Label = null
var _tween_nombre: Tween = null
var _tween_flash: Tween = null
var _numeros: Array[Label] = []


# ───────────── CICLO DE VIDA ─────────────

func _ready() -> void:
	add_to_group("enemigos")
	if figura == null:
		figura = get_node_or_null("FiguraConstructor")
	vida = life  # life llegó YA escalada por el WaveManager
	_cargar_comportamiento()
	_notificar_educacion()
	queue_redraw()
	_al_spawnear()
	_mostrar_nombre()


func _physics_process(delta: float) -> void:
	if _muerto:
		return
	_resolver_referencias_fallback()
	_vel_deseada = Vector2.ZERO     # las órdenes se dictan CADA frame
	_mecanica(delta)                # 1) mecánica del enemigo concreto (extends)
	if _comp != null and is_instance_valid(_comp) and _comp.has_method("pensar"):
		_comp.pensar(self, delta)   # 2) órdenes del comportamiento
	else:
		_melee_interna(delta)       # 2b) respaldo si no hay comp_*.gd
	velocity = _vel_deseada
	move_and_slide()
	_contacto(delta)                # 3) contacto con jugador Y árbol
	_actualizar_zoom_texto()


# ───────────── API PARA COMPORTAMIENTOS (única permitida) ─────────────

## A quién atacar:
##  • anti_estructura → siempre el árbol (jefes).
##  • jugador muerto/ausente → el árbol.
##  • rango_aggro > 0 y el jugador quedó lejos → el árbol (nube de gas).
##  • resto → el jugador.
func objetivo() -> Node2D:
	if anti_estructura:
		return arbol if _valido(arbol) else null
	if _valido(jugador):
		if rango_aggro > 0.0 and _valido(arbol) and distancia_a(jugador) > rango_aggro:
			return arbol
		return jugador
	return arbol if _valido(arbol) else null


func distancia_a(n: Node2D) -> float:
	if not _valido(n):
		return INF
	return global_position.distance_to(n.global_position)


func dir_a(n: Node2D) -> Vector2:
	if not _valido(n):
		return Vector2.ZERO
	return global_position.direction_to(n.global_position)


func velocidad_efectiva() -> float:
	return speed * velocidad_multiplicador


## Órden de movimiento: hacia un punto global.
func mover_hacia(punto: Vector2, multiplicador: float = 1.0) -> void:
	_vel_deseada = global_position.direction_to(punto) * velocidad_efectiva() * multiplicador


## Órden de movimiento: en una dirección (se normaliza sola).
func mover_en(direccion: Vector2, multiplicador: float = 1.0) -> void:
	if direccion.length_squared() < 0.0001:
		_vel_deseada = Vector2.ZERO
		return
	_vel_deseada = direccion.normalized() * velocidad_efectiva() * multiplicador


func detener() -> void:
	_vel_deseada = Vector2.ZERO


## Daña a cualquier objetivo (jugador, árbol, otro enemigo) por la
## vía que exponga: recibir_danio() o take_damage(). Devuelve true
## si conectó.
## Daña a cualquier objetivo (jugador, árbol, otro enemigo) por la
## vía que exponga: recibir_danio() o take_damage(). Devuelve true
## si conectó.
## obj OPCIONAL: sin argumento ataca a objetivo() automáticamente
## (compatible con los comp_*.gd que llaman e.atacar_objetivo()).
func atacar_objetivo(obj: Node2D = null, cantidad: float = -1.0) -> bool:
	if obj == null:
		obj = objetivo()
	if not _valido(obj):
		return false
	var d := damage if cantidad < 0.0 else cantidad
	if obj.has_method("recibir_danio"):
		obj.recibir_danio(d)
		return true
	elif obj.has_method("take_damage"):
		obj.take_damage(int(d))
		return true
	return false
## Dispara desde un origen (usa 'boca' si existe). Con escena de
## proyectil propia la instancia; sin ella usa el proyectil interno.
func disparar_desde(origen: Node2D, direccion: Vector2, dano: float = -1.0, velocidad: float = 260.0) -> void:
	var dir := direccion.normalized()
	if dir == Vector2.ZERO:
		return
	var pos := (origen if _valido(origen) else self).global_position
	if boca != null and _valido(boca):
		pos = boca.global_position
	var d := damage if dano < 0.0 else dano
	if proyectil != null:
		var p := proyectil.instantiate()
		_contenedor_salida().add_child(p)
		if p is Node2D:
			(p as Node2D).global_position = pos
			(p as Node2D).rotation = dir.angle()
		p.set("damage", d)
		p.set("direccion", dir)
		p.set("velocidad", velocidad)
		return
	_crear_proyectil_interno(pos, dir, d, velocidad)


# ───────────── REFERENCIAS (resolución perezosa) ─────────────

## El WaveManager inyecta antes de add_child(); esto SOLO repara si
## algo llegó nulo. Costo cero cuando todo está bien.
func _resolver_referencias_fallback() -> void:
	if not _valido(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	if not _valido(arbol):
		arbol = get_tree().get_first_node_in_group("arbol") as Node2D
	if jugador == null and arbol == null and not _fallback_aviso:
		_fallback_aviso = true
		push_warning("[Enemigo] '%s': sin jugador ni árbol en los grupos 'jugador'/'arbol'. Revisa WaveManager._pasar_referencias()." % name)


func _valido(n: Node) -> bool:
	return n != null and is_instance_valid(n) and n.is_inside_tree()


# ───────────── CONTACTO (jugador y ÁRBOL) ─────────────

func _contacto(delta: float) -> void:
	_t_contacto -= delta
	if not dano_al_tocar or _t_contacto > 0.0:
		return
	if _golpear_por_contacto():
		_t_contacto = periodo_contacto


func _golpear_por_contacto() -> bool:
	var pego := false
	# 1) Jugador por proximidad.
	if _valido(jugador) and distancia_a(jugador) <= radio_contacto:
		if atacar_objetivo(jugador):
			pego = true
			_al_tocar_jugador()
	# 2) Árbol: si el empuje nos dejó rozando el tronco, también lo
	# muerde. Aunque "persiga al jugador", el bloqueo lo castiga.
	for i in get_slide_collision_count():
		var obj: Object = get_slide_collision(i).get_collider()
		if obj is Node and obj != jugador and _es_arbol(obj as Node):
			if atacar_objetivo(obj as Node2D):
				pego = true
				_al_tocar_arbol()
			break
	return pego


func _es_arbol(n: Node) -> bool:
	if n.is_in_group("arbol"):
		return true
	# El que bloquea puede ser un StaticBody2D hijo del árbol.
	return n.get_parent() != null and n.get_parent().is_in_group("arbol")


# ───────────── DAÑO Y MUERTE ─────────────

func recibir_danio(cantidad: float) -> void:
	if _muerto:
		return
	vida -= cantidad
	recibo_danio.emit(cantidad)
	_al_recibir_danio(cantidad)
	_flash_danio()
	_ocultar_nombre()                # el nombre se quita al primer golpe
	_mostrar_numero_danio(cantidad)  # número flotante con entrada animada
	if vida <= 0.0:
		morir()


func morir() -> void:
	if _muerto:
		return
	_muerto = true
	_al_morir()
	murio.emit(self)
	queue_free()   # el WaveManager contabiliza la baja con tree_exited


func porcentaje_vida() -> float:
	return clampf(vida / maxf(life, 0.01), 0.0, 1.0)


func _flash_danio() -> void:
	var objetivo_flash: CanvasItem = figura if _valido(figura) else self
	if _tween_flash != null and _tween_flash.is_valid():
		_tween_flash.kill()
	objetivo_flash.modulate = Color(3.0, 3.0, 3.0, 1.0)
	_tween_flash = create_tween()
	_tween_flash.tween_property(objetivo_flash, "modulate", Color.WHITE, 0.15)


# ───────────── NOMBRE Y DAÑO FLOTANTE ─────────────

func _texto_nombre() -> String:
	if nombre_mostrado.strip_edges() != "":
		return nombre_mostrado
	if scene_file_path != "":
		var t: String = scene_file_path.get_file().get_basename().replace("_", " ")
		return t.to_upper() if mayusculas_nombre else t
	return "Enemigo"


func _altura_nombre() -> float:
	return altura_nombre if altura_nombre != 0.0 else -(radio_contacto + 14.0)


func _zoom_camara() -> float:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return 1.0
	return maxf(cam.zoom.x, 0.01)


func _zoom_inv() -> float:
	return 1.0 / _zoom_camara()


func _crear_label(texto: String, fuente: Font, tam: int, color: Color, contorno: int, sombra: bool) -> Label:
	var lbl := Label.new()
	lbl.text = texto
	var cfg := LabelSettings.new()
	if fuente != null:
		cfg.font = fuente
	cfg.font_size = tam
	cfg.font_color = color
	cfg.outline_size = contorno          # 0 = sin borde
	cfg.outline_color = Color(0, 0, 0, 0.85)
	cfg.shadow_color = Color(0, 0, 0, 0.6) if sombra else Color(0, 0, 0, 0)
	cfg.shadow_offset = Vector2(1, 1)
	lbl.label_settings = cfg
	lbl.z_index = 20
	add_child(lbl)
	lbl.reset_size()
	return lbl


func _mostrar_nombre() -> void:
	if not mostrar_nombre:
		return
	if _etiqueta_nombre == null or not is_instance_valid(_etiqueta_nombre):
		_etiqueta_nombre = _crear_label(_texto_nombre(), fuente_nombre, tamano_fuente_nombre, color_nombre, contorno_nombre, sombra_nombre)
		_etiqueta_nombre.position = Vector2(-_etiqueta_nombre.size.x * 0.5, _altura_nombre())
		_etiqueta_nombre.pivot_offset = _etiqueta_nombre.size * 0.5
	_etiqueta_nombre.visible = true
	if _tween_nombre != null and _tween_nombre.is_valid():
		_tween_nombre.kill()
	_tween_nombre = create_tween()
	if entrada_nombre == "pop":
		_etiqueta_nombre.set_meta("anim", true)
		_etiqueta_nombre.modulate.a = 0.0
		_tween_nombre.set_parallel(true)
		_tween_nombre.tween_property(_etiqueta_nombre, "modulate:a", 1.0, 0.3)
		_tween_nombre.tween_property(_etiqueta_nombre, "scale", Vector2.ONE * _zoom_inv(), 0.25) \
			.from(Vector2.ONE * (_zoom_inv() * 0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween_nombre.chain().tween_callback(func() -> void: _etiqueta_nombre.set_meta("anim", false))
	else:
		_etiqueta_nombre.scale = Vector2.ONE * _zoom_inv()
		_etiqueta_nombre.modulate.a = 0.0
		_tween_nombre.tween_property(_etiqueta_nombre, "modulate:a", 1.0, 0.3)


func _ocultar_nombre() -> void:
	if _etiqueta_nombre == null or not _etiqueta_nombre.visible:
		return
	if _tween_nombre != null and _tween_nombre.is_valid():
		_tween_nombre.kill()
	_tween_nombre = create_tween()
	_tween_nombre.tween_property(_etiqueta_nombre, "modulate:a", 0.0, 0.25)
	_tween_nombre.tween_callback(func() -> void: _etiqueta_nombre.visible = false)


func _mostrar_numero_danio(cantidad: float) -> void:
	if not mostrar_danio:
		return
	var lbl := _crear_label(str(int(round(cantidad))), fuente_danio, tamano_fuente_danio, color_danio, contorno_danio, sombra_danio)
	var centro := Vector2(0.0, _altura_nombre() + 8.0)
	lbl.position = centro - lbl.size * 0.5   # centrado exacto
	lbl.pivot_offset = lbl.size * 0.5        # pivote en centro LOCAL
	var z_inv := _zoom_inv()
	_numeros.append(lbl)
	var tw := create_tween()
	if entrada_danio == "pop":
		lbl.set_meta("anim", true)
		lbl.scale = Vector2.ONE * (z_inv * 0.2)
		lbl.modulate.a = 0.0
		tw.set_parallel(true)
		tw.tween_property(lbl, "scale", Vector2.ONE * z_inv, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(lbl, "modulate:a", 1.0, 0.1)
		tw.chain().tween_callback(func() -> void: lbl.set_meta("anim", false))
	else:
		lbl.scale = Vector2.ONE * z_inv
	# Fase de vida: sube y se desvanece.
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - subida_danio, duracion_numero) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, duracion_numero).set_delay(duracion_numero * 0.4)
	tw.chain().tween_callback(_limpiar_numero.bind(lbl))


func _limpiar_numero(lbl: Label) -> void:
	_numeros.erase(lbl)
	if is_instance_valid(lbl):
		lbl.queue_free()


## Compensa el zoom de la cámara cada frame (solo cuando la etiqueta
## no está animando su entrada, para no pelear con el pop).
func _actualizar_zoom_texto() -> void:
	var z_inv := _zoom_inv()
	var pendientes: Array = [_etiqueta_nombre]
	pendientes.append_array(_numeros)
	for n in pendientes:
		if n is Label and is_instance_valid(n) and n.visible and not n.get_meta("anim", false):
			(n as Label).scale = Vector2.ONE * z_inv


# ───────────── COMPORTAMIENTO (carga y respaldo) ─────────────

func _cargar_comportamiento() -> void:
	_comp = null
	var script_comp: GDScript = comportamiento_personalizado
	if script_comp == null and COMPORTAMIENTOS.has(comportamiento_tipo):
		var ruta: String = COMPORTAMIENTOS[comportamiento_tipo]
		if ResourceLoader.exists(ruta):
			script_comp = load(ruta) as GDScript
	if script_comp != null:
		var instancia: Node = script_comp.new()
		if instancia is Node:
			_comp = instancia
			add_child(_comp)
			if _comp.has_method("iniciar"):
				_comp.iniciar(self)
			return
	if not _aviso_comp:
		_aviso_comp = true
		push_warning("[Enemigo] '%s': sin comp_%s.gd → uso el melee interno." % [name, comportamiento_tipo])


## Respaldo melee: persigue a objetivo() y golpea al llegar.
## Los comp_*.gd lo reemplazan cuando existen.
func _melee_interna(delta: float) -> void:
	_recarga_interna -= delta
	var obj := objetivo()
	if obj == null:
		detener()
		return
	if distancia_a(obj) > melee_radio:
		mover_hacia(obj.global_position, melee_mult_persecucion)
	else:
		detener()
		if _recarga_interna <= 0.0:
			if atacar_objetivo(obj):
				if obj == jugador:
					_al_tocar_jugador()
				elif _es_arbol(obj):
					_al_tocar_arbol()
			_recarga_interna = melee_recarga


# ───────────── PROYECTIL INTERNO (respaldo) ─────────────

func _contenedor_salida() -> Node:
	var escena := get_tree().current_scene
	return escena if escena != null else get_parent()


func _crear_proyectil_interno(pos: Vector2, dir: Vector2, dano: float, vel: float) -> void:
	var area := Area2D.new()
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(6, 0), Vector2(0, 4), Vector2(-6, 0), Vector2(0, -4)])
	poly.color = Color("d81b60")
	area.add_child(poly)
	var col := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 5.0
	col.shape = forma
	area.add_child(col)
	_contenedor_salida().add_child(area)
	area.global_position = pos
	area.rotation = dir.angle()
	area.body_entered.connect(_proyectil_interno_toco.bind(dano))
	area.area_entered.connect(_proyectil_interno_toco.bind(dano))
	var tw := area.create_tween()
	tw.tween_property(area, "global_position", pos + dir * 600.0, 600.0 / vel)
	tw.tween_callback(area.queue_free)


func _proyectil_interno_toco(n: Node, dano: float) -> void:
	if n == null or n == self or n is Enemigo:
		return
	if n.has_method("recibir_danio"):
		n.recibir_danio(dano)
	elif n.has_method("take_damage"):
		n.take_damage(int(dano))


# ───────────── EDUCACIÓN / ENCICLOPEDIA ─────────────

func _notificar_educacion() -> void:
	var edu := get_node_or_null("/root/EducationManager")
	if edu != null and edu.has_method("on_enemy_encountered") and scene_file_path != "":
		edu.on_enemy_encountered(scene_file_path.get_file().get_basename())


# ───────────── GANCHOS PARA MECÁNICAS (extends Enemigo) ─────────────

func _al_spawnear() -> void: pass
func _mecanica(_delta: float) -> void: pass
func _al_recibir_danio(_cantidad: float) -> void: pass
func _al_tocar_jugador() -> void: pass
func _al_tocar_arbol() -> void: pass
func _al_morir() -> void: pass


# ───────────── DEBUG ─────────────

func _draw() -> void:
	if not debug_dibujar:
		return
	draw_arc(Vector2.ZERO, radio_contacto, 0.0, TAU, 32, Color(1.0, 0.4, 0.7, 0.35), 1.0)
	draw_arc(Vector2.ZERO, melee_radio, 0.0, TAU, 32, Color(0.0, 1.0, 0.5, 0.35), 1.0)
	if rango_aggro > 0.0:
		draw_arc(Vector2.ZERO, rango_aggro, 0.0, TAU, 48, Color(1.0, 0.9, 0.2, 0.3), 1.0)
