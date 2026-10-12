extends SceneTree

## ══════════════════════════════════════════════════════════
##  GENERADOR FASE A — Ensambla los 36 enemigos que faltan
##  (etapas 2..10: 27 normales + 9 jefes) y sus EtapaConfig.
##
##  Uso:  godot --headless --script res://tools/generar_enemigos.gd
##
##  Por cada enemigo normal:
##    • ecenes/enemies/main/<rango>/<shape>/<shape>_enemi.tscn
##    • ecenes/enemies/main/<rango>/<shape>/<shape>.tres   (EnemigoOleadaConfig)
##  Por cada jefe:
##    • ecenes/enemies/main/<rango>/boss/<shape>_boss.tscn
##  Por cada etapa:
##    • ecenes/enemies/etapas/etapa_<NN>.tres              (EtapaConfig)
##
##  La figura se copia del shape (assets/stage/enemis/stages), el radio de
##  colisión se calcula de los vértices, y los stats salen de las tablas de
##  abajo. NO toca la etapa 1 (ya existe).
## ══════════════════════════════════════════════════════════

const BASE_ENEMIGO := "res://ecenes/enemies/class/clase_enemigo.tscn"
const SCRIPT_OLEADA := preload("res://scripts/enemigo_oleada_config.gd")
const SCRIPT_ETAPA := preload("res://scripts/etapa_config.gd")
const SCRIPT_MEC := preload("res://ecenes/enemies/class/MecanicasEnemigo.gd")
const SCRIPT_ANIM := preload("res://ecenes/enemies/class/AnimacionEnemigo.gd")
const SCRIPT_BOSS := preload("res://ecenes/enemies/class/BossAttackComponent.gd")
const DATA_EDU := preload("res://scripts/education/education_data_stages.gd")
const FUENTE := "res://themes/Chakra_Petch/ChakraPetch-BoldItalic.ttf"
const DIR_STAGES := "res://assets/stage/enemis/stages"
const DIR_MAIN := "res://ecenes/enemies/main"
const DIR_ETAPAS := "res://ecenes/enemies/etapas"

# ── Stats base por arquetipo ──
const TIPO_DEF := {
	"enjambre":  {"vida": 22.0,  "vel": 150.0, "danio": 10.0, "contacto": true},
	"melee":     {"vida": 65.0,  "vel": 80.0,  "danio": 18.0, "contacto": false},
	"rango":     {"vida": 26.0,  "vel": 95.0,  "danio": 9.0,  "contacto": false},
	"torreta":   {"vida": 90.0,  "vel": 60.0,  "danio": 12.0, "contacto": false},
	"embestida": {"vida": 80.0,  "vel": 75.0,  "danio": 22.0, "contacto": true},
}

# ── Overrides por enemigo normal (clave = id educativo normalizado) ──
const NORMALES := {
	"lataoxidada":        {"tipo": "enjambre"},
	"neumaticoquemado":   {"tipo": "embestida"},
	"bolsaplastica":      {"tipo": "enjambre", "vida": 20.0, "vel": 170.0},
	"botellaplastico":    {"tipo": "melee", "vida": 150.0, "vel": 55.0, "danio": 24.0},
	"botellalanzadora":   {"tipo": "rango", "vida": 30.0},
	"redfantasma":        {"tipo": "melee", "vida": 70.0},
	"humofabrica":        {"tipo": "rango"},
	"chimenea":           {"tipo": "torreta"},
	"hollin":             {"tipo": "melee", "vida": 45.0},
	"gotaacida":          {"tipo": "enjambre", "vida": 18.0},
	"charcoacido":        {"tipo": "melee", "vida": 75.0},
	"nubeacida":          {"tipo": "rango"},
	"basuraelectronica":  {"tipo": "enjambre"},
	"cableelectrico":     {"tipo": "torreta"},
	"bateriatoxica":      {"tipo": "embestida"},
	"residuoradiactivo":  {"tipo": "torreta"},
	"barrilexplosivo":    {"tipo": "embestida"},
	"mutante":            {"tipo": "melee", "vida": 90.0},
	"dronpesticida":      {"tipo": "rango"},
	"nubefumigacion":     {"tipo": "rango"},
	"plaga":              {"tipo": "enjambre", "vida": 14.0, "vel": 190.0},
	"talador":            {"tipo": "melee", "vida": 85.0, "anti_estructura": true},
	"motosierra":         {"tipo": "embestida", "vel": 95.0},
	"incendio":           {"tipo": "enjambre", "vida": 20.0},
	"olacalor":           {"tipo": "torreta", "vida": 110.0},
	"tormenta":           {"tipo": "rango", "vida": 34.0},
	"deshielo":           {"tipo": "melee", "vida": 160.0, "vel": 52.0},
}

