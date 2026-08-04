class_name WaveManager
extends Node2D

signal oleada_iniciada(numero_oleada: int)
signal oleada_completada(numero_oleada: int)
signal tiempo_actualizado(segundos_restantes: int, es_descanso: bool)
signal descanso_iniciado(tiempo_total: float)

@export_category("Configuración")
@export var enemigos_disponibles: Array[PackedScene] = []
@export var puntos_spawn: Array[Node2D] = []

@export_category("Parámetros de Dificultad")
@export var enemigos_base_por_oleada: int = 4
@export var incremento_enemigos_por_oleada: int = 3
@export var tiempo_entre_spawns: float = 1.2
@export var tiempo_descanso: float = 8.0
@export var escalado_vida_por_oleada: float = 0.15

var oleada_actual: int = 1
var enemigos_vivos: int = 0
var enemigos_por_spawnear: int = 0
var en_descanso: bool = false
var tiempo_restante: int = 0

var spawn_timer: Timer
var rest_timer: Timer
var ui_timer: Timer


func _ready() -> void:
	# Crear y configurar spawn_timer
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.wait_time = tiempo_entre_spawns
	spawn_timer.autostart = false
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_spawnear_siguiente_enemigo)

	# Crear y configurar rest_timer
	rest_timer = Timer.new()
	rest_timer.one_shot = true
	rest_timer.wait_time = tiempo_descanso
	rest_timer.autostart = false
	add_child(rest_timer)
	rest_timer.timeout.connect(_on_descanso_terminado)

	# Crear y configurar ui_timer (se activa solo durante el descanso)
	ui_timer = Timer.new()
	ui_timer.one_shot = false
	ui_timer.wait_time = 1.0
	ui_timer.autostart = false
	add_child(ui_timer)
	ui_timer.timeout.connect(_on_ui_tick)

	# Leer la horda inicial desde SaveManager si existe
	if SaveManager != null:
		oleada_actual = SaveManager.get_horda()

	# Iniciar la primera oleada
	iniciar_oleada()


func iniciar_oleada() -> void:
	en_descanso = false
	# Calcular cuántos enemigos spawnearemos en esta oleada
	enemigos_por_spawnear = enemigos_base_por_oleada + ((oleada_actual - 1) * incremento_enemigos_por_oleada)
	if enemigos_por_spawnear < 1:
		enemigos_por_spawnear = 1

	oleada_iniciada.emit(oleada_actual)

	spawn_timer.start(tiempo_entre_spawns)


func _spawnear_siguiente_enemigo() -> void:
	if enemigos_disponibles.is_empty() or puntos_spawn.is_empty():
		spawn_timer.stop()
		return

	# Elegir escena y punto de spawn aleatorio
	var escena: PackedScene = enemigos_disponibles.pick_random()
	var punto: Node2D = puntos_spawn.pick_random()

	var enemigo: Node2D = escena.instantiate() as Node2D
	if enemigo == null:
		# La escena no es un Node2D, ignorar
		return

	# Posicionar en el punto de spawn
	enemigo.global_position = punto.global_position

	# Aplicar escalado de vida según la oleada
	var factor_dificultad: float = 1.0 + ((oleada_actual - 1) * escalado_vida_por_oleada)
	if "life" in enemigo:
		var vida_actual = enemigo.get("life")
		if vida_actual != null:
			enemigo.set("life", vida_actual * factor_dificultad)

	# Conectar señal tree_exited para saber cuándo muere
	enemigo.tree_exited.connect(_on_enemigo_derrotado)

	# Agregar el enemigo a la escena principal (asumimos que WaveManager está en el árbol)
	get_parent().add_child(enemigo)

	enemigos_vivos += 1
	enemigos_por_spawnear -= 1

	if enemigos_por_spawnear <= 0:
		spawn_timer.stop()


func _on_enemigo_derrotado() -> void:
	enemigos_vivos -= 1
	if enemigos_vivos < 0:
		enemigos_vivos = 0

	# Si el WaveManager ya no está en el SceneTree (ej. cambio de escena), abortar
	if not is_inside_tree():
		return

	# Verificar si la oleada ha terminado
	if enemigos_vivos <= 0 and enemigos_por_spawnear <= 0:
		oleada_completada.emit(oleada_actual)

		# Guardado automático mediante Autoload SaveManager
		if SaveManager != null:
			SaveManager.set_horda(oleada_actual + 1)
			SaveManager.guardar_partida()

		# Iniciar fase de descanso
		en_descanso = true
		tiempo_restante = int(tiempo_descanso)
		descanso_iniciado.emit(tiempo_descanso)

		if rest_timer.is_inside_tree():
			rest_timer.start(tiempo_descanso)
		if ui_timer.is_inside_tree():
			ui_timer.start(1.0)


func _on_ui_tick() -> void:
	if en_descanso:
		tiempo_actualizado.emit(tiempo_restante, true)
		tiempo_restante -= 1


func _on_descanso_terminado() -> void:
	ui_timer.stop()
	oleada_actual += 1
	iniciar_oleada()


## Métodos públicos para consulta (pueden ser usados por UI, otros scripts, etc.)
func obtener_oleada_actual() -> int:
	return oleada_actual


func hay_enemigos_vivos() -> bool:
	return enemigos_vivos > 0


func esta_en_descanso() -> bool:
	return en_descanso
