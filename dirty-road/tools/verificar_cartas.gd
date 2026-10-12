extends SceneTree

## ══════════════════════════════════════════════════════════
##  VERIFICADOR DE CARTAS
##  Comprueba la coherencia de las 4 fuentes de datos de las cartas:
##    • assets/cards/catalogoCards.gd     (nombre, rareza, precio)
##    • assets/cards/descripciones.gd     (texto por nombre)
##    • assets/cards/mejorasConfig.tres   (efectos por slug)
##    • scripts/mejoras_manager.gd        (EFECTOS fallback por slug)
##
##  Uso:
##    godot --headless --script res://tools/verificar_cartas.gd
##  Sale con código 1 si hay fallos.
## ══════════════════════════════════════════════════════════

const RUTA_CATALOGO := "res://assets/cards/catalogoCards.gd"
const RUTA_DESCRIPCIONES := "res://assets/cards/descripciones.gd"
const RUTA_EFECTOS_TRES := "res://assets/cards/mejorasConfig.tres"
const RUTA_MANAGER := "res://scripts/mejoras_manager.gd"
const RUTA_SAVE := "res://scripts/save_manager.gd"
const RUTA_CARTAS_CONFIG := "res://ecenes/cards/CartasConfig.gd"

const RAREZAS := ["Común", "Rara", "Épica", "Legendaria"]
const OPS := ["pct", "add", "mult"]

var _fallos: int = 0
var _avisos: int = 0


func _initialize() -> void:
	print("[CARTAS] Verificando catálogo, descripciones y efectos...")

	var catalogo: Array = _cargar_catalogo()
	var descripciones: Dictionary = _cargar_descripciones()
	var efectos_tres: Dictionary = _cargar_efectos_tres()
	var efectos_manager: Dictionary = _cargar_efectos_manager()
	var stats_validos: Dictionary = _stats_validos()
	var costos: Dictionary = _costos()

	if catalogo.is_empty():
		printerr("  [FALLO] catálogo vacío o no cargó.")
		_fallos += 1

	# ── Recorrido del catálogo ──
	var nombres := {}
	var slugs := {}
	for entrada in catalogo:
		var nombre := str(entrada.get("nombre", ""))
		var rareza := str(entrada.get("rareza", ""))
		var precio := int(entrada.get("precio", -1))

		if nombre.is_empty():
			_fallo("entrada sin nombre: %s" % [entrada])
			continue
		if nombres.has(nombre):
			_fallo("nombre DUPLICADO: %s" % nombre)
		nombres[nombre] = true

		var slug := _slug(nombre)
		if slugs.has(slug):
			_fallo("slug DUPLICADO: %s (%s)" % [slug, nombre])
		slugs[slug] = true

		if not RAREZAS.has(rareza):
			_fallo("%s: rareza inválida '%s'" % [nombre, rareza])
		elif precio != int(costos.get(rareza, -1)):
			_fallo("%s: precio %d != costo_de(%s)=%d" % [nombre, precio, rareza, int(costos.get(rareza, -1))])

		# Descripción.
		var desc := str(descripciones.get(nombre, ""))
		if desc.strip_edges().is_empty():
			_fallo("%s: sin descripción" % nombre)

		# Efectos (tres y manager) por slug.
		var en_tres := efectos_tres.has(slug)
		var en_manager := efectos_manager.has(slug)
		if not en_tres:
			_fallo("%s: sin efecto en mejorasConfig.tres (%s)" % [nombre, slug])
		if not en_manager:
			_fallo("%s: sin efecto en EFECTOS (%s)" % [nombre, slug])

		var lista: Array = efectos_tres.get(slug, efectos_manager.get(slug, []))
		if lista.is_empty():
			_fallo("%s: efecto vacío" % nombre)
		for ef in lista:
			if not (ef is Array) or (ef as Array).size() < 3:
				_fallo("%s: efecto mal formado: %s" % [nombre, ef])
				continue
			var ruta := str(ef[0])
			var op := str(ef[1])
			if not stats_validos.has(ruta):
				_fallo("%s: ruta de stat inválida '%s'" % [nombre, ruta])
			if not OPS.has(op):
				_fallo("%s: operación inválida '%s'" % [nombre, op])

	# ── Sobrantes en otras fuentes ──
	for n in descripciones.keys():
		if not nombres.has(n):
			_aviso("descripción sin carta en el catálogo: %s" % n)
	for slug in efectos_tres.keys():
		if not slugs.has(slug):
			_aviso("efecto en .tres sin carta: %s" % slug)
	for slug in efectos_manager.keys():
		if not slugs.has(slug):
			_aviso("efecto en EFECTOS sin carta: %s" % slug)

	# ── Resumen ──
	print("[CARTAS] cartas=%d  descripciones=%d  efectos(.tres)=%d  efectos(EFECTOS)=%d"
			% [nombres.size(), descripciones.size(), efectos_tres.size(), efectos_manager.size()])
	print("[CARTAS] fallos=%d  avisos=%d" % [_fallos, _avisos])
	if _fallos == 0:
		print("[CARTAS] ✅ OK")
	else:
		print("[CARTAS] ❌ hay %d fallo(s)" % _fallos)
	quit(1 if _fallos > 0 else 0)


