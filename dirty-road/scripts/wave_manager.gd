class_name WaveManager
extends Node2D

signal oleada_iniciada(numero_oleada: int)
signal oleada_completada(numero_oleada: int)
signal todos_enemigos_derrotados()

@export_category("Configuración de Enemigos")
## Arreglo de escenas de enemigos disponibles. Funciona con 1, 3 o N tipos de enemigos.
@export var enemigos_disponibles: Array[PackedScene] = []
## Puntos de origen (Node2D/Marker2D) donde aparecerán los enemigos.
@export var puntos_spawn: Array[Node2D] = []

@export_category("Parámetros de Oleadas")
@export var oleada_inicial: int = 1
@export var enemigos_base_por_oleada: int = 4
@export var incremento_enemigos_por_oleada: int = 3
@export var tiempo_entre_spawns: float = 1.2
@export var tiempo_descanso_entre_oleadas: float = 8.0

@export_category("Multiplicadores de Dificultad")
## Porcentaje de incremento de vida por oleada (0.15 = +15% de vida)
@export var escalado_vida_por_oleada: float = 0.15

var oleada_actual: int = 1
var enemigos_vivos: int = 0
var enemigos_por_spawnear: int = 0
var en_descanso: bool = false

@onready var spawn_timer: Timer = Timer.new()
@onready var rest_timer: Timer = Timer.new()


func _ready() -> void:
	# Configurar timers
	spawn_timer.one_shot = false
	spawn_timer.wait_time = tiempo_entre_spawns
	spawn_timer.autostart = false
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_spawnear_siguiente_enemigo)

	rest_timer.one_shot = true
	rest_timer.wait_time = tiempo_descanso_entre_oleadas
	rest_timer.autostart = false
	add_child(rest_timer)
	rest_timer.timeout.connect(iniciar_siguiente_oleada)


## Inicia el sistema de oleadas desde una oleada específica (útil para cargar partidas guardadas).
func iniciar_sistema(oleada_desde: int = 1) -> void:
	oleada_actual = oleada_desde
	en_descanso = false
	enemigos_vivos = 0
	enemigos_por_spawnear = 0
	spawn_timer.stop()
	rest_timer.stop()
	iniciar_siguiente_oleada()


func iniciar_siguiente_oleada() -> void:
	en_descanso = false
	# Calcular cantidad de enemigos para esta oleada
	enemigos_por_spawnear = enemigos_base_por_oleada + (oleada_actual * incremento_enemigos_por_oleada)
	# Asegurar mínimo 1 enemigo
	if enemigos_por_spawnear < 1:
		enemigos_por_spawnear = 1

	oleada_iniciada.emit(oleada_actual)

	# Iniciar el timer de spawn
	spawn_timer.start()


func _spawnear_siguiente_enemigo() -> void:
	if enemigos_disponibles.is_empty() or puntos_spawn.is_empty():
		# No hay recursos para spawnear, detener el timer
		spawn_timer.stop()
		return

	# Elegir escena y punto aleatorio
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
	if enemigo.has_method("set_life") or "life" in enemigo:
		# Intentar modificar la vida
		var vida_actual = enemigo.get("life")
		if vida_actual != null:
			enemigo.set("life", vida_actual * factor_dificultad)
	# También se puede escalar daño u otras stats si se desea

	# Conectar señal de muerte (tree_exited o señal personalizada)
	if enemigo.tree_exited.is_connected(_on_enemigo_derrotado):
		# Ya conectado, evitar duplicados
		pass
	else:
		enemigo.tree_exited.connect(_on_enemigo_derrotado.bind(enemigo))

	# Agregar a la escena principal (asumiendo que este WaveManager está en el árbol)
	get_parent().add_child(enemigo)

	enemigos_vivos += 1
	enemigos_por_spawnear -= 1

	if enemigos_por_spawnear <= 0:
		spawn_timer.stop()


func _on_enemigo_derrotado(enemigo: Node2D) -> void:
	# Desconectar la señal para evitar fugas
	if enemigo.tree_exited.is_connected(_on_enemigo_derrotado):
		enemigo.tree_exited.disconnect(_on_enemigo_derrotado)

	enemigos_vivos -= 1
	if enemigos_vivos < 0:
		enemigos_vivos = 0

	# Verificar si la oleada ha terminado
	if enemigos_vivos <= 0 and enemigos_por_spawnear <= 0:
		oleada_completada.emit(oleada_actual)

		# Guardado automático si existe SaveManager
		if Engine.has_singleton("SaveManager"):
			var save_manager = Engine.get_singleton("SaveManager")
			if save_manager.has_method("guardar_partida_auto"):
				save_manager.guardar_partida_auto(oleada_actual)
		else:
			var save_node = get_node_or_null("/root/SaveManager")
			if save_node != null and save_node.has_method("guardar_partida_auto"):
				save_node.guardar_partida_auto(oleada_actual)

		# Iniciar pausa táctica
		en_descanso = true
		rest_timer.start()

		# Emitir señal de todos derrotados (opcional)
		todos_enemigos_derrotados.emit()


## Método público para obtener la oleada actual (puede ser usado por UI)
func obtener_oleada_actual() -> int:
	return oleada_actual


## Método público para saber si hay enemigos vivos
func hay_enemigos_vivos() -> bool:
	return enemigos_vivos > 0


## Método público para saber si estamos en descanso entre oleadas
func esta_en_descanso() -> bool:
	return en_descanso
