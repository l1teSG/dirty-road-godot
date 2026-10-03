class_name EducationDataGeneral
extends RefCounted

static func get_data() -> Dictionary:
	return {
		# Se muestran en el descanso entre oleadas
		"wave_break": [
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
			"Desconectar los aparatos que no usas también ahorra energía.",
			"Llevar tu propia bolsa evita decenas de bolsas plásticas al año.",
			"Los manglares protegen las costas y almacenan mucho carbono.",
			"Comer más vegetales y de temporada reduce tu huella ambiental.",
			"Los residuos orgánicos pueden convertirse en abono con el compostaje.",
			"Cerrar el grifo mientras te cepillas ahorra litros de agua."
		],

		# Se muestran al morir el jugador
		"death": [
			"Un árbol cae, pero miles de semillas esperan.",
			"La naturaleza no se rinde, y nosotros tampoco deberíamos.",
			"El planeta no pide perfección, solo constancia.",
			"Cada intento te enseña cómo proteger mejor.",
			"Los ecosistemas se recuperan cuando alguien los cuida.",
			"Caer no es el final: la restauración también empieza de nuevo.",
			"Proteger el planeta es una carrera de resistencia, no de velocidad.",
			"Aprende, mejora y vuelve a defender la naturaleza."
		],

		# Se muestran cada cierto tiempo durante la partida (survival_interval)
		"survival": [
			"Los bosques ayudan a regular el clima del planeta.",
			"La biodiversidad mantiene el equilibrio de los ecosistemas.",
			"Reciclar reduce la cantidad de residuos en los vertederos.",
			"Los ríos limpios sostienen a comunidades y a la fauna.",
			"Cuidar el suelo es cuidar los alimentos del futuro.",
			"Las energías renovables reducen las emisiones de gases contaminantes.",
			"Un consumo responsable empieza por preguntarte si de verdad lo necesitas.",
			"Los pequeños hábitos, repetidos por mucha gente, cambian el planeta.",
			"Los arrecifes de coral albergan una enorme variedad de vida marina.",
			"Los insectos, aunque pequeños, son clave para los ecosistemas."
		]
	}
