extends Node

# ---------------------------------------------------------------------------
# EducationManager
# Single centralized autoload for the educational system.
# Simplified on purpose for the pre-sustentación deadline:
# - No Resources / .tres files.
# - No extra data classes.
# - Everything lives in arrays/dictionaries inside this script.
# - One reusable popup (EducationPopup) handles all visual presentation.
#
# After the fair, this can be refactored into a data-driven Resource-based
# architecture without changing the public API used by the rest of the game.
# ---------------------------------------------------------------------------

enum PopupVariant { WAVE_BREAK, DEATH, ENEMY_CARD, SURVIVAL }

@export var survival_interval: float = 120.0

var _popup: CanvasLayer

# ---------------------------------------------------------------------------
# CONTENT (Spanish, short, readable in under ~3 seconds)
# ---------------------------------------------------------------------------

var wave_break_messages: Array = [
	"Un árbol adulto puede absorber unos 22 kg de CO₂ al año.",
	"Los océanos producen más del 50% del oxígeno del planeta.",
	"Reducir el plástico de un solo uso protege la vida marina.",
	"Una ducha más corta ahorra miles de litros de agua al año.",
	"Los bosques albergan más del 80% de la biodiversidad terrestre.",
	"Separar la basura facilita muchísimo el reciclaje.",
	"Las abejas polinizan un tercio de los alimentos que comemos.",
	"Apagar las luces que no usas reduce tu huella de carbono.",
	"El plástico puede tardar más de 400 años en degradarse.",
	"Plantar un árbol es una de las acciones más simples y poderosas.",
	"El agua limpia es esencial para todos los ecosistemas.",
	"Usar bicicleta reduce emisiones y mejora tu salud.",
	"Los humedales filtran el agua de forma natural.",
	"Reutilizar objetos reduce la cantidad de residuos generados.",
	"La deforestación afecta el clima de todo el planeta.",
	"Cada botella reciclada es un paso menos hacia el vertedero.",
	"Los suelos sanos almacenan grandes cantidades de carbono.",
	"Comprar productos locales reduce emisiones de transporte.",
	"Las plantas nativas ayudan a mantener la fauna local.",
	"El compost transforma residuos orgánicos en nutrientes útiles.",
	"Cerrar la llave mientras te cepillas los dientes ahorra agua.",
	"Los arrecifes de coral protegen las costas de tormentas.",
	"Menos consumo de carne reduce la huella ecológica.",
	"Las energías renovables no se agotan con el uso.",
	"Un río limpio sostiene incontables formas de vida.",
	"Reforestar recupera hábitats perdidos para la fauna.",
	"El aire limpio es vital para la salud respiratoria.",
	"Cada acción pequeña suma cuando se repite a diario.",
	"Los polinizadores están desapareciendo por el uso de pesticidas.",
	"Elegir productos sin empaques reduce residuos plásticos.",
	"La biodiversidad hace más resistentes a los ecosistemas.",
	"El calentamiento global altera los ciclos de las estaciones.",
	"Recoger basura en la naturaleza protege a los animales.",
	"Usar bolsas reutilizables reduce el plástico de un solo uso.",
	"El suelo fértil tarda siglos en formarse naturalmente.",
	"Los manglares protegen las costas de la erosión.",
	"Ahorrar energía en casa reduce emisiones de CO₂.",
	"Las especies invasoras pueden desplazar a la fauna local.",
	"El reciclaje de papel salva árboles y reduce residuos.",
	"Cuidar el agua dulce es cuidar la vida silvestre.",
	"Los desechos electrónicos contienen materiales tóxicos.",
	"Las ciudades verdes reducen el efecto isla de calor.",
	"Cada tonelada de CO₂ evitada ayuda al planeta.",
	"El transporte público reduce la congestión y las emisiones.",
	"Los glaciares almacenan gran parte del agua dulce del mundo.",
	"Los suelos contaminados afectan a toda la cadena alimenticia.",
	"Sembrar flores nativas ayuda a las abejas locales.",
	"Reducir el consumo de agua ayuda en épocas de sequía.",
	"Los bosques regulan la temperatura de regiones enteras.",
	"El ruido excesivo también afecta a la fauna silvestre.",
	"Cada residuo reciclado es un recurso que no se pierde.",
	"La contaminación del aire afecta más a las ciudades densas.",
	"El uso responsable del agua beneficia a toda la comunidad.",
	"Los ríos limpios sostienen la pesca y la agricultura.",
	"Evitar productos desechables reduce la basura diaria.",
	"La reforestación ayuda a combatir la erosión del suelo.",
	"Cuidar los océanos es cuidar el clima global.",
	"Las plantas absorben contaminantes del aire urbano.",
	"Cada gesto sostenible inspira a otras personas.",
	"Proteger un árbol es proteger todo un ecosistema."
]

