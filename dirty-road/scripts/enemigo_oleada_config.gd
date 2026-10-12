class_name EnemigoOleadaConfig
extends Resource

@export var escena: PackedScene
@export var peso: float = 1.0
@export var oleada_minima: int = 1
@export var oleada_maxima: int = 0   # 0 = sin límite
@export var max_simultaneos: int = 0 # 0 = sin límite
## Override opcional del objetivo de este enemigo EN esta etapa.
## "auto" = usar el del propio enemigo (auto por arquetipo).
@export_enum("auto", "jugador", "arbol", "mixto") var objetivo: String = "auto"
