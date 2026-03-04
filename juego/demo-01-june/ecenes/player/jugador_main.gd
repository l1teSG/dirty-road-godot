extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@export var velocidadMovimiento: float = 150
@export var fuerzaSalto: float = -200
@export var gravedad: float = 398


enum estadosJugador { IDLE, FALL, WALK, RUN, JUMP}
var estadoJugador: estadosJugador = estadosJugador.IDLE
var correrOn: bool = false

func voltearx():
	if Input.is_action_just_pressed('ui_left'):
		$AnimatedSprite2D.flip_h = true
	if Input.is_action_just_pressed('ui_right'):
		$AnimatedSprite2D.flip_h = false
func movimientoVuelo(ejeJugador):
	if not is_on_floor():
		velocity.x = ejeJugador * velocidadMovimiento
func validacionCorrer():
	if Input.is_action_just_pressed("correr"):
		if correrOn == false:
			correrOn = true
		else:
			correrOn = false
		

func movimiento (delta)->void:
	var ejeJugador = Input.get_axis('ui_left','ui_right')
	match estadoJugador:
		estadosJugador.IDLE:
			sprite.play("idle")
			if not is_on_floor():
				estadoJugador = estadosJugador.FALL
			if (Input.is_action_just_pressed('ui_right') or Input.is_action_just_pressed('ui_left')) and velocity.y == 0:
				sprite.stop()
				estadoJugador = estadosJugador.WALK
			if Input.is_action_just_pressed('ui_accept'):
				sprite.stop()
				estadoJugador = estadosJugador.JUMP
		estadosJugador.FALL:
			sprite.play("fall")
			velocity.y += gravedad * delta
			if is_on_floor() and velocity.x == 0:
				sprite.stop()
				estadoJugador = estadosJugador.IDLE
			if is_on_floor() and (velocity.x < 0 or velocity.x > 0):
				sprite.stop()
				estadoJugador = estadosJugador.WALK
		estadosJugador.WALK:
			sprite.play("walk")
			velocity.x = ejeJugador * velocidadMovimiento
			if velocity.x == 0:
				estadoJugador = estadosJugador.IDLE
				sprite.stop()
			if not is_on_floor():
				sprite.stop()
				estadoJugador = estadosJugador.FALL
			if Input.is_action_just_pressed('ui_accept'):
				sprite.stop()
				estadoJugador = estadosJugador.JUMP
			if Input.is_action_just_pressed("ui_accept") and ( Input.is_action_just_pressed('ui_left') or Input.is_action_just_pressed('ui_right') ):
				estadoJugador = estadosJugador.IDLE
			if correrOn:
				estadoJugador = estadosJugador.RUN
		estadosJugador.JUMP:
			sprite.play("jump")
			velocity.y = fuerzaSalto 
			var tiempoSalto = 0
			await get_tree().create_timer(0.3  ).timeout
			tiempoSalto = 1
			if  tiempoSalto == 1:
				tiempoSalto = 0
				estadoJugador = estadosJugador.FALL
		estadosJugador.RUN: 
			sprite.play("run")
			velocity.x = (velocidadMovimiento * 2) * ejeJugador
			if velocity.x == 0:
				correrOn = false
				estadoJugador = estadosJugador.IDLE
			if not is_on_floor():
				estadoJugador = estadosJugador.FALL
			if correrOn == false:
				estadoJugador = estadosJugador.WALK
			if Input.is_action_just_pressed('ui_accept'):
				sprite.stop()
				estadoJugador = estadosJugador.JUMP                    
	movimientoVuelo(ejeJugador)

func _physics_process(delta: float) -> void:
	movimiento(delta)
	voltearx()
	validacionCorrer()
	move_and_slide()
 
