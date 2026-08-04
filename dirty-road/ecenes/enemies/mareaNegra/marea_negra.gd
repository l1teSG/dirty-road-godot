class_name MareaNegra
extends enemigoNuevo

## ------------------------------------------------------------
## Enemigo Tanque "Marea Negra"
## Avanza lentamente hacia el Árbol, lo ataca en rango y es
## resistente al empuje.
## ------------------------------------------------------------

# Variables exportables (ajustables en Inspector)
@export var vida_maxima: float = 300.0
@export var velocidad: float = 45.0
@export var resistencia_knockback: float = 0.85          # Recibe solo el 15% del empuje
@export var dano_al_arbol: float = 25.0
@export var intervalo_ataque_arbol: float = 2.5
@export var orbes_biomasa_al_morir: int = 6

# Estado interno
var vida_actual: float
var esta_atacando_arbol: bool = false
var vector_knockback: Vector2 = Vector2.ZERO

# Referencias al Árbol, sistema de biomasa y WaveManager
var tree_node: Node2D = null
var biomass_system: Node = null
var wave_manager: Node = null

# Nodos auxiliares (se crean dinámicamente si no existen en la escena)
var attack_range: Area2D
var attack_timer: Timer

func _ready() -> void:
	super()

	# Registrar en el grupo de enemigos
	add_to_group("enemigos")

	# Inicializar vida
	vida_actual = vida_maxima

	# Buscar el Árbol (grupo "arbol" o "tree")
	tree_node = get_tree().get_first_node_in_group("arbol")
	if tree_node == null:
		tree_node = get_tree().get_first_node_in_group("tree")

	# Buscar sistema de biomasa y WaveManager
	biomass_system = get_tree().get_first_node_in_group("biomasa")
	wave_manager = get_tree().get_first_node_in_group("wave_manager")

	# Asegurar que existe el Area2D de rango de ataque
	attack_range = get_node_or_null("AttackRange")
	if attack_range == null:
		attack_range = Area2D.new()
		attack_range.name = "AttackRange"
		add_child(attack_range)
		attack_range.position = Vector2.ZERO

		var collision_shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 50.0   # Rango de ataque por defecto
		collision_shape.shape = circle
		attack_range.add_child(collision_shape)

	# Configurar el Area2D para detectar al Árbol
	attack_range.collision_layer = 0
	attack_range.collision_mask = 1   # Asume que el Árbol está en la capa 1
	attack_range.monitoring = true
	attack_range.monitorable = false
	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)

	# Asegurar que existe el Timer de ataque
	attack_timer = get_node_or_null("AttackTimer")
	if attack_timer == null:
		attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		add_child(attack_timer)

	attack_timer.wait_time = intervalo_ataque_arbol
	attack_timer.one_shot = false
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _physics_process(delta: float) -> void:
	# Si no hay Árbol, no se mueve ni ataca
	if tree_node == null or not is_instance_valid(tree_node):
		return

	if esta_atacando_arbol:
		# Detiene el movimiento de avance, solo conserva el knockback residual
		velocity = vector_knockback
	else:
		var direccion: Vector2 = (tree_node.global_position - global_position).normalized()
		velocity = direccion * velocidad + vector_knockback

	move_and_slide()

	# Amortiguar el knockback
	vector_knockback = vector_knockback.move_toward(Vector2.ZERO, 300.0 * delta)

# --- Detección de rango de ataque ---
func _on_attack_range_body_entered(body: Node2D) -> void:
	# Solo interesa el Árbol
	if body == tree_node or body.is_in_group("arbol") or body.is_in_group("tree"):
		esta_atacando_arbol = true
		attack_timer.start()

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body == tree_node or body.is_in_group("arbol") or body.is_in_group("tree"):
		esta_atacando_arbol = false
		attack_timer.stop()

func _on_attack_timer_timeout() -> void:
	# Verificar que el Árbol siga existiendo y que seguimos en rango
	if tree_node == null or not is_instance_valid(tree_node):
		esta_atacando_arbol = false
		attack_timer.stop()
		return

	if tree_node.has_method("recibir_dano"):
		tree_node.recibir_dano(dano_al_arbol)
	else:
		push_warning("MareaNegra: el nodo del Árbol no tiene el método 'recibir_dano'.")

# --- Recibir daño y muerte ---
func recibir_dano(cantidad: float, empuje_origen: Vector2 = Vector2.ZERO, fuerza_knockback: float = 0.0) -> void:
	vida_actual -= cantidad

	if empuje_origen != Vector2.ZERO:
		var direccion_empuje: Vector2 = (global_position - empuje_origen).normalized()
		var fuerza_aplicada: float = fuerza_knockback * (1.0 - resistencia_knockback)
		vector_knockback = direccion_empuje * fuerza_aplicada

	if vida_actual <= 0.0:
		_morir()

func _morir() -> void:
	# Notificar al WaveManager si existe
	if wave_manager != null and is_instance_valid(wave_manager):
		if wave_manager.has_method("enemigo_muerto"):
			wave_manager.enemigo_muerto(self)
		else:
			push_warning("MareaNegra: WaveManager no tiene el método 'enemigo_muerto'.")

	# Generar orbes de biomasa
	if biomass_system != null and is_instance_valid(biomass_system):
		if biomass_system.has_method("generar_orbes"):
			biomass_system.generar_orbes(global_position, orbes_biomasa_al_morir)
		else:
			push_warning("MareaNegra: el sistema de biomasa no tiene el método 'generar_orbes'.")

	# Eliminar el nodo
	queue_free()
