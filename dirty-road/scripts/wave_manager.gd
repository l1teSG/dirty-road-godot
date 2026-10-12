class_name WaveManager
extends Node2D

## ══════════════════════════════════════════════════════════
##  WAVE MANAGER — única fuente de verdad de oleadas, spawns y escalado.
##
##  MODELO:
##  • El RELOJ manda: la oleada dura su tiempo y los enemigos entran
##    en spawn continuo cada tiempo_entre_spawns hasta que termine.
##    Matar enemigos NO adelanta nada.
##  • Oleada de JEFE: la ÚLTIMA de cada etapa (sin reloj; solo cierra
##    al morir el jefe). Los escoltas salen del pool normal, con tope
##    etapa.jefe_escoltas.
##  • Escalado: life/speed/damage se aplican ANTES de add_child.
##    Vida   = base × etapa.mult_vida × cfg.mult_vida × (1 + (ol−1) × escalado_vida)
##    Daño   = base × etapa.mult_danio × (1 + (ol−1) × escalado_danio)
##    Veloc. = base × etapa.mult_velocidad   (no hay escalado por oleada)
##  • Referencias: jugador y árbol se resuelven POR GRUPOS (con caché)
##    y se inyectan antes de add_child. Nada se asigna a mano.
##  • ARRANQUE ESPERADO: la primera iniciar_oleada() de la partida
##    queda en espera hasta que terminan los mensajes iniciales del
##    EducationManager (señal, liberar_arranque() o timeout).
## ══════════════════════════════════════════════════════════

signal oleada_iniciada(numero_oleada: int)
signal oleada_completada(numero_oleada: int)
signal tiempo_actualizado(segundos_restantes: int, es_descanso: bool)
signal descanso_iniciado(tiempo_total: float)
signal enemigos_restantes_actualizado(cantidad: int)
signal etapa_iniciada(indice: int, nombre: String)
signal jefe_aparecido(jefe: Node2D, nombre: String)
signal jefe_derrotado(nombre: String)
## Se emite cuando termina una etapa y el juego espera a que el jugador
## cruce la puerta para pasar al siguiente escenario.
signal etapa_completada(indice: int)
## Arranque esperado: avisos para la UI ("Prepárate...").
signal arranque_en_espera
signal arranque_liberado

@export_category("Configuración")
@export var puntos_spawn: Array[Node2D] = []
@export var punto_spawn_jefe: Node2D

@export_category("Etapas")
## Orden: etapa_01, etapa_02, etapa_03...
@export var etapas: Array[EtapaConfig] = []
@export var oleadas_por_etapa: int = 10

@export_category("Tiempos")
## Frecuencia de refuerzos: cada cuántos segundos entra un enemigo.
## Es EL knob de presión: a menor valor, más enemigos por oleada.
@export var tiempo_entre_spawns: float = 1.2
## Duración BASE de la oleada (luego la escalan los aumentos micro/macro).
@export var tiempo_maximo_oleada: float = 40.0
@export var tiempo_descanso: float = 5.0

@export_category("Duración de oleadas")
## Aumento MICRO: la oleada N de la etapa dura base × (1 + esto × (N−1)). 0 = fija.
@export_range(0.0, 2.0) var aumento_duracion_por_oleada: float = 0.10
## Aumento MACRO: + este % por cada etapa avanzada (etapa 1 = ×1.0).
@export_range(0.0, 2.0) var aumento_duracion_por_etapa: float = 0.0
## Tope de duración en segundos (0 = sin tope).
@export var duracion_maxima_oleada: float = 0.0

@export_category("Spawns")
## Reserva (sin etapas o como tope duro extra): enemigos vivos a la vez.
## 0 = sin tope. Con etapas, el tope por oleada sale de la etapa
## (enemigos_base_por_oleada + incremento × (pos − 1)); si esta cifra es
## menor, actúa como tope duro adicional.
@export var max_enemigos_simultaneos: int = 0
## Al acabar el tiempo: true elimina a los vivos (y sueltan orbes); false los
## deja en pantalla y se mezclan con la siguiente oleada (siguen atacando).
@export var eliminar_sobrevivientes: bool = true

@export_category("Debug")
@export var debug_activo: bool = false
@export var debug_oleada_inicial: int = 1
@export var debug_no_guardar: bool = true
@export var debug_spawnear_enemigos: bool = true
## Si no está vacío, SOLO aparecen estos enemigos (ahora TAMBIÉN respetan
## su ventana, salvo que actives el toggle de abajo).
@export var debug_enemigos_fijos: Array[EnemigoOleadaConfig] = []
## Comportamiento antiguo: los enemigos fijos ignoran su ventana de
## oleadas. Déjalo en false para probar debuts reales.
@export var debug_fijos_ignoran_ventana: bool = false
@export var debug_sin_limite_tiempo: bool = false
## 0 = usa el tiempo de descanso normal
@export var debug_descanso: float = 0.0
@export var debug_imprimir_info: bool = true

