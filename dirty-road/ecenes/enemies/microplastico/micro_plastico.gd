extends enemigoNuevo

# ── Configuración exportada ────────────────────────────
@export var speed: float = 100.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.5
@export var attack_range: float = 45.0
@export var aggro_range: float = 120.0

# ── Referencias a objetivos ────────────────────────────
var tree_target: Node2D = null
var player_target: Node2D = null
var current_target: Node2D = null

# ── Estado de ataque ───────────────────────────────────
var can_attack: bool = true


func _ready() -> void:
	tree_target = get_tree().get_first_node_in_group("arbol")
	player_target = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	animar_cuerpo_enemigo(delta)

	_elegir_objetivo()

	if current_target == null:
		return

	var distancia = global_position.distance_to(current_target.global_position)

	if distancia <= attack_range:
		velocity = Vector2.ZERO
		move_and_slide()
		atacar(current_target)
	else:
		var direccion = (current_target.global_position - global_position).normalized()
		velocity = direccion * speed
		move_and_slide()


## Selecciona el objetivo actual según prioridad:
## 1. Si el jugador está dentro del rango de agresión, se convierte en objetivo.
## 2. Si no, el árbol (si existe) es el objetivo principal.
## 3. Si el árbol ha sido destruido, el jugador es el objetivo por defecto.
func _elegir_objetivo() -> void:
	# Verificar si el jugador está dentro del rango de agresión
	if player_target != null and is_instance_valid(player_target):
		var dist_player = global_position.distance_to(player_target.global_position)
		if dist_player <= aggro_range:
			current_target = player_target
			return

	# Si el árbol existe y es válido, es el objetivo principal
	if tree_target != null and is_instance_valid(tree_target):
		current_target = tree_target
		return

	# Si no hay árbol, el jugador es el objetivo por defecto
	if player_target != null and is_instance_valid(player_target):
		current_target = player_target
		return

	# Si no hay ningún objetivo válido, se queda sin objetivo
	current_target = null


## Aplica daño al objetivo si está dentro del rango de ataque y respeta el
## cooldown. Después de atacar, inicia un temporizador para restablecer
## can_attack.
func atacar(target: Node2D) -> void:
	if not can_attack:
		return

	if not is_instance_valid(target):
		return

	if not target.has_method("take_damage"):
		return

	target.call("take_damage", damage)
	can_attack = false

	# Esperar el cooldown antes de poder atacar de nuevo
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
