class_name WaveManager
extends Node2D

signal oleada_iniciada(numero_oleada: int)
signal oleada_completada(numero_oleada: int)
signal tiempo_actualizado(segundos_restantes: int, es_descanso: bool)
signal descanso_iniciado(tiempo_total: float)
signal enemigos_restantes_actualizado(cantidad: int)
signal etapa_iniciada(indice: int, nombre: String)
signal jefe_aparecido(jefe: Node2D, nombre: String)
signal jefe_derrotado(nombre: String)

@export_category("Configuración")
@export var puntos_spawn: Array[Node2D] = []
@export var punto_spawn_jefe: Node2D

@export_category("Etapas")
## Orden: etapa_01, etapa_02, etapa_03...
@export var etapas: Array[EtapaConfig] = []
@export var oleadas_por_etapa: int = 10

@export_category("Tiempos")
## Frecuencia de refuerzos: cada cuántos segundos entra un enemigo.
## Es EL knob de presión ahora: a menor valor, más enemigos por oleada.
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
## Tope de enemigos vivos a la vez (0 = sin tope). Si se alcanza, el spawner
## se salta la tanda y reintenta en el siguiente tick; el reloj NO se pausa.
@export var max_enemigos_simultaneos: int = 0
## Al acabar el tiempo: true elimina a los vivos; false los deja en pantalla
## y se mezclan con la siguiente oleada (siguen atacando el árbol).
@export var eliminar_sobrevivientes: bool = false

@export_category("Debug")
@export var debug_activo: bool = false
@export var debug_oleada_inicial: int = 1
@export var debug_no_guardar: bool = true
@export var debug_spawnear_enemigos: bool = true
## Si no está vacío, solo aparecen estos enemigos (ignora las etapas)
@export var debug_enemigos_fijos: Array[EnemigoOleadaConfig] = []
@export var debug_sin_limite_tiempo: bool = false
## 0 = usa el tiempo de descanso normal
@export var debug_descanso: float = 0.0
@export var debug_imprimir_info: bool = true

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

## true cuando esta partida empezó con "Nueva partida" desde un menú:
## anula los overrides de ARRANQUE del debug (oleada inicial / enemigos
## fijos) para que la partida siempre arranque limpia en la horda 1.
var _ignorar_debug := false


func _ready() -> void:
	add_to_group("wave_manager")

	spawn_timer = _crear_timer(false, tiempo_entre_spawns)
	spawn_timer.timeout.connect(_spawnear_siguiente_enemigo)

	rest_timer = _crear_timer(true, tiempo_descanso)
	rest_timer.timeout.connect(_on_descanso_terminado)

	ui_timer = _crear_timer(false, 1.0)
	ui_timer.timeout.connect(_on_ui_tick)

	duracion_timer = _crear_timer(true, tiempo_maximo_oleada)
	duracion_timer.timeout.connect(_on_tiempo_oleada_agotado)

	# "Nueva partida" desde un menú ignora los overrides de debug:
	# arranca en la horda guardada (1 tras el reset), con el pool real.
	_ignorar_debug = SaveManager != null and SaveManager.evitar_debug_esta_partida

	if debug_activo and not _ignorar_debug:
		oleada_actual = maxi(debug_oleada_inicial, 1)
	elif SaveManager != null:
		oleada_actual = SaveManager.get_horda()

	if debug_imprimir_info:
		var origen := "debug_oleada_inicial" if (debug_activo and not _ignorar_debug) else "SaveManager"
		print("[WaveManager] arranque en horda %d (origen: %s)" % [oleada_actual, origen])

	# La corrida educativa se arma ANTES de la primera oleada.
	if EducationManager != null:
		EducationManager.start_run()

	# Diferido: evita el "Parent node is busy setting up children" cuando
	# el jefe (o un enemigo) se spawnea durante el montaje de la escena.
	iniciar_oleada.call_deferred()


func _crear_timer(one_shot: bool, tiempo: float) -> Timer:
	var t := Timer.new()
	t.one_shot = one_shot
	t.wait_time = tiempo
	t.autostart = false
	add_child(t)
	return t


