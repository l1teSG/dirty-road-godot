extends enemigoNuevo

# ── Configuración exportada ────────────────────────────
@export var speed: float = 100.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.5
@export var attack_range: float = 45.0
@export var aggro_range: float = 120.0

# ── Referencias a objetivos ────────────────────────────
var tree_target: Node2D = null
var current_target: Node2D = null

# ── Estado de ataque ───────────────────────────────────
var can_attack: bool = true


func _ready() -> void:
	tree_target = get_tree().get_first_node_in_group("arbol")


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


## Selecciona el objetivo actual: exclusivamente el árbol.
## Si el árbol ha sido destruido (no existe o dejó de ser válido),
## el enemigo se queda sin objetivo.
func _elegir_objetivo() -> void:
	if tree_target != null and is_instance_valid(tree_target):
		current_target = tree_target
		return

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
