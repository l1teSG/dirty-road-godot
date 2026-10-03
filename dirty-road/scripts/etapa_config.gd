class_name EtapaConfig
extends Resource

@export var nombre: String = "Etapa"

@export_group("Enemigos")
## Enemigos NUEVOS de esta etapa
@export var enemigos: Array[EnemigoOleadaConfig] = []
## Si es true, también aparecen los enemigos de las etapas anteriores
@export var heredar_enemigos_anteriores: bool = true

@export_group("Mejora / Dificultad")
@export var enemigos_base_por_oleada: int = 4
@export var incremento_enemigos_por_oleada: int = 3
## Vida extra por oleada (0.15 = +15% por oleada)
@export var escalado_vida_por_oleada: float = 0.15
## Multiplicadores fijos de la etapa para TODOS sus enemigos
@export var multiplicador_vida: float = 1.0
@export var multiplicador_velocidad: float = 1.0
@export var multiplicador_dano: float = 1.0

@export_group("Jefe")
## Si está vacío, la etapa no tiene jefe
@export var jefe_escena: PackedScene
@export var jefe_nombre: String = "Jefe"
@export var jefe_multiplicador_vida: float = 8.0
## Enemigos normales que acompañan al jefe
@export var jefe_escoltas: int = 4
## Descanso después de derrotar al jefe
@export var jefe_tiempo_descanso: float = 15.0
