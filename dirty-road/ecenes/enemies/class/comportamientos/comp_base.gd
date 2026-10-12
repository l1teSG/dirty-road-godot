class_name ComportamientoEnemigo
extends RefCounted

## ══════════════════════════════════════════════════════════
##  COMPORTAMIENTO ENEMIGO — base (solo lógica, sin escena).
##  • RefCounted: el Enemigo la crea con .new() SIN add_child;
##    al morir el enemigo se libera sola (sin fugas de memoria).
##  • El Enemigo llama iniciar() una vez y pensar() cada frame
##    físico, antes de move_and_slide().
##  • Órdenes SIEMPRE por la API: objetivo(), distancia_a(),
##    dir_a(), mover_hacia(), mover_en(), detener(),
##    atacar_objetivo(obj), disparar_desde(nodo, punto).
##  • NUNCA escribir e.life; daño SIEMPRE vía e.damage (escalado).
##  • El árbol llega por objetivo(): aquí solo añadimos márgenes
##    y detección de choque contra la estructura.
## ══════════════════════════════════════════════════════════

var e: Enemigo = null


## Compatibilidad hacia atrás (hoy no-op: los params se leen
## del Inspector del Enemigo en iniciar()).
func configurar(_datos: Dictionary) -> void: pass


## Una vez, en _ready del enemigo, con las stats ya escaladas.
func iniciar(enemigo: Enemigo) -> void:
	e = enemigo


## Cada frame físico, ANTES de move_and_slide().
func pensar(_enemigo: Enemigo, _delta: float) -> void: pass


## Debug: el enemigo lo llama dentro de su _draw() si existe.
func debug_dibujar_en(_enemigo: Enemigo) -> void: pass


# ── Ayudantes ──

## Lee un float del Inspector del ENEMIGO (p. ej. "melee_radio");
## si la propiedad no existe todavía, devuelve el defecto.
func _f(nombre: String, defecto: float) -> float:
	if e == null:
		return defecto
	var v: Variant = e.get(nombre)
	return defecto if v == null else float(v)


## Igual que _f pero para booleanos.
func _b(nombre: String, defecto: bool) -> bool:
	if e == null:
		return defecto
	var v: Variant = e.get(nombre)
	return defecto if v == null else bool(v)