@export_category("Arranque")
## Si es true, la primera oleada NO arranca sola al iniciar la partida:
## espera a que terminen los mensajes iniciales del EducationManager.
@export var esperar_mensajes_iniciales: bool = true
## Nombre EXACTO de la señal del EducationManager que avisa que los
## mensajes terminaron. Vacío = no escucha señales (usa timeout/manual).
@export var senal_fin_mensajes: String = ""
## Red de seguridad: segundos máximo de espera antes de arrancar igual.
## 0 = sin tope (solo arranca por señal o por liberar_arranque()).
@export var tiempo_maximo_espera: float = 20.0
## Si es true, al terminar la última oleada de una etapa el juego NO avanza
## solo: espera a que el jugador cruce la puerta (continuar_tras_puerta()).
@export var esperar_puerta_al_terminar_etapa: bool = true

var oleada_actual: int = 1
var enemigos_vivos: int = 0
## LEGADO: ya no hay cola fija de spawns; siempre 0. Se conserva porque
## la UI y otros sistemas pueden sumarla al contador de restantes.
var enemigos_por_spawnear: int = 0
var en_descanso: bool = false
var tiempo_restante: int = 0

var spawn_timer: Timer
var rest_timer: Timer
var ui_timer: Timer
var duracion_timer: Timer

var etapa_actual_idx: int = -1
var jefe_actual: Node2D = null
var oleada_de_jefe: bool = false

var _generacion: int = 0
var _descanso_jefe_actual: float = 0.0
var _duracion_oleada_actual: float = 0.0
var _enemigos_vivos_por_tipo: Dictionary = {}
var _aviso_sin_jugador: bool = false
var _aviso_sin_arbol: bool = false
var _aviso_sin_spawns: bool = false
var _jugador_ref: Node2D = null
var _arbol_ref: Node2D = null
var _nombre_jefe: String = ""
var _cerrando_oleada: bool = false
var _bajas_contabilizadas: Dictionary = {}
## instance_id del enemigo → ruta de su escena (para cupos y educación).
var _ruta_por_instancia: Dictionary = {}
## Para imprimir el pool una sola vez por oleada, no en cada tick.
var _pool_impreso_para: int = -1
## Escoltas que faltan por entrar en la oleada de jefe.
var _escoltas_restantes: int = 0

## true cuando esta partida empezó con "Nueva partida" desde un menú:
## anula los overrides de ARRANQUE del debug (oleada inicial / enemigos
## fijos) para que la partida siempre arranque limpia en la horda 1.
var _ignorar_debug := false
## true mientras el juego espera a que el jugador cruce la puerta de etapa.
var _esperando_puerta := false

# ── Puerta de arranque (internos) ──
var _arranque_resuelto: bool = false
var _arranque_pendiente: bool = true
var _fin_mensajes: bool = false
var _esperando_arranque: bool = false


# ───────────── CICLO DE VIDA ─────────────

func _ready() -> void:
	add_to_group("wave_manager")

	spawn_timer = _crear_timer(false, tiempo_entre_spawns)
	spawn_timer.timeout.connect(_spawnear_siguiente_enemigo)

	rest_timer = _crear_timer(true, tiempo_descanso)
	rest_timer.timeout.connect(_on_descanso_terminado)

	ui_timer = _crear_timer(false, 1.0)
	ui_timer.timeout.connect(_on_ui_tick)

	duracion_timer = _crear_timer(true, tiempo_maximo_oleada)
	duracion_timer.timeout.connect(_terminar_oleada_por_tiempo)

	# Diferido: nunca iniciar durante el montaje de la escena.
	iniciar_oleada.call_deferred()


func _crear_timer(uno_solo: bool, duracion: float) -> Timer:
	var t := Timer.new()
	t.one_shot = uno_solo
	t.wait_time = maxf(0.05, duracion)
	add_child(t)
	return t


# ───────────── RESOLUCIÓN INICIAL (una vez por partida) ─────────────

## El menú "Nueva partida" puede llamarlo ANTES de cargar el nivel
## (p. ej. guardándolo en un autoload y aplicándolo al entrar) para que
## los overrides de debug no afecten la partida real.
func marcar_nueva_partida() -> void:
	_ignorar_debug = true


