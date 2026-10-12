extends Node

## ══════════════════════════════════════════════════════════
##  SAVE MANAGER (autoload)
##  · Guardado de partida POR SLOTS (máx. 5): user://partida_1..5.save
##  · Metadatos de slots: user://slots.json (oleada, etapa, biomasa, fecha, tiempo)
##  · Ajustes GLOBALES: user://ajustes.save (no se borran con "Nueva partida")
##
##  Todo el código existente (get_horda, cargar_partida, nueva_partida…)
##  sigue funcionando, pero opera sobre el SLOT ACTUAL.
## ══════════════════════════════════════════════════════════

## Se emite cuando 'datos' cambia por completo (cargar o nueva partida).
signal datos_actualizados
## Se emite cuando cambia un stat concreto (para que el jugador/árbol se refresquen).
signal stats_actualizados
## Se emite cuando cambia cualquier ajuste.
signal ajustes_cambiados
## Se emite cuando la lista de slots cambia (crear/borrar/guardar).
signal slots_cambiados

const MAX_SLOTS := 5
const RUTA_AJUSTES := "user://ajustes.save"
const RUTA_SLOTS_META := "user://slots.json"

# Valores por defecto para una partida nueva.
const DATOS_DEFECTO := {
	"horda_actual": 1,
	"vida_jugador": 100,
	"vida_maxima": 100,
	"biomasa": 0,
	# id_carta -> nivel comprado (acumulable)
	"mejoras": {},
	# Stats finales (base + mejoras). El jugador y el árbol leen de aquí.
	"stats": {
		"jugador": {
			"vida_maxima": 100,
			"velocidad": 320.0,
			"danio": 12.0,
			"cadencia": 0.5,
			"critico_prob": 0.05,
			"critico_mult": 1.75,
			"perforacion": 0,
			"proyectiles_extra": 0,
			"alcance": 1.0,
			"tamano": 1.0,
			"velocidad_dash": 620.0,
			"cooldown_dash": 1.1,
			"regen": 0.6,
			"regen_espera": 6.0,
			"super_danio": 80.0,
			"super_radio": 130.0,
			"orbes_radio": 1.0,
			"orbes_valor": 1.0,
			"xp_mult": 1.0,
			"suerte": 0.0,
			"armadura": 0.0,
			"esquiva": 0.0,
			"danio_continuo": 0.0,
			"danio_elite": 0.0,
			"danio_acuaticos": 0.0,
			"danio_toxico": 0.0,
			"detonar_prob": 0.0,
			"descuento": 0.0,
			"vision": 0.0,
			"ralentizar": 0.0,
			"inmunidad_nube": 0.0,
			"inmunidad_fuego": 0.0,
			"bonus_quieto": 0.0,
			"paralizar": 0.0,
			"aturdir": 0.0,
			"dron": 0.0,
		},
		"arbol": {
			"vida_maxima": 1800,
			# Resistencia: multiplica TODO el daño recibido (<1 = menos daño).
			"dano_recibido_mult": 0.70,
			"regen": 6.0,
			"regen_espera": 4.0,
			# Tope de daño por golpe: fracción de la vida máxima que NINGÚN
			# golpe puede superar (evita one-shots en etapas altas).
			"tope_golpe_pct": 0.05,
			# Máximo de enemigos que dañan el tronco a la vez (0 = sin tope).
			"max_atacantes": 4,
			# ── Defensas propias del árbol (base pasiva + cartas) ──
			# Espinas: fracción del daño de contacto/melee que se devuelve.
			"espinas": 0.10,
			# Ondas de raíces: cada N s empuja a los enemigos del tronco.
			"raices_pulso": 6.0,
			"raices_empuje": 220.0,
			# Aura de purificación: ralentiza cerca; daña a los tóxicos.
			"aura_purificacion": 0.20,
			"aura_dano_toxico": 6.0,
			# Lianas: enraizan a quien se pegue al tronco demasiado tiempo.
			"lianas_tiempo": 2.0,
			"lianas_duracion": 1.5,
			# Barrera de corteza: bloquea golpes letales (cargas).
			"barrera": 0,
			"congelar": 0.0,
		},
	},
}

## Versión de balance de los stats base. Súbela al cambiar DATOS_DEFECTO si
## quieres que las partidas YA guardadas adopten los nuevos mínimos base sin
## perder sus mejoras compradas (ver _migrar_balance()).
const BALANCE_VERSION := 3

