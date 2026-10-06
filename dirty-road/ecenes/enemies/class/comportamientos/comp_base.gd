class_name ComportamientoEnemigo
extends Node

## ══════════════════════════════════════════════════════════
##  COMPORTAMIENTO ENEMIGO — base (solo lógica, sin escena).
##  • El Enemigo la instala (add_child), llama iniciar() una vez
##    y pensar() cada frame físico, antes de move_and_slide().
##  • Órdenes SIEMPRE por la API: objetivo(), distancia_a(),
##    dir_a(), mover_hacia(), mover_en(), detener(),
##    atacar_objetivo(obj), disparar_desde(nodo, dir).
##  • NUNCA escribir e.life; daño SIEMPRE vía e.damage (escalado).
##  • El árbol llega por objetivo(): estos ayudantes solo añaden
##    márgenes y detección de choque contra la estructura.
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
	var v = e.get(nombre)
	return defecto if v == null else float(v)


## true si el objetivo actual es el árbol/estructura a defender.
func _es_arbol(n: Node2D) -> bool:
	return e != null and n != null and n == e.arbol


## Nodo de salida de proyectiles: la boca si existe, si no el propio enemigo.
func _origen_disparo() -> Node2D:
	if e != null and e.boca != null and is_instance_valid(e.boca):
		return e.boca
	return e


## true si el deslizamiento de move_and_slide() chocó contra el
## objetivo o uno de sus hijos (p. ej. el tronco del árbol).
func _choco_con(obj: Node2D) -> bool:
	if e == null or obj == null:
		return false
	for i in e.get_slide_collision_count():
		var col: Object = e.get_slide_collision(i).get_collider()
		if col == null:
			continue
		if col == obj:
			return true
		var n := col as Node
		if n != null and obj.is_ancestor_of(n):
			return true
	return false