func _resolver_arranque() -> void:
	# Progreso guardado: retoma la horda donde quedó.
	if SaveManager != null and SaveManager.has_method("get_horda"):
		oleada_actual = maxi(1, int(SaveManager.call("get_horda")))
	# Overrides de ARRANQUE del debug (solo si no es partida nueva).
	if debug_activo and not _ignorar_debug:
		oleada_actual = maxi(debug_oleada_inicial, 1)
	var edu := _educacion()
	if edu != null and edu.has_method("start_run"):
		edu.call("start_run")


# ───────────── PUERTA DE ARRANQUE ─────────────
## La primera iniciar_oleada() de la partida se detiene aquí hasta que
## terminen los mensajes iniciales. La suelta lo que ocurra primero:
##  1) El EducationManager emite la señal `senal_fin_mensajes`.
##  2) Alguien llama liberar_arranque() (cierre del último mensaje o botón).
##  3) Se agota tiempo_maximo_espera (si > 0).

func _esperar_mensajes_iniciales() -> void:
	if not esperar_mensajes_iniciales:
		return
	var edu := _educacion()
	if edu == null:
		return  # Sin sistema educativo no hay mensajes que esperar.

	_esperando_arranque = true
	arranque_en_espera.emit()
	_fin_mensajes = false
	if debug_imprimir_info:
		print("[WaveManager] En espera de los mensajes iniciales...")

	var conectado := false
	var senal := String(senal_fin_mensajes)
	if senal != "" and edu.has_signal(senal):
		if not edu.is_connected(senal, _on_fin_mensajes):
			edu.connect(senal, _on_fin_mensajes)
		conectado = true
	elif senal != "":
		push_warning("[WaveManager] '%s' no tiene la señal '%s'. Revisa senal_fin_mensajes o llama liberar_arranque()." % [edu.name, senal])

	var t0 := Time.get_ticks_msec()
	while is_inside_tree():
		if _fin_mensajes:
			break
		if not conectado and tiempo_maximo_espera <= 0.0:
			# Sin señal detectable ni tope de tiempo: no esperaría nunca.
			break
		if tiempo_maximo_espera > 0.0 \
				and (Time.get_ticks_msec() - t0) / 1000.0 >= tiempo_maximo_espera:
			if debug_imprimir_info:
				print("[WaveManager] Timeout de arranque (%.1fs): arranca la oleada igual." % tiempo_maximo_espera)
			break
		await get_tree().process_frame

	_esperando_arranque = false
	arranque_liberado.emit()
	if debug_imprimir_info:
		print("[WaveManager] Arranque liberado: comienza la oleada 1.")


func _on_fin_mensajes() -> void:
	_fin_mensajes = true


## Suelta la puerta manualmente. Llámalo desde el cierre del último
## mensaje inicial o desde un botón "¡A pelear!".
func liberar_arranque() -> void:
	_fin_mensajes = true


## Para consultar desde la UI u otros sistemas.
func esta_esperando_arranque() -> bool:
	return _esperando_arranque


# ───────────── ETAPAS Y OLEADAS ─────────────

func iniciar_oleada() -> void:
	# Si el juego espera a la puerta de etapa, NO arrancar todavía.
	if _esperando_puerta:
		return
	# Resolución inicial: guardado, overrides de debug, start_run.
	if not _arranque_resuelto:
		_arranque_resuelto = true
		_resolver_arranque()

	# PUERTA DE ARRANQUE: solo actúa la primera vez de la partida.
	if _arranque_pendiente:
		_arranque_pendiente = false
		if esperar_mensajes_iniciales and not debug_activo:
			await _esperar_mensajes_iniciales()

	# Etapa que corresponde a esta oleada global (emite etapa_iniciada
	# solo cuando cambia).
	var idx := _etapa_idx_para(oleada_actual)
	if idx >= 0 and idx != etapa_actual_idx:
		_iniciar_etapa(idx)

	oleada_de_jefe = _es_oleada_de_jefe()
	var etapa := _etapa_actual()
	_escoltas_restantes = 0
	if oleada_de_jefe and etapa != null:
		_escoltas_restantes = maxi(etapa.jefe_escoltas, 0)

	en_descanso = false
	_pool_impreso_para = -1

	oleada_iniciada.emit(oleada_actual)
	var edu := _educacion()
	if edu != null and edu.has_method("on_wave_started"):
		edu.call("on_wave_started")

	if oleada_de_jefe:
		if etapa != null and etapa.jefe_escena != null:
			_spawnear_jefe()
		else:
			push_warning("[WaveManager] Oleada de jefe sin jefe_escena en la etapa: sigue como oleada normal.")

	# Reloj (la oleada de jefe no tiene: cierra solo con el jefe muerto).
	if debug_activo and debug_sin_limite_tiempo:
		tiempo_restante = 0
	else:
		var dur := _duracion_de_oleada()
		_duracion_oleada_actual = dur
		tiempo_restante = int(ceil(dur))
		duracion_timer.start(dur)
		ui_timer.start(1.0)

	if _spawns_activos():
		spawn_timer.start(tiempo_entre_spawns)

	_imprimir_pool_si_toca()
	_notificar_enemigos_restantes()


