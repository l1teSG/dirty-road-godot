class_name SelectorObjetivo
extends RefCounted
## Mantiene los enemigos dentro del rango y devuelve el más cercano.

var en_rango: Array[Node2D] = []


func agregar(cuerpo: Node2D) -> void:
	if not en_rango.has(cuerpo):
		en_rango.append(cuerpo)


func quitar(cuerpo: Node2D) -> void:
	en_rango.erase(cuerpo)


## Más cercano a 'origen' (null si no hay). Limpia de paso los eliminados.
func mas_cercano(origen: Vector2) -> Node2D:
	var mejor: Node2D = null
	var dist_min: float = INF
	for i in range(en_rango.size() - 1, -1, -1):
		var e = en_rango[i]  # sin tipo: puede estar liberado
		if not is_instance_valid(e):
			en_rango.remove_at(i)
			continue
		var d: float = origen.distance_squared_to(e.global_position)
		if d < dist_min:
			dist_min = d
			mejor = e
	return mejor