# ───────────── IDENTIFICACIÓN: JUGADOR Y ÁRBOL (SOLO GRUPOS) ─────────────
## Responsabilidad única de este script: encontrar al jugador y al árbol
## por sus grupos y pasárselos a cada enemigo que spawnea.

func _obtener_jugador() -> Node2D:
	var j := get_tree().get_first_node_in_group("jugador") as Node2D
	if j == null and not _aviso_sin_jugador:
		_aviso_sin_jugador = true
		push_warning("[WaveManager] Jugador no encontrado (grupo 'jugador').")
	return j


func _obtener_arbol() -> Node2D:
	var a := get_tree().get_first_node_in_group("arbol") as Node2D
	if a == null and not _aviso_sin_arbol:
		_aviso_sin_arbol = true
		push_warning("[WaveManager] Árbol no encontrado (grupo 'arbol').")
	return a


func _pasar_referencias(nodo: Node2D) -> void:
	# set() es un no-op seguro si la propiedad no existe: los enemigos
	# nuevos la reciben; los legacy usan su _resolver_referencias_fallback().
	nodo.set("jugador", _obtener_jugador())
	nodo.set("arbol", _obtener_arbol())


# ───────────── CICLO DE OLEADAS ─────────────

func iniciar_oleada() -> void:
	if not is_inside_tree():
		return

	en_descanso = false
	_generacion += 1
	jefe_actual = null

	if EducationManager != null:
		EducationManager.on_wave_started()

	var idx := _indice_etapa(oleada_actual)
	if idx != etapa_actual_idx:
		etapa_actual_idx = idx
		var nombre_etapa: String = ""
		if idx >= 0 and etapas[idx] != null:
			nombre_etapa = etapas[idx].nombre
		etapa_iniciada.emit(idx, nombre_etapa)
		if EducationManager != null:
			EducationManager.on_stage_started(idx)

	oleada_de_jefe = _es_oleada_de_jefe()

	# Duración escalada micro (por oleada) y macro (por etapa).
	var oleada_en_etapa: int = (oleada_actual - 1) % maxi(oleadas_por_etapa, 1) + 1
	_duracion_oleada_actual = _calcular_duracion(oleada_en_etapa)
	tiempo_restante = int(_duracion_oleada_actual)

	# Descanso largo tras jefe, si el recurso lo define.
	_descanso_jefe_actual = 0.0
	var etapa_oleada: EtapaConfig = _etapa(oleada_actual)
	if etapa_oleada != null:
		var descanso_jefe: Variant = etapa_oleada.get("descanso_jefe")
		if descanso_jefe != null:
			_descanso_jefe_actual = float(descanso_jefe)

	enemigos_vivos = 0
	enemigos_por_spawnear = 0
	_enemigos_vivos_por_tipo.clear()

	if oleada_de_jefe:
		_spawnear_jefe(etapa_oleada)

	# Sin nada que spawnear (etapa sin enemigos o spawns de debug apagados):
	# no se espera en vacío, se pasa directo al descanso.
	if not oleada_de_jefe and _enemigos_de_etapa(oleada_actual).is_empty():
		iniciar_fase_descanso()
		return

	oleada_iniciada.emit(oleada_actual)
	tiempo_actualizado.emit(tiempo_restante, false)
	_notificar_enemigos_restantes()

	# SPAWN CONTINUO: refuerzos durante TODA la oleada. Matar enemigos
	# no corta ni adelanta nada: el único que manda es el reloj.
	spawn_timer.start(tiempo_entre_spawns)

	# En oleada de jefe no hay reloj: termina cuando muera él.
	if not oleada_de_jefe and not (debug_activo and debug_sin_limite_tiempo):
		duracion_timer.start(_duracion_oleada_actual)

	ui_timer.start(1.0)


func _calcular_duracion(oleada_en_etapa: int) -> float:
	var duracion: float = tiempo_maximo_oleada
	duracion *= 1.0 + aumento_duracion_por_oleada * float(oleada_en_etapa - 1)
	if etapa_actual_idx > 0:
		duracion *= 1.0 + aumento_duracion_por_etapa * float(etapa_actual_idx)
	if duracion_maxima_oleada > 0.0:
		duracion = minf(duracion, duracion_maxima_oleada)
	return maxf(duracion, 1.0)