func _iniciar_etapa(idx: int) -> void:
	etapa_actual_idx = idx
	var nombre := "Etapa %d" % (idx + 1)
	var etapa := _etapa_actual()
	if etapa != null and not etapa.nombre.is_empty():
		nombre = etapa.nombre
	etapa_iniciada.emit(idx, nombre)
	var edu := _educacion()
	if edu != null and edu.has_method("on_stage_started"):
		edu.call("on_stage_started", idx)
	if debug_imprimir_info:
		print("[WaveManager] Etapa %d: %s" % [idx + 1, nombre])


func _etapa_idx_para(oleada_global: int) -> int:
	if etapas.is_empty():
		return -1
	return clampi((oleada_global - 1) / oleadas_por_etapa, 0, etapas.size() - 1)


func _pos_en_etapa() -> int:
	if etapa_actual_idx < 0:
		return oleada_actual
	return ((oleada_actual - 1) % oleadas_por_etapa) + 1


func _etapa_actual() -> EtapaConfig:
	if etapa_actual_idx < 0 or etapa_actual_idx >= etapas.size():
		return null
	return etapas[etapa_actual_idx]


func _es_oleada_de_jefe() -> bool:
	var etapa := _etapa_actual()
	if etapa == null or etapa.jefe_escena == null:
		return false
	return _pos_en_etapa() == oleadas_por_etapa


func _duracion_de_oleada() -> float:
	var pos := _pos_en_etapa()
	var dur := tiempo_maximo_oleada \
		* (1.0 + aumento_duracion_por_oleada * float(pos - 1)) \
		* (1.0 + aumento_duracion_por_etapa * float(maxi(etapa_actual_idx, 0)))
	if duracion_maxima_oleada > 0.0:
		dur = minf(dur, duracion_maxima_oleada)
	return maxf(dur, 1.0)


# ───────────── CIERRE Y DESCANSO ─────────────

## Reloj agotado: cierra la oleada, guarda y descansa.
func _terminar_oleada_por_tiempo() -> void:
	_cerrar_oleada(_duracion_descanso())


## Cierre unificado (reloj o muerte del jefe): un solo incremento y un
## solo guardado. `descanso` <= 0 encadena la siguiente oleada al instante.
func _cerrar_oleada(descanso: float) -> void:
	if _cerrando_oleada:
		return
	_cerrando_oleada = true

	spawn_timer.stop()
	duracion_timer.stop()
	ui_timer.stop()
	tiempo_actualizado.emit(0, false)

	if eliminar_sobrevivientes:
		_limpiar_enemigos_vivos()

	oleada_completada.emit(oleada_actual)
	var edu := _educacion()
	if edu != null and edu.has_method("on_wave_ended"):
		edu.call("on_wave_ended")

	oleada_actual += 1
	if SaveManager != null and not debug_no_guardar:
		SaveManager.set_horda(oleada_actual)

	_cerrando_oleada = false
	iniciar_fase_descanso(descanso)


func _duracion_descanso() -> float:
	if debug_activo and debug_descanso > 0.0:
		return debug_descanso
	return tiempo_descanso


## Los spawns están activos salvo que el MODO DEBUG los desactive.
## (Antes 'debug_spawnear_enemigos' bloqueaba los spawns incluso sin debug,
## dejando el juego sin enemigos.)
func _spawns_activos() -> bool:
	return not debug_activo or debug_spawnear_enemigos


func iniciar_fase_descanso(duracion: float) -> void:
	if duracion <= 0.0:
		_on_descanso_terminado()
		return
	en_descanso = true
	tiempo_restante = int(ceil(duracion))
	if debug_imprimir_info:
		print("[WaveManager] Descanso iniciado: %.1fs (tiempo sigue corriendo)." % duracion)
	descanso_iniciado.emit(float(tiempo_restante))
	tiempo_actualizado.emit(tiempo_restante, true)
	rest_timer.start(duracion)
	ui_timer.start(1.0)


