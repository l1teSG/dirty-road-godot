class_name NubeGas
extends enemigoNuevo

## ------------------------------------------------------------
## Enemigo a Rango "Nube de Gas"
## Dispara proyectiles desde lejos y huye cuando el jugador
## se acerca demasiado.
## ------------------------------------------------------------

# Variables exportables (ajustables en Inspector)
@export var velocidad_movimiento: float = 85.0
@export var rango_disparo: float = 850.0
@export var rango_huida: float = 140.0
@export var escena_proyectil: PackedScene = preload("res://ecenes/enemies/nubeGas/bullet/bulletGas.tscn")

# Referencias a nodos visuales (asignar en la escena)
@onready var cuerpo_ext: Polygon2D = $CuerpoExterior
@onready var luz: PointLight2D = $PointLight2D

# Estado interno (cooldown de recarga gestionado en evaluar_y_ejecutar_ataque)

func _ready() -> void:
	# Registrar en el grupo de enemigos
	add_to_group("enemi")

	# Ajustar perfil de Nube de Gas sobreescribiendo parámetros heredados
	life = 60
	danio_ataque = 12
	tiempo_recarga = 1.8
	distancia_ataque = 850.0          # Coincide con el nuevo rango de disparo
	distancia_urgencia_arbol = 400.0
	distancia_max_aggro = 500.0
	tiempo_aggro = 3.0


func _physics_process(delta: float) -> void:
	# Ejecuta comportamiento base (animación, selección de objetivo, etc.)
	super(delta)

	# Buscar al jugador para controlar huida
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_tree().get_first_node_in_group("jugador")

	var player_valid: bool = is_instance_valid(player)

	# Control de movimiento y persecución/huida
	if player_valid and global_position.distance_to(player.global_position) <= rango_huida:
		# Huir del jugador si está demasiado cerca
		var dir_opuesta: Vector2 = (global_position - player.global_position).normalized()
		velocity = dir_opuesta * velocidad_movimiento
	elif is_instance_valid(objetivo):
		var dist_objetivo: float = global_position.distance_to(objetivo.global_position)
		if dist_objetivo > rango_disparo:
			# Avanzar hacia el objetivo si está fuera de rango de disparo
			var direccion: Vector2 = (objetivo.global_position - global_position).normalized()
			velocity = direccion * velocidad_movimiento
		else:
			# Dentro del rango de disparo, detenerse para atacar
			velocity = Vector2.ZERO
	else:
		# Sin objetivo válido
		velocity = Vector2.ZERO

	move_and_slide()


func seleccionar_objetivo() -> void:
	# Buscar jugador
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_tree().get_first_node_in_group("jugador")

	if is_instance_valid(player):
		var dist: float = global_position.distance_to(player.global_position)
		# Si el jugador está en rango de huida, priorizarlo para alejarse
		if dist <= rango_huida or en_aggro:
			objetivo = player
			return

	# Si no hay jugador prioritario, usar la lógica de la clase padre (Árbol)
	super()


func evaluar_y_ejecutar_ataque() -> void:
	# Debug: Imprimir cada vez que se llama al método
	print("[NubeGas Debug] evaluar_y_ejecutar_ataque() llamado")

	if not puede_atacar:
		# print("[NubeGas Debug] No ataca: En recarga (puede_atacar = false)")
		return
	if not is_instance_valid(objetivo):
		print("[NubeGas Debug] No ataca: Objetivo no es válido")
		return

	var dist = global_position.distance_to(objetivo.global_position)
	if dist > rango_disparo:
		print("[NubeGas Debug] No ataca: Distancia al objetivo (", dist, ") > rango_disparo (", rango_disparo, ")")
		return

	print("[NubeGas Debug] --- INICIANDO DISPARO ---")
	print("[NubeGas Debug] Objetivo actual: ", objetivo.name, " a distancia: ", dist)

	if escena_proyectil == null:
		print("[NubeGas ERROR] 'escena_proyectil' es NULL. Revisa el Inspector.")
		return

	var bullet = escena_proyectil.instantiate()
	var dir_disparo: Vector2 = (objetivo.global_position - global_position).normalized()
	print("[NubeGas Debug] Direccion de disparo calculada: ", dir_disparo)

	# Agregar a la escena primero
	get_tree().current_scene.add_child(bullet)
	print("[NubeGas Debug] Bala agregada a la escena")

	# Asignar posición global e inyectar dirección después de estar en el árbol
	bullet.global_position = global_position + (dir_disparo * 45.0)
	print("[NubeGas Debug] Bala instanciada en Posicion Global: ", bullet.global_position)

	if bullet.has_method("set_direction"):
		bullet.set_direction(dir_disparo)
	else:
		print("[NubeGas WARNING] El proyectil no tiene el método 'set_direction'")

	_animar_retroceso()

	puede_atacar = false
	await get_tree().create_timer(tiempo_recarga).timeout
	puede_atacar = true


func _animar_retroceso() -> void:
	# Pequeña animación visual de retroceso al disparar
	if not is_instance_valid(cuerpo_ext):
		return

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Comprimir escala brevemente
	tween.tween_property(cuerpo_ext, "scale", Vector2(0.85, 0.85), 0.05)
	if is_instance_valid(luz):
		tween.tween_property(luz, "energy", 2.5, 0.05)

	# Recuperar escala normal
	tween.tween_property(cuerpo_ext, "scale", Vector2.ONE, 0.1).set_delay(0.05)
	if is_instance_valid(luz):
		tween.tween_property(luz, "energy", 1.0, 0.1).set_delay(0.05)
