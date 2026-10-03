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
@export var tiempo_entre_spawns: float = 1.2
@export var tiempo_maximo_oleada: float = 40.0
@export var tiempo_descanso: float = 5.0

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
var _enemigos_vivos_por_tipo: Dictionary = {}


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

	if debug_activo:
		oleada_actual = maxi(debug_oleada_inicial, 1)
	elif SaveManager != null:
		oleada_actual = SaveManager.get_horda()

	iniciar_oleada()

	if EducationManager != null:
		EducationManager.start_run()


func _crear_timer(one_shot: bool, tiempo: float) -> Timer:
	var t := Timer.new()
	t.one_shot = one_shot
	t.wait_time = tiempo
	t.autostart = false
	add_child(t)
	return t


# ───────────── ETAPAS ─────────────

func _indice_etapa(oleada: int) -> int:
	if etapas.is_empty():
		return -1
	var idx: int = int(floor((oleada - 1) / float(oleadas_por_etapa)))
	# Pasada la última etapa, se repite la última (modo infinito)
	return mini(idx, etapas.size() - 1)


func _etapa(oleada: int) -> EtapaConfig:
	var idx := _indice_etapa(oleada)
	if idx < 0:
		return null
	return etapas[idx]


func _enemigos_de_etapa(oleada: int) -> Array[EnemigoOleadaConfig]:
	var lista: Array[EnemigoOleadaConfig] = []

	if debug_activo and not debug_enemigos_fijos.is_empty():
		lista.append_array(debug_enemigos_fijos)
		return lista

	var idx := _indice_etapa(oleada)
	var etapa := _etapa(oleada)
	if etapa == null:
		return lista

	if etapa.heredar_enemigos_anteriores:
		for i in range(idx):
			if etapas[i] != null:
				lista.append_array(etapas[i].enemigos)
	lista.append_array(etapa.enemigos)
	return lista


## El jefe sale en la última oleada de cada etapa realmente definida
func _jefe_de_oleada(oleada: int) -> EtapaConfig:
	if oleada % oleadas_por_etapa != 0:
		return null
	var idx: int = oleada / oleadas_por_etapa - 1
	if idx < 0 or idx >= etapas.size():
		return null
	var etapa: EtapaConfig = etapas[idx]
	if etapa == null or etapa.jefe_escena == null:
		return null
	return etapa


# ───────────── OLEADAS ─────────────

func iniciar_oleada() -> void:
	en_descanso = false
	jefe_actual = null

	var idx := _indice_etapa(oleada_actual)
	if idx != etapa_actual_idx:
		etapa_actual_idx = idx
		var nombre_etapa: String = ""
		if idx >= 0 and etapas[idx] != null:
			nombre_etapa = etapas[idx].nombre
		etapa_iniciada.emit(idx, nombre_etapa)

	var etapa := _etapa(oleada_actual)
	var etapa_jefe := _jefe_de_oleada(oleada_actual)
	oleada_de_jefe = etapa_jefe != null

	var base: int = etapa.enemigos_base_por_oleada if etapa != null else 4
	var incremento: int = etapa.incremento_enemigos_por_oleada if etapa != null else 3

	if oleada_de_jefe:
		enemigos_por_spawnear = etapa_jefe.jefe_escoltas
	else:
		enemigos_por_spawnear = base + ((oleada_actual - 1) * incremento)
		enemigos_por_spawnear = maxi(enemigos_por_spawnear, 1)
		if debug_activo and not debug_spawnear_enemigos:
			enemigos_por_spawnear = 0

	tiempo_restante = int(tiempo_maximo_oleada)

	if debug_activo and debug_imprimir_info:
		print("[WaveManager] Oleada %d | Etapa %d | Jefe: %s | Enemigos: %d | Pool: %d" % [
			oleada_actual, etapa_actual_idx + 1, str(oleada_de_jefe),
			enemigos_por_spawnear, _enemigos_de_etapa(oleada_actual).size()])

	oleada_iniciada.emit(oleada_actual)
	tiempo_actualizado.emit(tiempo_restante, false)

	if oleada_de_jefe:
		_spawnear_jefe(etapa_jefe)

	_notificar_enemigos_restantes()

	# Oleada vacía: pasa directo al descanso
	if enemigos_por_spawnear <= 0 and enemigos_vivos <= 0:
		iniciar_fase_descanso()
		return

	if enemigos_por_spawnear > 0:
		spawn_timer.start(tiempo_entre_spawns)

	if oleada_de_jefe:
		# El jefe no tiene límite de tiempo
		ui_timer.stop()
		tiempo_actualizado.emit(0, false)
	else:
		if not (debug_activo and debug_sin_limite_tiempo):
			duracion_timer.start(tiempo_maximo_oleada)
		ui_timer.start(1.0)