func _on_descanso_terminado() -> void:
	if not en_descanso:
		return
	en_descanso = false
	ui_timer.stop()
	if debug_imprimir_info:
		print("[WaveManager] Descanso terminado → arranca oleada %d." % oleada_actual)
	iniciar_oleada()


## Cierra el descanso de inmediato (el jugador ya eligió/saltó su carta).
## El descanso NO se pausa: su cuenta atrás sigue corriendo; esto solo lo
## adelanta cuando el jugador decide.
func terminar_descanso() -> void:
	if not en_descanso:
		if debug_imprimir_info:
			print("[WaveManager] terminar_descanso() ignorado (no hay descanso activo).")
		return
	if debug_imprimir_info:
		print("[WaveManager] terminar_descanso(): el jugador ya decidió.")
	rest_timer.stop()
	_on_descanso_terminado()


func _on_ui_tick() -> void:
	tiempo_restante = maxi(tiempo_restante - 1, 0)
	tiempo_actualizado.emit(tiempo_restante, en_descanso)


func _limpiar_enemigos_vivos() -> void:
	# Invalida los tree_exited pendientes de esta oleada.
	_generacion += 1
	var limpiados := 0
	for e in get_tree().get_nodes_in_group("enemigos"):
		# Los sobrantes "mueren": sueltan orbes que persiguen al jugador.
		if e.has_method("morir_por_fin_de_oleada"):
			e.call("morir_por_fin_de_oleada")
		else:
			e.queue_free()
		limpiados += 1
	# Proyectiles enemigos que quedan volando.
	var proyectiles := get_tree().get_nodes_in_group("proyectil_enemigo").size()
	for p in get_tree().get_nodes_in_group("proyectil_enemigo"):
		p.queue_free()
	if debug_imprimir_info:
		print("[WaveManager] Cierre de oleada: %d enemigos limpiados (sueltan orbes), %d proyectiles." % [limpiados, proyectiles])
	enemigos_vivos = 0
	_enemigos_vivos_por_tipo.clear()
	_notificar_enemigos_restantes()


# ───────────── SPAWNS ─────────────

func _spawnear_siguiente_enemigo() -> void:
	if en_descanso or not _spawns_activos():
		return
	if oleada_de_jefe and _escoltas_restantes <= 0:
		return  # El jefe ya tiene todos sus escoltas.

	# Tope de simultáneos: se salta la tanda y reintenta en el siguiente
	# tick; el reloj NO se pausa.
	var tope := _tope_simultaneos()
	if tope > 0 and enemigos_vivos >= tope:
		return

	var cfg := _elegir_enemigo()
	if cfg == null:
		return

	var escena := _cfg_escena(cfg)
	if escena == null:
		if debug_imprimir_info:
			printerr("[WaveManager] Entrada del pool sin escena válida.")
		return

	var enemigo := escena.instantiate() as Node2D
	if enemigo == null:
		push_warning("[WaveManager] La escena del pool no es un Node2D: %s" % escena.resource_path)
		return

	var clave := escena.resource_path
	_escalar_stats(enemigo, cfg)
	_pasar_referencias(enemigo)
	_registrar_baja(enemigo, clave)
	enemigo.position = _posicion_spawn()

	if oleada_de_jefe:
		_escoltas_restantes -= 1
	_enemigos_vivos_por_tipo[clave] = int(_enemigos_vivos_por_tipo.get(clave, 0)) + 1
	enemigos_vivos += 1
	# Diferido: nunca add_child durante señales de física ni el montaje.
	get_tree().current_scene.add_child.call_deferred(enemigo)
	_notificar_enemigos_restantes()

	var edu := _educacion()
	if edu != null and edu.has_method("on_enemy_encountered"):
		edu.call("on_enemy_encountered", _obtener_enemy_id(clave))


func _tope_simultaneos() -> int:
	var tope := 0
	var etapa := _etapa_actual()
	if etapa != null:
		tope = etapa.enemigos_base_por_oleada \
			+ etapa.incremento_enemigos_por_oleada * (_pos_en_etapa() - 1)
	if max_enemigos_simultaneos > 0 and (tope <= 0 or max_enemigos_simultaneos < tope):
		tope = max_enemigos_simultaneos
	return tope


## Pool de la oleada: fijos de debug (si hay) o la etapa con herencia.
func _pool_para_oleada() -> Array:
	if debug_activo and not debug_enemigos_fijos.is_empty():
		return debug_enemigos_fijos
	var etapa := _etapa_actual()
	if etapa == null:
		return []
	var pool: Array = []
	if etapa.heredar_enemigos_anteriores:
		for i in range(etapa_actual_idx):
			var prev := etapas[i] as EtapaConfig
			if prev != null:
				pool.append_array(prev.enemigos)
	pool.append_array(etapa.enemigos)
	return pool


