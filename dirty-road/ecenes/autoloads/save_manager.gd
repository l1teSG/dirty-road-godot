extends Node

const RUTA_GUARDADO := "user://partida.save"

# Valores por defecto para una partida nueva
const DATOS_DEFECTO := {
	"horda_actual": 1,
	"vida_jugador": 100,
	"vida_maxima": 100,
}

var datos: Dictionary = DATOS_DEFECTO.duplicate(true)


func hay_partida_guardada() -> bool:
	return FileAccess.file_exists(RUTA_GUARDADO)


func guardar_partida() -> void:
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo == null:
		push_error("SaveManager: no se pudo abrir el archivo para guardar")
		return

	archivo.store_string(JSON.stringify(datos))
	archivo.close()


func cargar_partida() -> bool:
	if not hay_partida_guardada():
		return false

	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo == null:
		push_error("SaveManager: no se pudo abrir el archivo para leer")
		return false

	var contenido = archivo.get_as_text()
	archivo.close()

	var resultado = JSON.parse_string(contenido)
	if resultado == null or typeof(resultado) != TYPE_DICTIONARY:
		push_error("SaveManager: archivo de guardado corrupto")
		return false

	# combina con los valores por defecto, así si agregas campos nuevos
	# en el futuro y cargas una partida vieja, no faltan claves
	datos = DATOS_DEFECTO.duplicate(true)
	for clave in resultado.keys():
		datos[clave] = resultado[clave]

	return true


func nueva_partida() -> void:
	datos = DATOS_DEFECTO.duplicate(true)
	guardar_partida()  # Sobrescribe el archivo inmediatamente con horda 1


func borrar_partida() -> void:
	if hay_partida_guardada():
		DirAccess.remove_absolute(RUTA_GUARDADO)


# ── Helpers para leer/escribir campos individuales sin tocar todo el dict ──

func set_horda(numero: int) -> void:
	datos["horda_actual"] = numero

func get_horda() -> int:
	return datos.get("horda_actual", 1)

func set_vida(actual: int, maxima: int = -1) -> void:
	datos["vida_jugador"] = actual
	if maxima > 0:
		datos["vida_maxima"] = maxima

func get_vida() -> int:
	return datos.get("vida_jugador", 100)

func get_vida_maxima() -> int:
	return datos.get("vida_maxima", 100)