func _indice_etapa(numero_oleada: int) -> int:
	if etapas.is_empty():
		return -1
	var paso: int = maxi(oleadas_por_etapa, 1)
	var idx: int = floori(float(numero_oleada - 1) / float(paso))
	# Si se supera el contenido, se repite la última etapa (sin quedarse en null).
	return clampi(idx, 0, etapas.size() - 1)


func _etapa(numero_oleada: int) -> EtapaConfig:
	if etapas.is_empty():
		return null
	var idx := _indice_etapa(numero_oleada)
	if idx < 0:
		return null
	return etapas[idx]


func _es_oleada_de_jefe() -> bool:
	if etapas.is_empty() or etapa_actual_idx < 0:
		return false
	if oleada_actual % maxi(oleadas_por_etapa, 1) != 0:
		return false
	var etapa: EtapaConfig = etapas[etapa_actual_idx]
	return etapa != null and etapa.jefe_escena != null


# ───────────── SPAWNS ─────────────

func _spawnear_siguiente_enemigo() -> void:
	if en_descanso or not is_inside_tree():
		return

	# Tope opcional de simultáneos: se salta la tanda y reintenta luego.
	if max_enemigos_simultaneos > 0 and enemigos_vivos >= max_enemigos_simultaneos:
		return

	var pool: Array[EnemigoOleadaConfig] = _enemigos_de_etapa(oleada_actual)
	if pool.is_empty():
		return

	var config: EnemigoOleadaConfig = pool.pick_random()
	if config == null or config.escena == null:
		return

	var enemigo := config.escena.instantiate() as Node2D
	if enemigo == null:
		return

	var punto: Node2D = _elegir_punto_spawn()
	if punto != null:
		enemigo.global_position = punto.global_position

	_aplicar_stats(enemigo, _etapa(oleada_actual), 1.0, config)

	var clave: String = config.escena.resource_path
	_enemigos_vivos_por_tipo[clave] = int(_enemigos_vivos_por_tipo.get(clave, 0)) + 1
	enemigo.tree_exited.connect(_on_enemigo_derrotado.bind(clave, _generacion))

	_pasar_referencias(enemigo)
	get_tree().current_scene.add_child(enemigo)

	enemigos_vivos += 1
	_notificar_enemigos_restantes()

	if EducationManager != null:
		EducationManager.on_enemy_encountered(_obtener_enemy_id(enemigo))


func _enemigos_de_etapa(numero_oleada: int) -> Array[EnemigoOleadaConfig]:
	var pool: Array[EnemigoOleadaConfig] = []

	if debug_activo:
		if not debug_spawnear_enemigos:
			return pool
		if not debug_enemigos_fijos.is_empty():
			pool.append_array(debug_enemigos_fijos)
			return pool

	var etapa: EtapaConfig = _etapa(numero_oleada)
	if etapa == null:
		return pool

	for config in etapa.enemigos:
		var entrada := config as EnemigoOleadaConfig
		if entrada == null:
			continue
		if _disponible_en_oleada(entrada, numero_oleada):
			pool.append(entrada)
	return pool


func _disponible_en_oleada(entrada: EnemigoOleadaConfig, numero_oleada: int) -> bool:
	# Ventana de oleadas opcional del recurso: si los campos no existen,
	# get() devuelve null y el enemigo está siempre disponible.
	var desde: Variant = entrada.get("oleada_desde")
	if desde != null and int(desde) > numero_oleada:
		return false
	var hasta: Variant = entrada.get("oleada_hasta")
	if hasta != null and int(hasta) > 0 and int(hasta) < numero_oleada:
		return false
	return true


func _elegir_punto_spawn() -> Node2D:
	if puntos_spawn.is_empty():
		return self
	var punto: Node2D = puntos_spawn.pick_random()
	return punto


