# info_mejora.gd
class_name InfoMejora
extends Resource

## Datos de una carta de mejora. La fuente base (nombre/rareza/precio) está
## en assets/cards/catalogoCards.gd, y el texto descriptivo y la figura
## vectorial llegan desde assets/cards/descripciones.gd y figuras.gd.
## GestorCartas une las tres fuentes por 'nombre'.

@export var id: String = "mejora_base"
## Nombre visible de la carta (clave de unión con catálogo/descripciones/figuras).
@export var nombre: String = ""
## Común | Rara | Épica | Legendaria
@export var rareza: String = "Común"
## Icono de imagen clásico (opcional). La carta usa 'figura_texto' si está.
@export var icono: Texture2D
@export_multiline var descripcion: String = ""
## Bloque de texto para el FiguraConstructor (classShape). Dibuja la figura.
@export_multiline var figura_texto: String = ""
@export var costo_orbes: int = 10
@export var peso_aparicion: float = 1.0