# ── Jefes (clave = id educativo normalizado) ──
const JEFES := {
	"vertederoviviente":    {"tipo": "embestida", "vida": 1200.0},
	"islaplastico":         {"tipo": "embestida", "vida": 1300.0},
	"chimeneagigante":      {"tipo": "torreta",   "vida": 1500.0},
	"geiseracido":          {"tipo": "torreta",   "vida": 1400.0},
	"montanachatarra":      {"tipo": "embestida", "vida": 1500.0},
	"reactorroto":          {"tipo": "rango",     "vida": 1400.0},
	"helicopterofumigador": {"tipo": "rango",     "vida": 1450.0},
	"aserraderoandante":    {"tipo": "embestida", "vida": 1650.0},
	"calentamientoglobal":  {"tipo": "embestida", "vida": 2000.0},
}

# ── Mecánicas especiales por enemigo (clave = id educativo normalizado) ──
const MECANICAS := {
	"bolsaplastica":       {"es_aereo": true},
	"redfantasma":         {"aura_ralentiza": true, "ralentiza_pct": 0.35, "ralentiza_radio": 110.0},
	"hollin":              {"divide_al_morir": true, "divide_cantidad": 2},
	"gotaacida":           {"deja_zona": true, "hazard_danio": 7.0, "hazard_radio": 55.0},
	"charcoacido":         {"rastro_danio": true, "hazard_danio": 5.0, "hazard_radio": 45.0, "hazard_duracion": 3.0},
	"nubeacida":           {"aura_danio": true, "aura_dps": 8.0, "aura_radio": 95.0},
	"cableelectrico":      {"aura_danio": true, "aura_dps": 14.0, "aura_radio": 80.0, "aura_periodo": 0.7},
	"bateriatoxica":       {"explota_al_morir": true, "explota_radio": 95.0, "explota_danio": 28.0},
	"residuoradiactivo":   {"aura_danio": true, "aura_dps": 10.0, "aura_radio": 100.0},
	"barrilexplosivo":     {"explota_al_morir": true, "explota_radio": 105.0, "explota_danio": 34.0},
	"mutante":             {"regeneracion_hps": 4.0, "regen_retraso": 3.0},
	"dronpesticida":       {"es_aereo": true},
	"nubefumigacion":      {"aura_danio": true, "aura_dps": 7.0, "aura_radio": 90.0},
	"incendio":            {"divide_al_morir": true, "divide_cantidad": 2},
	"olacalor":            {"deja_zona": true, "hazard_danio": 9.0, "hazard_radio": 65.0},
	"deshielo":            {"aura_ralentiza": true, "ralentiza_pct": 0.4, "ralentiza_radio": 120.0},
	"helicopterofumigador": {"es_aereo": true},
	"calentamientoglobal": {"aura_danio": true, "aura_dps": 12.0, "aura_radio": 130.0},
}