func _aplicar_stats(enemigo: Node2D, etapa: EtapaConfig, extra_vida: float = 1.0) -> void:
	var escalado: float = etapa.escalado_vida_por_oleada if etapa != null else 0.15
	var mult_vida: float = etapa.multiplicador_vida if etapa != null else 1.0
	var mult_vel: float = etapa.multiplicador_velocidad if etapa != null else 1.0
	var mult_dano: float = etapa.multiplicador_dano if etapa != null else 1.0

	var factor_vida: float = (1.0 + (oleada_actual - 1) * escalado) * mult_vida * extra_vida
	# Cambia estos nombres si tus enemigos usan otras variables
	if "life" in enemigo and enemigo.get("life") != null:
		enemigo.set("life", enemigo.get("life") * factor_vida)
	if mult_vel != 1.0 and "speed" in enemigo and enemigo.get("speed") != null:
		enemigo.set("speed", enemigo.get("speed") * mult_vel)
	if mult_dano != 1.0 and "damage" in enemigo and enemigo.get("damage") != null:
		enemigo.set("damage", enemigo.get("damage") * mult_dano)


func _spawnear_jefe(etapa: EtapaConfig) -> void:
	var punto: Node2D = punto_spawn_jefe
	if punto == null and not puntos_spawn.is_empty():
		punto = puntos_spawn.pick_random()
	if punto == null or not punto.is_inside_tree():
		return

	var jefe: Node2D = etapa.jefe_escena.instantiate() as Node2D
	if jefe == null:
		return

	jefe.global_position = punto.global_position
	_aplicar_stats(jefe, etapa, etapa.jefe_multiplicador_vida)

	var clave: String = etapa.jefe_escena.resource_path
	_enemigos_vivos_por_tipo[clave] = _enemigos_vivos_por_tipo.get(clave, 0) + 1

	jefe.tree_exited.connect(_on_enemigo_derrotado.bind(clave, _generacion))
	jefe.tree_exited.connect(_on_jefe_muerto.bind(etapa.jefe_nombre, _generacion))

	get_tree().current_scene.add_child(jefe)

	jefe_actual = jefe
	_descanso_jefe_actual = etapa.jefe_tiempo_descanso
	enemigos_vivos += 1

	jefe_aparecido.emit(jefe, etapa.jefe_nombre)

	if EducationManager != null:
		EducationManager.on_enemy_encountered(_obtener_enemy_id(clave))


func _on_jefe_muerto(nombre: String, generacion: int) -> void:
	if generacion != _generacion or not is_inside_tree():
		return
	jefe_actual = null
	jefe_derrotado.emit(nombre)


func _spawnear_siguiente_enemigo() -> void:
	var pool := _enemigos_de_etapa(oleada_actual)
	if pool.is_empty() or puntos_spawn.is_empty():
		spawn_timer.stop()
		return

	var configs_validas: Array[EnemigoOleadaConfig] = []
	for config in pool:
		if config == null or config.escena == null:
			continue
		var clave: String = config.escena.resource_path
		var vivos_actuales: int = _enemigos_vivos_por_tipo.get(clave, 0)
		if config.max_simultaneos > 0 and vivos_actuales >= config.max_simultaneos:
			continue
		configs_validas.append(config)

	if configs_validas.is_empty():
		return

	var config_elegida: EnemigoOleadaConfig = _seleccionar_ponderado(configs_validas)
	if config_elegida == null:
		return

	var punto: Node2D = puntos_spawn.pick_random()
	if punto == null or not punto.is_inside_tree():
		return

	var enemigo: Node2D = config_elegida.escena.instantiate() as Node2D
	if enemigo == null:
		return

	enemigo.global_position = punto.global_position
	_aplicar_stats(enemigo, _etapa(oleada_actual))

	var clave_escena: String = config_elegida.escena.resource_path
	_enemigos_vivos_por_tipo[clave_escena] = _enemigos_vivos_por_tipo.get(clave_escena, 0) + 1

	enemigo.tree_exited.connect(_on_enemigo_derrotado.bind(clave_escena, _generacion))

	get_tree().current_scene.add_child(enemigo)

	enemigos_vivos += 1
	enemigos_por_spawnear -= 1

	_notificar_enemigos_restantes()

	if EducationManager != null:
		EducationManager.on_enemy_encountered(_obtener_enemy_id(clave_escena))

	if enemigos_por_spawnear <= 0:
		spawn_timer.stop()


func _obtener_enemy_id(ruta_escena: String) -> String:
	var nombre_archivo: String = ruta_escena.get_file().get_basename()
	return nombre_archivo.to_lower().replace("_", "")


func _seleccionar_ponderado(configs: Array[EnemigoOleadaConfig]) -> EnemigoOleadaConfig:
	var peso_total: float = 0.0
	for config in configs:
		peso_total += max(config.peso, 0.0)

	if peso_total <= 0.0:
		return configs[randi() % configs.size()]

	var valor: float = randf() * peso_total
	var acumulado: float = 0.0
	for config in configs:
		acumulado += max(config.peso, 0.0)
		if valor <= acumulado:
			return config

	return configs[configs.size() - 1]


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

	if enemigos_vivos <= 0 and enemigos_por_spawnear <= 0:
		duracion_timer.stop()
		spawn_timer.stop()
		ui_timer.stop()
		iniciar_fase_descanso()


func _on_tiempo_oleada_agotado() -> void:
	if oleada_de_jefe:
		return
	spawn_timer.stop()
	ui_timer.stop()
	iniciar_fase_descanso()


func iniciar_fase_descanso() -> void:
	if en_descanso:
		return

	en_descanso = true

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
