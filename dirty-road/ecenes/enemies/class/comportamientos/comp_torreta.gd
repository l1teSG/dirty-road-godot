## TORRETA — fija en su sitio, apunta al objetivo que le pasó el
## WaveManager (jugador o árbol) y suelta ráfagas al contenedor.
## Parámetros: alcance, recarga, balas_porrafaga, separacion, dispersion_grados.
extends ComportamientoEnemigo

var alcance: float = 600.0
var recarga: float = 2.2
var balas_porrafaga: int = 3
var separacion: float = 0.12
var dispersion_grados: float = 6.0

var _t_recarga: float = 0.0
var _t_bala: float = 0.0
var _balas: int = 0
var _obj: Node2D = null


func configurar(datos: Dictionary) -> void:
	alcance = datos.get("alcance", alcance)
	recarga = datos.get("recarga", recarga)
	balas_porrafaga = datos.get("balas_porrafaga", balas_porrafaga)
	separacion = datos.get("separacion", separacion)
	dispersion_grados = datos.get("dispersion_grados", dispersion_grados)


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	# Característica torreta: no se mueve. Se aplica en _ready, es
	# decir DESPUÉS del escalado del WaveManager: orden correcto.
	e.speed = 0.0
	_t_recarga = randf_range(0.2, 0.8)


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	_obj = e.objetivo()
	if _obj == null:
		return                       # sin objetivo (aún): quieta
	if e.distancia_a(_obj) > alcance:
		return

	_t_recarga -= delta
	_t_bala -= delta

	if _balas > 0:
		if _t_bala <= 0.0:
			_disparar()
			_balas -= 1
			_t_bala = separacion
	elif _t_recarga <= 0.0:
		_balas = balas_porrafaga
		_t_recarga = recarga


func _disparar() -> void:
	var dispersion: float = deg_to_rad(dispersion_grados)
	var origen: Vector2 = e.punto_salida()
	var dir: Vector2 = (_obj.global_position - origen).normalized() \
			.rotated(randf_range(-dispersion, dispersion))
	e.disparar_desde(origen, origen + dir * 120.0)


func debug_dibujar_en(enemigo: Enemigo) -> void:
	enemigo.draw_arc(Vector2.ZERO, alcance, 0.0, TAU, 48,
			Color(0.0, 1.0, 0.5, 0.3), 1.5)