# ── Kit de ataques por jefe (clave = id educativo normalizado) ──
const BOSS_KITS := {
	"excavadoratoxica":     {"onda": true, "meteoros": true, "met_cantidad": 6, "met_color": Color(0.6, 0.45, 0.25, 0.6)},
	"vertederoviviente":    {"meteoros": true, "invocar": true, "met_cantidad": 7, "met_color": Color(0.55, 0.5, 0.35, 0.6),
							 "inv_escena": "res://ecenes/enemies/main/11-20/lataOxidada/lataOxidada_enemi.tscn"},
	"islaplastico":         {"abanico": true, "onda": true, "ab_cantidad": 9, "ab_color": Color(0.3, 0.7, 1.0, 1.0)},
	"chimeneagigante":      {"meteoros": true, "onda": true, "met_cantidad": 8, "met_color": Color(0.35, 0.35, 0.4, 0.6)},
	"geiseracido":          {"meteoros": true, "onda": true, "met_color": Color(0.75, 0.95, 0.2, 0.6)},
	"montanachatarra":      {"rayo": true, "onda": true, "rayo_color": Color(0.6, 0.85, 1.0, 0.85)},
	"reactorroto":          {"rayo": true, "meteoros": true, "aura_pulso": true, "rayo_color": Color(0.7, 1.0, 0.4, 0.85), "pulso_color": Color(0.6, 1.0, 0.3, 0.5)},
	"helicopterofumigador": {"abanico": true, "meteoros": true, "ab_color": Color(0.7, 0.9, 0.4, 1.0)},
	"aserraderoandante":    {"abanico": true, "onda": true, "ab_color": Color(0.9, 0.6, 0.3, 1.0)},
	"calentamientoglobal":  {"rayo": true, "meteoros": true, "aura_pulso": true,
							 "met_color": Color(1.0, 0.35, 0.1, 0.6), "rayo_color": Color(1.0, 0.6, 0.2, 0.9), "pulso_color": Color(1.0, 0.4, 0.15, 0.5),
							 "inv_escena": "res://ecenes/enemies/main/91-100/deshielo/deshielo_enemi.tscn"},
}

# ── Categoría por enemigo (para efectos de cartas) ──
const CATEGORIAS := {
	"nubegas": "nube", "humofabrica": "nube", "nubeacida": "nube", "nubefumigacion": "nube",
	"petroleo": "toxico", "bateriatoxica": "toxico", "residuoradiactivo": "toxico",
	"charcoacido": "toxico", "gotaacida": "toxico", "cableelectrico": "toxico",
	"chimenea": "fuego", "hollin": "fuego", "incendio": "fuego", "olacalor": "fuego",
	"barrilexplosivo": "fuego",
	"botellaplastico": "acuatico", "botellalanzadora": "acuatico", "redfantasma": "acuatico",
}

# ── Multiplicadores por etapa (índice 0 = etapa 1) ──
## [mult_vida, mult_danio, mult_velocidad]. Alineado con los .tres ajustados
## (curvas de vida y daño suavizadas).
const MULT := [
	[1.00, 1.00, 1.00], [1.15, 1.15, 1.05], [1.30, 1.35, 1.10], [1.50, 1.60, 1.15],
	[1.70, 1.90, 1.20], [1.90, 2.25, 1.25], [2.10, 2.65, 1.30], [2.30, 3.10, 1.35],
	[2.50, 3.60, 1.40], [2.80, 4.20, 1.45],
]

# ── Ventana/peso de las 3 entradas normales de cada etapa ──
const VENTANAS := [
	{"peso": 3.0, "min": 1, "max": 0, "sim": 0},
	{"peso": 1.5, "min": 4, "max": 0, "sim": 0},
	{"peso": 1.0, "min": 7, "max": 0, "sim": 3},
]

# ── Cantidad de enemigos por oleada por etapa ──
const BASE_OLEADA := [8, 9, 10, 11, 12, 13, 15, 16, 18, 20]

# ── Cadencia de spawn y tope de vivos por etapa ──
const TIEMPO_SPAWNS := [1.2, 1.25, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0]
const MAX_VIVOS := [12, 12, 13, 14, 14, 15, 16, 16, 18, 20]