# Ajustes por defecto (globales, compartidos por todos los slots).
const AJUSTES_DEFECTO := {
	"disparo_automatico": true,
	"edu_escala": 1.0,
	"edu_posicion": 0,          # 0 arriba, 1 centro, 2 abajo
	"edu_duracion_mult": 1.0,
	"edu_insignia": true,
	"edu_sonido": true,
	"vol_master": 1.0,
	"vol_musica": 0.7,
	"vol_efectos": 0.9,
	"hud_escala": 1.0,
	"hud_opacidad": 1.0,
	"hud_mano": 0,              # 0 diestro, 1 zurdo (espeja los controles)
	"hud_botones_escala": 1.0,
	"hud_joystick_escala": 1.0,
	"fondo_shader": true,
	# ── Imagen ──
	"brillo": 1.0,
	"contraste": 1.0,
	"saturacion": 1.0,
	# ── General ──
	"mostrar_fps": false,
	"pausa_al_perder_foco": false,
	"mostrar_cartel_horda": true,
	"confirmar_compra": false,
	"mostrar_flecha_arbol": true,
	"pantalla_completa": false,
	# ── Combate / controles ──
	"disparo_continuo_manual": false,
	"autoapuntado": 0.0,
	"camara_zoom": 2.0,
	# ── Accesibilidad ──
	"reducir_flashes": false,
	"reducir_particulas": false,
	"vibracion": true,
	"audio_en_foco": true,
}

# Rangos válidos de los ajustes (se aplican al cargar para sanear valores).
const RANGOS_AJUSTES := {
	"edu_escala": [0.6, 1.6],
	"edu_posicion": [0, 2],
	"edu_duracion_mult": [0.5, 2.0],
	"vol_master": [0.0, 1.0],
	"vol_musica": [0.0, 1.0],
	"vol_efectos": [0.0, 1.0],
	"hud_escala": [0.6, 1.2],
	"hud_opacidad": [0.3, 1.0],
	"hud_mano": [0, 1],
	"hud_botones_escala": [0.5, 1.5],
	"hud_joystick_escala": [0.5, 1.5],
	"brillo": [0.5, 1.5],
	"contraste": [0.5, 1.5],
	"saturacion": [0.0, 2.0],
	"autoapuntado": [0.0, 1.0],
	"camara_zoom": [1.5, 3.0],
}

var datos: Dictionary = DATOS_DEFECTO.duplicate(true)
var ajustes: Dictionary = AJUSTES_DEFECTO.duplicate(true)

## Slot activo (1..MAX_SLOTS).
var slot_actual: int = 1
## Tiempo jugado acumulado de la partida en curso (segundos).
var _tiempo_jugado: float = 0.0
var _acumulando: bool = false

## Ajustes pendientes de escribir a disco (evita escribir en cada tick del slider).
var _sucio_ajustes: bool = false
var _timer_ajustes: Timer = null


func _ready() -> void:
	# Escritura diferida de ajustes: agrupa ráfagas de cambios (sliders) en una
	# sola escritura y se fuerza con flush_ajustes() al salir/pausar la app.
	_timer_ajustes = Timer.new()
	_timer_ajustes.one_shot = true
	_timer_ajustes.wait_time = 0.4
	_timer_ajustes.timeout.connect(guardar_ajustes)
	add_child(_timer_ajustes)

	cargar_ajustes()
	aplicar_modo_pantalla()
	# Recuerda el último slot usado si existía.
	var meta := _leer_meta()
	if meta.has("ultimo_slot"):
		slot_actual = clampi(int(meta["ultimo_slot"]), 1, MAX_SLOTS)
	# Carga la partida del slot actual UNA sola vez al arrancar.
	if hay_partida_guardada():
		cargar_partida()


func _process(delta: float) -> void:
	if _acumulando:
		_tiempo_jugado += delta


## El nivel llama a esto al entrar salir; controla el cronómetro de la partida.
func set_jugando(activo: bool) -> void:
	_acumulando = activo


# ───────────── SLOTS ─────────────

func ruta_slot(n: int) -> String:
	return "user://partida_%d.save" % clampi(n, 1, MAX_SLOTS)


func slot_actual_ruta() -> String:
	return ruta_slot(slot_actual)