var death_messages: Array = [
	"No pudiste salvar este árbol, pero aún podemos proteger millones.",
	"La contaminación nunca descansa, pero tampoco debemos hacerlo nosotros.",
	"Cada pequeña acción cuenta, incluso después de caer.",
	"El planeta todavía necesita personas que lo protejan.",
	"Un árbol menos, pero la lucha continúa.",
	"La naturaleza no se rinde, y nosotros tampoco deberíamos.",
	"Este árbol cayó, pero su historia inspira a seguir intentando.",
	"La contaminación avanza cuando dejamos de resistir.",
	"Cada intento nos acerca a entender mejor el problema.",
	"El ecosistema recuerda cada esfuerzo, aunque el árbol caiga.",
	"Perder una batalla no significa perder la guerra por el planeta.",
	"El cambio empieza incluso en la derrota.",
	"La Tierra sigue esperando a quienes no se rinden.",
	"Un árbol cae, pero miles de semillas esperan.",
	"La contaminación gana terreno solo si dejamos de actuar.",
	"Cada raíz cortada nos recuerda por qué seguimos luchando.",
	"El equilibrio se rompió hoy, pero puede restaurarse.",
	"La naturaleza necesita paciencia, incluso en sus derrotas.",
	"No fue suficiente esta vez, pero el esfuerzo no fue en vano.",
	"El planeta agradece cada intento, incluso los que fallan.",
	"La contaminación no descansa, así que nosotros tampoco podemos.",
	"Este árbol se apaga, pero otros esperan ser protegidos.",
	"Cada caída enseña algo nuevo sobre el cuidado del planeta.",
	"La resiliencia de la naturaleza también vive en nosotros.",
	"Hoy la contaminación avanzó, pero la lucha sigue viva.",
	"El daño ambiental es real, pero también lo es nuestra voluntad.",
	"Este árbol confió en ti, y tú puedes intentarlo de nuevo.",
	"La naturaleza perdona, si aprendemos de cada intento.",
	"Un ecosistema débil necesita manos que no se cansen.",
	"La contaminación es persistente, pero nosotros podemos serlo más.",
	"Cada intento fallido nos acerca a proteger mejor el próximo árbol.",
	"El planeta no pide perfección, solo constancia.",
	"Aunque el árbol cayó, la semilla del cambio sigue viva.",
	"La contaminación avanza en silencio; nuestra acción debe ser constante.",
	"Hoy no alcanzó, pero el mañana también necesita defensores.",
	"El ecosistema cae, pero la esperanza de restaurarlo no.",
	"Cada intento es un paso más hacia entender el equilibrio natural.",
	"La naturaleza es paciente; nosotros también deberíamos serlo.",
	"Un árbol menos no significa un bosque perdido para siempre.",
	"La lucha por el planeta nunca termina en un solo intento."
]

