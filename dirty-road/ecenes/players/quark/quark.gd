extends Player

@onready var rangeArea = $Area2D/range
@onready var labelVida = $controls/Label
var proyectil = preload("res://ecenes/players/projectile/quark/playerProyectil.tscn")
var power = 'basic' #basic super mega
var onFire: bool = false
var enemi: Node
var tiempo_caminata: float = 0.0

func move():
	var vectorDireccion = Input.get_vector('ui_left','ui_right','ui_up','ui_down')
	velocity = vectorDireccion * speed
	move_and_slide()

func shot(enemi, power):
	if onFire:
		var direction = (enemi.global_position - $aim.global_position).normalized()
		var bullet = proyectil.instantiate()
		bullet.scale = Vector2(0.5,0.5)
		bullet.add_to_group('bullet')
		bullet.global_position = $aim.global_position
		bullet.positionEnemi = direction
		get_tree().current_scene.add_child(bullet)
		

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		onFire = true
		enemi = body



func _on_timer_timeout() -> void:
	if onFire == true:
		shot(enemi, power)

func _on_super_pressed() -> void:
	power = 'super'


func _on_mega_pressed() -> void:
	power = 'mega'

func take_damage(damage):
	life -= damage
	if life == 0:
		get_tree().change_scene_to_file('res://demo/muerte.tscn')


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group('enemi'):
		onFire = false
	
func _physics_process(delta: float) -> void:
	aplicar_pulso_energia(delta)
	animar_sombra(delta)
	labelVida.text = 'vida: ' + str(life)
	move()
	if life <= 0:
		self.queue_free()

# Variable para el ritmo continuo del latido (colócala fuera de la función, al inicio del script)
var tiempo_pulso: float = 0.0

# -------------------------------------------------------------------
# FUNCIÓN DE PULSO DE ENERGÍA (Nodos referenciados internamente)
# -------------------------------------------------------------------
func aplicar_pulso_energia(delta: float) -> void:
	# 1. Obtenemos las referencias a los nodos DENTRO de esta función
	var nucleo = $Nucleo as Polygon2D
	var luz_punta = $LuzPunta as PointLight2D
	
	# Comprobación de seguridad por si los nodos aún no existen o tienen otro nombre
	if nucleo == null or luz_punta == null:
		return
		
	# 2. Acumulamos el tiempo para la onda senoidal
	tiempo_pulso += delta * 5.0
	
	# 3. El núcleo de cristal blanco se expande y contrae
	var factor_pulso: float = 1.0 + sin(tiempo_pulso) * 0.12
	nucleo.scale = Vector2(factor_pulso, factor_pulso)
	
	# 4. La luz de la punta oscila en brillo e intensidad
	luz_punta.energy = 1.8 + sin(tiempo_pulso * 2.0) * 0.5


func animar_sombra(delta: float) -> void:
	# 1. Referencia directa y segura al nodo Sombra
	var sombra = $sombra as Polygon2D
	if sombra == null:
		return
		
	# 2. Si el personaje se está moviendo (velocity > 0)
	if velocity != Vector2.ZERO:
		tiempo_caminata += delta * 18.0
		# La sombra se expande y contrae en X simular el paso al caminar
		sombra.scale.x = 1.0 - sin(tiempo_caminata) * 0.1
	else:
		# Al detenerse, la sombra vuelve suavemente a su tamaño normal
		sombra.scale = sombra.scale.lerp(Vector2.ONE, delta * 10.0)
