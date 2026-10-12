class_name EfectoRegeneracion
extends Node
## Feedback visual de regeneración: barra verde pulsante, partículas y luces.
## Solo visual; la lógica de curar vive en el jugador.
## La energía de LuzPunta la controla AnimacionQuark; aquí solo se tiñe.

const COLOR_REGEN := Color(0.2, 1.0, 0.3, 1.0)

var activo: bool = false

var _barra: ProgressBar = null
var _luz_base: PointLight2D = null
var _luz_punta: PointLight2D = null
var _particulas: GPUParticles2D = null
var _tweens: Array[Tween] = []

var _barra_modulate0: Color = Color.WHITE
var _base_color0: Color = Color.WHITE
var _base_energia0: float = 1.0
var _punta_color0: Color = Color.WHITE


func configurar(barra: ProgressBar, luz_base: PointLight2D, luz_punta: PointLight2D) -> void:
	_barra = barra
	_luz_base = luz_base
	_luz_punta = luz_punta
	if _barra != null:
		_barra_modulate0 = _barra.modulate
	if _luz_base != null:
		_base_color0 = _luz_base.color
		_base_energia0 = _luz_base.energy
	if _luz_punta != null:
		_punta_color0 = _luz_punta.color
	_crear_particulas()


## Idempotente: solo actúa cuando cambia el estado.
func set_activo(valor: bool) -> void:
	if valor == activo:
		return
	activo = valor
	if valor:
		_iniciar()
	else:
		_detener()


func _crear_particulas() -> void:
	var p := GPUParticles2D.new()
	p.name = "ParticulasRegeneracion"
	p.amount = 10
	p.lifetime = 1.0
	p.emitting = false
	p.local_coords = true

	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, -1, 0)
	m.gravity = Vector3.ZERO
	m.initial_velocity_min = 15.0
	m.initial_velocity_max = 30.0
	m.lifetime_randomness = 0.2
	m.scale_min = 0.3
	m.scale_max = 0.6
	m.color = Color(0.2, 1.0, 0.3, 0.8)
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(4.0, 4.0, 0.0)
	p.process_material = m

	add_child(p)
	_particulas = p


func _iniciar() -> void:
	_matar_tweens()

	if _barra != null:
		_barra.pivot_offset = _barra.size / 2.0
		var pulso := create_tween().set_loops()
		pulso.tween_property(_barra, "scale", Vector2(1.08, 1.08), 0.6)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		pulso.tween_property(_barra, "scale", Vector2.ONE, 0.6)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_tweens.append(pulso)

		var tinte := create_tween()
		tinte.tween_property(_barra, "modulate", COLOR_REGEN, 0.3).set_ease(Tween.EASE_IN_OUT)
		_tweens.append(tinte)

	if _particulas != null:
		_particulas.emitting = not _reducir_particulas()

	_pulsar_luz(_luz_base, _base_color0, _base_energia0, true)
	_pulsar_luz(_luz_punta, _punta_color0, 0.0, false)


## Accesibilidad: si "reducir_particulas" está activo, no se emiten partículas.
func _reducir_particulas() -> bool:
	return SaveManager != null and bool(SaveManager.get_ajuste("reducir_particulas", false))


func _pulsar_luz(luz: PointLight2D, color0: Color, energia0: float, con_energia: bool) -> void:
	if luz == null:
		return
	var t := create_tween().set_loops()
	t.tween_property(luz, "color", COLOR_REGEN, 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	if con_energia:
		t.parallel().tween_property(luz, "energy", energia0 * 1.6, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(luz, "color", color0, 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	if con_energia:
		t.parallel().tween_property(luz, "energy", energia0, 0.5)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tweens.append(t)


func _detener() -> void:
	_matar_tweens()

	if _barra != null:
		_barra.scale = Vector2.ONE
		_barra.modulate = _barra_modulate0
	if _particulas != null:
		_particulas.emitting = false
	if _luz_base != null:
		_luz_base.color = _base_color0
		_luz_base.energy = _base_energia0
	if _luz_punta != null:
		_luz_punta.color = _punta_color0


func _matar_tweens() -> void:
	for t in _tweens:
		if t != null and t.is_valid():
			t.kill()
	_tweens.clear()