func _initialize() -> void:
	print("[GEN] Fase A — generando enemigos de etapas 2..10")
	var data := DATA_EDU.get_data()
	var total_enemigos := 0

	for i in range(1, data.size()):  # 1..9  → etapas 2..10
		var rango := "%d-%d" % [i * 10 + 1, i * 10 + 10]
		var etapa: Dictionary = data[i]
		var claves: Array = etapa.get("enemies", {}).keys()
		if claves.size() < 4:
			push_warning("[GEN] etapa %d tiene %d enemigos (se esperaban 4)" % [i + 1, claves.size()])
			continue

		var oleadas: Array = []          # EnemigoOleadaConfig (normales)
		var boss_escena := ""            # path del jefe
		var boss_nombre := ""

		for k in range(claves.size()):
			var key: String = str(claves[k])
			var es_jefe: bool = (k == 3)
			var nombre: String = str(etapa["enemies"][key].get("name", key))
			var shape := _buscar_shape(rango, key)
			if shape == "":
				push_warning("[GEN] no encontré shape para '%s' en etapa %s" % [key, rango])
				continue
			var info := _analizar_shape(shape)
			var radio: float = info["radio"]

			if es_jefe:
				var escena := _construir_jefe(key, nombre, shape, radio)
				var path := "%s/%s/boss/%s_boss.tscn" % [DIR_MAIN, rango, shape.get_file().get_basename()]
				_guardar(escena, path)
				boss_escena = path
				boss_nombre = nombre
			else:
				var escena := _construir_normal(key, nombre, shape, radio)
				var base := "%s/%s/%s/%s" % [DIR_MAIN, rango, shape.get_file().get_basename(), shape.get_file().get_basename()]
				var path_tscn := base + "_enemi.tscn"
				_guardar(escena, path_tscn)
				var cfg := _crear_oleada(path_tscn, VENTANAS[k])
				var path_tres := base + ".tres"
				_guardar(cfg, path_tres)
				oleadas.append(load(path_tres))
			total_enemigos += 1

		# EtapaConfig
		var et := SCRIPT_ETAPA.new()
		et.nombre = "Etapa %d: %s" % [i + 1, str(etapa.get("theme", ""))]
		var arr: Array[EnemigoOleadaConfig] = []
		for o in oleadas:
			arr.append(o)
		et.enemigos = arr
		et.heredar_enemigos_anteriores = false
		et.enemigos_base_por_oleada = int(BASE_OLEADA[i])
		et.incremento_enemigos_por_oleada = 1
		et.escalado_vida_por_oleada = 0.10
		et.escalado_danio_por_oleada = 0.04
		et.tiempo_entre_spawns = float(TIEMPO_SPAWNS[i])
		et.max_enemigos_simultaneos = int(MAX_VIVOS[i])
		et.mult_vida = float(MULT[i][0])
		et.mult_velocidad = float(MULT[i][2])
		et.mult_danio = float(MULT[i][1])
		if boss_escena != "":
			et.jefe_escena = load(boss_escena)
			et.jefe_nombre = boss_nombre
			et.jefe_escoltas = 6
			et.jefe_tiempo_descanso = 15.0
		_guardar(et, "%s/etapa_%02d.tres" % [DIR_ETAPAS, i + 1])

	print("[GEN] listo. Enemigos generados: %d" % total_enemigos)
	quit()


# ─────────────────────────────────────────────────────────
#  CONSTRUCCIÓN
# ─────────────────────────────────────────────────────────

func _construir_normal(key: String, nombre: String, shape: String, radio: float) -> PackedScene:
	var conf := _stats(key, NORMALES, false)
	var root := _raiz_enemigo(nombre, conf, radio)
	_adjuntar_figura(root, shape)
	_adjuntar_colision(root, radio)
	_adjuntar_boca(root, conf)
	root.set("categoria", str(CATEGORIAS.get(key, "")))
	_adjuntar_mecanicas(root, key)
	_adjuntar_animacion(root)
	return _pack(root)


func _construir_jefe(key: String, nombre: String, shape: String, radio: float) -> PackedScene:
	var conf := _stats(key, JEFES, true)
	conf["contacto"] = (conf["tipo"] == "embestida")
	var root := _raiz_enemigo(nombre, conf, radio)
	_adjuntar_figura(root, shape)
	_adjuntar_colision(root, radio)
	_adjuntar_boca(root, conf)
	root.set("categoria", "elite")
	_adjuntar_mecanicas(root, key)
	_adjuntar_ataques(root, key)
	_adjuntar_animacion(root)
	return _pack(root)


func _pack(root: Node) -> PackedScene:
	var p := PackedScene.new()
	var err := p.pack(root)
	if err != OK:
		push_error("[GEN] pack() falló (err %d) para %s" % [err, root.name])
	root.free()
	return p


