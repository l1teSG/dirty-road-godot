shader_type canvas_item;

// Fondo animado del menú: verde oscuro que respira, con vetas y brillos.
uniform vec4 color_a : source_color = vec4(0.0196, 0.0627, 0.0431, 1.0);
uniform vec4 color_b : source_color = vec4(0.0588, 0.1647, 0.1020, 1.0);
uniform vec4 color_brillo : source_color = vec4(0.6, 1.0, 0.2, 1.0);
uniform float velocidad : hint_range(0.0, 1.0) = 0.06;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * velocidad;

	// Dos capas de ruido en movimiento -> manchas orgánicas.
	float n1 = noise(uv * 3.0 + vec2(t, t * 0.7));
	float n2 = noise(uv * 6.0 - vec2(t * 0.5, t * 1.1));
	float m = clamp(n1 * 0.65 + n2 * 0.35, 0.0, 1.0);

	vec3 col = mix(color_a.rgb, color_b.rgb, m);

	// Vetas diagonales suaves en movimiento.
	float veta = sin((uv.x + uv.y) * 8.0 - t * 6.0) * 0.5 + 0.5;
	col += color_b.rgb * veta * 0.25;

	// Brillo verdoso en las crestas del ruido.
	float brillo = smoothstep(0.78, 1.0, m);
	col += color_brillo.rgb * brillo * 0.18;

	COLOR = vec4(col, 1.0);
}
