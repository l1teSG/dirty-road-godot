extends Node
## Autoload 'BiomasaManager'. Responsabilidades:
##  • Recibir la biomasa que recoge el jugador (los orbes llaman a sumar()).
##  • Mantener el contador SIN LÍMITE SUPERIOR y avisar a la UI por señal.
##  • Guardar/cargar el contador a través de SaveManager.
## No crea orbes ni dibuja nada: eso es de los enemigos y de la UI.
##
## IMPORTANTE: en Proyecto > Ajustes > Autoload, SaveManager debe estar
## ANTES que BiomasaManager en la lista.
##
## DEBUG: con DEBUG = true imprime quién cambia el contador, cuántos
## listeners tiene la señal y cuándo se recarga desde el guardado.
## Además corre un autodiagnóstico automático al cargar cada escena.

signal biomasa_incrementada

## Biomasa que cuesta usar el super. Es un COSTO, no un tope: se puede
## acumular más y lo que sobra se conserva.
const COSTO_SUPER := 10
const GUARDAR_EN_CADA_CAMBIO := false

const DEBUG := true
const AUTOTEST_AL_INICIAR := true
const RETRASO_AUTOTEST := 1.5

## Nunca baja de 0; no tiene máximo. Avisa a la UI y se refleja en SaveManager
## incluso si alguien escribe directamente 'BiomasaManager.contador += 1'.
var contador: int = 0:
	set(valor):
		var nuevo: int = maxi(valor, 0)
		if nuevo == contador:
			_log("set contador=%d IGNORADO (sin cambio; pedido=%d) <- %s" % [contador, valor, _quien_llama()])
			return
		_log("contador %d -> %d (pedido=%d)%s <- %s" % [
			contador, nuevo, valor,
			" [desde guardado]" if _sincronizando else "",
			_quien_llama()])
		contador = nuevo
		if not _sincronizando:
			SaveManager.set_biomasa(contador)
			if GUARDAR_EN_CADA_CAMBIO:
				SaveManager.guardar_partida()
		_emitir_cambio()

var _sincronizando: bool = false
var _escena_diagnosticada: Node = null


func _ready() -> void:
	_log("listo. SaveManager.biomasa=%d" % SaveManager.get_biomasa())
	SaveManager.datos_actualizados.connect(_on_datos_actualizados)
	_cargar_desde_guardado.call_deferred()
	set_process(DEBUG and OS.is_debug_build())


func _on_datos_actualizados() -> void:
	_log("SaveManager.datos_actualizados recibido (cargar/nueva partida) -> se relee el contador")
	_cargar_desde_guardado()


func _cargar_desde_guardado() -> void:
	_sincronizando = true  # leer del guardado no debe reescribirlo
	contador = SaveManager.get_biomasa()
	_sincronizando = false


func _emitir_cambio() -> void:
	var oyentes: int = get_signal_connection_list("biomasa_incrementada").size()
	if oyentes == 0:
		_log("⚠ señal emitida pero NADIE escucha (el Label no está conectado o no existe aún)")
	else:
		_log("señal emitida a %d oyente(s); contador=%d" % [oyentes, contador])
	biomasa_incrementada.emit()


## ¿Alcanza para usar el super?
func puede_usar_super() -> bool:
	return contador >= COSTO_SUPER


## OBSOLETO: ya no hay máximo, así que nunca está "llena". Se mantiene para
## no romper llamadas viejas.
func esta_llena() -> bool:
	return false


## Suma 'cantidad' (sin límite superior). Devuelve cuánta se sumó.
func sumar(cantidad: int = 1) -> int:
	_log("sumar(%d) llamado <- %s" % [cantidad, _quien_llama()])
	var antes: int = contador
	contador += maxi(cantidad, 0)
	return contador - antes