var survival_facts: Array = [
	"Los bosques ayudan a regular el clima del planeta.",
	"La biodiversidad mantiene el equilibrio de los ecosistemas.",
	"Reciclar reduce la cantidad de residuos en los vertederos.",
	"El aire contaminado afecta la salud respiratoria de millones.",
	"Los océanos absorben gran parte del CO₂ generado por el ser humano.",
	"La deforestación reduce el hábitat de miles de especies.",
	"Los árboles filtran partículas contaminantes del aire.",
	"El agua dulce representa menos del 3% del agua del planeta.",
	"Las especies polinizadoras son esenciales para la agricultura.",
	"El plástico en los océanos afecta a la vida marina cada día.",
	"La restauración de ecosistemas puede tardar décadas en completarse.",
	"El cambio climático altera los patrones de lluvia en el mundo.",
	"Los suelos saludables retienen más agua y nutrientes.",
	"La pérdida de bosques acelera el calentamiento global.",
	"Los humedales son de los ecosistemas más productivos del planeta.",
	"El reciclaje de aluminio ahorra grandes cantidades de energía.",
	"La contaminación del aire puede viajar largas distancias.",
	"Los arrecifes de coral albergan una enorme biodiversidad marina.",
	"Las emisiones de CO₂ han aumentado drásticamente en un siglo.",
	"Los ríos contaminados afectan a comunidades enteras.",
	"La reforestación ayuda a recuperar suelos degradados.",
	"Cada especie extinta afecta el equilibrio de su ecosistema.",
	"El calentamiento global derrite glaciares cada año.",
	"Los desechos plásticos tardan siglos en desaparecer.",
	"La biodiversidad marina depende de aguas limpias.",
	"Los bosques tropicales generan gran parte del oxígeno mundial.",
	"El aire limpio reduce enfermedades respiratorias crónicas.",
	"La sobreexplotación pesquera reduce las poblaciones marinas.",
	"Los suelos contaminados afectan cultivos y alimentos.",
	"Las áreas protegidas ayudan a conservar especies en riesgo.",
	"El efecto invernadero es natural, pero se intensificó por el hombre.",
	"La pérdida de hábitat es la principal causa de extinción.",
	"El reciclaje de papel reduce la tala de árboles.",
	"Los manglares protegen la costa y capturan carbono.",
	"El agua contaminada puede transmitir enfermedades graves.",
	"La biodiversidad genética fortalece la resistencia de especies.",
	"El transporte es una fuente importante de emisiones globales.",
	"Los incendios forestales liberan grandes cantidades de CO₂.",
	"La restauración de ríos mejora la calidad del agua.",
	"Las especies invasoras alteran ecosistemas nativos.",
	"El derretimiento de hielos eleva el nivel del mar.",
	"Los bosques regulan el ciclo del agua en grandes regiones.",
	"La contaminación sonora afecta la comunicación animal.",
	"El suministro alimentario depende de ecosistemas saludables.",
	"Los desechos electrónicos son de los más difíciles de reciclar.",
	"La agricultura sostenible protege la salud del suelo.",
	"Los ecosistemas saludables absorben más carbono atmosférico.",
	"La contaminación lumínica afecta a especies nocturnas.",
	"El uso excesivo de pesticidas daña la fauna local.",
	"Los océanos generan la mayor parte del oxígeno del planeta.",
	"La restauración de bosques favorece el regreso de fauna silvestre.",
	"El agua reciclada puede reutilizarse para riego y limpieza.",
	"La deforestación aumenta el riesgo de inundaciones.",
	"Los polinizadores están disminuyendo por pérdida de hábitat.",
	"Las energías limpias reducen la dependencia de combustibles fósiles.",
	"La contaminación plástica llega incluso a zonas remotas.",
	"El suelo fértil puede tardar cientos de años en formarse.",
	"Los ecosistemas resilientes se recuperan más rápido de disturbios.",
	"La pérdida de biodiversidad afecta la seguridad alimentaria.",
	"Los bosques antiguos almacenan carbono durante siglos.",
	"La calidad del aire mejora con más áreas verdes urbanas.",
	"El calentamiento de los océanos afecta la vida marina.",
	"La gestión de residuos reduce la contaminación del suelo.",
	"Los ríos sanos sostienen la pesca y el turismo local.",
	"La conservación de especies protege cadenas alimenticias completas.",
	"El uso de energía solar reduce las emisiones de carbono.",
	"La restauración de humedales mejora la calidad del agua.",
	"La tala ilegal amenaza ecosistemas forestales enteros.",
	"El aire limpio beneficia tanto a personas como a animales.",
	"La acidificación del océano afecta a los corales y moluscos.",
	"El uso responsable del agua ayuda en tiempos de sequía.",
	"La agricultura urbana puede reducir emisiones de transporte.",
	"Los ecosistemas costeros protegen contra tormentas severas.",
	"La reforestación urbana reduce el calor en las ciudades.",
	"El monitoreo ambiental ayuda a prevenir desastres ecológicos.",
	"La pérdida de glaciares afecta el suministro de agua dulce.",
	"Los proyectos de restauración pueden revivir ríos completos.",
	"La educación ambiental impulsa el cuidado a largo plazo.",
	"Cada ecosistema protegido es un paso hacia el equilibrio global.",
	"El futuro del planeta depende de decisiones tomadas hoy."
]