func _spawnear_jefe(etapa: EtapaConfig) -> void:
	if etapa == null or etapa.jefe_escena == null:
		return

	var jefe := etapa.jefe_escena.instantiate() as Node2D
	if jefe == null:
		return

	var punto: Node2D = punto_spawn_jefe
	if punto == null and not puntos_spawn.is_empty():
		punto = puntos_spawn.pick_random()
	if punto != null:
		jefe.global_position = punto.global_position

	_aplicar_stats(jefe, etapa, etapa.jefe_multiplicador_vida)

	var clave: String = etapa.jefe_escena.resource_path
	_enemigos_vivos_por_tipo[clave] = int(_enemigos_vivos_por_tipo.get(clave, 0)) + 1
	jefe.tree_exited.connect(_on_enemigo_derrotado.bind(clave, _generacion))
	jefe.tree_exited.connect(_on_jefe_muerto.bind(etapa.jefe_nombre, _generacion))

	_pasar_referencias(jefe)
	# Diferido: nunca add_child durante el montaje de la escena.
	get_tree().current_scene.add_child.call_deferred(jefe)

	jefe_actual = jefe
	enemigos_vivos += 1
	jefe_aparecido.emit(jefe, etapa.jefe_nombre)
	_notificar_enemigos_restantes()

	if EducationManager != null:
		EducationManager.on_enemy_encountered(_obtener_enemy_id(jefe))


func _aplicar_stats(nodo: Node2D, etapa: EtapaConfig, mult_extra: float = 1.0, config: EnemigoOleadaConfig = null) -> void:
	var escala_vida: float = 1.0
	var mult_dano: float = 1.0

	if etapa != null:
		escala_vida = 1.0 + etapa.escalado_vida_por_oleada * float(oleada_actual - 1)
		mult_dano = etapa.multiplicador_dano

	# Multiplicadores opcionales del recurso (si existen en EnemigoOleadaConfig).
	if config != null:
		var mult_vida: Variant = config.get("mult_vida")
		if mult_vida != null:
			escala_vida *= float(mult_vida)
		var extra_vida: Variant = config.get("extra_vida")
		if extra_vida != null:
			escala_vida *= float(extra_vida)

	escala_vida *= mult_extra

	# La clase Enemigo expone life/speed/damage y el escalado va ANTES de
	# add_child (su _ready inicializa vida = life ya escalada). Para nodos
	# legacy sin esas propiedades, set() es un no-op seguro.
	if "life" in nodo:
		nodo.set("life", float(nodo.get("life")) * escala_vida)
	if "damage" in nodo:
		nodo.set("damage", float(nodo.get("damage")) * mult_dano)
	if etapa != null and "speed" in nodo:
		var mult_velocidad: Variant = etapa.get("multiplicador_velocidad")
		if mult_velocidad != null:
			nodo.set("speed", float(nodo.get("speed")) * float(mult_velocidad))


func _obtener_enemy_id(nodo: Node2D) -> String:
	var ruta: String = nodo.scene_file_path
	var base: String = ruta.get_file().get_basename() if not ruta.is_empty() else String(nodo.name)
	# EducationManager normaliza tildes/espacios por su lado; aquí solo
	# minúsculas y sin separadores.
	return base.to_lower().replace(" ", "").replace("_", "").replace("-", "")


# ───────────── CIERRES DE OLEADA ─────────────

func _on_enemigo_derrotado(clave_escena: String, generacion: int) -> void:
	if generacion != _generacion:
		return

	enemigos_vivos = maxi(enemigos_vivos - 1, 0)

	if _enemigos_vivos_por_tipo.has(clave_escena):
		_enemigos_vivos_por_tipo[clave_escena] -= 1
		if _enemigos_vivos_por_tipo[clave_escena] <= 0:
			_enemigos_vivos_por_tipo.erase(clave_escena)

	if not is_inside_tree():
		return

	_notificar_enemigos_restantes()

	# SIN cierre por limpieza: matar al último enemigo NUNCA cierra la
	# oleada ni detiene los spawns. El único cierre anticipado es la
	# muerte del jefe (_on_jefe_muerto); el resto lo decide el reloj.


func _on_jefe_muerto(nombre: String, generacion: int) -> void:
	if generacion != _generacion or not is_inside_tree():
		return
	jefe_actual = null
	jefe_derrotado.emit(nombre)

	if EducationManager != null:
		EducationManager.on_boss_defeated(etapa_actual_idx)

	# La oleada del jefe no tiene reloj: termina al morir él.
	if eliminar_sobrevivientes:
		_limpiar_enemigos_vivos()

	iniciar_fase_descanso()


