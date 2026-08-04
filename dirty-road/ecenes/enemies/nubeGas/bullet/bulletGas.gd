extends Area2D

## ------------------------------------------------------------
## Proyectil de la Nube de Gas
## Se mueve en línea recta y daña al primer objetivo que toca.
## ------------------------------------------------------------

@export var velocidad: float = 400.0
@export var danio: int = 12

var direction: Vector2 = Vector2.ZERO
var tiempo_vida: float = 0.0

func _ready() -> void:
	print("[BulletGas Debug] _ready() llamado. top_level = true")
	top_level = true # Desconecta la posición del transform del padre si fue instanciado como hijo
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		print("[BulletGas Debug] Señal body_entered conectada")
	else:
		print("[BulletGas Debug] Señal body_entered ya estaba conectada")

func _physics_process(delta: float) -> void:
	tiempo_vida += delta
	
	if direction != Vector2.ZERO:
		var movimiento = direction * velocidad * delta
		global_position += movimiento
		# Debug: imprimir movimiento cada 0.5 segundos para no saturar consola
		if int(tiempo_vida * 2) % 10 == 0: # cada 0.5s aprox
			print("[BulletGas Debug] Frame: dirección=", direction, " velocidad=", velocidad, " delta=", delta, " posición=", global_position)

	if tiempo_vida > 5.0:
		print("[BulletGas Debug] Tiempo de vida superó 5s, destruyendo")
		queue_free()

func set_direction(dir: Vector2) -> void:
	print("[BulletGas Debug] set_direction() llamado con dir=", dir)
	direction = dir.normalized()
	rotation = direction.angle()
	print("[BulletGas Debug] dirección establecida: ", direction, " rotación: ", rotation)

func _on_body_entered(body: Node2D) -> void:
	print("[BulletGas Debug] Colisión con: ", body.name, " (grupo enemi? ", body.is_in_group("enemi"), ")")
	# Ignorar a los enemigos del grupo "enemi"
	if body.is_in_group("enemi"):
		print("[BulletGas Debug] Ignorando colisión con enemigo")
		return

	# Dañar al jugador o árbol
	if body.has_method("take_damage"):
		print("[BulletGas Debug] Dañando mediante 'take_damage'")
		body.take_damage(danio)
	elif body.has_method("recibir_danio"):
		print("[BulletGas Debug] Dañando mediante 'recibir_danio'")
		body.recibir_danio(danio)
	else:
		print("[BulletGas Debug] El cuerpo impactado no tiene método de daño")

	print("[BulletGas Debug] Destruyendo proyectil tras impacto")
	queue_free()
