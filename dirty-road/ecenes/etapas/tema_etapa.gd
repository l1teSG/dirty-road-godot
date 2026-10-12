class_name TemaEtapa
extends Resource

## ══════════════════════════════════════════════════════════
##  TEMA DE ETAPA — identidad propia de cada etapa, editable en el
##  Inspector: ambiente, partículas, banner y peligro característico.
## ══════════════════════════════════════════════════════════

@export var nombre: String = "Etapa"

@export_group("Ambiente")
## Tinte del mundo (CanvasModulate) durante la etapa.
@export var color_ambiente: Color = Color(0.82, 0.86, 0.9)

@export_group("Partículas ambientales")
@export var particulas_activas: bool = true
@export var color_particulas: Color = Color(0.6, 0.9, 0.4, 0.8)
@export_range(0, 400, 1) var particulas_cantidad: int = 50
@export var particulas_direccion: Vector2 = Vector2(0, 1)
@export var particulas_velocidad: float = 70.0
@export_range(0.5, 6.0, 0.1) var particulas_tamano: float = 2.0

@export_group("Banner")
@export var banner_color: Color = Color("99ff33")

@export_group("Terreno")
@export var color_suelo: Color = Color(0.34, 0.44, 0.26)
@export var color_suelo_detalle: Color = Color(0.26, 0.36, 0.20)
@export var color_borde: Color = Color(0.10, 0.14, 0.10)
@export var color_props: Color = Color(0.45, 0.4, 0.28)
@export_range(0, 120, 1) var props_cantidad: int = 26

@export_group("Peligro característico")
## Activa un peligro temático que aparece periódicamente durante la etapa.
@export var peligro_activo: bool = false
@export var peligro_nombre: String = ""
@export var peligro_color: Color = Color(0.9, 0.4, 0.2, 0.35)
@export var peligro_radio: float = 75.0
@export var peligro_danio: float = 6.0
@export_range(0.5, 10.0, 0.1) var peligro_intervalo: float = 2.5
@export_range(1.0, 12.0, 0.5) var peligro_duracion: float = 3.0
