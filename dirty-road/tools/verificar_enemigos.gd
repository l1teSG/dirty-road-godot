extends SceneTree

## Verifica que todos los enemigos generados cargan e instancian sin errores
## y que tienen figura, colisión, comportamiento y vida.

const DIR_MAIN := "res://ecenes/enemies/main"


func _initialize() -> void:
	var rutas := _todas(DIR_MAIN)
	var fallos := 0
	for ruta in rutas:
		if not _probar(ruta):
			fallos += 1
	print("[VERIF] escenas probadas=%d  fallos=%d" % [rutas.size(), fallos])
	quit()


func _todas(base: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(base)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with("_enemi.tscn") or f.ends_with("_boss.tscn"):
			out.append(base + "/" + f)
	for sub in d.get_directories():
		out.append_array(_todas(base + "/" + sub))
	return out


func _probar(ruta: String) -> bool:
	var esc := load(ruta) as PackedScene
	if esc == null:
		print("  [FALLO] no carga: ", ruta)
		return false
	var n := esc.instantiate() as Node2D
	if n == null:
		print("  [FALLO] no es Node2D: ", ruta)
		return false
	var fig := n.get_node_or_null("FiguraConstructor")
	var col := n.get_node_or_null("CollisionShape2D")
	var tipo := str(n.get("comportamiento_tipo"))
	var vida := float(n.get("life"))
	var ok := fig != null and col != null and tipo != "" and vida > 0.0
	if not ok:
		print("  [FALLO] incompleto: ", ruta, " fig=", fig, " col=", col, " tipo=", tipo, " vida=", vida)
	else:
		var r := (col.shape as CircleShape2D).radius if col.shape is CircleShape2D else -1.0
		print("  ok %-60s tipo=%-9s vida=%6.0f r=%5.1f" % [ruta.replace(DIR_MAIN + "/", ""), tipo, vida, r])
	n.free()
	return ok