func hay_partida_guardada() -> bool:
	return slot_tiene_partida(slot_actual)


func slot_tiene_partida(n: int) -> bool:
	return FileAccess.file_exists(ruta_slot(n))


func set_slot_actual(n: int) -> void:
	slot_actual = clampi(n, 1, MAX_SLOTS)
	var meta := _leer_meta()
	meta["ultimo_slot"] = slot_actual
	_guardar_meta(meta)


## Lista de slots con metadatos para el menú.
func listar_slots() -> Array:
	var meta := _leer_meta()
	var lista: Array = []
	for n in range(1, MAX_SLOTS + 1):
		var info: Dictionary = meta.get(str(n), {})
		var tiene := slot_tiene_partida(n)
		lista.append({
			"slot": n,
			"existe": tiene,
			"horda": int(info.get("horda", 1)),
			"etapa": int(info.get("etapa", 1)),
			"biomasa": int(info.get("biomasa", 0)),
			"fecha": str(info.get("fecha", "")),
			"tiempo": float(info.get("tiempo", 0.0)),
			"activo": n == slot_actual,
		})
	return lista


## Carga un slot y lo deja como actual. Devuelve true si había partida.
func cargar_slot(n: int) -> bool:
	set_slot_actual(n)
	if not slot_tiene_partida(n):
		datos = DATOS_DEFECTO.duplicate(true)
		return false
	return cargar_partida()


## Crea una partida nueva en un slot (sobrescribe).
func nueva_partida_slot(n: int) -> void:
	set_slot_actual(n)
	_tiempo_jugado = 0.0
	nueva_partida()


## Borra un slot (partida + metadatos).
func borrar_slot(n: int) -> void:
	var ruta := ruta_slot(n)
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ruta)
	var meta := _leer_meta()
	meta.erase(str(n))
	_guardar_meta(meta)
	slots_cambiados.emit()


# ───────────── GUARDADO DE PARTIDA ─────────────

func guardar_partida() -> void:
	var archivo := FileAccess.open(slot_actual_ruta(), FileAccess.WRITE)
	if archivo == null:
		push_error("SaveManager: no se pudo abrir el archivo para guardar")
		return
	archivo.store_string(JSON.stringify(datos))
	archivo.close()
	_guardar_meta_slot()
	slots_cambiados.emit()


func cargar_partida() -> bool:
	return cargar_desde_ruta(slot_actual_ruta())


func cargar_desde_ruta(ruta: String) -> bool:
	if not FileAccess.file_exists(ruta):
		return false
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		push_error("SaveManager: no se pudo abrir el archivo para leer")
		return false
	var contenido := archivo.get_as_text()
	archivo.close()

	var resultado = JSON.parse_string(contenido)
	if resultado == null or typeof(resultado) != TYPE_DICTIONARY:
		push_error("SaveManager: archivo de guardado corrupto")
		return false

	datos = DATOS_DEFECTO.duplicate(true)
	for clave in resultado.keys():
		datos[clave] = resultado[clave]
	_fusionar_defecto("stats")
	_fusionar_defecto("mejoras")
	_migrar_balance()

	datos_actualizados.emit()
	stats_actualizados.emit()
	return true


## Rellena las claves que falten de un sub-diccionario anidado con los defaults.
func _fusionar_defecto(clave: String) -> void:
	var actual = datos.get(clave)
	var defecto = DATOS_DEFECTO.get(clave, {})
	if typeof(actual) != TYPE_DICTIONARY or typeof(defecto) != TYPE_DICTIONARY:
		datos[clave] = (defecto as Dictionary).duplicate(true)
		return
	for k in defecto.keys():
		if typeof(defecto[k]) == TYPE_DICTIONARY:
			if typeof(actual.get(k)) != TYPE_DICTIONARY:
				actual[k] = {}
			for kk in (defecto[k] as Dictionary).keys():
				if not actual[k].has(kk):
					actual[k][kk] = defecto[k][kk]
		elif not actual.has(k):
			actual[k] = defecto[k]