## COMPATIBILIDAD con llamadas viejas. Ya no hay vuelo visual: suma directo.
func emitir_biomasa(_desde_global: Vector2 = Vector2.ZERO, _destino_screen_pos: Vector2 = Vector2.ZERO,
		_canvas_layer: CanvasLayer = null, valor: int = 1) -> void:
	_log("emitir_biomasa() (API vieja) valor=%d" % valor)
	sumar(valor)


func _incrementar() -> void:
	_log("_incrementar() (API vieja)")
	sumar(1)


func reiniciar_biomasa() -> void:
	_log("reiniciar_biomasa() <- %s" % _quien_llama())
	contador = 0


## Gasta COSTO_SUPER de biomasa si alcanza (el excedente se conserva).
## true = se puede usar el super.
func consumir_biomasa() -> bool:
	if contador < COSTO_SUPER:
		_log("consumir_biomasa() rechazado (%d/%d)" % [contador, COSTO_SUPER])
		return false
	_log("consumir_biomasa() OK (-%d)" % COSTO_SUPER)
	contador -= COSTO_SUPER
	return true


## Gasta 'cantidad' de biomasa si alcanza. true = se pudo gastar.
## (Genérico, para las cartas de mejora.)
func gastar(cantidad: int) -> bool:
	if cantidad <= 0:
		return true
	if contador < cantidad:
		_log("gastar(%d) rechazado (%d)" % [cantidad, contador])
		return false
	_log("gastar(%d) OK" % cantidad)
	contador -= cantidad
	return true


# ── Debug ─────────────────────────────────────────────

func debug_estado() -> void:
	print("──── BiomasaManager ────")
	print("contador: %d (el super cuesta %d)" % [contador, COSTO_SUPER])
	print("SaveManager.biomasa: %d" % SaveManager.get_biomasa())
	print("oyentes de la señal:")
	for c in get_signal_connection_list("biomasa_incrementada"):
		var callable: Callable = c["callable"]
		print("  → %s.%s" % [callable.get_object(), callable.get_method()])
	print("────────────────────────")


## Detecta solo cada escena nueva (menú, nivel...) y le corre el diagnóstico.
func _process(_delta: float) -> void:
	var escena: Node = get_tree().current_scene
	if escena != null and escena != _escena_diagnosticada:
		_escena_diagnosticada = escena
		_autodiagnostico()


## No requiere pulsar nada. Espera un poco a que la escena termine de cargar.
func _autodiagnostico() -> void:
	var escena: Node = _escena_diagnosticada
	await get_tree().create_timer(RETRASO_AUTOTEST).timeout
	if escena != get_tree().current_scene:
		return  # la escena cambió mientras esperábamos
	_log("── AUTODIAGNÓSTICO de la escena '%s' ──" % escena.name)
	debug_estado()

	if get_signal_connection_list("biomasa_incrementada").is_empty():
		push_warning("BiomasaManager: nadie escucha la señal. ¿Existe el Label con ContadorBiomasa en esta escena?")

	if not AUTOTEST_AL_INICIAR:
		return

	_log("autotest: sumo 1 (si el texto no sube, el problema está en la UI)")
	var valor_original: int = contador
	sumar(1)
	await get_tree().create_timer(0.5).timeout
	_log("autotest: revierto a %d" % valor_original)
	contador = valor_original


func _log(msg: String) -> void:
	if DEBUG:
		print("[Biomasa %.2fs] %s" % [Time.get_ticks_msec() / 1000.0, msg])


## "archivo:línea (función)" de quien llamó (en builds de release no hay pila).
func _quien_llama(profundidad: int = 2) -> String:
	var pila: Array = get_stack()
	if pila.size() <= 2:
		return "?"
	var partes := PackedStringArray()
	for i in range(2, mini(pila.size(), 2 + profundidad)):
		partes.append("%s:%d (%s)" % [str(pila[i]["source"]).get_file(), pila[i]["line"], pila[i]["function"]])
	return " <- ".join(partes)
