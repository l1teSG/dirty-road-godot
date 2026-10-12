extends Node

## ══════════════════════════════════════════════════════════
##  AUDIO MANAGER (autoload)
##  · Buses Master / Música / Efectos creados en runtime (sin bus layout).
##  · Volúmenes tomados de los Ajustes (SaveManager) y aplicados en caliente.
##  · SFX generados por CÓDIGO (AudioStreamWAV). Si algo falla, no rompe:
##    simplemente no suena. Puedes reemplazar los streams por audios reales.
## ══════════════════════════════════════════════════════════

const BUS_MASTER := "Master"
const BUS_MUSICA := "Música"
const BUS_EFECTOS := "Efectos"

var _sfx: Dictionary = {}
var _musica: AudioStreamPlayer = null
var _listo: bool = false


func _ready() -> void:
	_asegurar_buses()
	_generar_sfx()
	_listo = true
	if SaveManager != null and SaveManager.has_signal("ajustes_cambiados"):
		SaveManager.ajustes_cambiados.connect(_on_ajustes)
	_on_ajustes()


func _on_ajustes() -> void:
	aplicar_volumenes()


# ───────────── BUSES ─────────────

func _asegurar_buses() -> void:
	if AudioServer.get_bus_index(BUS_MUSICA) < 0:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, BUS_MUSICA)
		AudioServer.set_bus_send(i, BUS_MASTER)
	if AudioServer.get_bus_index(BUS_EFECTOS) < 0:
		AudioServer.add_bus()
		var i2 := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i2, BUS_EFECTOS)
		AudioServer.set_bus_send(i2, BUS_MASTER)


func _db(v: float) -> float:
	if v <= 0.001:
		return -80.0
	return linear_to_db(clampf(v, 0.0, 1.0))


func aplicar_volumenes() -> void:
	if SaveManager == null:
		return
	var vm := float(SaveManager.get_ajuste("vol_master", 1.0))
	var vmu := float(SaveManager.get_ajuste("vol_musica", 0.7))
	var ve := float(SaveManager.get_ajuste("vol_efectos", 0.9))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), _db(vm))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSICA), _db(vmu))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_EFECTOS), _db(ve))
	if _musica != null:
		_musica.volume_db = 0.0


# ───────────── SFX ─────────────

func _generar_sfx() -> void:
	# (freq_hz, duración_s, volumen, barrido_hz)  barrido = delta de frecuencia
	_sfx["disparo"] = _blip(880.0, 0.07, 0.5, -300.0)
	_sfx["golpe"] = _blip(180.0, 0.10, 0.7, -60.0)
	_sfx["dash"] = _blip(500.0, 0.14, 0.5, 500.0)
	_sfx["muerte"] = _blip(160.0, 0.22, 0.6, -110.0)
	_sfx["popup"] = _blip(1200.0, 0.10, 0.4, 200.0)
	_sfx["clic"] = _blip(1500.0, 0.05, 0.4, 0.0)
	_sfx["jefe"] = _blip(90.0, 0.5, 0.7, -30.0)


## Genera un "blip" corto como AudioStreamWAV. Devuelve null si falla.
func _blip(freq: float, dur: float, vol: float, barrido: float) -> AudioStreamWAV:
	var rate := 22050
	var n := maxi(int(rate * dur), 1)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var fase := 0.0
	for i in n:
		var t := float(i) / float(rate)
		var f := freq + barrido * t
		fase += TAU * f / float(rate)
		var env: float = exp(-t * 9.0 / maxf(dur, 0.01))
		var s: float = sin(fase) * env * vol
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w


func reproducir(nombre: String, vol_extra: float = 0.0) -> void:
	if not _listo:
		return
	var stream: AudioStream = _sfx.get(nombre, null)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = BUS_EFECTOS
	p.volume_db = vol_extra
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func poner_musica(stream: AudioStream, vol_db: float = 0.0) -> void:
	if stream == null:
		return
	if _musica == null:
		_musica = AudioStreamPlayer.new()
		_musica.bus = BUS_MUSICA
		_musica.volume_db = vol_db
		add_child(_musica)
	_musica.stream = stream
	_musica.play()
