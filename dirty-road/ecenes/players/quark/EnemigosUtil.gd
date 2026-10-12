class_name EnemigosUtil
extends RefCounted
## Utilidades estáticas para tratar con enemigos viejos ('enemi')
## y nuevos ('enemigos') sin que el resto del código lo sepa.
## Requiere Godot 4.1+ (static var).

const GRUPOS: Array[String] = ["enemigos", "enemi"]

## Script -> cantidad de argumentos de recibir_danio (cacheado).
static var _cache_aridad: Dictionary = {}


static func es_enemigo(nodo: Node) -> bool:
	for grupo in GRUPOS:
		if nodo.is_in_group(grupo):
			return true
	return false


## Todos los enemigos válidos, sin duplicados (dedupe O(1) con Dictionary).
static func vivos(tree: SceneTree) -> Array[Node2D]:
	var vistos: Dictionary = {}
	var lista: Array[Node2D] = []
	for grupo in GRUPOS:
		for nodo in tree.get_nodes_in_group(grupo):
			if nodo is Node2D and not vistos.has(nodo):
				vistos[nodo] = true
				lista.append(nodo)
	return lista


## Daña respetando el contrato de cada enemigo:
## • Nuevo: recibir_danio(cantidad)
## • Viejo: recibir_danio(cantidad, fuente)
## • Fallback: take_damage(int)
static func danar(enemigo: Node, cantidad: float, fuente: Node = null) -> void:
	if not is_instance_valid(enemigo):
		return
	if enemigo.has_method("recibir_danio"):
		if _aridad(enemigo, "recibir_danio") == 2:
			enemigo.call("recibir_danio", cantidad, fuente)
		else:
			enemigo.call("recibir_danio", cantidad)
	elif enemigo.has_method("take_damage"):
		enemigo.call("take_damage", roundi(cantidad))


static func _aridad(nodo: Node, metodo: String) -> int:
	var clave: Variant = nodo.get_script()
	if _cache_aridad.has(clave):
		return _cache_aridad[clave]
	var n: int = 1
	for m in nodo.get_method_list():
		if m.get("name", "") == metodo:
			n = (m.get("args", []) as Array).size()
			break
	_cache_aridad[clave] = n
	return n
