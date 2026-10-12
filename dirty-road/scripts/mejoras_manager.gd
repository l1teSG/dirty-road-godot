extends Node

## ══════════════════════════════════════════════════════════
##  MEJORAS MANAGER (autoload)
##
##  Aplica las mejoras de las cartas a los stats de SaveManager.
##  Acumulable: cada compra reaplica su delta (no hay "única").
##
##  Mapa: id_carta (slug del nombre) -> Array de [ruta_stat, op, valor]
##    op "pct"  -> stat *= (1 + valor)      (valor = fracción, 0.20 = +20%)
##    op "add"  -> stat += valor            (para bases 0.0; el consumidor
##                                            interpreta 1+stat si es fracción)
##    op "mult" -> stat *= valor            (multiplicador absoluto)
##
##  Todos los stats listados ya los consume alguna mecánica (proyectiles,
##  auras, IA, dron, etc.); no quedan hooks pendientes.
## ══════════════════════════════════════════════════════════

const EFECTOS: Dictionary = {
	"reforestacion": [["arbol.vida_maxima", "pct", 0.20]],
	"murodeecoladrillos": [["arbol.dano_recibido_mult", "pct", -0.10]],
	"barreraviva": [["arbol.espinas", "add", 0.25]],
	"compostajeorganico": [["arbol.regen", "add", 0.5]],
	"capadeozono": [["arbol.barrera", "add", 1]],
	"bloquedehieloseco": [["arbol.congelar", "add", 2.0]],

	# ── Defensas propias del árbol (mecánicas nuevas) ──
	# Raíces Sísmicas: pulso más fuerte y más frecuente.
	"raicessismicas": [
		["arbol.raices_empuje", "pct", 0.60],
		["arbol.raices_pulso", "pct", -0.25],
	],
	# Aura de Purificación: más ralentización y daño a los tóxicos.
	"auradedepurificacion": [
		["arbol.aura_purificacion", "add", 0.15],
		["arbol.aura_dano_toxico", "add", 5.0],
	],
	# Lianas Ancestrales: enraizan antes y por más tiempo.
	"lianasancestrales": [
		["arbol.lianas_tiempo", "pct", -0.30],
		["arbol.lianas_duracion", "add", 1.0],
	],
	# Corteza Endurecida: una carga extra de barrera + algo de espinas.
	"cortezaendurecida": [
		["arbol.barrera", "add", 1],
		["arbol.espinas", "add", 0.05],
	],

	# ── Ofensiva ──
	"herramientareciclada": [["jugador.danio", "pct", 0.15]],
	"molinodeviento": [["jugador.cadencia", "pct", -0.20]],
	"lentesolar": [["jugador.critico_prob", "add", 0.10]],
	"gafasrecicladas": [["jugador.critico_mult", "add", 0.15]],
	"proyectildebambu": [["jugador.perforacion", "add", 1]],
	"injertobotanico": [["jugador.proyectiles_extra", "add", 1]],
	"mangueradegoteo": [["jugador.alcance", "pct", 0.25]],
	"semillagigante": [["jugador.tamano", "pct", 0.30]],
	"hachaconfiscada": [["jugador.danio_elite", "add", 0.40]],
	"reddelimpiezaoceanica": [["jugador.danio_acuaticos", "add", 0.30]],
	"fertilizantenatural": [["jugador.danio_continuo", "add", 1]],
	"biopesticida": [["jugador.danio_toxico", "add", 1]],
	"bombadesemillas": [["jugador.detonar_prob", "add", 0.15]],

	# ── Movimiento / utilidad ──
	"bicicletaecologica": [["jugador.velocidad", "pct", 0.15]],
	"zapatillasdecaucho": [
		["jugador.velocidad_dash", "pct", 0.15],
		["jugador.cooldown_dash", "pct", -0.15],
	],
	"relojdesol": [["jugador.cooldown_dash", "pct", -0.15]],
	"recoleccionselectiva": [["jugador.orbes_radio", "pct", 0.30]],
	"frascodevidrio": [["jugador.orbes_valor", "pct", 0.20]],
	"granjadelombrices": [
		["jugador.orbes_valor", "pct", 0.10],
		["jugador.regen", "add", 0.2],
	],
	"abonoorganico": [["jugador.xp_mult", "pct", 0.20]],
	"electroimancasero": [["arbol.regen", "add", 0.2]],
	"panelsolarportatil": [["jugador.regen", "add", 0.4]],
	"linternadedinamo": [["jugador.vision", "add", 1]],
	"hongoluminiscente": [["jugador.ralentizar", "add", 0.20]],
	"treboldecuatrohojas": [["jugador.suerte", "add", 1]],
	"espejoparabolico": [["jugador.esquiva", "add", 0.10]],
	"filtrodecarbon": [["jugador.inmunidad_nube", "add", 1]],
	"raicesprofundas": [["jugador.bonus_quieto", "add", 0.50]],
	"pararrayosreciclado": [["jugador.paralizar", "add", 1]],
	"mantaignifuga": [["jugador.inmunidad_fuego", "add", 1]],
	"alarmatemprana": [["jugador.aturdir", "add", 1]],
	"dronconservacionista": [["jugador.dron", "add", 1]],
	"semillasdetrueque": [["jugador.descuento", "add", 0.15]],

	# ── Legendaria mixta ──
	"fuerzadelanaturaleza": [
		["jugador.danio", "pct", 0.40],
		["jugador.cadencia", "pct", -0.40],
		["jugador.velocidad", "pct", -0.20],
	],
	"compostvolcanico": [["jugador.danio", "pct", 0.25]],
	"cadenadesemillas": [["jugador.cadencia", "pct", -0.15]],
	"telescopiodebambu": [["jugador.critico_prob", "add", 0.08]],
	"colmillodevidrio": [["jugador.critico_mult", "add", 0.3]],
	"flechaperforante": [["jugador.perforacion", "add", 1]],
	"racimodesemillas": [["jugador.proyectiles_extra", "add", 1]],
	"canalarga": [["jugador.alcance", "pct", 0.2]],
	"bellotamasiva": [["jugador.tamano", "pct", 0.25]],
	"hachareforzada": [["jugador.danio_elite", "add", 0.3]],
	"redtupida": [["jugador.danio_acuaticos", "add", 0.25]],
	"fumigadororganico": [["jugador.danio_toxico", "add", 0.5]],
	"esporasardientes": [["jugador.danio_continuo", "add", 1]],
	"cortezapersonal": [["jugador.vida_maxima", "pct", 0.15]],
	"chalecodellantas": [["jugador.armadura", "add", 0.1]],
	"reflejofelino": [["jugador.esquiva", "add", 0.08]],
	"saviacurativa": [["jugador.regen", "add", 0.6]],
	"metabolismolento": [["jugador.regen_espera", "pct", -0.25]],
	"respiradornatural": [["jugador.inmunidad_nube", "add", 0.5]],
	"patinetareciclada": [["jugador.velocidad", "pct", 0.12]],
	"botasdegoma": [["jugador.velocidad_dash", "pct", 0.15]],
	"brujulasolar": [["jugador.cooldown_dash", "pct", -0.15]],
	"imandechatarrero": [["jugador.orbes_radio", "pct", 0.3]],
	"cofredesemillas": [["jugador.orbes_valor", "pct", 0.25]],
	"bibliotecaverde": [["jugador.xp_mult", "pct", 0.2]],
	"veletaafortunada": [["jugador.suerte", "add", 1]],
	"farodereciclaje": [["jugador.vision", "add", 1]],
	"luciernagaguardiana": [["jugador.dron", "add", 1]],
	"raiceslargas": [["jugador.bonus_quieto", "add", 0.4]],
	"neemconcentrado": [["jugador.ralentizar", "add", 0.2]],
	"descargaestatica": [["jugador.paralizar", "add", 1]],
	"rafagaaturdidora": [["jugador.aturdir", "add", 0.6]],
	"bombadecompost": [["jugador.detonar_prob", "add", 0.12]],
	"lluviadesemillas": [["jugador.super_danio", "pct", 0.5]],
	"craterderaices": [["jugador.super_radio", "pct", 0.25]],
	"cupuladehojas": [["arbol.dano_recibido_mult", "pct", -0.15]],
	"regeneracionprofunda": [["arbol.regen", "add", 1.5]],
	"escudodeozonomenor": [["arbol.barrera", "add", 1]],
	"ventiscainterior": [["arbol.congelar", "add", 1.5]],
	"brumapurificadora": [["arbol.aura_dano_toxico", "add", 6]],
	"empujeraigal": [["arbol.raices_empuje", "pct", 0.4]],
}


