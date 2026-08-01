class_name enemigoNuevo
extends CharacterBody2D

var tiempo_anim: float = randf() * 10.0
var life: int = 30  # ajusta a la vida que quieras

func animar_cuerpo_enemigo(delta: float) -> void:
	var cuerpo_int = $CuerpoInterior as Polygon2D
	var nucleo = $NucleoToxico as Polygon2D

	if cuerpo_int == null:
		return

	tiempo_anim += delta * 8.0

	var deformacion = sin(tiempo_anim) * 0.06
	cuerpo_int.scale.x = 0.8 + deformacion
	cuerpo_int.scale.y = 0.8 - deformacion

	if nucleo != null:
		nucleo.rotation += delta * 2.0

func _physics_process(delta: float) -> void:
	animar_cuerpo_enemigo(delta)

func take_hit(damage: int = 10) -> void:
	life -= damage
	if life <= 0:
		var label = get_tree().current_scene.find_child("TextoBiomasa", true, false)
		if label:
			BiomasaManager.emitir_biomasa(global_position, label.global_position, label.get_node("/root").find_child("ui", true, false))
		self.queue_free()