## Migra partidas guardadas de versiones anteriores al balance actual. Aplica
## los NUEVOS MÍNIMOS base a las defensas del árbol sin bajar las mejoras ya
## compradas (solo sube las que estén por debajo / baja el "regar_espera").
func _migrar_balance() -> void:
	if int(datos.get("balance_version", 1)) >= BALANCE_VERSION:
		return
	# "Al menos este valor": sube si el guardado está por debajo.
	var al_menos := {
		"arbol.vida_maxima": 1800.0,
		"arbol.regen": 6.0,
		"arbol.espinas": 0.10,
		"arbol.raices_pulso": 6.0,
		"arbol.aura_purificacion": 0.20,
		"arbol.lianas_tiempo": 2.0,
		"arbol.tope_golpe_pct": 0.05,
		"arbol.max_atacantes": 4.0,
	}
	for ruta in al_menos.keys():
		if get_stat(ruta, 0.0) < float(al_menos[ruta]):
			set_stat(ruta, float(al_menos[ruta]))
	# "Como mucho este valor" (menor = mejor): baja si estaba por encima.
	var a_lo_mas := {
		"arbol.regen_espera": 4.0,
		"arbol.dano_recibido_mult": 0.70,
	}
	for ruta in a_lo_mas.keys():
		if get_stat(ruta, 999.0) > float(a_lo_mas[ruta]):
			set_stat(ruta, float(a_lo_mas[ruta]))
	datos["balance_version"] = BALANCE_VERSION
	print("[SaveManager] Balance migrado a v%d (defensas base del árbol)." % BALANCE_VERSION)


func nueva_partida() -> void:
	datos = DATOS_DEFECTO.duplicate(true)
	datos["balance_version"] = BALANCE_VERSION
	_tiempo_jugado = 0.0
	guardar_partida()  # Sobrescribe el archivo inmediatamente con horda 1
	datos_actualizados.emit()
	stats_actualizados.emit()


func borrar_partida() -> void:
	borrar_slot(slot_actual)


# ───────────── METADATOS DE SLOTS ─────────────

func _leer_meta() -> Dictionary:
	if not FileAccess.file_exists(RUTA_SLOTS_META):
		return {}
	var f := FileAccess.open(RUTA_SLOTS_META, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	return d if typeof(d) == TYPE_DICTIONARY else {}


func _guardar_meta(meta: Dictionary) -> void:
	var f := FileAccess.open(RUTA_SLOTS_META, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(meta))
	f.close()


func _guardar_meta_slot() -> void:
	var meta := _leer_meta()
	meta["ultimo_slot"] = slot_actual
	meta[str(slot_actual)] = {
		"horda": get_horda(),
		"etapa": _etapa_desde_horda(get_horda()),
		"biomasa": get_biomasa(),
		"fecha": Time.get_datetime_string_from_system(false, true),
		"tiempo": _tiempo_jugado,
	}
	_guardar_meta(meta)


func _etapa_desde_horda(horda: int) -> int:
	return clampi(int((maxi(horda, 1) - 1) / 10) + 1, 1, 10)


# ───────────── AJUSTES ─────────────

func get_ajuste(clave: String, defecto: Variant = null) -> Variant:
	# Asegura que toda clave conocida exista en memoria (defecto si faltaba).
	if not ajustes.has(clave) and AJUSTES_DEFECTO.has(clave):
		ajustes[clave] = AJUSTES_DEFECTO[clave]
	if ajustes.has(clave):
		return ajustes[clave]
	if defecto != null:
		return defecto
	return null


func set_ajuste(clave: String, valor: Variant) -> void:
	ajustes[clave] = valor
	# No escribe a disco en cada cambio: marca sucio y reprograma el volcado.
	_sucio_ajustes = true
	if _timer_ajustes != null:
		_timer_ajustes.start()
	else:
		guardar_ajustes()
	if clave == "pantalla_completa":
		aplicar_modo_pantalla()
	ajustes_cambiados.emit()


## Aplica el ajuste de pantalla completa (solo escritorio).
func aplicar_modo_pantalla() -> void:
	if OS.has_feature("mobile"):
		return
	var full := bool(get_ajuste("pantalla_completa", false))
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED)


## Fuerza la escritura si hay cambios pendientes. Llamar al salir/pausar/cerrar.
func flush_ajustes() -> void:
	if _sucio_ajustes:
		guardar_ajustes()


