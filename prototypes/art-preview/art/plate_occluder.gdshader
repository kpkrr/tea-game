// Re-draws the painted plate under 3D blockers so they hide sprites but stay invisible.
// UI s7: the station-sign decal (drawn right over the plate) is repainted too.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D plate : source_color, filter_linear_mipmap;
uniform vec4 plate_rect = vec4(0.0, 0.0, 1.0, 1.0); // plate area in SCREEN_UV space
uniform sampler2D decal : source_color, filter_nearest;
uniform vec4 decal_rect = vec4(0.0, 0.0, 0.0, 0.0); // decal area in SCREEN_UV space
uniform float decal_on = 0.0;

void fragment() {
	vec3 c = texture(plate, (SCREEN_UV - plate_rect.xy) / plate_rect.zw).rgb;
	vec2 duv = (SCREEN_UV - decal_rect.xy) / max(decal_rect.zw, vec2(1e-6));
	if (decal_on > 0.5 && all(greaterThanEqual(duv, vec2(0.0))) && all(lessThan(duv, vec2(1.0)))) {
		vec4 d = texture(decal, duv);
		c = mix(c, d.rgb, d.a);
	}
	ALBEDO = c;
}