func _stats(key: String, tabla: Dictionary, es_jefe: bool) -> Dictionary:
	var ov: Dictionary = tabla.get(key, {})
	var tipo: String = str(ov.get("tipo", "melee"))
	var def: Dictionary = TIPO_DEF[tipo]
	var c := {
		"tipo": tipo,
		"vida": float(ov.get("vida", def["vida"])),
		"vel": float(ov.get("vel", def["vel"])),
		"danio": float(ov.get("danio", def["danio"])),
		"contacto": bool(def["contacto"]),
	}
	if es_jefe:
		c["contacto"] = (tipo == "embestida")
	c["anti_estructura"] = bool(ov.get("anti_estructura", es_jefe))
	return c


func _raiz_enemigo(nombre: String, conf: Dictionary, radio: float) -> Node2D:
	var base := load(BASE_ENEMIGO) as PackedScene
	var root := base.instantiate() as Node2D
	root.name = "enemigo"

	root.set("life", conf["vida"])
	root.set("speed", conf["vel"])
	root.set("damage", conf["danio"])
	root.set("comportamiento_tipo", conf["tipo"])
	root.set("danio_contacto", conf["danio"] if conf["contacto"] else 0.0)
	root.set("dano_al_tocar", conf["contacto"])
	# Radio de contacto un poco mayor que el cuerpo: así el enjambre que se
	# pega al jugador SÍ registra daño (antes quedaba fuera del umbral).
	root.set("radio_contacto", clampf(radio + 16.0, 24.0, 90.0))
	root.set("nombre_texto", nombre)
	var fuente := load(FUENTE) as Font
	root.set("fuente_nombre", fuente)
	root.set("fuente_danio", fuente)
	root.set("anti_estructura", conf["anti_estructura"])

	if conf["tipo"] == "enjambre":
		root.set("enjambre_recarga", 0.8)
		root.set("enjambre_separacion", 24.0)
	elif conf["tipo"] == "melee":
		# El melee ataca al llegar (comp_mele) en vez de depender del contacto.
		root.set("melee_radio", 30.0)
		root.set("melee_recarga", 1.0)
		root.set("melee_margen_arbol", 16.0)
	elif conf["tipo"] == "embestida":
		root.set("embestida_mult_dano", 1.5)
		root.set("embestida_telegrafiar", 0.6)

	# Movilidad dinámica por arquetipo.
	match conf["tipo"]:
		"enjambre":
			root.set("mov_zigzag_grados", 22.0)
			root.set("mov_zigzag_freq", 3.0)
			root.set("mov_orbita", 0.35)
			root.set("mov_dash_mult", 1.3)
			root.set("mov_dash_freq", 0.6)
		"melee":
			root.set("mov_zigzag_grados", 8.0)
			root.set("mov_orbita", 0.55)
			root.set("mov_dash_mult", 1.5)
			root.set("mov_dash_freq", 0.7)
		"rango":
			root.set("mov_zigzag_grados", 6.0)
			root.set("mov_orbita", 0.7)
		"torreta":
			root.set("mov_orbita", 0.0)
		"embestida":
			root.set("mov_zigzag_grados", 10.0)
			root.set("mov_orbita", 0.35)
			root.set("mov_dash_mult", 1.6)
			root.set("mov_dash_freq", 0.5)

	if conf["anti_estructura"]:
		# Movilidad de JEFE: más orbita, más dash, más separación.
		root.set("mov_zigzag_grados", 10.0)
		root.set("mov_zigzag_freq", 2.0)
		root.set("mov_orbita", 0.5)
		root.set("mov_dash_mult", 1.6)
		root.set("mov_dash_freq", 0.5)
		root.set("mov_separacion_fuerza", 1.0)
		root.set("furia_umbral_vida", 0.4)
		root.set("furia_mult_velocidad", 1.35)
		root.set("furia_mult_danio", 1.3)
		root.set("orbes_min", 8)
		root.set("orbes_max", 14)
		root.set("orbe_valor", 3.0)
	return root