# Keyed by a stable "enemy_id" string (sin guiones bajos, en minúsculas —
# ver WaveManager._obtener_enemy_id()). "default" es el respaldo seguro
# para cualquier enemy_id no catalogado todavía.
var enemy_info: Dictionary = {
	"microplastico": {
		"name": "Micro-Plástico",
		"represents": "Contaminación por residuos plásticos.",
		"fact": "Los microplásticos pueden tardar cientos de años en degradarse."
	},
	"ignis": {
		"name": "Ignis",
		"represents": "Riesgo de incendios forestales.",
		"fact": "La sequía y la deforestación aumentan el riesgo de incendios."
	},
	"nubegas": {
		"name": "Nube de Gas",
		"represents": "Contaminación del aire.",
		"fact": "El aire contaminado puede afectar la salud humana y los ecosistemas."
	},
	"mareanegra": {
		"name": "Marea Negra",
		"represents": "Contaminación por derrames de petróleo.",
		"fact": "Un derrame de petróleo puede tardar años en limpiarse por completo."
	},
	"default": {
		"name": "Contaminación",
		"represents": "Una amenaza para el ecosistema.",
		"fact": "Cada forma de contaminación afecta el equilibrio natural."
	}
}

# ---------------------------------------------------------------------------
# NO-REPEAT DRAW QUEUES
# ---------------------------------------------------------------------------

var _wave_queue: Array = []
var _death_queue: Array = []
var _survival_queue: Array = []

var _last_wave_message: String = ""
var _last_death_message: String = ""
var _last_survival_fact: String = ""

var _seen_enemies: Dictionary = {}

var _survival_timer: Timer


func _ready() -> void:
	randomize()

	var popup_script = load("res://scripts/education/EducationPopup.gd")
	_popup = popup_script.new()
	add_child(_popup)

	_survival_timer = Timer.new()
	_survival_timer.wait_time = survival_interval
	_survival_timer.one_shot = false
	_survival_timer.timeout.connect(_on_survival_timeout)
	add_child(_survival_timer)


# ---------------------------------------------------------------------------
# PUBLIC API — call these from WaveManager / Player / Enemy scripts
# ---------------------------------------------------------------------------

func start_run() -> void:
	_seen_enemies.clear()
	_wave_queue.clear()
	_death_queue.clear()
	_survival_queue.clear()
	_survival_timer.start()


func stop_run() -> void:
	_survival_timer.stop()


func on_wave_ended() -> void:
	var msg: String = _draw(_wave_queue, wave_break_messages, "_last_wave_message")
	_popup.enqueue(msg, PopupVariant.WAVE_BREAK, 3.5)


func on_enemy_encountered(enemy_id: String) -> void:
	if _seen_enemies.has(enemy_id):
		return
	_seen_enemies[enemy_id] = true

	var info: Dictionary = enemy_info.get(enemy_id, enemy_info["default"])
	var text: String = "%s\n%s\n%s" % [info["name"], info["represents"], info["fact"]]
	_popup.enqueue(text, PopupVariant.ENEMY_CARD, 4.0)


func on_player_died() -> void:
	stop_run()
	var msg: String = _draw(_death_queue, death_messages, "_last_death_message")
	_popup.enqueue(msg, PopupVariant.DEATH, 3.5)
	await _popup.popup_finished


# ---------------------------------------------------------------------------
# INTERNAL
# ---------------------------------------------------------------------------

func _on_survival_timeout() -> void:
	var fact: String = _draw(_survival_queue, survival_facts, "_last_survival_fact")
	_popup.enqueue(fact, PopupVariant.SURVIVAL, 3.5)


func _draw(queue: Array, source: Array, last_property_name: String) -> String:
	if queue.is_empty():
		queue.append_array(source)
		queue.shuffle()
		var last_value = get(last_property_name)
		if queue.size() > 1 and queue[0] == last_value:
			var tmp = queue[0]
			queue[0] = queue[1]
			queue[1] = tmp

	var picked: String = queue.pop_front()
	set(last_property_name, picked)
	return picked
