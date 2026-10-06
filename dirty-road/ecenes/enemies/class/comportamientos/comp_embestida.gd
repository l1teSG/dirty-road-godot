## EMBESTIDA — patrulla, apunta (telegrafía), carga y descansa.
## El objetivo puede ser el jugador o el árbol (anti-estructura).
## Parámetros: alcance_deteccion, tiempo_apuntado, mult_carga,
## tiempo_carga, tiempo_descanso, mult_dano_carga, vel_patrulla, telegrafiar.
extends ComportamientoEnemigo

enum Estado { PATRULLANDO, APUNTANDO, CARGANDO, DESCANSANDO }

var alcance_deteccion: float = 340.0
var tiempo_apuntado: float = 0.7
var mult_carga: float = 3.2
var tiempo_carga: float = 0.9
var tiempo_descanso: float = 1.1
var mult_dano_carga: float = 2.0
var vel_patrulla: float = 0.6
var telegrafiar: bool = true

var _estado: Estado = Estado.PATRULLANDO
var _t: float = 0.0
var _dir: Vector2 = Vector2.RIGHT
var _dir_patrulla: Vector2 = Vector2.RIGHT
var _t_patrulla: float = 0.0


func configurar(datos: Dictionary) -> void:
	alcance_deteccion = datos.get("alcance_deteccion", alcance_deteccion)
	tiempo_apuntado = datos.get("tiempo_apuntado", tiempo_apuntado)
	mult_carga = datos.get("mult_carga", mult_carga)
	tiempo_carga = datos.get("tiempo_carga", tiempo_carga)
	tiempo_descanso = datos.get("tiempo_descanso", tiempo_descanso)
	mult_dano_carga = datos.get("mult_dano_carga", mult_dano_carga)
	vel_patrulla = datos.get("vel_patrulla", vel_patrulla)
	telegrafiar = datos.get("telegrafiar", telegrafiar)


func iniciar(enemigo: Enemigo) -> void:
	e = enemigo
	_estado = Estado.PATRULLANDO
	_dir_patrulla = Vector2.RIGHT.rotated(randf() * TAU)
	_t_patrulla = randf_range(1.0, 2.5)


func pensar(enemigo: Enemigo, delta: float) -> void:
	e = enemigo
	_t -= delta
	var obj := e.objetivo()
	match _estado:
		Estado.PATRULLANDO:
			_t_patrulla -= delta
			if _t_patrulla <= 0.0:
				_t_patrulla = randf_range(1.0, 2.5)
				_dir_patrulla = _dir_patrulla.rotated(randf_range(-1.2, 1.2))
			e.mover_en(_dir_patrulla, vel_patrulla)
			if obj != null and e.distancia_a(obj) <= alcance_deteccion:
				_entrar(Estado.APUNTANDO, tiempo_apuntado)
		Estado.APUNTANDO:
			e.detener(20.0)
			if obj != null:
				_dir = e.dir_a(obj)
			if _t <= 0.0:
				# e.damage ya viene escalado por el WaveManager: se
				# multiplica aquí y se restaura al terminar la carga.
				e.damage *= mult_dano_carga
				_entrar(Estado.CARGANDO, tiempo_carga)
		Estado.CARGANDO:
			e.mover_en(_dir, mult_carga)
			if e.atacar_objetivo() or _t <= 0.0:
				_terminar_carga()
		Estado.DESCANSANDO:
			e.detener()
			if _t <= 0.0:
				_entrar(Estado.PATRULLANDO, 0.0)


func _terminar_carga() -> void:
	e.damage /= mult_dano_carga      # restaurar el valor escalado
	_entrar(Estado.DESCANSANDO, tiempo_descanso)


func _entrar(nuevo: Estado, duracion: float) -> void:
	_estado = nuevo
	_t = duracion
	if telegrafiar and e.figura != null and is_instance_valid(e.figura):
		# Aviso magenta mientras apunta; blanco el resto del tiempo.
		e.figura.modulate = Color(1.0, 0.35, 0.55) if nuevo == Estado.APUNTANDO else Color.WHITE


func debug_dibujar_en(enemigo: Enemigo) -> void:
	enemigo.draw_arc(Vector2.ZERO, alcance_deteccion, 0.0, TAU, 40,
			Color(1.0, 0.35, 0.55, 0.35), 1.5)
