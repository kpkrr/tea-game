# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Four guest slots, spawn flow, patience, strikes (guest-ai-patience.md).
## Guest = {uid, slot, recipe, t_spawn, patience_max, state, x}.
## Tick: serves (already done during the barista step) -> walkouts -> end check -> spawn.

signal guest_spawned(slot: int)
signal served(recipe_id: StringName, remaining_fraction: float)
signal guest_served(slot: int, guest: Dictionary)
signal guest_left(slot: int, guest: Dictionary)
signal guest_refused(slot: int)
signal target_vanished(slot: int)
signal guests_lost_reached()

enum GState { APPROACHING, WAITING, SERVED, LEAVING }

const DifficultyCurve := preload("difficulty_curve.gd")

var guests: Array = []      # per slot: Dictionary or null
var departing: Array = []   # served / leaving guests walking out
var guests_lost := 0

var _clock: RefCounted
var _book: RefCounted
var _brewing: RefCounted
var _cfg: Resource
var _diff: Resource
var _kitchen: Resource
var _rng_tier: RefCounted
var _rng_recipe: RefCounted
var _next_spawn_t := 0.0
var _deferred := false
var _ended := false
var _uid := 0


func _init(clock: RefCounted, book: RefCounted, brewing: RefCounted, guest_cfg: Resource,
		difficulty_cfg: Resource, kitchen_cfg: Resource) -> void:
	_clock = clock
	_book = book
	_brewing = brewing
	_cfg = guest_cfg
	_diff = difficulty_cfg
	_kitchen = kitchen_cfg
	guests.resize(guest_cfg.guest_slot_count)


## New match: everything cleared, the first guest spawns this tick (t = 0).
func reset(rng_tier: RefCounted, rng_recipe: RefCounted) -> void:
	_rng_tier = rng_tier
	_rng_recipe = rng_recipe
	guests.fill(null)
	departing.clear()
	guests_lost = 0
	_deferred = false
	_ended = false
	_spawn(0, _clock.t)
	_next_spawn_t = _clock.t + spawn_interval(_clock.t)


func remaining_fraction(g: Dictionary) -> float:
	return clampf(1.0 - (_clock.t - g.t_spawn) / g.patience_max, 0.0, 1.0)


## "calm" / "warn" / "urgent" by the GDD thresholds.
func patience_level(g: Dictionary) -> StringName:
	var rf := remaining_fraction(g)
	if rf <= _cfg.patience_urgent_threshold:
		return &"urgent"
	if rf <= _cfg.patience_warn_threshold:
		return &"warn"
	return &"calm"


func can_serve(slot: int) -> bool:
	var g: Variant = guests[slot]
	return not _ended and g != null and _brewing.held_match() == g.recipe


## Pre-walk validity of a guest tap.
func is_valid(slot: int) -> bool:
	if guests[slot] == null:
		return false
	if not can_serve(slot):
		guest_refused.emit(slot)
		return false
	return true


## Holding at the serve point: serve now if the cup still matches.
func offer(slot: int) -> int:
	if not can_serve(slot):
		if guests[slot] != null:
			guest_refused.emit(slot)
		return 2  # REFUSE
	var g: Dictionary = guests[slot]
	var rf := remaining_fraction(g)
	_brewing.consume_held_cup()
	g.state = GState.SERVED
	guests[slot] = null
	departing.append(g)
	served.emit(g.recipe, rf)
	guest_served.emit(slot, g)
	return 0  # EXECUTE


func step(dt: float) -> void:
	if _ended:
		return
	_walk(dt)
	# (b) walkouts, in slot order
	for i in guests.size():
		var g: Variant = guests[i]
		if g != null and remaining_fraction(g) <= 0.0:
			g.state = GState.LEAVING
			guests[i] = null
			departing.append(g)
			guests_lost = mini(guests_lost + 1, _cfg.max_guests_lost)
			guest_left.emit(i, g)
			target_vanished.emit(i)
	# (c) end check
	if guests_lost >= _cfg.max_guests_lost:
		_ended = true
		guests_lost_reached.emit()
		return
	# (d) spawn: a fired timer with no free slot becomes one deferred spawn
	if _deferred or _clock.t >= _next_spawn_t:
		var free := guests.find(null)
		if free < 0:
			_deferred = true
		else:
			_deferred = false
			_spawn(free, _clock.t)
			_next_spawn_t = _clock.t + spawn_interval(_clock.t)


func spawn_interval(t: float) -> float:
	var rate := DifficultyCurve.guests_per_minute(_diff, t)
	if t < _cfg.onboarding_duration:
		rate *= _cfg.onboarding_factor
	return 60.0 / rate


func pick_recipe(t: float) -> StringName:
	var tier := &"simple"
	if t >= _cfg.onboarding_duration:
		var p_complex := DifficultyCurve.complex_order_share(_diff, t)
		var p_medium: float = (1.0 - p_complex) * _cfg.medium_share_of_remaining
		var p_simple := 1.0 - p_complex - p_medium
		var r: float = _rng_tier.randf()
		tier = &"simple" if r < p_simple else (&"medium" if r < p_simple + p_medium else &"complex")
	var ids: Array = _book.recipes_by_tier(tier)
	return ids[_rng_recipe.randi_range(0, ids.size() - 1)]


func _spawn(slot: int, t: float) -> void:
	_uid += 1
	guests[slot] = {
		"uid": _uid, "slot": slot, "recipe": pick_recipe(t), "t_spawn": t,
		"patience_max": DifficultyCurve.patience_max(_diff, t),
		"state": GState.APPROACHING, "x": _kitchen.guest_spawn_x,
	}
	guest_spawned.emit(slot)


func _walk(dt: float) -> void:
	var v: float = _cfg.guest_walk_speed * dt
	for g: Variant in guests:
		if g != null and g.state == GState.APPROACHING:
			var to: float = _kitchen.guest_slot_x[g.slot]
			g.x = move_toward(g.x, to, v)
			if is_equal_approx(g.x, to):
				g.state = GState.WAITING
	for i in range(departing.size() - 1, -1, -1):
		var g: Dictionary = departing[i]
		g.x = move_toward(g.x, _kitchen.guest_exit_x, v * (1.3 if g.state == GState.SERVED else 1.0))
		if is_equal_approx(g.x, _kitchen.guest_exit_x):
			departing.remove_at(i)
