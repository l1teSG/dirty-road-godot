extends Area2D
class_name BulletGas

## ------------------------------------------------------------
## Proyectil de la Nube de Gas
## Se mueve en línea recta y daña al primer objetivo que toca.
## ------------------------------------------------------------

@export var velocidad: float = 400.0
@export var danio: int = 12
@export var debug_bullet := true

var direction: Vector2 = Vector2.ZERO
var tiempo_vida: float = 0.0

func _ready() -> void:
	top_level = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	if debug_bullet:
		print("=== BULLET DEBUG ===")
		print("Nombre: ", name)
		print("Collision Layer: ", collision_layer)
		print("Collision Mask: ", collision_mask)
		print("Posición inicial: ", global_position)
		print("====================")

func _physics_process(delta: float) -> void:
	tiempo_vida += delta
	
	if direction != Vector2.ZERO:
		global_position += direction * velocidad * delta

	if tiempo_vida > 5.0:
		queue_free()

func inicializar(dir: Vector2, pos_inicial: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()
	global_position = pos_inicial

func _on_body_entered(body: Node2D) -> void:
	if debug_bullet:
		print("=== BODY DETECTADO ===")
		print("Nombre: ", body.name)
		print("Clase: ", body.get_class())
		print("Ruta: ", body.get_path())
		print("Grupos: ", body.get_groups())
		print("Collision Layer: ", body.collision_layer if body is CollisionObject2D else "N/A")
		print("Collision Mask: ", body.collision_mask if body is CollisionObject2D else "N/A")
		print("======================")
	
	# Ignorar enemigos
	if body.is_in_group("enemi"):
		return

	# Dañar al jugador solo si es su CharacterBody2D
	if body.is_in_group("jugador"):
		if body.has_method("recibir_danio"):
			body.recibir_danio(danio)
		if debug_bullet:
			print("Bullet destruida por: ", body.name)
		queue_free()
		return

	# Si el body pertenece al árbol, no destruir la bala.
	# Esperar a que area_entered procese el Area2D del árbol.
	if body.is_in_group("arbol"):
		if debug_bullet:
			print("Body del árbol detectado, esperando area_entered")
		return

	# Cualquier otro body (paredes, etc.) también destruye el proyectil
	if debug_bullet:
		print("Bullet destruida por: ", body.name)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if debug_bullet:
		print("=== AREA DETECTADA ===")
		print("Nombre: ", area.name)
		print("Clase: ", area.get_class())
		print("Ruta: ", area.get_path())
		print("Grupos: ", area.get_groups())
		print("Collision Layer: ", area.collision_layer if area is CollisionObject2D else "N/A")
		print("Collision Mask: ", area.collision_mask if area is CollisionObject2D else "N/A")
		print("======================")
	
	# Solo reaccionar a áreas del grupo "arbol"
	if area.is_in_group("arbol"):
		if area.has_method("recibir_danio"):
			area.recibir_danio(danio)
		if debug_bullet:
			print("Bullet destruida por: ", area.name)
		queue_free()
		return

	# Ignorar cualquier otra área (sensores, hitboxes, etc.)
	# No destruir el proyectil
