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
##  Los stats marcados "(hook pendiente)" se guardan pero aún no los consume
##  ninguna mecánica; se irán conectando (proyectiles, auras, IA...).
## ══════════════════════════════════════════════════════════

const EFECTOS: Dictionary = {
	"reforestacion": [["arbol.vida_maxima", "pct", 0.20]],
	"murodeecoladrillos": [["arbol.dano_recibido_mult", "pct", -0.10]],
	"barreraviva": [["arbol.espinas", "add", 0.25]],
	"compostajeorganico": [["arbol.regen", "add", 0.5]],
	"capadeozono": [["arbol.barrera", "add", 1]],
	"bloquedehieloseco": [["arbol.congelar", "add", 2.0]],  # hook pendiente

	# ── Ofensiva ──
	"herramientareciclada": [["jugador.danio", "pct", 0.15]],
	"molinodeviento": [["jugador.cadencia", "pct", -0.20]],
	"lentesolar": [["jugador.critico_prob", "add", 0.10]],
	"gafasrecicladas": [["jugador.critico_mult", "add", 0.15]],
	"proyectildebambu": [["jugador.perforacion", "add", 1]],
	"injertobotanico": [["jugador.proyectiles_extra", "add", 1]],
	"mangueradegoteo": [["jugador.alcance", "pct", 0.25]],
	"semillagigante": [["jugador.tamano", "pct", 0.30]],
	"hachaconfiscada": [["jugador.danio_elite", "add", 0.40]],  # hook pendiente
	"reddelimpiezaoceanica": [["jugador.danio_acuaticos", "add", 0.30]],  # hook pendiente
	"fertilizantenatural": [["jugador.danio_continuo", "add", 1]],  # hook pendiente
	"biopesticida": [["jugador.danio_toxico", "add", 1]],  # hook pendiente
	"bombadesemillas": [["jugador.detonar_prob", "add", 0.15]],  # hook pendiente

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
	"electroimancasero": [["arbol.regen", "add", 0.2]],  # aprox.; hook real pendiente
	"panelsolarportatil": [["jugador.regen", "add", 0.4]],  # aprox.; hook pendiente
	"linternadedinamo": [["jugador.vision", "add", 1]],  # hook pendiente
	"hongoluminiscente": [["jugador.ralentizar", "add", 0.20]],  # hook pendiente
	"treboldecuatrohojas": [["jugador.suerte", "add", 1]],
	"espejoparabolico": [["jugador.esquiva", "add", 0.10]],
	"filtrodecarbon": [["jugador.inmunidad_nube", "add", 1]],  # hook pendiente
	"raicesprofundas": [["jugador.bonus_quieto", "add", 0.50]],  # hook pendiente
	"pararrayosreciclado": [["jugador.paralizar", "add", 1]],  # hook pendiente
	"mantaignifuga": [["jugador.inmunidad_fuego", "add", 1]],  # hook pendiente
	"alarmatemprana": [["jugador.aturdir", "add", 1]],  # hook pendiente
	"dronconservacionista": [["jugador.dron", "add", 1]],  # hook pendiente
	"semillasdetrueque": [["jugador.descuento", "add", 0.15]],  # hook pendiente

	# ── Legendaria mixta ──
	"fuerzadelanaturaleza": [
		["jugador.danio", "pct", 0.40],
		["jugador.cadencia", "pct", -0.40],
		["jugador.velocidad", "pct", -0.20],
	],
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
