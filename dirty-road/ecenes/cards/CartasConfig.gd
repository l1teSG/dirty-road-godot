class_name CartasConfig
extends Resource

## ══════════════════════════════════════════════════════════
##  Configuración de las cartas de mejora (editable en el editor).
##  Se asigna al nodo "Cartas" (GestorCartas) y se pasa a cada carta.
## ══════════════════════════════════════════════════════════

@export_group("Flujo")
@export var cartas_por_descanso: int = 3
## Retraso antes de mostrar las cartas (para ver "¡OLEADA COMPLETADA!").
@export var retraso_mostrar: float = 1.0
## Cada cuántas oleadas se ofrecen cartas (1 = todas, 2 = cada dos…).
@export var mostrar_cada_n_oleadas: int = 2
## No ofrecer cartas antes de esta oleada (completada).
@export var min_oleada: int = 1
## Si es true, se pueden comprar varias cartas en un mismo descanso.
@export var permitir_multi_compra: bool = true
## Esperar a que se recojan TODOS los orbes (grupo "orbe") antes de mostrar
## las cartas, para que no salgan mientras los orbes de fin de oleada vuelan.
@export var esperar_orbes: bool = true
## Tope de espera (s) de esos orbes; al agotarse se muestran las cartas igual.
@export var espera_max_orbes: float = 6.0

@export_group("Rareza · Común")
@export var peso_comun: float = 100.0
@export var costo_comun: int = 20
@export var oleada_min_comun: int = 1
@export var color_comun: Color = Color("7fdcb0")

@export_group("Rareza · Rara")
@export var peso_rara: float = 40.0
@export var costo_rara: int = 35
@export var oleada_min_rara: int = 3
@export var color_rara: Color = Color("5ee6a0")

@export_group("Rareza · Épica")
@export var peso_epica: float = 12.0
@export var costo_epica: int = 60
@export var oleada_min_epica: int = 6
@export var color_epica: Color = Color("99ff33")

@export_group("Rareza · Legendaria")
@export var peso_legendaria: float = 3.0
@export var costo_legendaria: int = 100
@export var oleada_min_legendaria: int = 10
@export var color_legendaria: Color = Color("ffd54a")

@export_group("Layout")
@export var tamano_carta: Vector2 = Vector2(340, 476)
@export var alto_figura: float = 168.0
@export var sep_cartas: int = 20
@export var sep_vertical: int = 20
@export var margen_carta: int = 20

@export_group("Fuentes y tamaños")
@export var fuente_titulo: Font = preload("res://themes/Chakra_Petch/ChakraPetch-Bold.ttf")
@export var tam_titulo: int = 54
@export var fuente_nombre: Font = preload("res://themes/Chakra_Petch/ChakraPetch-Bold.ttf")
@export var tam_nombre: int = 26
@export var fuente_rareza: Font = preload("res://themes/Chakra_Petch/ChakraPetch-SemiBold.ttf")
@export var tam_rareza: int = 16
@export var fuente_desc: Font = preload("res://themes/Chakra_Petch/ChakraPetch-Medium.ttf")
@export var tam_desc: int = 18
@export var fuente_boton: Font = preload("res://themes/Chakra_Petch/ChakraPetch-SemiBold.ttf")
@export var tam_boton: int = 21

@export_group("Colores")
@export var color_fondo: Color = Color("0d2015")
@export var color_sabor: Color = Color("a8c0b4")
@export var color_texto: Color = Color("e8fff1")
@export var bold_outline: Color = Color("06120b")
@export var bold_outline_size: int = 5


func color_de(rareza: String) -> Color:
	match rareza:
		"Rara": return color_rara
		"Épica": return color_epica
		"Legendaria": return color_legendaria
		_: return color_comun


func costo_de(rareza: String) -> int:
	match rareza:
		"Rara": return costo_rara
		"Épica": return costo_epica
		"Legendaria": return costo_legendaria
		_: return costo_comun


func peso_de(rareza: String) -> float:
	match rareza:
		"Rara": return peso_rara
		"Épica": return peso_epica
		"Legendaria": return peso_legendaria
		_: return peso_comun


func oleada_min_de(rareza: String) -> int:
	match rareza:
		"Rara": return oleada_min_rara
		"Épica": return oleada_min_epica
		"Legendaria": return oleada_min_legendaria
		_: return oleada_min_comun