# ───────────── CARGA ─────────────

func _cargar_catalogo() -> Array:
	var s := load(RUTA_CATALOGO)
	if s == null:
		return []
	return s.get("CATALOGO")


func _cargar_descripciones() -> Dictionary:
	var s := load(RUTA_DESCRIPCIONES)
	if s == null:
		return {}
	# DescripcionesCartas.get_datos() es estático.
	var inst = s.new() if s.can_instantiate() else s
	if inst == null:
		return {}
	if inst.has_method("get_datos"):
		return inst.get_datos()
	return {}


func _cargar_efectos_tres() -> Dictionary:
	if not ResourceLoader.exists(RUTA_EFECTOS_TRES):
		return {}
	var res := load(RUTA_EFECTOS_TRES)
	if res == null:
		return {}
	var e = res.get("efectos")
	return e if e is Dictionary else {}


func _cargar_efectos_manager() -> Dictionary:
	var s := load(RUTA_MANAGER)
	if s == null:
		return {}
	var e = s.get_script_constant_map().get("EFECTOS", {})
	return e if e is Dictionary else {}


## Conjunto de rutas de stats válidas: "grupo.clave" desde DATOS_DEFECTO.stats.
func _stats_validos() -> Dictionary:
	var out := {}
	var s := load(RUTA_SAVE)
	if s == null:
		return out
	var datos = s.get_script_constant_map().get("DATOS_DEFECTO", {})
	var stats = datos.get("stats", {}) if datos is Dictionary else {}
	if stats is Dictionary:
		for grupo in stats.keys():
			var sub = stats[grupo]
			if sub is Dictionary:
				for clave in sub.keys():
					out["%s.%s" % [grupo, clave]] = true
	return out


## Costo por rareza (defecto del .tres/script; fallback a los valores base).
func _costos() -> Dictionary:
	var out := {"Común": 20, "Rara": 35, "Épica": 60, "Legendaria": 100}
	var res = load("res://assets/cards/cartasConfig.tres")
	if res == null:
		res = load(RUTA_CARTAS_CONFIG)
	var inst = null
	if res is GDScript and res.can_instantiate():
		inst = res.new()
	elif res is Resource:
		inst = res
	if inst != null and inst.has_method("costo_de"):
		for r in RAREZAS:
			out[r] = int(inst.call("costo_de", r))
	return out


# ───────────── HELPERS ─────────────

func _slug(texto: String) -> String:
	var t := texto.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		t = t.replace(par[0], par[1])
	var out := ""
	for c in t:
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
	return out


func _fallo(msg: String) -> void:
	_fallos += 1
	print("  [FALLO] ", msg)


func _aviso(msg: String) -> void:
	_avisos += 1
	print("  [aviso] ", msg)