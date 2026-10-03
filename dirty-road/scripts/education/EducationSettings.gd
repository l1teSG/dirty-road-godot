class_name EducationSettings
extends Node

# EducationSettings
# Nodo configurable desde el Inspector.
# Debe colocarse en la escena principal del juego.
# EducationManager lo encuentra mediante el grupo
# "education_settings".

@export_group("General")

@export var debug_log: bool = true
@export var stage_caption_include_theme: bool = true

@export_group("Popup - Posición")

@export var toast_on_top: bool = false

@export_range(0.0, 400.0, 1.0)
var top_margin: float = 40.0

@export_range(0.0, 400.0, 1.0)
var bottom_margin: float = 70.0


@export_group("Popup - Estilo")

@export_enum("Tarjeta:0", "Subtítulos:1")
var style_wave_break: int = 1

@export_enum("Tarjeta:0", "Subtítulos:1")
var style_death: int = 0

@export_enum("Tarjeta:0", "Subtítulos:1")
var style_enemy_card: int = 0

@export_enum("Tarjeta:0", "Subtítulos:1")
var style_survival: int = 1


@export_group("Colores por variante")

@export var color_wave_break: Color = Color("00ff7f")
@export var color_death: Color = Color("d81b60")
@export var color_enemy_card: Color = Color("00ff7f")
@export var color_survival: Color = Color("00ff7f")


@export_group("Tarjetas - Apariencia")

@export var card_background_color: Color = Color("1e3a24")
@export var card_text_color: Color = Color("e8fff1")
@export var card_title_color: Color = Color("00ff7f")
@export var card_stage_color: Color = Color("00ff7f")
@export var card_border_color: Color = Color("00ff7f")

@export var card_use_variant_color: bool = false

@export_range(0, 8, 1)
var card_border_width: int = 2

@export_range(0, 32, 1)
var card_corner_radius: int = 10

@export_range(0, 24, 1)
var card_shadow_size: int = 8


@export_group("Tarjetas - Tamaño")

@export_range(0.20, 0.90, 0.01)
var card_width_ratio: float = 0.45

@export_range(200.0, 1600.0, 1.0)
var card_max_width: float = 640.0

@export_range(0.10, 0.80, 0.01)
var card_max_height_ratio: float = 0.40

@export var card_padding: Vector2 = Vector2(18.0, 12.0)


@export_group("Tarjetas - Texto")

@export_range(12, 72, 1)
var card_title_font_size: int = 22

@export_range(12, 72, 1)
var card_body_font_size: int = 18

@export_range(10, 48, 1)
var card_stage_font_size: int = 14

@export var card_show_stage: bool = true
@export var card_show_title: bool = true
@export var card_show_body: bool = true

@export_range(0, 30, 1)
var card_max_body_lines: int = 0


@export_group("Subtítulos - Apariencia")

@export_range(12, 72, 1)
var subtitles_font_size: int = 28

@export_range(0.30, 0.95, 0.01)
var subtitles_width_ratio: float = 0.70

@export_range(200.0, 2000.0, 1.0)
var subtitles_max_width: float = 1100.0

@export_range(0.10, 0.80, 0.01)
var subtitles_max_height_ratio: float = 0.30

@export var subtitles_text_color: Color = Color.WHITE
@export var subtitles_outline_color: Color = Color.BLACK

@export_range(0, 16, 1)
var subtitles_outline_size: int = 6

@export var subtitles_background_enabled: bool = false
@export var subtitles_background_color: Color = Color(0, 0, 0, 0.55)


@export_group("Subtítulos - Contenido")

@export var subtitles_show_stage: bool = false
@export var subtitles_show_title: bool = false
@export var subtitles_show_default_title: bool = false
@export var subtitles_show_body: bool = true

@export_range(0, 30, 1)
var subtitles_max_lines: int = 0

@export_range(0, 3000, 1)
var subtitles_max_characters: int = 0


@export_group("Comportamiento")

@export var survival_interval: float = 120.0
@export_range(0.0, 1.0) var stage_mix_ratio: float = 0.4
@export var enemy_repeat_waves: int = 3
@export var message_duration: float = 4.0
@export var enemy_duration: float = 5.5

@export_group("Insignia circular")

## Activa o desactiva el círculo con el icono del tipo de mensaje
@export var badge_enabled: bool = true
## Diámetro del círculo en píxeles
@export var badge_size: float = 54.0
## Grosor del borde del círculo
@export var badge_border_width: float = 2.0
## Fondo del círculo
@export var badge_background_color: Color = Color(0.012, 0.09, 0.05, 0.95)
## Color del borde e icono (si no se usa el color de la variante)
@export var badge_border_color: Color = Color(0.0, 1.0, 0.5)
## Usar el color de la variante para el borde y el icono
@export var badge_use_variant_color: bool = true
## Mostrar la insignia también en los subtítulos
@export var badge_show_on_subtitles: bool = false
## Escala de la insignia cuando es un subtítulo
@export var badge_subtitle_scale: float = 0.72

## Icono por tipo: "hoja", "calavera", "alerta", "bomba",
## "nada" o cualquier texto (ej. "B", "?", "T")
@export var icon_wave_break: String = "hoja"
@export var icon_death: String = "calavera"
@export var icon_enemy_card: String = "alerta"
@export var icon_survival: String = "bomba"

@export_group("Temas por tipo (tarjetas)")

## Si se desactiva, las tarjetas usan los colores globales de las secciones de arriba
@export var usar_temas_por_tipo: bool = true

## Esquinas del chip del título
@export var chip_radio: float = 10.0
## Grosor del contorno del chip
@export var chip_borde_grosor: float = 2.0
## Espacio interior del chip
@export var chip_pad_x: float = 10.0
@export var chip_pad_y: float = 4.0

# ── Dato Ambiental (verde neón) ──
@export var tema_wave_chip_fondo: Color = Color("#00ff7f")
@export var tema_wave_chip_texto: Color = Color("#071a0e")
@export var tema_wave_chip_borde: Color = Color("#00ff7f")
@export var tema_wave_fondo: Color = Color("#0d2015")
@export var tema_wave_borde: Color = Color("#00ff7f")
@export var tema_wave_texto: Color = Color("#e8f5e9")

# ── Muerte / Reflexión (rojo apagado) ──
@export var tema_death_chip_fondo: Color = Color("#ff5252")
@export var tema_death_chip_texto: Color = Color("#1c0808")
@export var tema_death_chip_borde: Color = Color("#ff5252")
@export var tema_death_fondo: Color = Color("#241010")
@export var tema_death_borde: Color = Color("#ff5252")
@export var tema_death_texto: Color = Color("#f7e9e9")

# ── Enemigo (magenta rojizo) ──
@export var tema_enemy_chip_fondo: Color = Color("#d81b60")
@export var tema_enemy_chip_texto: Color = Color("#ffffff")
@export var tema_enemy_chip_borde: Color = Color("#ff5c8a")
@export var tema_enemy_fondo: Color = Color("#26070f")
@export var tema_enemy_borde: Color = Color("#d81b60")
@export var tema_enemy_texto: Color = Color("#ffe6ee")

# ── ¿Sabías qué? (cian) ──
@export var tema_survival_chip_fondo: Color = Color("#00e5d0")
@export var tema_survival_chip_texto: Color = Color("#06231f")
@export var tema_survival_chip_borde: Color = Color("#00e5d0")
@export var tema_survival_fondo: Color = Color("#06231f")
@export var tema_survival_borde: Color = Color("#00e5d0")
@export var tema_survival_texto: Color = Color("#e0fbf7")