func _on_tiempo_oleada_agotado() -> void:
	# En oleada de jefe no corre el reloj (el cierre lo hace _on_jefe_muerto).
	if oleada_de_jefe:
		return
	_terminar_oleada_por_tiempo()


func _terminar_oleada_por_tiempo() -> void:
	spawn_timer.stop()
	duracion_timer.stop()
	ui_timer.stop()
	enemigos_por_spawnear = 0

	if eliminar_sobrevivientes:
		_limpiar_enemigos_vivos()

	iniciar_fase_descanso()


func iniciar_fase_descanso() -> void:
	if en_descanso:
		return

	en_descanso = true

	spawn_timer.stop()
	duracion_timer.stop()
	ui_timer.stop()

	var duracion_descanso: float = tiempo_descanso
	if oleada_de_jefe and _descanso_jefe_actual > 0.0:
		duracion_descanso = _descanso_jefe_actual
	if debug_activo and debug_descanso > 0.0:
		duracion_descanso = debug_descanso
	tiempo_restante = int(duracion_descanso)

	oleada_completada.emit(oleada_actual)
	descanso_iniciado.emit(duracion_descanso)
	tiempo_actualizado.emit(tiempo_restante, true)
	_notificar_enemigos_restantes()

	if EducationManager != null:
		EducationManager.on_wave_ended()

	if SaveManager != null and not (debug_activo and debug_no_guardar):
		SaveManager.set_horda(oleada_actual + 1)
		SaveManager.guardar_partida()

	rest_timer.start(duracion_descanso)
	ui_timer.start(1.0)


func _limpiar_enemigos_vivos() -> void:
	# Limpieza real (no debug): cubre 'enemigos' y el legacy 'enemi'.
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		nodo.queue_free()
	for nodo in get_tree().get_nodes_in_group("enemi"):
		nodo.queue_free()


func _on_ui_tick() -> void:
	if not is_inside_tree():
		return
	tiempo_actualizado.emit(tiempo_restante, en_descanso)
	tiempo_restante = maxi(tiempo_restante - 1, 0)


func _on_descanso_terminado() -> void:
	ui_timer.stop()
	oleada_actual += 1
	iniciar_oleada()


func _notificar_enemigos_restantes() -> void:
	enemigos_restantes_actualizado.emit(enemigos_vivos + enemigos_por_spawnear)


# ───────────── DEBUG ─────────────

func _unhandled_input(event: InputEvent) -> void:
	if not debug_activo:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F5: debug_ir_a_oleada(oleada_actual + 1)
			KEY_F6: debug_ir_a_oleada(oleada_actual - 1)
			KEY_F7: debug_matar_enemigos()
			KEY_F8: debug_saltar_descanso()


func debug_ir_a_oleada(numero: int) -> void:
	numero = maxi(numero, 1)
	_generacion += 1
	debug_matar_enemigos()
	spawn_timer.stop()
	duracion_timer.stop()
	rest_timer.stop()
	ui_timer.stop()
	enemigos_vivos = 0
	enemigos_por_spawnear = 0
	_enemigos_vivos_por_tipo.clear()
	oleada_actual = numero
	iniciar_oleada()


func debug_matar_enemigos() -> void:
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		nodo.queue_free()


func debug_saltar_descanso() -> void:
	if en_descanso:
		rest_timer.stop()
		_on_descanso_terminado()


# ───────────── MÉTODOS PÚBLICOS ─────────────

func obtener_oleada_actual() -> int:
	return oleada_actual


func obtener_etapa_actual() -> int:
	return etapa_actual_idx


func hay_enemigos_vivos() -> bool:
	return enemigos_vivos > 0


func esta_en_descanso() -> bool:
	return en_descanso


func obtener_enemigos_restantes() -> int:
	return enemigos_vivos + enemigos_por_spawnear


func es_oleada_de_jefe() -> bool:
	return oleada_de_jefe


func obtener_jefe_actual() -> Node2D:
	return jefe_actual
