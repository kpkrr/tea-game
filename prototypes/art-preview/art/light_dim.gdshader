// Multiplies the plate under a light mask toward dark embers (flicker "low" side).
shader_type canvas_item;
render_mode blend_mul;

uniform vec3 dim_color = vec3(0.42, 0.26, 0.24);
uniform float dim = 0.0;

void fragment() {
	float m = texture(TEXTURE, UV).a;
	COLOR = vec4(mix(vec3(1.0), dim_color, m * dim), 1.0);
}
