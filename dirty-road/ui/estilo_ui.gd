class_name EstiloUI
extends RefCounted

## ══════════════════════════════════════════════════════════
##  Estilo de UI compartido (paleta, tipografía y animaciones).
##  El tema base está en themes/mainTheme.tres; este helper añade
##  el acabado dinámico (hover con escala, títulos con glow).
## ══════════════════════════════════════════════════════════

const NEON := Color("99ff33")
const VERDE_CLARO := Color("c9ffa0")
const FONDO := Color("0a1710")
const PANEL := Color("10241a")
const TEXTO := Color("e8fff1")
const APAGADO := Color("a8c0b4")
const PELIGRO := Color("ff4d6d")

const F_BOLD := preload("res://themes/Chakra_Petch/ChakraPetch-Bold.ttf")
const F_SEMI := preload("res://themes/Chakra_Petch/ChakraPetch-SemiBold.ttf")


## Hover con escala suave para cualquier Control (p. ej. un botón).
static func hover_escala(control: Control, factor: float = 1.06) -> void:
	control.mouse_entered.connect(func() -> void:
		control.pivot_offset = control.size * 0.5
		control.z_index = 1
		var tw := control.create_tween()
		tw.tween_property(control, "scale", Vector2.ONE * factor, 0.12)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	control.mouse_exited.connect(func() -> void:
		control.z_index = 0
		var tw := control.create_tween()
		tw.tween_property(control, "scale", Vector2.ONE, 0.12)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)


## Aplica hover con escala a todos los botones dentro de 'root'.
static func aplicar_hover_a(root: Node, factor: float = 1.06) -> void:
	for b in root.find_children("*", "Button", true, false):
		hover_escala(b, factor)


## Da formato de TÍTULO a un Label: Chakra Petch Bold, mayúsculas y glow.
static func titulo(label: Label, tam: int = 100, color: Color = NEON) -> void:
	label.add_theme_font_override("font", F_BOLD)
	label.add_theme_font_size_override("font_size", tam)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("outline_size", 6)
	label.uppercase = true


## Da formato a un botón de menú: Chakra Petch SemiBold + tamaño + hover.
static func boton_menu(boton: Button, tam: int = 40, hover: bool = true) -> void:
	boton.add_theme_font_override("font", F_SEMI)
	boton.add_theme_font_size_override("font_size", tam)
	if hover:
		hover_escala(boton)
