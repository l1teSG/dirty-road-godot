class_name ComportamientoEnemigo
extends RefCounted

## ══════════════════════════════════════════════════════════
##  COMPORTAMIENTO ENEMIGO — base (SOLO lógica, sin escena).
##  CONTRATO:
##  • e.life / e.speed / e.damage llegan YA escalados por oleada
##    (el WaveManager los ajusta antes de add_child).
##  • NUNCA escribir e.life. e.speed y e.damage solo con
##    multiplicadores temporales que se restauran (ver embestida).
##  • Movimiento SIEMPRE por la API (mover_hacia / mover_en /
##    detener): respetan velocidad_efectiva y el escalado.
##  • El objetivo (jugador o árbol) se pide con e.objetivo(); el
##    WaveManager ya lo identificó y se lo pasó al enemigo.
##  • Proyectiles/invocaciones van a e.disparar_desde() /
##    e._contenedor_salida(): el WaveManager pasa el contenedor.
##  • Daño SIEMPRE con e.atacar_objetivo() o e.damage.
## ══════════════════════════════════════════════════════════

var e: Enemigo = null

## El Enemigo inyecta los parámetros de su grupo correspondiente
## (ver _datos_comportamiento) ANTES de iniciar().
func configurar(_datos: Dictionary) -> void: pass

## Una vez, en _ready del enemigo, con las stats ya escaladas.
func iniciar(enemigo: Enemigo) -> void:
	e = enemigo

## Cada frame físico, ANTES de move_and_slide().
func pensar(_enemigo: Enemigo, _delta: float) -> void: pass

## Debug: el enemigo lo llama dentro de su _draw().
func debug_dibujar_en(_enemigo: Enemigo) -> void: pass