func _adjuntar_figura(root: Node2D, shape: String) -> void:
	var fig := (load(shape) as PackedScene).instantiate() as Node2D
	fig.name = "FiguraConstructor"
	root.add_child(fig)
	fig.owner = root


func _adjuntar_colision(root: Node2D, radio: float) -> void:
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = radio
	cs.shape = circle
	root.add_child(cs)
	cs.owner = root


func _adjuntar_boca(root: Node2D, conf: Dictionary) -> void:
	if conf["tipo"] != "rango" and conf["tipo"] != "torreta":
		return
	var m := Marker2D.new()
	m.name = "boca"
	root.add_child(m)
	m.owner = root
	root.set("boca", m)


func _adjuntar_mecanicas(root: Node2D, key: String) -> void:
	var conf: Dictionary = MECANICAS.get(key, {})
	if conf.is_empty():
		return
	var nodo := SCRIPT_MEC.new()
	nodo.name = "Mecanicas"
	for k in conf.keys():
		nodo.set(k, conf[k])
	root.add_child(nodo)
	nodo.owner = root


func _adjuntar_animacion(root: Node2D) -> void:
	var nodo := SCRIPT_ANIM.new()
	nodo.name = "Animacion"
	root.add_child(nodo)
	nodo.owner = root


func _adjuntar_ataques(root: Node2D, key: String) -> void:
	var kit: Dictionary = BOSS_KITS.get(key, {})
	if kit.is_empty():
		return
	var nodo := SCRIPT_BOSS.new()
	nodo.name = "Ataques"
	for k in kit.keys():
		if k == "inv_escena":
			nodo.set("inv_escena", load(kit[k]) as PackedScene)
		else:
			nodo.set(k, kit[k])
	root.add_child(nodo)
	nodo.owner = root


func _crear_oleada(path_tscn: String, v: Dictionary) -> EnemigoOleadaConfig:
	var r := SCRIPT_OLEADA.new()
	r.escena = load(path_tscn) as PackedScene
	r.peso = float(v["peso"])
	r.oleada_minima = int(v["min"])
	r.oleada_maxima = int(v["max"])
	r.max_simultaneos = int(v["sim"])
	return r


# ─────────────────────────────────────────────────────────
#  SHAPES
# ─────────────────────────────────────────────────────────

func _buscar_shape(rango: String, key: String) -> String:
	var base := "%s/stage%s" % [DIR_STAGES, rango]
	var candidatos: Array = []
	var rutas := _listar_dir(base)
	for r in rutas:
		candidatos.append(r)
	for r in _listar_dir(base + "/boss"):
		candidatos.append(r)
	var exacto := ""
	var contiene := ""
	for r in candidatos:
		var n := _norm(r.get_file().get_basename())
		if n == key:
			exacto = r
			break
		if n.contains(key) or key.contains(n):
			if contiene == "" or n.length() > _norm(contiene.get_file().get_basename()).length():
				contiene = r
	return exacto if exacto != "" else contiene


func _listar_dir(base: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(base)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".tscn"):
			out.append(base + "/" + f)
	return out


func _analizar_shape(ruta: String) -> Dictionary:
	var esc := load(ruta) as PackedScene
	var escala := 1.0
	var capas: Array = []
	if esc != null:
		var fc := esc.instantiate()
		escala = float(fc.get("escala_global"))
		capas = fc.get("capas")
		fc.free()
	return {"radio": _radio(capas, escala)}


func _radio(capas: Array, escala: float) -> float:
	var max2 := 0.0
	for c in capas:
		if c == null:
			continue
		for p in c.puntos:
			max2 = maxf(max2, p.length_squared())
	return clampf(sqrt(max2) * escala, 10.0, 200.0)


func _norm(s: String) -> String:
	var t := s.to_lower()
	for par in [["á","a"],["é","e"],["í","i"],["ó","o"],["ú","u"],["ü","u"],["ñ","n"]]:
		t = t.replace(par[0], par[1])
	var out := ""
	for c in t:
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
	return out


# ─────────────────────────────────────────────────────────

func _guardar(res: Resource, path: String) -> void:
	var dir := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("[GEN] no se pudo guardar %s (err %d)" % [path, err])
	else:
		print("[GEN]  · %s" % path)
