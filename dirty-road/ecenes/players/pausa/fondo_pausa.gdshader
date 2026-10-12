shader_type canvas_item;

// Overlay sutil para la pausa: líneas diagonales en movimiento + viñeta verde.
uniform vec4 color_linea : source_color = vec4(0.6, 1.0, 0.2, 1.0);
uniform float velocidad : hint_range(0.0, 1.0) = 0.12;
uniform float intensidad : hint_range(0.0, 1.0) = 0.14;

void fragment() {
	vec2 uv = UV;
	float t = TIME * velocidad;

	// Líneas diagonales que se desplazan.
	float lineas = sin((uv.x + uv.y) * 34.0 - t * 18.0) * 0.5 + 0.5;
	lineas = smoothstep(0.86, 1.0, lineas);

	// Viñeta: refuerza los bordes.
	vec2 c = uv - 0.5;
	float vig = smoothstep(0.25, 0.85, length(c));

	float a = (lineas * 0.55 + vig * 0.45) * intensidad;
	COLOR = vec4(color_linea.rgb, a);
}