## Efectos activos (del .tres si existe, si no la const EFECTOS).
var _efectos: Dictionary = {}


func _ready() -> void:
	const RUTA := "res://assets/cards/mejorasConfig.tres"
	if ResourceLoader.exists(RUTA):
		var cfg = load(RUTA)
		if cfg != null:
			var e = cfg.get("efectos")
			if e is Dictionary and not (e as Dictionary).is_empty():
				_efectos = e
				print("[MejorasManager] Efectos cargados de %s (%d cartas)." % [RUTA, _efectos.size()])
	if _efectos.is_empty():
		_efectos = EFECTOS
		print("[MejorasManager] Usando efectos por defecto del código (%d)." % _efectos.size())


## Compra una mejora: gasta biomasa, la registra y aplica sus efectos.
## Devuelve true si se pudo comprar.
func comprar(id: String, costo: int) -> bool:
	if BiomasaManager == null or SaveManager == null:
		return false
	# Descuento (carta "Semillas de Trueque"): reduce el costo efectivo.
	var desc := clampf(SaveManager.get_stat("jugador.descuento", 0.0), 0.0, 0.9)
	var costo_final := int(round(float(costo) * (1.0 - desc)))
	if not BiomasaManager.gastar(costo_final):
		return false

	SaveManager.subir_mejora(id)
	_aplicar_efectos(id)
	SaveManager.guardar_partida()
	SaveManager.notificar_stats()
	print("[MejorasManager] Comprada '%s' (-%d biomasa). Nivel=%d" % [id, costo, SaveManager.get_mejora(id)])
	return true


func _aplicar_efectos(id: String) -> void:
	var lista: Array = _efectos.get(id, [])
	if lista.is_empty():
		push_warning("[MejorasManager] La carta '%s' no tiene efectos definidos." % id)
		return

	for efecto in lista:
		var ruta: String = str(efecto[0])
		var op: String = str(efecto[1])
		var valor: float = float(efecto[2])
		match op:
			"pct":
				SaveManager.multiplicar_stat(ruta, valor)
			"add":
				SaveManager.sumar_stat(ruta, valor)
			"mult":
				SaveManager.set_stat(ruta, SaveManager.get_stat(ruta) * valor)
			_:
				push_warning("[MejorasManager] Operación desconocida '%s' en '%s'." % [op, id])
