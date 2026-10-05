# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Pure config validation: collects ALL errors, same in debug and release.
## Error = {path: "difficulty.patience_max_end", rule: &"range", message}.

const REQUIRED_RECIPES := 5
const TIERS: Array[StringName] = [&"simple", &"medium", &"complex"]


static func err(path: String, rule: StringName, message: String) -> Dictionary:
	return {"path": path, "rule": rule, "message": message}


static func validate(cfg: Resource) -> Array:
	var errors: Array = []
	for section: String in ["view", "kitchen", "control", "recipes", "brewing", "guest",
			"difficulty", "currency", "till", "hud", "audio"]:
		var sub: Resource = cfg.get(section)
		if sub == null:
			errors.append(err(section, &"missing", "section missing"))
			continue
		_check_sentinels(section, sub, errors)
	if not errors.is_empty():
		return errors
	_check_ranges(cfg, errors)
	_check_difficulty(cfg.difficulty, errors)
	_check_recipes(cfg, errors)
	_check_kitchen(cfg, errors)
	return errors


## Every exported field must differ from its sentinel (NaN, -1, empty).
static func _check_sentinels(section: String, sub: Resource, errors: Array) -> void:
	for prop: Dictionary in sub.get_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var v: Variant = sub.get(prop.name)
		var path := "%s.%s" % [section, prop.name]
		match typeof(v):
			TYPE_FLOAT:
				if is_nan(v) or is_inf(v):
					errors.append(err(path, &"not_finite", "missing or not finite"))
			TYPE_INT:
				if v < 0:
					errors.append(err(path, &"missing", "missing (sentinel -1)"))
			TYPE_VECTOR3:
				if not v.is_finite():
					errors.append(err(path, &"not_finite", "missing or not finite"))
			TYPE_STRING, TYPE_STRING_NAME, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_STRING_ARRAY:
				if v.is_empty():
					errors.append(err(path, &"missing", "empty"))


static func _range(errors: Array, path: String, v: float, lo: float, hi: float) -> void:
	if v < lo or v > hi:
		errors.append(err(path, &"range", "%s outside [%s, %s]" % [v, lo, hi]))


static func _check_ranges(cfg: Resource, errors: Array) -> void:
	var g: Resource = cfg.guest
	if g.guest_slot_count != 4:
		errors.append(err("guest.guest_slot_count", &"range", "must be 4"))
	_range(errors, "guest.max_guests_lost", g.max_guests_lost, 1, 99)
	_range(errors, "guest.onboarding_factor", g.onboarding_factor, 0.0001, 1.0)
	_range(errors, "guest.medium_share_of_remaining", g.medium_share_of_remaining, 0.0, 1.0)
	if not (0.0 < g.patience_urgent_threshold and g.patience_urgent_threshold < g.patience_warn_threshold and g.patience_warn_threshold < 1.0):
		errors.append(err("guest.patience_warn_threshold", &"invariant", "need 0 < urgent < warn < 1"))
	_range(errors, "guest.guest_walk_speed", g.guest_walk_speed, 0.01, 100.0)
	_range(errors, "guest.max_step_delta", g.max_step_delta, 0.001, 0.5)
	_range(errors, "till.till_capacity", cfg.till.till_capacity, 1, 1000000)
	_range(errors, "till.daily_reset_time_utc", cfg.till.daily_reset_time_utc, 0, 23)
	_range(errors, "currency.score_multiplier_base", cfg.currency.score_multiplier_base, 1, 1000)
	_range(errors, "brewing.t_brew_base", cfg.brewing.t_brew_base, 0.1, 60.0)
	_range(errors, "audio.music_lowpass_cutoff_hz", cfg.audio.music_lowpass_cutoff_hz, 20.0, 19999.0)
	_range(errors, "audio.music_lowpass_ramp_s", cfg.audio.music_lowpass_ramp_s, 0.0, 5.0)
	_range(errors, "view.hud_min_strip_dp", cfg.view.hud_min_strip_dp, 1, 160)
	_range(errors, "view.kitchen_fill_target", cfg.view.kitchen_fill_target, cfg.view.playfield_min_fill, 1.0)
	_range(errors, "view.camera_fov_deg", cfg.view.camera_fov_deg, 25.0, 35.0)
	_range(errors, "view.camera_pitch_deg", cfg.view.camera_pitch_deg, 45.0, 60.0)
	_range(errors, "view.camera_yaw_deg", cfg.view.camera_yaw_deg, -30.0, 30.0)
	_range(errors, "view.camera_far_m", cfg.view.camera_far_m, 60.0, 1000.0)
	if cfg.hud.hud_row_height_dp > cfg.view.hud_min_strip_dp:
		errors.append(err("hud.hud_row_height_dp", &"invariant", "must be <= view.hud_min_strip_dp"))
	var c: Resource = cfg.control
	_range(errors, "control.clearance_margin", c.clearance_margin, 0.05, 0.15)
	_range(errors, "control.pick_radius_factor", c.pick_radius_factor, 1.0, 1.5)
	if not is_equal_approx(c.agent_radius, c.work_gap - c.clearance_margin) or c.agent_radius >= c.work_gap:
		errors.append(err("control.agent_radius", &"invariant", "agent_radius = work_gap - clearance_margin"))
	if absf(c.agent_radius / 0.05 - roundf(c.agent_radius / 0.05)) > 1e-6:
		errors.append(err("control.agent_radius", &"invariant", "must be a multiple of 0.05"))


