class_name EtapaConfig
extends Resource

@export var nombre: String = "Etapa"

@export_group("Enemigos")
## Enemigos NUEVOS de esta etapa. Cada uno define su ventana de
## oleadas (oleada_minima / oleada_maxima) y su mult_vida propio.
@export var enemigos: Array[EnemigoOleadaConfig] = []
## Si es true, también aparecen los enemigos de las etapas anteriores.
## Por defecto FALSE: cada etapa usa SOLO sus propios enemigos.
@export var heredar_enemigos_anteriores: bool = false

@export_group("Cantidad por oleada")
## Enemigos que spawnean en la PRIMERA oleada de la etapa.
@export var enemigos_base_por_oleada: int = 5
## Enemigos extra por cada oleada adicional dentro de la etapa.
@export var incremento_enemigos_por_oleada: int = 2

@export_group("Spawns")
## Segundos entre refuerzos en ESTA etapa. 0 = usa el global del WaveManager.
## Es LA palanca de presión: a menor valor, más rápido se repone el hueco.
@export var tiempo_entre_spawns: float = 0.0
## Tope DURO de enemigos vivos en esta etapa. 0 = usa la fórmula
## (base + incremento × (pos−1)). Evita el agobio en etapas avanzadas.
@export var max_enemigos_simultaneos: int = 0

@export_group("Escalado por oleada")
## Se aplica sobre la OLEADA GLOBAL: vida = base × (1 + (oleada-1) × esto).
## 0.07 = +7% compuesto por oleada.
@export_range(0.0, 1.0) var escalado_vida_por_oleada: float = 0.07
## Daño extra por oleada. 0.04 = +4%.
@export_range(0.0, 1.0) var escalado_danio_por_oleada: float = 0.04

@export_group("Multiplicadores de etapa")
## Se aplican a TODOS los enemigos de la etapa, encima del escalado.
## El WaveManager lee EXACTAMENTE estos nombres — no renombrar.
@export var mult_vida: float = 1.0
@export var mult_velocidad: float = 1.0
@export var mult_danio: float = 1.0

@export_group("Jefe")
## Si está vacío, la etapa no tiene jefe. Aparece en la ÚLTIMA oleada
## de la etapa (la 10 con oleadas_por_etapa = 10).
@export var jefe_escena: PackedScene
@export var jefe_nombre: String = "Jefe"
## Enemigos normales que acompañan al jefe (0 = solo el jefe).
@export var jefe_escoltas: int = 4
## Descanso después de derrotar al jefe (0 = usa el descanso global).
@export var jefe_tiempo_descanso: float = 15.0