## Sorteo ponderado respetando ventana de oleadas y cupo por tipo.
func _elegir_enemigo() -> Resource:
	var pos := _pos_en_etapa()
	var candidatos: Array = []
	for cfg in _pool_para_oleada():
		if cfg == null:
			continue
		if not _en_ventana(cfg, pos):
			continue
		if not _tiene_cupo(cfg):
			continue
		candidatos.append(cfg)
	if candidatos.is_empty():
		return null

	var total := 0.0
	for c in candidatos:
		total += maxf(_cfg_float(c, "peso", 1.0), 0.01)
	var r := randf() * total
	for c in candidatos:
		r -= maxf(_cfg_float(c, "peso", 1.0), 0.01)
		if r <= 0.0:
			return c
	return candidatos.back()


func _en_ventana(cfg: Resource, pos: int) -> bool:
	if debug_activo and debug_fijos_ignoran_ventana and debug_enemigos_fijos.has(cfg):
		return true
	var minima := _cfg_int(cfg, "oleada_minima", 1)
	var maxima := _cfg_int(cfg, "oleada_maxima", 0)
	return pos >= minima and (maxima <= 0 or pos <= maxima)


func _tiene_cupo(cfg: Resource) -> bool:
	var maximo := _cfg_int(cfg, "max_simultaneos", 0)
	if maximo <= 0:
		return true
	var esc := _cfg_escena(cfg)
	if esc == null:
		return true
	return int(_enemigos_vivos_por_tipo.get(esc.resource_path, 0)) < maximo


func _posicion_spawn() -> Vector2:
	if not puntos_spawn.is_empty():
		# Tipado EXPLÍCITO: pick_random() devuelve Variant y con ':='
		# el warning-as-error tira "typed as Variant".
		var punto: Node2D = puntos_spawn.pick_random()
		if punto != null:
			return punto.global_position
	if punto_spawn_jefe != null:
		return punto_spawn_jefe.global_position
	if not _aviso_sin_spawns:
		_aviso_sin_spawns = true
		push_warning("[WaveManager] Sin puntos_spawn asignados: los enemigos entran en (0,0).")
	return Vector2.ZERO


## Aplica el escalado de etapa + oleada ANTES de add_child.
## cfg = null para el jefe (solo etapa + escalado por oleada).
func _escalar_stats(enemigo: Node2D, cfg: Resource) -> void:
	var mult_vida_etapa := 1.0
	var mult_vel_etapa := 1.0
	var mult_danio_etapa := 1.0
	var esc_vida := 0.0
	var esc_danio := 0.0
	var etapa := _etapa_actual()
	if etapa != null:
		mult_vida_etapa = etapa.mult_vida
		mult_vel_etapa = etapa.mult_velocidad
		mult_danio_etapa = etapa.mult_danio
		esc_vida = etapa.escalado_vida_por_oleada
		esc_danio = etapa.escalado_danio_por_oleada

	var mult_vida_cfg := 1.0
	if cfg != null:
		mult_vida_cfg = _cfg_float(cfg, "mult_vida", 1.0)

	var oleadas_previas := maxi(oleada_actual - 1, 0)
	var f_vida := mult_vida_etapa * mult_vida_cfg * (1.0 + float(oleadas_previas) * esc_vida)
	var f_danio := mult_danio_etapa * (1.0 + float(oleadas_previas) * esc_danio)
	var f_vel := mult_vel_etapa

	var vida_base := _f_enemigo(enemigo, "life", 10.0)
	var vel_base := _f_enemigo(enemigo, "speed", 100.0)
	var danio_base := _f_enemigo(enemigo, "damage", 5.0)
	enemigo.set("life", vida_base * f_vida)
	enemigo.set("speed", vel_base * f_vel)
	enemigo.set("damage", danio_base * f_danio)

	# Agro por TIPO: override opcional por entrada del pool ("auto" = el del enemigo).
	if cfg != null:
		var obj := String(cfg.get("objetivo"))
		if obj != "" and obj != "auto":
			enemigo.set("objetivo_tipo", obj)

	if debug_imprimir_info:
		print("[WaveManager] Stats %s → vida %.1f (×%.2f), daño %.1f (×%.2f), vel %.0f (×%.2f)" \
			% [enemigo.name, vida_base * f_vida, f_vida, danio_base * f_danio, f_danio, vel_base * f_vel, f_vel])


# ───────────── JEFE ─────────────

