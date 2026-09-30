# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends GdUnitTestSuite
## Logic checks for the slice's pure modules against the GDD numbers.
## No scene, no disk writes: config is the shipped .tres, saves use MemoryBackend.

const R := "res://prototypes/tea-rush-vertical-slice/"
const ConfigLoader := preload(R + "src/foundation/config/config_loader.gd")
const GameClock := preload(R + "src/foundation/game_clock.gd")
const UtcClock := preload(R + "src/foundation/utc_clock.gd")
const Rng := preload(R + "src/foundation/rng.gd")
const SaveStore := preload(R + "src/foundation/save_store.gd")
const SaveBackends := preload(R + "src/foundation/save_backends.gd")
const ViewFitMath := preload(R + "src/foundation/view_fit_math.gd")
const KitchenLayout := preload(R + "src/foundation/kitchen_layout.gd")
const RecipeBook := preload(R + "src/core/recipe_book.gd")
const Brewing := preload(R + "src/feature/brewing.gd")
const GuestSim := preload(R + "src/feature/guest_sim.gd")
const DifficultyCurve := preload(R + "src/feature/difficulty_curve.gd")
const Currency := preload(R + "src/feature/currency.gd")
const Till := preload(R + "src/feature/till.gd")
const MatchLifecycle := preload(R + "src/feature/match_lifecycle.gd")

var cfg: Resource


func before_test() -> void:
	var loaded := ConfigLoader.load_config(R + "data/game_config.tres")
	assert_array(loaded.errors).is_empty()
	cfg = loaded.config


func _store() -> RefCounted:
	var s := SaveStore.new()
	s.open(SaveBackends.MemoryBackend.new())
	return s


func test_shipped_config_validates_and_bad_price_is_rejected() -> void:
	var broken: Resource = cfg.duplicate(true)
	broken.recipes.recipes[3].price = 9
	var errors := preload(R + "src/foundation/config/config_validator.gd").validate(broken)
	assert_bool(errors.any(func(e: Dictionary) -> bool: return e.path == "recipes.price")).is_true()


func test_recipe_grammar_prefix_and_match() -> void:
	var book := RecipeBook.new(cfg.recipes)
	assert_bool(book.is_valid_next([], &"cup")).is_true()
	assert_bool(book.is_valid_next([&"cup"], &"water_100")).is_false()
	assert_bool(book.is_valid_next([&"cup", &"leaf_black"], &"water_80")).is_false()
	assert_bool(book.is_valid_next([&"cup", &"leaf_black", &"water_100"], &"lemon")).is_true()
	assert_bool(book.is_valid_next([&"cup", &"iced_tea"], &"lemon")).is_false()
	assert_str(String(book.matches([&"cup", &"leaf_black", &"water_100"]))).is_equal("black_tea")
	assert_str(String(book.matches([&"cup", &"leaf_black"]))).is_equal("")
	assert_int(book.recipe_price(&"green_tea_lemon")).is_equal(7)


func test_difficulty_curve_matches_gdd_table() -> void:
	var d: Resource = cfg.difficulty
	assert_float(DifficultyCurve.guests_per_minute(d, 90.0)).is_equal_approx(15.75, 1e-6)
	assert_float(DifficultyCurve.patience_max(d, 90.0)).is_equal_approx(43.75, 1e-6)
	assert_float(DifficultyCurve.complex_order_share(d, 90.0)).is_equal_approx(0.10, 1e-6)
	assert_float(DifficultyCurve.guests_per_minute(d, 500.0)).is_equal_approx(18.0, 1e-6)
	assert_float(DifficultyCurve.patience_max(d, 180.0)).is_equal_approx(25.0, 1e-6)


func test_score_rounds_half_up() -> void:
	assert_int(Currency.score_for(7, 10, 0.4)).is_equal(98)
	assert_int(Currency.score_for(2, 10, 0.025)).is_equal(21)
	assert_int(Currency.score_for(2, 10, 0.0)).is_equal(20)


func test_new_record_only_when_strictly_greater() -> void:
	var store := _store()
	var cur := Currency.new(RecipeBook.new(cfg.recipes), cfg.currency, store.scope(&"currency"))
	cur.on_match_started()
	cur.on_match_ended()
	assert_bool(cur.is_new_record).is_false()
	cur.on_match_started()
	cur.on_served(&"cold_tea", 1.0)
	cur.on_match_ended()
	assert_bool(cur.is_new_record).is_true()
	assert_int(cur.best_score).is_equal(40)