func guardar_ajustes() -> void:
	_sucio_ajustes = false
	if _timer_ajustes != null:
		_timer_ajustes.stop()
	var f := FileAccess.open(RUTA_AJUSTES, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: no se pudo guardar ajustes")
		return
	f.store_string(JSON.stringify(ajustes))
	f.close()


func cargar_ajustes() -> void:
	ajustes = AJUSTES_DEFECTO.duplicate(true)
	if FileAccess.file_exists(RUTA_AJUSTES):
		var f := FileAccess.open(RUTA_AJUSTES, FileAccess.READ)
		if f != null:
			var txt := f.get_as_text()
			f.close()
			var d = JSON.parse_string(txt)
			if typeof(d) == TYPE_DICTIONARY:
				for k in d.keys():
					ajustes[k] = d[k]
	# Claves nuevas que no estaban en el archivo guardado.
	for k in AJUSTES_DEFECTO.keys():
		if not ajustes.has(k):
			ajustes[k] = AJUSTES_DEFECTO[k]
	_sanear_ajustes()


## Recorta valores fuera de rango (archivos viejos o editados a mano).
func _sanear_ajustes() -> void:
	for clave in RANGOS_AJUSTES.keys():
		if not ajustes.has(clave):
			continue
		var r: Array = RANGOS_AJUSTES[clave]
		var v = ajustes[clave]
		if typeof(v) == TYPE_BOOL or typeof(v) == TYPE_NIL:
			continue
		if typeof(v) == TYPE_INT:
			ajustes[clave] = clampi(int(v), int(r[0]), int(r[1]))
		elif typeof(v) == TYPE_FLOAT:
			ajustes[clave] = clampf(float(v), float(r[0]), float(r[1]))


func reset_ajustes() -> void:
	ajustes = AJUSTES_DEFECTO.duplicate(true)
	guardar_ajustes()
	ajustes_cambiados.emit()


## Vuelca los ajustes cuando la app pierde foco, se pausa o se cierra.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, \
		NOTIFICATION_WM_GO_BACK_REQUEST, \
		NOTIFICATION_APPLICATION_PAUSED, \
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			flush_ajustes()


# ───────────── Helpers de partida (sin tocar todo el dict) ─────────────

func set_horda(numero: int) -> void:
	datos["horda_actual"] = numero

func get_horda() -> int:
	return int(datos.get("horda_actual", 1))

func set_vida(actual: int, maxima: int = -1) -> void:
	datos["vida_jugador"] = actual
	if maxima > 0:
		datos["vida_maxima"] = maxima

func get_vida() -> int:
	return int(datos.get("vida_jugador", 100))

func get_vida_maxima() -> int:
	return int(datos.get("vida_maxima", 100))

func set_biomasa(cantidad: int) -> void:
	datos["biomasa"] = cantidad

func get_biomasa() -> int:
	return int(datos.get("biomasa", 0))


# ───────────── STATS ─────────────

func get_stat(ruta: String, defecto: float = 0.0) -> float:
	var partes := ruta.split(".", false, 1)
	var stats: Dictionary = datos.get("stats", {})
	if partes.size() == 2:
		var grupo: Dictionary = stats.get(partes[0], {})
		if grupo.has(partes[1]):
			return float(grupo[partes[1]])
	return defecto

func set_stat(ruta: String, valor) -> void:
	var partes := ruta.split(".", false, 1)
	if partes.size() != 2:
		push_warning("SaveManager.set_stat: ruta inválida '%s'" % ruta)
		return
	var stats: Dictionary = datos.get("stats", {})
	if not stats.has(partes[0]):
		stats[partes[0]] = {}
	stats[partes[0]][partes[1]] = valor

func sumar_stat(ruta: String, delta: float) -> void:
	set_stat(ruta, get_stat(ruta) + delta)

func multiplicar_stat(ruta: String, pct: float) -> void:
	set_stat(ruta, get_stat(ruta) * (1.0 + pct))

func notificar_stats() -> void:
	stats_actualizados.emit()


# ───────────── MEJORAS ─────────────

func get_mejora(id: String) -> int:
	var mejoras: Dictionary = datos.get("mejoras", {})
	return int(mejoras.get(id, 0))

func subir_mejora(id: String) -> int:
	var mejoras: Dictionary = datos.get("mejoras", {})
	mejoras[id] = int(mejoras.get(id, 0)) + 1
	datos["mejoras"] = mejoras
	return mejoras[id]

func get_mejoras() -> Dictionary:
	return (datos.get("mejoras", {}) as Dictionary).duplicate()