func _spawnear_jefe() -> void:
	var etapa := _etapa_actual()
	if etapa == null or etapa.jefe_escena == null:
		return
	var jefe := etapa.jefe_escena.instantiate() as Node2D
	if jefe == null:
		push_warning("[WaveManager] La escena del jefe no es un Node2D.")
		return

	var clave := etapa.jefe_escena.resource_path
	_escalar_stats(jefe, null)
	_pasar_referencias(jefe)
	_registrar_baja(jefe, clave)
	_enemigos_vivos_por_tipo[clave] = int(_enemigos_vivos_por_tipo.get(clave, 0)) + 1
	# El jefe cierra su oleada al salir del árbol (muerte).
	jefe.tree_exited.connect(_on_jefe_muerto.bind(etapa.jefe_nombre, _generacion))
	_nombre_jefe = etapa.jefe_nombre
	_descanso_jefe_actual = etapa.jefe_tiempo_descanso if etapa.jefe_tiempo_descanso > 0.0 else tiempo_descanso

	if punto_spawn_jefe != null:
		jefe.position = punto_spawn_jefe.global_position
	else:
		jefe.position = _posicion_spawn()

	# Diferido: nunca add_child durante el montaje de la escena.
	get_tree().current_scene.add_child.call_deferred(jefe)

	jefe_actual = jefe
	enemigos_vivos += 1
	jefe_aparecido.emit(jefe, etapa.jefe_nombre)
	_notificar_enemigos_restantes()

	var edu := _educacion()
	if edu != null and edu.has_method("on_enemy_encountered"):
		edu.call("on_enemy_encountered", _obtener_enemy_id(clave))


func _on_jefe_muerto(nombre: String, generacion: int) -> void:
	# Ignora avisos de generaciones cerradas (limpieza, cambio de escena).
	if generacion != _generacion or jefe_actual == null:
		return
	jefe_actual = null
	oleada_de_jefe = false
	if nombre.is_empty():
		nombre = _nombre_jefe
	jefe_derrotado.emit(nombre)
	var edu := _educacion()
	if edu != null and edu.has_method("on_boss_defeated"):
		edu.call("on_boss_defeated", etapa_actual_idx)
	_cerrar_oleada_tras_jefe()


## Cierra la oleada del jefe. Si hay siguiente etapa y está activada la
## puerta, se espera a que el jugador la cruce antes de arrancar.
func _cerrar_oleada_tras_jefe() -> void:
	if esperar_puerta_al_terminar_etapa and _hay_siguiente_etapa():
		_esperando_puerta = true
		_cerrar_oleada(tiempo_descanso)
		etapa_completada.emit(etapa_actual_idx)
	else:
		_cerrar_oleada(_descanso_jefe_actual)


func _hay_siguiente_etapa() -> bool:
	if etapas.is_empty():
		return false
	return _etapa_idx_para(oleada_actual + 1) > etapa_actual_idx


## Reanuda las oleadas tras cruzar la puerta (lo llama el nivel).
func continuar_tras_puerta() -> void:
	if not _esperando_puerta:
		return
	_esperando_puerta = false
	iniciar_oleada()


func esperando_puerta() -> bool:
	return _esperando_puerta


# ───────────── BAJAS Y CONTADORES ─────────────

func _registrar_baja(enemigo: Node2D, ruta_tipo: String) -> void:
	if not enemigo.is_in_group("enemigos"):
		enemigo.add_to_group("enemigos")
	_ruta_por_instancia[enemigo.get_instance_id()] = ruta_tipo
	if enemigo.has_signal("murio"):
		# 'murio' YA emite el propio enemigo (murio.emit(self) en Enemigo.gd).
		# NO hacer bind: el bind añadía un 2º argumento y provocaba
		# "Method expected 1 argument(s), but called with 2".
		enemigo.connect("murio", _on_enemigo_muerto)
	enemigo.connect("tree_exited", _on_enemigo_salio.bind(enemigo))


func _on_enemigo_muerto(enemigo: Node2D) -> void:
	if enemigo == null:
		return
	var id := enemigo.get_instance_id()
	if _bajas_contabilizadas.has(id):
		return
	_bajas_contabilizadas[id] = true
	_aviso_educativo_muerte(id)


func _on_enemigo_salio(enemigo: Node2D) -> void:
	if enemigo == null:
		return
	var id := enemigo.get_instance_id()
	_bajas_contabilizadas.erase(id)
	var clave: String = _ruta_por_instancia.get(id, "")
	_ruta_por_instancia.erase(id)
	if clave != "" and _enemigos_vivos_por_tipo.has(clave):
		var restantes := int(_enemigos_vivos_por_tipo[clave]) - 1
		if restantes <= 0:
			_enemigos_vivos_por_tipo.erase(clave)
		else:
			_enemigos_vivos_por_tipo[clave] = restantes
	enemigos_vivos = maxi(enemigos_vivos - 1, 0)
	_notificar_enemigos_restantes()


