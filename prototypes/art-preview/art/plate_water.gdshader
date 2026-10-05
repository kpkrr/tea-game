// Plate with animated glints on the turquoise water (detected by colour).
shader_type canvas_item;


float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float water = smoothstep(0.08, 0.2, c.g - c.r) * smoothstep(0.02, 0.1, c.b - c.r * 0.9);
	vec2 p = UV * vec2(22.0, 40.0);
	float n = noise(p + vec2(TIME * 0.35, TIME * 0.2)) * noise(p * 1.7 - vec2(TIME * 0.25, -TIME * 0.3));
	float glint = smoothstep(0.5, 0.75, n);
	c.rgb += water * glint * vec3(0.12, 0.16, 0.15);
	c.a *= smoothstep(0.0, 0.06, UV.y) * smoothstep(0.0, 0.05, UV.x) * smoothstep(1.0, 0.95, UV.x);   // fade into the blurred fill
	COLOR = c;
}