static func _check_difficulty(d: Resource, errors: Array) -> void:
	_range(errors, "difficulty.ramp_duration", d.ramp_duration, 0.001, 3600.0)
	_range(errors, "difficulty.curve_exponent", d.curve_exponent, 1.0, 3.0)
	_range(errors, "difficulty.guests_per_minute_start", d.guests_per_minute_start, 0.001, 600.0)
	_range(errors, "difficulty.patience_max_end", d.patience_max_end, 0.001, 600.0)
	_range(errors, "difficulty.complex_share_start", d.complex_share_start, 0.0, 1.0)
	_range(errors, "difficulty.complex_share_end", d.complex_share_end, 0.0, 1.0)
	if d.guests_per_minute_end < d.guests_per_minute_start:
		errors.append(err("difficulty.guests_per_minute_end", &"direction", "end easier than start"))
	if d.patience_max_end > d.patience_max_start:
		errors.append(err("difficulty.patience_max_end", &"direction", "end easier than start"))
	if d.complex_share_end < d.complex_share_start:
		errors.append(err("difficulty.complex_share_end", &"direction", "end easier than start"))


static func _check_recipes(cfg: Resource, errors: Array) -> void:
	var recipes: Array = cfg.recipes.recipes
	var types: PackedStringArray = cfg.kitchen.station_types
	if recipes.size() != REQUIRED_RECIPES:
		errors.append(err("recipes.recipes", &"range", "exactly %d recipes required" % REQUIRED_RECIPES))
	var seen := {}
	var price_by_tier := {}
	for i in recipes.size():
		var r: Resource = recipes[i]
		var path := "recipes.recipes[%d]" % i
		if r == null or r.recipe_id == &"" or r.price < 1 or r.steps.is_empty():
			errors.append(err(path, &"missing", "recipe incomplete"))
			continue
		if r.steps[0] != &"cup" or r.steps[-1] != &"serve" or r.steps.count(&"serve") != 1:
			errors.append(err(path + ".steps", &"invariant", "must start with cup and end with one serve"))
		for s: StringName in r.steps:
			if s != &"serve" and not types.has(String(s)):
				errors.append(err(path + ".steps", &"invariant", "step %s has no station" % s))
		var key := str(r.steps)
		if key in seen:
			errors.append(err(path + ".steps", &"invariant", "duplicate step list"))
		seen[key] = true
		if not r.tier in TIERS:
			errors.append(err(path + ".tier", &"range", "unknown tier"))
			continue
		price_by_tier.get_or_add(r.tier, []).append(r.price)
	for t: StringName in TIERS:
		if not t in price_by_tier:
			errors.append(err("recipes.recipes", &"invariant", "tier %s empty" % t))
	if errors.is_empty():
		# Two cheap drinks must stay a real alternative to one expensive one.
		var cx: int = price_by_tier[&"complex"].max()
		var sm: int = price_by_tier[&"simple"].min()
		var md: int = price_by_tier[&"medium"].min()
		if cx * 100 > (sm + md) * 115 or cx * 10 > md * 16:
			errors.append(err("recipes.price", &"invariant", "complex price breaks the value invariants"))


static func _check_kitchen(cfg: Resource, errors: Array) -> void:
	var k: Resource = cfg.kitchen
	if k.guest_slot_x.size() != cfg.guest.guest_slot_count:
		errors.append(err("kitchen.guest_slot_x", &"invariant", "must match guest.guest_slot_count"))
	var boxes: Array = []  # [path, Rect2]
	var ids := {}
	var placed := {}
	var slots := 0
	var id_re := RegEx.create_from_string("^[a-z0-9_]+$")
	for i in k.stations.size():
		var s: Dictionary = k.stations[i]
		var path := "kitchen.stations[%d]" % i
		if not (s.has("id") and s.has("type") and s.has("pos") and s.has("size") and s.has("side") and s.has("top")):
			errors.append(err(path, &"missing", "station needs id/type/pos/size/side/top"))
			continue
		if id_re.search(s.id) == null or s.id in ids:
			errors.append(err(path + ".id", &"invariant", "id must be unique [a-z0-9_]+"))
		ids[s.id] = true
		if s.type == "slot":
			slots += 1
		elif s.type != "trash":
			placed[s.type] = true
		boxes.append([path, Rect2(s.pos - s.size / 2.0, s.size)])
	for i in k.walls.size():
		boxes.append(["kitchen.walls[%d]" % i, Rect2(k.walls[i].pos - k.walls[i].size / 2.0, k.walls[i].size)])
	if slots != 7:
		errors.append(err("kitchen.stations", &"invariant", "exactly 7 slots required, got %d" % slots))
	for t: String in k.station_types:
		if not t in placed:
			errors.append(err("kitchen.station_types", &"invariant", "type %s has no station" % t))
	for t: String in placed:
		if not k.station_types.has(t):
			errors.append(err("kitchen.stations", &"invariant", "station type %s not declared" % t))
	for a in boxes.size():
		if not k.nav_rect.grow(0.001).encloses(boxes[a][1]):
			errors.append(err(boxes[a][0], &"range", "footprint outside nav_rect"))
		for b in range(a + 1, boxes.size()):
			if boxes[a][1].grow(-0.001).intersects(boxes[b][1].grow(-0.001)):
				errors.append(err(boxes[a][0], &"invariant", "overlaps " + boxes[b][0]))