func _notificar_enemigos_restantes() -> void:
	enemigos_restantes_actualizado.emit(enemigos_vivos + enemigos_por_spawnear)


# ───────────── REFERENCIAS (por grupos, con caché) ─────────────

func _obtener_jugador() -> Node2D:
	if _jugador_ref != null and is_instance_valid(_jugador_ref):
		return _jugador_ref
	_jugador_ref = get_tree().get_first_node_in_group("jugador") as Node2D
	if _jugador_ref == null:
		_jugador_ref = get_tree().get_first_node_in_group("player") as Node2D
	if _jugador_ref == null and not _aviso_sin_jugador:
		_aviso_sin_jugador = true
		push_warning("[WaveManager] No encontré al jugador en el grupo 'jugador' ni 'player'.")
	return _jugador_ref


func _obtener_arbol() -> Node2D:
	if _arbol_ref != null and is_instance_valid(_arbol_ref):
		return _arbol_ref
	_arbol_ref = get_tree().get_first_node_in_group("arbol") as Node2D
	if _arbol_ref == null and not _aviso_sin_arbol:
		_aviso_sin_arbol = true
		push_warning("[WaveManager] No encontré el árbol en el grupo 'arbol'.")
	return _arbol_ref


func _pasar_referencias(enemigo: Node2D) -> void:
	var jug := _obtener_jugador()
	if jug != null:
		enemigo.set("jugador", jug)
	var arb := _obtener_arbol()
	if arb != null:
		enemigo.set("arbol", arb)


# ───────────── EDUCACIÓN ─────────────

func _educacion() -> Node:
	return get_node_or_null("/root/EducationManager")


func _aviso_educativo_muerte(id_instancia: int) -> void:
	var edu := _educacion()
	if edu == null:
		return
	var clave: String = _ruta_por_instancia.get(id_instancia, "")
	if clave == "":
		return
	if edu.has_method("on_enemy_defeated"):
		edu.call("on_enemy_defeated", _obtener_enemy_id(clave))


# ───────────── HELPERS ─────────────

func _cfg_escena(cfg: Resource) -> PackedScene:
	var v: Variant = cfg.get("escena")
	if v == null:
		v = cfg.get("escena_enemigo")
	return v as PackedScene


## Nombre legible de una entrada del pool (para el print de debug).
func _cfg_nombre(cfg: Resource) -> String:
	var v: Variant = cfg.get("nombre")
	if v != null and not String(v).is_empty():
		return String(v)
	var esc := _cfg_escena(cfg)
	if esc != null and esc.resource_path != "":
		return esc.resource_path.get_file().get_basename()
	return "sin_nombre"


func _cfg_int(cfg: Resource, propiedad: String, defecto: int) -> int:
	var v: Variant = cfg.get(propiedad)
	return defecto if v == null else int(v)


func _cfg_float(cfg: Resource, propiedad: String, defecto: float) -> float:
	var v: Variant = cfg.get(propiedad)
	return defecto if v == null else float(v)


func _f_enemigo(enemigo: Node2D, propiedad: String, defecto: float) -> float:
	var v: Variant = enemigo.get(propiedad)
	return defecto if v == null else float(v)


func _obtener_enemy_id(ruta: String) -> String:
	var id := ruta.get_file().get_basename()
	return id if id != "" else ruta


func _imprimir_pool_si_toca() -> void:
	if not debug_imprimir_info or _pool_impreso_para == oleada_actual:
		return
	_pool_impreso_para = oleada_actual
	var pos := _pos_en_etapa()
	var lineas: Array[String] = []
	for cfg in _pool_para_oleada():
		if cfg == null:
			continue
		var minima := _cfg_int(cfg, "oleada_minima", 1)
		var maxima := _cfg_int(cfg, "oleada_maxima", 0)
		var disponible := _en_ventana(cfg, pos) and _tiene_cupo(cfg)
		var ventana := "%d-%s" % [minima, "inf" if maxima <= 0 else str(maxima)]
		var marca := "" if disponible else " (fuera o sin cupo)"
		lineas.append("%s[%s]%s" % [_cfg_nombre(cfg), ventana, marca])
	print("[WaveManager] Pool etapa %d · oleada %d (pos %d): %s" \
		% [etapa_actual_idx + 1, oleada_actual, pos, " | ".join(lineas)])
