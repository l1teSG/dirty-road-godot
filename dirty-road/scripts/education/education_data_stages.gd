class_name EducationDataStages
extends RefCounted

static func get_data() -> Array:
	return [
		# ───── ETAPA 1 · Oleadas 1-10 ─────
		{
			"theme": "Contaminación del suelo y el aire",
			"intro": "Los contaminantes dañan el suelo y el aire que respiramos.",
			"facts": [
				"Un suelo contaminado afecta cultivos, agua y alimentos.",
				"El aire limpio reduce enfermedades respiratorias crónicas.",
				"Los suelos sanos almacenan grandes cantidades de carbono.",
				"Los árboles filtran partículas contaminantes del aire."
			],
			"death": [
				"El aire y el suelo siguen necesitando defensores. Inténtalo otra vez.",
				"La contaminación avanzó hoy, pero tu próximo intento puede frenarla."
			],
			"boss_defeated": "Un suelo sano es la base de todo ecosistema.",
			"action": "Compostar tus residuos orgánicos devuelve nutrientes al suelo.",
			"enemies": {
				"microplastico": {
					"name": "Microplástico",
					"represents": "Fragmentos diminutos de plástico en suelo y agua.",
					"facts": [
						"Los microplásticos miden menos de 5 mm y se han hallado en casi todos los ambientes.",
						"Muchos nacen cuando el plástico grande se rompe poco a poco.",
						"Pueden entrar en la cadena alimenticia al ser ingeridos por animales."
					]
				},
				"nubegas": {
					"name": "Nube de Gas",
					"represents": "Gases contaminantes en el aire.",
					"facts": [
						"Los gases de combustión empeoran la calidad del aire de las ciudades.",
						"El aire contaminado afecta más a niños y adultos mayores.",
						"Los árboles y las zonas verdes ayudan a filtrar el aire."
					]
				},
				"petroleo": {
					"name": "Petróleo",
					"represents": "Derrames y residuos de hidrocarburos.",
					"facts": [
						"Un pequeño derrame de petróleo puede contaminar el suelo y el agua.",
						"El petróleo cubre plumas y pelaje y dificulta la vida animal.",
						"Limpiar un derrame puede tardar años."
					]
				},
				"excavadoratoxica": {
					"name": "Excavadora Tóxica",
					"represents": "La maquinaria que remueve y contamina el suelo.",
					"facts": [
						"Remover y compactar el suelo destruye los organismos que lo mantienen vivo.",
						"Los contaminantes del suelo pasan a las plantas y a quienes las consumen.",
						"Recuperar un suelo degradado puede tardar décadas."
					]
				}
			}
		},
		# ───── ETAPA 2 · Oleadas 11-20 ─────
		{
			"theme": "Basura y vertederos",
			"intro": "La basura mal gestionada contamina suelo, agua y aire.",
			"facts": [
				"Los vertederos emiten metano, un gas de efecto invernadero.",
				"Una lata de aluminio puede tardar hasta 200 años en degradarse.",
				"Una bolsa plástica se usa minutos, pero dura siglos.",
				"Separar la basura facilita muchísimo el reciclaje."
			],
			"death": [
				"La basura se acumula cuando nadie actúa. Vuelve a intentarlo.",
				"Cada residuo evitado es una victoria. Prueba de nuevo."
			],
			"boss_defeated": "Reducir, reutilizar y reciclar frena la basura.",
			"action": "Separa tus residuos y reutiliza envases antes de desecharlos.",
			"enemies": {
				"lataoxidada": {
					"name": "Lata Oxidada",
					"represents": "Residuos metálicos abandonados.",
					"facts": [
						"El aluminio se puede reciclar muchas veces sin perder calidad.",
						"Reciclar aluminio ahorra gran parte de la energía de fabricarlo nuevo.",
						"Una lata abandonada puede tardar siglos en degradarse."
					]
				},
				"neumaticoquemado": {
					"name": "Neumático Quemado",
					"represents": "Llantas desechadas y quemadas al aire libre.",
					"facts": [
						"Quemar neumáticos libera humo denso y sustancias tóxicas.",
						"Las llantas viejas pueden reutilizarse o reciclarse en nuevos productos.",
						"Los neumáticos abandonados acumulan agua y favorecen plagas como los mosquitos."
					]
				},
				"bolsaplastica": {
					"name": "Bolsa Plástica",
					"represents": "Plásticos de un solo uso.",
					"facts": [
						"Una bolsa plástica se usa minutos, pero puede durar siglos.",
						"Las bolsas reutilizables reducen mucho el plástico desechable.",
						"El viento lleva las bolsas a ríos, campos y mares."
					]
				},
				"vertederoviviente": {
					"name": "Vertedero Viviente",
					"represents": "Los vertederos desbordados.",
					"facts": [
						"Los vertederos liberan metano al descomponerse los residuos orgánicos.",
						"Los líquidos de la basura, los lixiviados, pueden contaminar aguas subterráneas.",
						"Producir menos basura es mejor que gestionar más basura."
					]
				}
			}
		},
		# ───── ETAPA 3 · Oleadas 21-30 ─────
		{
			"theme": "Océanos y plástico",
			"intro": "Gran parte del plástico termina en el mar.",
			"facts": [
				"Millones de toneladas de plástico llegan a los océanos cada año.",
				"Las redes de pesca abandonadas siguen atrapando animales por años.",
				"Muchas aves y tortugas confunden el plástico con comida.",
				"Los océanos producen más del 50% del oxígeno del planeta."
			],
			"death": [
				"El mar sigue pidiendo ayuda. Intenta de nuevo.",
				"El plástico gana terreno solo si dejamos de actuar."
			],
			"boss_defeated": "Cuidar los océanos es cuidar el clima global.",
			"action": "Rechaza pitillos y envases de un solo uso; limpia playas cuando puedas.",
			"enemies": {
				"botellaplastico": {
					"name": "Botella de Plástico",
					"represents": "Envases plásticos que llegan al mar.",
					"facts": [
						"Una botella de plástico puede tardar cientos de años en degradarse.",
						"Reciclar o reutilizar botellas evita que lleguen al mar.",
						"Llevar tu propia botella reutilizable reduce residuos a diario."
					]
				},
				"botellalanzadora": {
					"name": "Botella Lanzadora",
					"represents": "Basura que las corrientes dispersan por el océano.",
					"facts": [
						"Las corrientes marinas concentran basura en grandes zonas del océano.",
						"Gran parte de la basura marina proviene de tierra firme.",
						"Una botella tirada lejos del mar puede terminar en él por ríos y desagües."
					]
				},
				"redfantasma": {
					"name": "Red Fantasma",
					"represents": "Redes de pesca abandonadas.",
					"facts": [
						"Las redes abandonadas siguen atrapando animales por años.",
						"Tortugas, delfines y peces pueden quedar enredados en ellas.",
						"Pescar de forma responsable reduce el equipo perdido en el mar."
					]
				},
				"islaplastico": {
					"name": "Isla de Plástico",
					"represents": "Las grandes acumulaciones de basura marina.",
					"facts": [
						"Las grandes zonas de basura marina son sobre todo plástico fragmentado.",
						"El plástico se rompe en trozos cada vez más pequeños, pero no desaparece.",
						"Evitar que el plástico llegue al mar es más eficaz que sacarlo después."
					]
				}
			}
		},
		# ───── ETAPA 4 · Oleadas 31-40 ─────
		{
			"theme": "Contaminación industrial",
			"intro": "La industria emite gases y partículas que afectan la salud.",
			"facts": [
				"La industria es una de las mayores fuentes de emisiones de CO₂.",
				"Los filtros industriales reducen mucho las partículas contaminantes.",
				"Las partículas finas del hollín dañan los pulmones.",
				"Regular las emisiones mejora el aire de ciudades enteras."
			],
			"death": [
				"El humo no se detiene solo. Vuelve a intentarlo.",
				"La industria limpia es posible; tu esfuerzo también cuenta."
			],
			"boss_defeated": "Las industrias limpias reducen las emisiones.",
			"action": "Prefiere productos de empresas que reporten y reduzcan sus emisiones.",
			"enemies": {
				"humofabrica": {
					"name": "Humo de Fábrica",
					"represents": "Emisiones de fábricas sin control.",
					"facts": [
						"Las fábricas sin filtros liberan gases y partículas al aire.",
						"Los filtros y los combustibles más limpios reducen las emisiones.",
						"Las normas de emisiones mejoran el aire de las ciudades."
					]
				},
				"chimenea": {
					"name": "Chimenea",
					"represents": "Fuentes fijas de contaminación del aire.",
					"facts": [
						"Las chimeneas concentran las emisiones en un solo punto, pero el viento las dispersa lejos.",
						"Instalar filtros en las chimeneas reduce mucho lo que llega al aire.",
						"Medir las emisiones permite detectar y corregir la contaminación."
					]
				},
				"hollin": {
					"name": "Hollín",
					"represents": "Partículas finas de la combustión.",
					"facts": [
						"Las partículas finas pueden llegar hasta los pulmones.",
						"Se generan al quemar combustibles fósiles y biomasa.",
						"Respirarlas durante años se asocia a enfermedades respiratorias."
					]
				},
				"chimeneagigante": {
					"name": "Chimenea Gigante",
					"represents": "La industria que no controla su impacto.",
					"facts": [
						"La industria puede reducir su impacto con energías limpias y eficiencia.",
						"La economía circular reutiliza materiales para generar menos residuos.",
						"Los consumidores influyen al elegir productos más responsables."
					]
				}
			}
		},
		# ───── ETAPA 5 · Oleadas 41-50 ─────
		{
			"theme": "Lluvia ácida",
			"intro": "Los gases industriales vuelven al suelo como lluvia ácida.",
			"facts": [
				"La lluvia ácida daña bosques, suelos y lagos.",
				"El dióxido de azufre y los óxidos de nitrógeno causan la lluvia ácida.",
				"Un agua con pH muy bajo puede acabar con la vida acuática.",
				"La acidificación del océano afecta a los corales y moluscos."
			],
			"death": [
				"La acidez avanzó esta vez. Inténtalo de nuevo.",
				"Menos emisiones, menos lluvia ácida. Sigue intentándolo."
			],
			"boss_defeated": "Menos emisiones, menos lluvia ácida.",
			"action": "Ahorra energía en casa: menos consumo, menos gases contaminantes.",
			"enemies": {
				"gotaacida": {
					"name": "Gota Ácida",
					"represents": "Lluvia con pH bajo.",
					"facts": [
						"La lluvia ácida se forma cuando ciertos gases reaccionan con el agua de la atmósfera.",
						"Daña hojas y suelos, y debilita los bosques.",
						"Puede deteriorar edificios y monumentos."
					]
				},
				"charcoacido": {
					"name": "Charco Ácido",
					"represents": "Agua acidificada que se acumula en el suelo.",
					"facts": [
						"Un agua demasiado ácida puede acabar con peces y anfibios.",
						"Los suelos acidificados pierden nutrientes que las plantas necesitan.",
						"Reducir las emisiones permite que algunos ecosistemas se recuperen con el tiempo."
					]
				},
				"nubeacida": {
					"name": "Nube Ácida",
					"represents": "Gases ácidos en la atmósfera.",
					"facts": [
						"El dióxido de azufre proviene sobre todo de quemar carbón y petróleo.",
						"Los óxidos de nitrógeno vienen del tráfico y la industria.",
						"Estos gases también irritan las vías respiratorias."
					]
				},
				"geiseracido": {
					"name": "Géiser Ácido",
					"represents": "El efecto acumulado de la lluvia ácida.",
					"facts": [
						"La lluvia ácida ha disminuido donde se han reducido las emisiones.",
						"Las normas ambientales han demostrado que sí funcionan.",
						"Las energías limpias ayudan a evitar este problema desde el origen."
					]
				}
			}
		},
		# ───── ETAPA 6 · Oleadas 51-60 ─────
		{
			"theme": "Residuos electrónicos",
			"intro": "Los aparatos desechados contienen materiales tóxicos.",
			"facts": [
				"Los desechos electrónicos contienen materiales tóxicos y valiosos.",
				"Una sola pila puede contaminar grandes cantidades de agua.",
				"Del cobre reciclado se puede recuperar gran parte del metal.",
				"Los desechos electrónicos son de los más difíciles de reciclar."
			],
			"death": [
				"La chatarra se acumula si no la gestionamos. Prueba otra vez.",
				"Reciclar bien un aparato empieza con un intento más."
			],
			"boss_defeated": "Reparar y reutilizar aparatos reduce la basura electrónica.",
			"action": "Lleva pilas y aparatos viejos a puntos de recolección autorizados.",
			"enemies": {
				"basuraelectronica": {
					"name": "Basura Electrónica",
					"represents": "Aparatos desechados antes de tiempo.",
					"facts": [
						"Un teléfono contiene metales valiosos y otros contaminantes.",
						"Reparar un aparato prolonga su vida útil.",
						"Cambiar de dispositivo con menos frecuencia reduce la basura electrónica."
					]
				},
				"cableelectrico": {
					"name": "Cable Eléctrico",
					"represents": "Cables y chatarra electrónica.",
					"facts": [
						"Los cables contienen cobre, que se puede recuperar reciclando.",
						"Quemar cables al aire libre libera humos tóxicos.",
						"Reciclar metales evita extraer más materia prima."
					]
				},
				"bateriatoxica": {
					"name": "Batería Tóxica",
					"represents": "Pilas y baterías desechadas.",
					"facts": [
						"Las pilas y baterías contienen metales que pueden contaminar suelo y agua.",
						"Deben entregarse en puntos de recolección, no en la basura común.",
						"Las pilas recargables reducen la cantidad de residuos."
					]
				},
				"montanachatarra": {
					"name": "Montaña de Chatarra",
					"represents": "La montaña global de residuos electrónicos.",
					"facts": [
						"Los residuos electrónicos están entre los que más crecen en el mundo.",
						"Solo una parte de ellos se recicla de forma adecuada.",
						"Diseñar aparatos reparables ayuda a reducir el problema."
					]
				}
			}
		},
		# ───── ETAPA 7 · Oleadas 61-70 ─────
		{
			"theme": "Energía nuclear y radiación",
			"intro": "Algunos residuos permanecen peligrosos durante miles de años.",
			"facts": [
				"Algunos residuos radiactivos permanecen peligrosos por miles de años.",
				"Un mal almacenamiento puede contaminar suelo y agua.",
				"Ciertos contaminantes pueden dañar el material genético.",
				"Un accidente nuclear puede dejar zonas inhabitables por décadas."
			],
			"death": [
				"Estos residuos requieren paciencia y cuidado. Vuelve a intentarlo.",
				"La seguridad se construye intento a intento."
			],
			"boss_defeated": "Gestionar bien los residuos protege a las futuras generaciones.",
			"action": "Infórmate y apoya energías limpias y una gestión segura de residuos.",
			"enemies": {
				"residuoradiactivo": {
					"name": "Residuo Radiactivo",
					"represents": "Material que sigue emitiendo radiación durante mucho tiempo.",
					"facts": [
						"Algunos isótopos radiactivos tardan miles de años en perder su actividad.",
						"Pueden acumularse en el suelo, el agua y los seres vivos.",
						"La exposición alta a la radiación daña las células."
					]
				},
				"barrilexplosivo": {
					"name": "Barril Explosivo",
					"represents": "Residuos nucleares mal almacenados.",
					"facts": [
						"Algunos residuos requieren almacenamiento seguro durante miles de años.",
						"Un contenedor dañado puede filtrar sustancias al suelo y al agua.",
						"Su gestión exige control y vigilancia a largo plazo."
					]
				},
				"mutante": {
					"name": "Mutante",
					"represents": "Seres vivos afectados por contaminantes extremos.",
					"facts": [
						"Ciertos contaminantes pueden dañar el material genético de los seres vivos.",
						"Tras un accidente grave, algunas zonas se cierran durante décadas.",
						"La prevención es mucho más eficaz que la limpieza posterior."
					]
				},
				"reactorroto": {
					"name": "Reactor Roto",
					"represents": "El riesgo de los accidentes nucleares.",
					"facts": [
						"Los accidentes nucleares son poco frecuentes, pero sus efectos son muy duraderos.",
						"Las energías renovables no generan residuos radiactivos.",
						"Informarse permite opinar con criterio sobre el futuro energético."
					]
				}
			}
		},
		# ───── ETAPA 8 · Oleadas 71-80 ─────
		{
			"theme": "Pesticidas y agricultura",
			"intro": "El exceso de agroquímicos daña la fauna y el agua.",
			"facts": [
				"El exceso de pesticidas daña a la fauna local.",
				"Los pesticidas pueden viajar con el viento y llegar a ríos y poblaciones.",
				"Un ecosistema diverso controla las plagas de forma natural.",
				"Los polinizadores están desapareciendo por el uso de pesticidas."
			],
			"death": [
				"Las plagas ganaron esta vez. Intenta de nuevo.",
				"Los polinizadores te necesitan. Vuelve a intentarlo."
			],
			"boss_defeated": "La agricultura sostenible protege el suelo y los polinizadores.",
			"action": "Compra alimentos locales y de cultivo sostenible; siembra flores nativas.",
			"enemies": {
				"dronpesticida": {
					"name": "Dron Pesticida",
					"represents": "Aplicación aérea de agroquímicos.",
					"facts": [
						"La fumigación aérea puede dispersar pesticidas más allá del cultivo.",
						"Aplicar solo lo necesario reduce el daño ambiental.",
						"Un uso excesivo afecta a insectos beneficiosos."
					]
				},
				"nubefumigacion": {
					"name": "Nube de Fumigación",
					"represents": "Pesticidas dispersos en el aire.",
					"facts": [
						"Los pesticidas pueden viajar con el viento y llegar a ríos y poblaciones.",
						"La lluvia puede arrastrarlos a los ríos y contaminar el agua.",
						"Las franjas de vegetación junto a los ríos ayudan a filtrar el agua."
					]
				},
				"plaga": {
					"name": "Plaga",
					"represents": "Insectos que proliferan cuando se rompe el equilibrio natural.",
					"facts": [
						"Los monocultivos son más vulnerables a plagas y enfermedades.",
						"Los depredadores naturales controlan plagas sin químicos.",
						"Rotar y diversificar cultivos mantiene el suelo sano."
					]
				},
				"helicopterofumigador": {
					"name": "Helicóptero Fumigador",
					"represents": "La agricultura intensiva dependiente de agroquímicos.",
					"facts": [
						"Las abejas polinizan un tercio de los alimentos que comemos.",
						"Los pesticidas y la pérdida de hábitat ponen en riesgo a los polinizadores.",
						"La agricultura sostenible puede producir alimento cuidando el ecosistema."
					]
				}
			}
		},
		# ───── ETAPA 9 · Oleadas 81-90 ─────
		{
			"theme": "Deforestación",
			"intro": "Perder bosques acelera el calentamiento global.",
			"facts": [
				"La deforestación es una de las principales causas de pérdida de biodiversidad.",
				"La tala ilegal amenaza ecosistemas forestales enteros.",
				"Los incendios forestales liberan grandes cantidades de CO₂.",
				"La deforestación aumenta el riesgo de inundaciones."
			],
			"death": [
				"Otro árbol cayó, pero el bosque aún puede salvarse.",
				"Cada árbol protegido cuenta. Inténtalo otra vez."
			],
			"boss_defeated": "Reforestar recupera hábitats perdidos.",
			"action": "Planta un árbol nativo y elige papel y madera con certificación.",
			"enemies": {
				"talador": {
					"name": "Talador",
					"represents": "La tala indiscriminada.",
					"facts": [
						"La tala sin control destruye el hábitat de miles de especies.",
						"Cada árbol talado deja de absorber CO₂.",
						"La madera con certificación proviene de bosques bien manejados."
					]
				},
				"motosierra": {
					"name": "Motosierra",
					"represents": "La rapidez con la que se pierde un bosque.",
					"facts": [
						"Talar un bosque lleva mucho menos tiempo que restaurarlo.",
						"Las raíces sujetan el suelo; sin árboles, la lluvia lo arrastra.",
						"Reforestar ayuda a estabilizar laderas."
					]
				},
				"incendio": {
					"name": "Incendio",
					"represents": "Los incendios forestales.",
					"facts": [
						"Los incendios forestales liberan grandes cantidades de CO₂.",
						"Muchos incendios son provocados o causados por descuidos humanos.",
						"Apagar bien las fogatas ayuda a prevenirlos."
					]
				},
				"aserraderoandante": {
					"name": "Aserradero Andante",
					"represents": "La deforestación a gran escala.",
					"facts": [
						"Los bosques regulan el ciclo del agua en grandes regiones.",
						"La tala ilegal amenaza ecosistemas forestales enteros.",
						"Proteger los bosques existentes es una de las acciones climáticas más efectivas."
					]
				}
			}
		},
		# ───── ETAPA 10 · Oleadas 91-100 ─────
		{
			"theme": "Cambio climático",
			"intro": "El planeta se calienta y el clima se altera.",
			"facts": [
				"El calentamiento global hace más frecuentes las olas de calor.",
				"El cambio climático intensifica tormentas e inundaciones.",
				"El derretimiento de los hielos eleva el nivel del mar.",
				"Las energías limpias reducen la dependencia de combustibles fósiles."
			],
			"death": [
				"El clima es el mayor reto, y no se resuelve en un intento.",
				"Cada tonelada de CO₂ evitada ayuda. Sigue intentándolo."
			],
			"boss_defeated": "Cada acción cuenta para frenar el cambio climático.",
			"action": "Reduce tu huella: ahorra energía, camina más y consume con conciencia.",
			"enemies": {
				"olacalor": {
					"name": "Ola de Calor",
					"represents": "Temperaturas extremas cada vez más frecuentes.",
					"facts": [
						"El calentamiento global hace más frecuentes las olas de calor.",
						"Las ciudades con más zonas verdes se mantienen más frescas.",
						"El calor extremo afecta la salud, los cultivos y los ecosistemas."
					]
				},
				"tormenta": {
					"name": "Tormenta",
					"represents": "Fenómenos climáticos más intensos.",
					"facts": [
						"Un clima más cálido puede intensificar tormentas y lluvias.",
						"Los manglares y humedales ayudan a amortiguar sus efectos.",
						"Prepararse y prevenir reduce los daños a las comunidades."
					]
				},
				"deshielo": {
					"name": "Deshielo",
					"represents": "El derretimiento de los hielos.",
					"facts": [
						"El derretimiento de glaciares y casquetes eleva el nivel del mar.",
						"Muchos glaciares almacenan agua dulce de la que dependen comunidades.",
						"Reducir las emisiones frena el ritmo del deshielo."
					]
				},
				"calentamientoglobal": {
					"name": "Calentamiento Global",
					"represents": "El exceso de gases de efecto invernadero.",
					"facts": [
						"El CO₂ proviene sobre todo de quemar combustibles fósiles.",
						"Las energías renovables y la eficiencia reducen las emisiones.",
						"Las acciones individuales, sumadas a las colectivas, marcan la diferencia."
					]
				}
			}
		}
	]
