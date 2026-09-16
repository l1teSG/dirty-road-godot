class_name MareaNegra
extends enemigoNuevo

## ------------------------------------------------------------
## Enemigo Tanque "Marea Negra"
## Avanza lentamente hacia el Árbol, lo ataca en rango y es
## resistente al empuje.
## ------------------------------------------------------------

# Variables exportables (ajustables en Inspector)
@export var velocidad_movimiento: float = 40.0
@export var resistencia_knockback: float = 0.85   # Absorbe el 85% del empuje recibido
@export var fuerza_friccion_knockback: float = 350.0

# Referencias a nodos visuales (asignar en la escena)
@onready var cuerpo_ext: Polygon2D = $CuerpoExterior
@onready var cuerpo_int: Polygon2D = $CuerpoInterior
@onready var nucleo: Polygon2D = $NucleoToxico
@onready var luz: PointLight2D = $PointLight2D

# Estado interno
var vector_knockback: Vector2 = Vector2.ZERO
var esta_animando_ataque: bool = false

func _ready() -> void:
	configurar_etiqueta_nombre("Marea Negra")

	# Registrar en el grupo de enemigos (usa "enemi" como el resto del proyecto)
	add_to_group("enemi")

	# Forzar perfil de Tanque sobreescribiendo parámetros heredados
	life = 300
	danio_ataque = 25
	tiempo_recarga = 2.5
	distancia_ataque = 50.0          # Damos margen para golpear al jugador
	distancia_urgencia_arbol = 250.0 # No anula la detección de proximidad
	distancia_max_aggro = 50.0       # Rango de aggro ultra reducido
	tiempo_aggro = 0.5               # Pierde el aggro del jugador casi de inmediato


func _physics_process(delta: float) -> void:
	super(delta)

	seleccionar_objetivo()
	evaluar_y_ejecutar_ataque()
	mover(delta)
	move_and_slide()


func mover(delta: float) -> void:
	if is_instance_valid(objetivo):
		var dist: float = global_position.distance_to(objetivo.global_position)
		if dist > distancia_ataque:
			var direccion: Vector2 = (objetivo.global_position - global_position).normalized()
			velocity = (direccion * velocidad_movimiento) + vector_knockback
		else:
			velocity = vector_knockback
	else:
		velocity = vector_knockback

	# Amortiguar el knockback progresivamente
	vector_knockback = vector_knockback.move_toward(Vector2.ZERO, fuerza_friccion_knockback * delta)


func seleccionar_objetivo() -> void:
	# Prioriza al jugador si está en rango de ataque
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_tree().get_first_node_in_group("jugador")

	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= distancia_ataque:
		objetivo = player
		return

	# Si no, ejecuta la lógica estándar de la clase padre
	super()


func evaluar_y_ejecutar_ataque() -> void:
	# Sobrescribe el método heredado para añadir animación de golpe
	if not puede_atacar:
		return

	if not is_instance_valid(objetivo):
		return

	if global_position.distance_to(objetivo.global_position) <= distancia_ataque:
		# Disparar la animación de golpe justo antes de infligir daño
		_animar_golpe()
		# Infligir daño al objetivo (jugador o árbol)
		if objetivo.has_method("recibir_danio"):
			objetivo.recibir_danio(danio_ataque)
		elif objetivo.has_method("take_damage"):
			objetivo.take_damage(danio_ataque)
		# Iniciar cooldown de recarga
		puede_atacar = false
		# (El cooldown se restablece en la clase padre mediante un Timer o similar)


func _animar_golpe() -> void:
	if esta_animando_ataque:
		return

	esta_animando_ataque = true

	# Guardar valores originales para restaurar después
	var escala_original: Vector2 = cuerpo_ext.scale
	var energia_original: float = luz.energy

	# Crear un Tween paralelo
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Fase 1: Carga / Anticipación (0.2s)
	tween.tween_property(cuerpo_ext, "scale", Vector2(0.7, 0.7), 0.2)
	tween.tween_property(cuerpo_int, "scale", Vector2(0.7, 0.7), 0.2)
	tween.tween_property(nucleo, "scale", Vector2(0.7, 0.7), 0.2)
	tween.tween_property(luz, "energy", 2.0, 0.2)

	# Fase 2: Impacto / Embestida (0.15s)
	tween.tween_property(cuerpo_ext, "scale", Vector2(1.35, 1.35), 0.15)
	tween.tween_property(cuerpo_int, "scale", Vector2(1.35, 1.35), 0.15)
	tween.tween_property(nucleo, "scale", Vector2(1.5, 1.5), 0.15)  # Núcleo más expandido
	tween.tween_property(luz, "energy", 3.0, 0.15)

	# Fase 3: Recuperación (0.25s) con TRANS_BACK y EASE_OUT
	tween.tween_property(cuerpo_ext, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cuerpo_int, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(nucleo, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(luz, "energy", energia_original, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Al finalizar, restablecer el flag
	tween.finished.connect(func():
		esta_animando_ataque = false
	)


func recibir_danio(cantidad: int, atacante: Node2D = null) -> void:
	# Aplicar knockback reducido por la resistencia del tanque
	if atacante != null and is_instance_valid(atacante):
		var dir_empuje: Vector2 = (global_position - atacante.global_position).normalized()
		vector_knockback = dir_empuje * (80.0 * (1.0 - resistencia_knockback))

	# Delegar el resto del daño (resta de vida, comprobación de muerte,
	# emisión de biomasa y eliminación) al método base
	super(cantidad, atacante)


func take_hit(damage: int = 10) -> void:
	recibir_danio(damage)
