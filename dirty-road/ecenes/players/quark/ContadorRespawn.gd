class_name ContadorRespawn
extends Node
## Cuenta regresiva de respawn sobre un Label.
## Un id evita que dos cuentas simultáneas se pisen.

var _label: Label = null
var _id: int = 0
var _tween: Tween = null


func configurar(label: Label) -> void:
	_label = label


func iniciar(tiempo_espera: float) -> void:
	if _label == null:
		return
	_id += 1
	var mi_id: int = _id
	var restantes: int = int(ceil(tiempo_espera))

	_label.visible = true
	_mostrar(restantes)

	while restantes > 0:
		await get_tree().create_timer(1.0).timeout
		if mi_id != _id:
			return  # llegó una cuenta más nueva (o se canceló)
		restantes -= 1
		_mostrar(restantes)

	if mi_id == _id:
		_label.visible = false


func ocultar() -> void:
	_id += 1
	if _label != null:
		_label.visible = false


func _mostrar(segundos: int) -> void:
	_label.text = str(segundos)
	_pop.call_deferred()


func _pop() -> void:
	if _label == null:
		return
	_label.pivot_offset = _label.size / 2.0
	_label.scale = Vector2(1.4, 1.4)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
