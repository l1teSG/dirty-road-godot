class_name ConstructorCartas
extends Node

## Toma la información, instancia la clase de la carta, le inyecta los datos
## (y la config visual) y la devuelve.
func fabricar_carta(info: InfoMejora, orbes_jugador: int, config: CartasConfig = null) -> CartaDefinicion:
	var nueva_carta := CartaDefinicion.new()
	nueva_carta.construir(config)
	nueva_carta.inyectar_datos(info, orbes_jugador)
	return nueva_carta
