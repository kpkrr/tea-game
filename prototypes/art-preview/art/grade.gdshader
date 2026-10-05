// Look grade over the frame (characters included, HUD excluded).
// Recipe (cozy stylized game look): gentle filmic S-curve with lifted blacks,
// split toning — cool teal shadows / soft golden highlights (complementary pair
// for depth), vibrance in the midtones only (shadows and extreme highlights are
// desaturated to avoid muddy or neon patches), soft bloom from lanterns and fire,
// soft blurred vignette.
// Evening (owner pick "B"): outside the light mask the frame sinks into cool dusk,
// the kitchen and the lantern/hearth pools stay warm — the eye lands on the work zone.
// Kitchen focus (owner pick, rhombus C + B2): outside art/kitchen_mask.png the whole frame —
// plate, desktop backdrop and the characters walking there — is blurred and dimmed.
// One look on every screen: vignettes live in the reference frame (`ref_rect`, the
// plate area a 16:10 desktop window shows), so a phone sees a crop of the same image.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float exposure = 1.02;
uniform float contrast = 0.06;        // S-curve strength
uniform float black_lift = 0.02;
uniform float vibrance = 0.1;
uniform vec3 shadow_tint = vec3(0.92, 1.0, 1.1);     // cool teal-blue
uniform vec3 highlight_tint = vec3(1.05, 1.01, 0.93);  // soft gold
uniform float bloom = 0.28;
uniform float edge_blur = 0.6;
uniform sampler2D light_mask : filter_linear;   // art/light_mask.png, plate space (tools/make_light_mask.py)
uniform vec4 plate_rect = vec4(0.0, 0.0, 1.0, 1.0); // plate area in SCREEN_UV space
uniform float evening = 1.0;                       // 0 = off
uniform vec3 dusk_tint = vec3(0.36, 0.42, 0.66);
uniform float dusk_sat = 0.55;
uniform vec3 lit_tint = vec3(1.06, 1.0, 0.9);
uniform float light_gain = 1.0;                    // lantern breathing, set per frame
uniform float dusk_vignette = 0.45;
uniform vec3 haze_color = vec3(0.96, 0.86, 0.82);  // morning mist
uniform float haze = 0.0;                          // outside the lit kitchen
uniform sampler2D kitchen_mask : filter_linear;  // art/kitchen_mask.png: tight cut, always fully lit
uniform float bg_blur = 1.3;      // mip levels at a 1080 px tall screen (scaled to the real height)
uniform float bg_sat = 0.8;
uniform float bg_bright = 0.82;
uniform vec4 ref_rect = vec4(0.0, 0.0, 1.0, 1.0);  // reference frame in plate UV

vec3 soft5(vec2 uv, float lod, vec2 px) {
	vec2 o = exp2(lod) * px * 0.7;
	return (textureLod(screen, uv, lod).rgb * 2.0
		+ textureLod(screen, uv + vec2(o.x, o.y), lod).rgb + textureLod(screen, uv + vec2(-o.x, o.y), lod).rgb
		+ textureLod(screen, uv + vec2(o.x, -o.y), lod).rgb + textureLod(screen, uv - o, lod).rgb) / 6.0;
}

vec3 bright(vec2 uv, float lod) {
	vec3 c = textureLod(screen, uv, lod).rgb;
	return max(c - 0.8, 0.0) * 3.0;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 puv = (uv - plate_rect.xy) / plate_rect.zw;
	vec2 ruv = (puv - ref_rect.xy) / ref_rect.zw;      // position in the reference frame
	float vig = smoothstep(0.42, 1.05, length((ruv - vec2(0.5, 0.5)) * vec2(1.3, 0.95)));
	vec3 sharp = texture(screen, uv).rgb;
	vec2 pin = clamp(puv, 0.0, 1.0);
	float in_plate = step(0.0, puv.x) * step(puv.x, 1.0) * step(0.0, puv.y) * step(puv.y, 1.0);
	float focus = texture(kitchen_mask, pin).r * in_plate;
	float lod = bg_blur + log2(max(1.0 / SCREEN_PIXEL_SIZE.y, 1.0) / 1080.0);
	vec3 bg = soft5(uv, max(lod, 0.0), SCREEN_PIXEL_SIZE);
	bg = mix(vec3(dot(bg, vec3(0.299, 0.587, 0.114))), bg, bg_sat) * bg_bright;
	sharp = mix(bg, sharp, focus);
	vec3 soft = textureLod(screen, uv, 2.0).rgb * 0.5 + textureLod(screen, uv, 3.0).rgb * 0.5;
	vec3 c = mix(sharp, soft, clamp(vig * 1.3, 0.0, 1.0) * edge_blur) * exposure;
	c += (bright(uv, 3.0) * 0.5 + bright(uv, 4.5) * 0.35 + bright(uv, 6.0) * 0.25) * vec3(1.0, 0.82, 0.6) * bloom;
	// Filmic S-curve around mid grey, then lift the blacks.
	c = clamp(c, 0.0, 1.0);
	c = mix(c, c * c * (3.0 - 2.0 * c), contrast);
	c = black_lift + c * (1.0 - black_lift);
	// Split toning by luminance.
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c *= mix(shadow_tint, vec3(1.0), smoothstep(0.05, 0.5, l));
	c *= mix(vec3(1.0), highlight_tint, smoothstep(0.55, 0.95, l));
	// Vibrance: boost low-saturation midtones, leave shadows/highlights calmer.
	l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	float sat = max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b);
	float mid = smoothstep(0.08, 0.35, l) * (1.0 - smoothstep(0.75, 0.98, l));
	c = mix(vec3(l), c, 1.0 + vibrance * mid * (1.0 - sat));
	c = mix(c, c * vec3(0.66, 0.67, 0.74), vig * 0.35);
	// Evening: mask lookup in plate space; outside the plate it is dusk.
	float inside = step(0.0, puv.x) * step(puv.x, 1.0) * step(0.0, puv.y) * step(puv.y, 1.0);
	float lit = clamp(texture(light_mask, clamp(puv, 0.0, 1.0)).r * inside * light_gain, 0.0, 1.0);
	lit = max(lit, texture(kitchen_mask, clamp(puv, 0.0, 1.0)).r * inside);
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 dusk = mix(vec3(g), c, dusk_sat) * dusk_tint;
	// The kitchen keeps its daytime brightness and contrast: the phase only shifts its hue.
	vec3 hue = lit_tint / dot(lit_tint, vec3(0.299, 0.587, 0.114));
	vec3 eve = mix(dusk, c * hue, lit);
	vec2 d = (ruv - vec2(0.5, 0.55)) / vec2(0.55, 0.6);
	eve *= 1.0 - dusk_vignette * clamp(dot(d, d) - 0.35, 0.0, 1.0);
	c = mix(c, eve, evening);
	c = mix(c, haze_color, haze * (1.0 - lit));   // mist only outside the kitchen
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
