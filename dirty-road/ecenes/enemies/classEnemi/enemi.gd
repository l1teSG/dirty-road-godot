class_name enemigoNuevo
extends CharacterBody2D

var tiempo_anim: float = randf() * 10.0 # Inicio aleatorio para que no se muevan idénticos

func animar_cuerpo_enemigo(delta: float) -> void:
	var cuerpo_int = $CuerpoInterior as Polygon2D
	var nucleo = $NucleoToxico as Polygon2D
	
	if cuerpo_int == null:
		return
		
	tiempo_anim += delta * 8.0
	
	# Efecto de deformación/respiración al caminar
	var deformacion = sin(tiempo_anim) * 0.06
	cuerpo_int.scale.x = 0.8 + deformacion
	cuerpo_int.scale.y = 0.8 - deformacion
	
	if nucleo != null:
		nucleo.rotation += delta * 2.0 # El núcleo gira lentamente

func _physics_process(delta: float) -> void:
	# ... (código de movimiento que ya tenías hacia el árbol) ...
	
	animar_cuerpo_enemigo(delta)
