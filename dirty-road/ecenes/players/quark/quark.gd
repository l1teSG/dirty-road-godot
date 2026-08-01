extends Player

@onready var rangeArea = $Area2D/range
var proyectil = preload("res://ecenes/players/projectile/quark/playerProyectil.tscn")
var power = 'basic' #basic super mega
var onFire: bool = false
var enemi: Node = null
var enemigos_en_rango: Array[Node2D] = []
var tiempo_caminata: float = 0.0

func move():
	var vectorDireccion = Input.get_vector('ui_left','ui_right','ui_up','ui_down')
	velocity = vectorDireccion * speed
	move_and_slide()

func shot(target: Node2D, power) -> void:
	if not onFire or not is_instance_valid(target):
		return

	var direction = (target.global_position - $aim.global_position).normalized()
	var bullet = proyectil.instantiate()
	bullet.scale = Vector2(0.5, 0.5)
	bullet.rotation = direction.angle() 
	bullet.add_to_group('bullet')
	bullet.global_position = $aim.global_position
	bullet.positionEnemi = direction
	get_tree().current_scene.add_child(bullet)

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("¡Colisión detectada con!: ", body.name, " | grupos: ", body.get_groups())
	if body.is_in_group('enemi'):
		enemigos_en_rango.append(body)
		_actualizar_objetivo()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		enemigos_en_rango.erase(body)
		_actualizar_objetivo()

func _actualizar_objetivo() -> void:
	# limpia referencias a enemigos que ya no existen
	enemigos_en_rango = enemigos_en_rango.filter(func(e): return is_instance_valid(e))

	if enemigos_en_rango.is_empty():
		onFire = false
		enemi = null
		return

	# elige siempre el enemigo más cercano al punto de mira
	enemi = enemigos_en_rango[0]
	var dist_min = $aim.global_position.distance_to(enemi.global_position)
	for e in enemigos_en_rango:
		var d = $aim.global_position.distance_to(e.global_position)
		if d < dist_min:
			dist_min = d
			enemi = e

	onFire = true

func _on_timer_timeout() -> void:
	if onFire and is_instance_valid(enemi):
		shot(enemi, power)
	else:
		_actualizar_objetivo()

func _on_super_pressed() -> void:
	power = 'super'

func _on_mega_pressed() -> void:
	power = 'mega'

func take_damage(damage):
	life -= damage
	if life <= 0:
		get_tree().change_scene_to_file('res://demo/muerte.tscn')

func _physics_process(delta: float) -> void:
	aplicar_pulso_energia(delta)
	animar_sombra(delta)

	move()
	if life <= 0:
		self.queue_free()

var tiempo_pulso: float = 0.0
func aplicar_pulso_energia(delta: float) -> void:

	var nucleo = $Nucleo as Polygon2D
	var luz_punta = $LuzPunta as PointLight2D


	if nucleo == null or luz_punta == null:
		return

	tiempo_pulso += delta * 5.0


	var factor_pulso: float = 1.0 + sin(tiempo_pulso) * 0.12
	nucleo.scale = Vector2(factor_pulso, factor_pulso)


	luz_punta.energy = 1.8 + sin(tiempo_pulso * 2.0) * 0.5

func animar_sombra(delta: float) -> void:

	var sombra = $sombra as Polygon2D
	if sombra == null:
		return


	if velocity != Vector2.ZERO:
		tiempo_caminata += delta * 18.0

		sombra.scale.x = 1.0 - sin(tiempo_caminata) * 0.1
	else:

		sombra.scale = sombra.scale.lerp(Vector2.ONE, delta * 10.0)

func _on_ajustes_button_down() -> void:
	$Pausa.visible = true