func test_till_clamps_fills_same_tick_and_resets_once_after_midnight() -> void:
	var utc := UtcClock.new()
	utc.fake_now = 86400 * 100 + 3600 * 20  # day 100, 20:00 UTC
	var till := Till.new(cfg.till, _store().scope(&"till"), utc)
	for i in 35:
		till.on_coins_earned(7)
	assert_int(till.till_amount).is_equal(245)
	var added := []
	till.coins_added.connect(func(n: int, _e: int) -> void: added.append(n))
	till.on_coins_earned(7)
	till.on_coins_earned(5)
	assert_array(added).contains_exactly([5, 0])
	assert_bool(till.is_full).is_true()
	till.on_match_started()
	assert_bool(till.is_full).is_true()  # same day: stays full
	utc.fake_now = 86400 * 103 + 60      # three midnights later
	till.on_match_started()
	assert_int(till.till_amount).is_equal(0)


func test_clock_clamps_and_drops_hidden_time() -> void:
	var clock := GameClock.new(0.25)
	assert_float(clock.advance(1.0)).is_equal(0.25)
	clock.pause()
	assert_float(clock.advance(0.1)).is_equal(0.0)
	clock.resume()
	assert_float(clock.advance(0.1)).is_equal(0.0)  # first frame after resume
	assert_float(clock.advance(0.1)).is_equal_approx(0.1, 1e-6)
	assert_float(clock.t).is_equal_approx(0.35, 1e-6)


func test_lifecycle_user_pause_survives_tab_return() -> void:
	var clock := GameClock.new(0.25)
	var lc := MatchLifecycle.new(clock)
	lc.on_ready_reached()
	lc.apply_pending()
	lc.request_pause()
	lc.on_visibility_changed(false)
	lc.on_visibility_changed(true)
	assert_bool(lc.is_user_paused()).is_true()
	assert_bool(clock.is_running()).is_false()
	lc.request_resume()
	assert_bool(clock.is_running()).is_true()


func test_kettle_wrong_temperature_ruins_cup_and_ready_swap() -> void:
	var layout := KitchenLayout.new(cfg.kitchen, cfg.control)
	var brewing := Brewing.new(layout, RecipeBook.new(cfg.recipes), cfg.brewing)
	assert_int(brewing.offer(&"cups")).is_equal(Brewing.EXECUTE)
	assert_int(brewing.offer(&"leaf_black")).is_equal(Brewing.EXECUTE)
	assert_int(brewing.offer(&"kettle_80")).is_equal(Brewing.EXECUTE)
	assert_bool(brewing.held.ruined).is_true()
	assert_int(brewing.offer(&"lemon")).is_equal(Brewing.REFUSE)
	assert_int(brewing.offer(&"cups")).is_equal(Brewing.EXECUTE)  # ruined cup replaced
	brewing.offer(&"leaf_black")
	brewing.offer(&"kettle_100")
	assert_that(brewing.held).is_null()
	assert_int(brewing.offer(&"kettle_100")).is_equal(Brewing.WAIT)
	brewing.step(3.0)
	assert_int(brewing.offer(&"kettle_100")).is_equal(Brewing.EXECUTE)
	assert_str(String(brewing.held_match())).is_equal("black_tea")


func test_guests_onboarding_spawns_cold_tea_every_4s() -> void:
	var clock := GameClock.new(0.25)
	var book := RecipeBook.new(cfg.recipes)
	var layout := KitchenLayout.new(cfg.kitchen, cfg.control)
	var sim := GuestSim.new(clock, book, Brewing.new(layout, book, cfg.brewing), cfg.guest, cfg.difficulty, cfg.kitchen)
	var spawn_times := []
	sim.guest_spawned.connect(func(_s: int) -> void: spawn_times.append(clock.t))
	sim.reset(Rng.new(1), Rng.new(2))
	while clock.t < 7.0:
		sim.step(clock.advance(0.25))
	assert_int(spawn_times.size()).is_equal(2)
	assert_float(spawn_times[1]).is_equal_approx(4.0, 1e-6)
	for g: Variant in sim.guests:
		if g != null:
			assert_str(String(g.recipe)).is_equal("cold_tea")
	assert_int(sim.guests.find(null)).is_equal(2)  # lowest free slot ids used first


func test_view_fit_mode_a_on_phone_mode_c_on_square() -> void:
	var v: Resource = cfg.view
	var frame := ViewFitMath.project_frame(v.frame_bounds, v.camera_position, v.camera_pitch_deg)
	var phone := ViewFitMath.fit(Vector2(360, 800), Rect2(0, 0, 360, 800), frame, 0.45, 1.0, 0.96, 56)
	assert_bool(phone.reserved).is_false()
	assert_float(phone.kitchen_rect.size.x / 360.0).is_equal_approx(0.96, 1e-4)
	var square := ViewFitMath.fit(Vector2(640, 640), Rect2(0, 0, 640, 640), frame, 0.45, 1.0, 0.96, 56)
	assert_bool(square.reserved).is_true()
	assert_float(square.kitchen_rect.position.y).is_greater_equal(56.0)
