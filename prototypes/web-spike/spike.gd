# PROTOTYPE — throwaway. Web spike for ADR-0001/0002/0003/0005/0006/0007.
# A guided on-device checklist: measures boot, rendering, input, visibility,
# persistence and navigation on a real phone and POSTs results to server.py.
# Not production code — do not copy into src/.
extends Node3D

const PITCH_DEG := 39.3
const CAM_POS := Vector3(0, 9, 8.6)
const CAM_TARGET := Vector3(0, 0, -2.4)
const FRAME_MIN := Vector3(-4.05, 0.0, -7.55)   # world AABB that must stay visible
const FRAME_MAX := Vector3(4.05, 1.8, 3.9)
const FILL_TARGET := 0.96
const ASPECT_MIN := 0.45
const ASPECT_MAX := 1.0
const PIXEL_BUDGET := 1500000.0
const SCALE_MIN := 0.6
const CENSUS := 75
const SPAWN := Vector3(0, 0, 3.0)
const SAVE_KEY := "tea_rush.spike"
const TOP_RESERVE_DP := 170.0      # instruction panel strip (stand-in for the HUD strip)
# Upright sprites (no backward lean into geometry behind them), stretched to
# undo the camera's foreshortening: on screen they look camera-facing.
var UPRIGHT_STRETCH := 1.0 / cos(deg_to_rad(PITCH_DEG))

const STATIONS := [
	{"id": "cups", "pos": Vector3(-2.5, 0, -7.0), "side": "back", "color": Color(0.95, 0.95, 0.95)},
	{"id": "green_leaf", "pos": Vector3(0.0, 0, -7.0), "side": "back", "color": Color(0.3, 0.7, 0.3)},
	{"id": "black_leaf", "pos": Vector3(2.5, 0, -7.0), "side": "back", "color": Color(0.7, 0.4, 0.15)},
	{"id": "kettle100", "pos": Vector3(-3.5, 0, -4.25), "side": "left", "size": Vector2(1.0, 1.5), "color": Color(0.9, 0.3, 0.3)},
	{"id": "slot_left", "pos": Vector3(-3.5, 0, -1.75), "side": "left", "size": Vector2(1.0, 1.5), "color": Color(0.4, 0.28, 0.2)},
	{"id": "trash", "pos": Vector3(-3.5, 0, 0.75), "side": "left", "size": Vector2(1.0, 1.5), "color": Color(0.4, 0.4, 0.4)},
	{"id": "kettle80", "pos": Vector3(3.5, 0, -4.25), "side": "right", "size": Vector2(1.0, 1.5), "color": Color(0.3, 0.5, 0.95)},
	{"id": "slot_right", "pos": Vector3(3.5, 0, -1.75), "side": "right", "size": Vector2(1.0, 1.5), "color": Color(0.4, 0.28, 0.2)},
	{"id": "iced_tea", "pos": Vector3(-0.5, 0, -4.5), "side": "island_left", "color": Color(0.6, 0.35, 0.85)},
	{"id": "slot_island_l1", "pos": Vector3(-0.5, 0, -3.5), "side": "island_left", "color": Color(0.4, 0.28, 0.2)},
	{"id": "slot_island_l2", "pos": Vector3(-0.5, 0, -2.5), "side": "island_left", "color": Color(0.4, 0.28, 0.2)},
	{"id": "slot_island_l3", "pos": Vector3(-0.5, 0, -1.5), "side": "island_left", "color": Color(0.4, 0.28, 0.2)},
	{"id": "slot_island_r1", "pos": Vector3(0.5, 0, -4.5), "side": "island_right", "color": Color(0.4, 0.28, 0.2)},
	{"id": "slot_island_r2", "pos": Vector3(0.5, 0, -3.5), "side": "island_right", "color": Color(0.4, 0.28, 0.2)},
	{"id": "lemon", "pos": Vector3(0.5, 0, -1.5), "side": "island_right", "color": Color(0.95, 0.85, 0.25)},
]
const WALLS := [
	{"pos": Vector3(-3.5, 0, -7.0), "size": Vector2(1.0, 1.0)},
	{"pos": Vector3(-1.25, 0, -7.0), "size": Vector2(1.5, 1.0)},
	{"pos": Vector3(1.25, 0, -7.0), "size": Vector2(1.5, 1.0)},
	{"pos": Vector3(3.5, 0, -7.0), "size": Vector2(1.0, 1.0)},
	{"pos": Vector3(-3.5, 0, -5.75), "size": Vector2(1.0, 1.5)},
	{"pos": Vector3(-3.5, 0, -3.0), "size": Vector2(1.0, 1.0)},
	{"pos": Vector3(-3.5, 0, -0.5), "size": Vector2(1.0, 1.0)},
	{"pos": Vector3(-3.5, 0, 1.75), "size": Vector2(1.0, 0.5)},
	{"pos": Vector3(3.5, 0, -5.75), "size": Vector2(1.0, 1.5)},
	{"pos": Vector3(3.5, 0, -3.0), "size": Vector2(1.0, 1.0)},
	{"pos": Vector3(3.5, 0, 0.5), "size": Vector2(1.0, 3.0)},
	{"pos": Vector3(0.5, 0, -2.5), "size": Vector2(1.0, 1.0)},
]
const GUEST_X := [-2.4, -0.8, 0.8, 2.4]
const GUEST_Z := 3.2

enum Step { BOOT, SORTING, PRICE, PERF, TAPS, BACKGROUND, REOPEN, DONE }
const MODES := ["prepass", "discard", "blend"]

var _web := OS.has_feature("web")
var _js: JavaScriptObject
var _vis_cb: JavaScriptObject          # must live as long as the app (ADR-0001)
var _session := ""
var _step := Step.BOOT
var _results := {}

var _camera: Camera3D
var _sprites: Array[Sprite3D] = []     # world sprites whose alpha mode is switched
var _census_nodes: Array[Node3D] = []
var _price_label: Label3D
var _marker: Sprite3D
var _tex_cache := {}

var _ui_title: Label
var _ui_text: Label
var _ui_buttons: HBoxContainer
var _ui_status: Label

# Navigation (ADR-0006 flow)
var _map := RID()
var _region := RID()
var _nav_ready := false
var _nav_frames := 0
var _boot_prewarm_frames := -1

# Frame-level measurements
var _in_process := false
var _frames := 0
var _hidden_since_frame := -1
var _hide_t := 0.0
var _visible := true
var _resume_pending := false
var _vis_events: Array = []
var _perf_phases: Array = []
var _perf_idx := -1
var _perf_t := 0.0
var _perf_deltas: PackedFloat32Array = PackedFloat32Array()
var _perf_calls := 0
var _mode_idx := 0
var _sort_votes := {}
var _tap_log: Array = []
var _raw_events := {"emulated_mouse": 0, "mouse": 0, "touch": 0}


func _ready() -> void:
	randomize()
	if _web:
		_js = JavaScriptBridge.get_interface("spike")
		_vis_cb = JavaScriptBridge.create_callback(_on_js_visibility)
		_js.onVis = _vis_cb
	_session = _load_session()
	_results["boot_ready_start_ms"] = _now_ms()
	_build_ui()
	_build_world()
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)
	_bake_navigation()
	_set_ui("Загрузка…", "Готовлю кухню и замеряю запуск.", [])


func _process(delta: float) -> void:
	_in_process = true
	_frames += 1
	_debug_shot()
	if _resume_pending:
		_resume_pending = false
		var hidden_frames := _frames - 1 - _hidden_since_frame
		_record_vis("first_frame_after_return", {"real_delta_s": delta, "frames_while_hidden": hidden_frames})
	if not _nav_ready:
		_poll_navigation()
	elif _boot_prewarm_frames >= 0:
		_boot_prewarm_frames += 1
		if _boot_prewarm_frames >= 2:
			_boot_prewarm_frames = -1
			_on_boot_complete()
	if _step == Step.PERF:
		_perf_tick(delta)
	_in_process = false


# ---------------------------------------------------------------- boot

func _on_boot_complete() -> void:
	var ready_ms := _now_ms()
	_results["boot_ready_ms"] = ready_ms
	var reopen: Variant = _read_save()
	var device: Variant = _eval_json("spike.device()")
	var resources: Variant = _eval_json("spike.resources()")
	var win := DisplayServer.window_get_size()
	var vis := get_viewport().get_visible_rect()
	var ft := get_viewport().get_final_transform()
	var boot := {
		"ready_ms_since_navigation": ready_ms,
		"nav_frames_to_ready": _nav_frames,
		"nav_bake_ms": _results.get("nav_bake_ms", -1),
		"nav_verify": _results.get("nav_verify", {}),
		"texgen_ms_spike_only": _results.get("texgen_ms", -1),
		"device": device,
		"resources": resources,
		"window_px": [win.x, win.y],
		"visible_rect_dp": [vis.size.x, vis.size.y],
		"final_transform_scale": [ft.x.x, ft.y.y],
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"video_vendor": RenderingServer.get_video_adapter_vendor(),
		"engine": Engine.get_version_info().string,
		"wasm_heap_bytes": _eval("spike.heapBytes()"),
		"is_visible_at_boot": _eval("spike.isVisible()"),
		"camera": {"size": _camera.size, "h_offset": _camera.h_offset, "v_offset": _camera.v_offset},
	}
	_results["boot"] = boot
	if reopen is Dictionary and reopen.get("stage", "") == "await_reopen":
		_step = Step.REOPEN
		var gap := (Time.get_unix_time_from_system() - float(reopen.get("written_unix", 0.0)))
		_report("reopen", {
			"persisted": true, "token_ok": reopen.get("token", "") != "",
			"seconds_since_write": gap, "hide_flush_counter": reopen.get("hide_flush_counter", 0),
			"warm_boot": boot,
		})
		_write_save({"stage": "done"})
		_goto(Step.DONE)
		return
	_report("boot", boot)
	_goto(Step.BOOT)


# ---------------------------------------------------------------- steps

func _goto(step: Step) -> void:
	_step = step
	match step:
		Step.BOOT:
			var b: Dictionary = _results["boot"]
			_set_ui("1/7 · Запуск",
				"Кухня готова за %.1f с после открытия ссылки.\nЭкран: %s px окна, DPR %s.\nЗамеры отправлены. Дальше — несколько проверок, ~10 минут." % [
					float(b["ready_ms_since_navigation"]) / 1000.0, str(b["window_px"]), _dpr_text()],
				[["Начать", func() -> void: _goto(Step.SORTING)]])
		Step.SORTING:
			_apply_mode(MODES[_mode_idx])
			_set_ui("2/7 · Как нарисованы фигуры (вариант %d из 3)" % (_mode_idx + 1),
				"Посмотри на гостей внизу и на фигуру за островом в центре.\nГости должны быть ПЕРЕД стойкой, фигура — ЗА островом. Края мягкие, без светлых/тёмных ореолов и мерцания.\nСделай скриншот экрана, потом ответь.",
				[["Всё правильно", func() -> void: _vote_sort(true)], ["Есть косяки", func() -> void: _vote_sort(false)]])
		Step.PRICE:
			_apply_mode("prepass")
			_set_ui("3/7 · Цена на жетоне",
				"Над каждым гостем жетон с ценой «7». Держи телефон как обычно в игре.\nЦифра читается без напряжения?",
				[["Читается", func() -> void: _vote_price(true)], ["С трудом / нет", func() -> void: _vote_price(false)]])
		Step.PERF:
			_set_ui("4/7 · Замер скорости", "Ничего не трогай ~50 секунд, телефон не блокируй.", [])
			_start_perf()
		Step.TAPS:
			_tap_log.clear()
			_set_ui("5/7 · Тапы", "Потапай по полу кухни 10 раз в разных местах (по одному пальцу).\nОсталось: 10", [])
		Step.BACKGROUND:
			_vis_events.clear()
			_set_ui("6/7 · Сворачивание",
				"Сверни браузер (кнопка «домой») или переключись на другое приложение.\nПодожди ~10 секунд и вернись сюда.", [])
		Step.REOPEN:
			_write_save({"stage": "await_reopen", "token": str(randi()), "written_unix": Time.get_unix_time_from_system(), "hide_flush_counter": 0})
			_set_ui("7/7 · Перезапуск",
				"Закрой эту вкладку совсем (смахни её в списке вкладок или закрой браузер), потом открой ту же ссылку заново.\nПроверим, что сохранение пережило закрытие, и замерим повторный запуск.", [])
		Step.DONE:
			_set_ui("Готово ✓", "Все результаты отправлены на компьютер. Спасибо!\nМожно закрыть вкладку.", [])


func _vote_sort(ok: bool) -> void:
	_sort_votes[MODES[_mode_idx]] = ok
	_mode_idx += 1
	if _mode_idx < MODES.size():
		_goto(Step.SORTING)
	else:
		_report("sorting", {"votes": _sort_votes, "note": "prepass=ALPHA_CUT_OPAQUE_PREPASS (vendor list cleared), discard=ALPHA_CUT_DISCARD, blend=no alpha cut (≈ stock mobile fallback)"})
		_goto(Step.PRICE)


func _vote_price(ok: bool) -> void:
	_report("price", {"readable": ok, "price_height_dp": _label_height_dp(), "viewport_dp": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y]})
	_goto(Step.PERF)


# ---------------------------------------------------------------- perf

func _start_perf() -> void:
	var win := Vector2(DisplayServer.window_get_size())
	var budget_scale := clampf(sqrt(PIXEL_BUDGET / maxf(1.0, win.x * win.y)), SCALE_MIN, 1.0)
	_results["budget_scale"] = budget_scale
	_perf_phases = [
		{"name": "scale_1.0_prepass", "scale": 1.0, "mode": "prepass", "census": false, "max_fps": 0},
		{"name": "scale_budget_prepass", "scale": budget_scale, "mode": "prepass", "census": false, "max_fps": 0},
		{"name": "scale_0.6_prepass", "scale": 0.6, "mode": "prepass", "census": false, "max_fps": 0},
		{"name": "scale_budget_discard", "scale": budget_scale, "mode": "discard", "census": false, "max_fps": 0},
		{"name": "scale_budget_blend", "scale": budget_scale, "mode": "blend", "census": false, "max_fps": 0},
		{"name": "census75_budget_prepass", "scale": budget_scale, "mode": "prepass", "census": true, "max_fps": 0},
		{"name": "census75_scale_1.0_prepass", "scale": 1.0, "mode": "prepass", "census": true, "max_fps": 0},
		{"name": "max_fps_30", "scale": budget_scale, "mode": "prepass", "census": false, "max_fps": 30},
	]
	_perf_idx = -1
	_next_perf_phase()


func _next_perf_phase() -> void:
	_perf_idx += 1
	if _perf_idx >= _perf_phases.size():
		get_viewport().scaling_3d_scale = float(_results["budget_scale"])
		Engine.max_fps = 0
		_set_census(false)
		_report("perf", {"phases": _results.get("perf", []), "budget_scale": _results["budget_scale"], "wasm_heap_bytes": _eval("spike.heapBytes()")})
		_goto(Step.TAPS)
		return
	var p: Dictionary = _perf_phases[_perf_idx]
	get_viewport().scaling_3d_scale = float(p["scale"])
	_apply_mode(p["mode"])
	_set_census(p["census"])
	Engine.max_fps = int(p["max_fps"])
	_perf_t = 0.0
	_perf_deltas = PackedFloat32Array()
	_perf_calls = 0
	_ui_status.text = "Замер %d/%d: %s" % [_perf_idx + 1, _perf_phases.size(), p["name"]]


func _perf_tick(delta: float) -> void:
	if _perf_idx < 0 or _perf_idx >= _perf_phases.size():
		return
	_perf_t += delta
	if _perf_t < 1.0:          # warm-up: skip the first second of every phase
		return
	_perf_deltas.append(delta)
	_perf_calls += int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if _perf_t >= 5.0:
		var sorted := _perf_deltas.duplicate()
		sorted.sort()
		var n := sorted.size()
		var total := 0.0
		for d in sorted:
			total += d
		var p: Dictionary = _perf_phases[_perf_idx]
		var entry := {
			"name": p["name"], "frames": n, "fps_avg": n / maxf(total, 0.001),
			"frame_ms_p50": sorted[n / 2] * 1000.0, "frame_ms_p95": sorted[mini(n - 1, int(n * 0.95))] * 1000.0,
			"frame_ms_max": sorted[n - 1] * 1000.0, "draw_calls_avg": float(_perf_calls) / maxf(1, n),
			"renderables": _count_renderables(),
		}
		if not _results.has("perf"):
			_results["perf"] = []
		(_results["perf"] as Array).append(entry)
		_next_perf_phase()


## Census phase: top the scene up to exactly CENSUS renderables (ADR-0007 §3).
func _set_census(on: bool) -> void:
	for n in _census_nodes:
		n.visible = false
	if not on:
		return
	var need := CENSUS - _count_renderables()
	for i in mini(need, _census_nodes.size()):
		_census_nodes[i].visible = true


func _count_renderables() -> int:
	var count := 0
	for n in find_children("*", "GeometryInstance3D", true, false):
		if (n as Node3D).is_visible_in_tree():
			count += 1
	return count


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			_raw_events["emulated_mouse"] += 1
			return                                   # ADR-0006: ignore emulated mouse
		_raw_events["mouse"] += 1
		pressed = true
		pos = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_raw_events["touch"] += 1
		pressed = true
		pos = (event as InputEventScreenTouch).position
	if not pressed or _step != Step.TAPS:
		return
	var latency: Variant = _eval("performance.now() - spike.lastDown")
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(_camera.project_ray_origin(pos), _camera.project_ray_normal(pos))
	var path_us := -1
	var path_pts := 0
	var reached := false
	if hit != null and _nav_ready:
		var t0 := Time.get_ticks_usec()
		var path := NavigationServer3D.map_get_path(_map, Vector3(0, 0, 0.5), hit, true)
		path_us = Time.get_ticks_usec() - t0
		path_pts = path.size()
		if path_pts > 0:
			var end := path[path_pts - 1]
			reached = Vector2(end.x - hit.x, end.z - hit.z).length() < 0.05
			_marker.position = Vector3(end.x, 0.02, end.z)
			_marker.visible = true
	_tap_log.append({"browser_to_engine_ms": latency, "pos_dp": [pos.x, pos.y], "path_us": path_us, "path_points": path_pts, "reached": reached})
	var left := 10 - _tap_log.size()
	_ui_text.text = "Потапай по полу кухни 10 раз в разных местах (по одному пальцу).\nОсталось: %d" % left
	if left <= 0:
		_report("taps", {"taps": _tap_log, "raw_events": _raw_events, "browser_presses": _eval("spike.downs")})
		_goto(Step.BACKGROUND)


# ---------------------------------------------------------------- visibility

func _on_js_visibility(args: Array) -> void:
	var visible := bool(args[0])
	var type := str(args[1])
	var t := float(args[2])
	_record_vis(type, {"visible": visible, "js_t": t, "in_process": _in_process, "frame": _frames})
	if visible == _visible:
		return
	_visible = visible
	if not visible:
		_hidden_since_frame = _frames
		_hide_t = t
		# ADR-0005: synchronous save flush inside the browser event
		var s: Variant = _read_save()
		if s is Dictionary and s.get("stage", "") == "await_reopen":
			s["hide_flush_counter"] = int(s.get("hide_flush_counter", 0)) + 1
			_write_save(s)
	else:
		_resume_pending = true
		if _step == Step.BACKGROUND and t - _hide_t >= 4000.0:
			_record_vis("hidden_duration_ms", {"ms": t - _hide_t})
			call_deferred("_finish_background")


func _finish_background() -> void:
	_report("background", {"events": _vis_events, "shell_log": _eval_json("JSON.stringify(spike.visLog)")})
	_goto(Step.REOPEN)


func _record_vis(kind: String, data: Dictionary) -> void:
	data["kind"] = kind
	_vis_events.append(data)


# ---------------------------------------------------------------- navigation (ADR-0006)

func _bake_navigation() -> void:
	var t0 := Time.get_ticks_usec()
	var src := NavigationMeshSourceGeometryData3D.new()
	var a := Vector3(FRAME_MIN.x + 0.05, 0, FRAME_MIN.z + 0.05)
	var b := Vector3(FRAME_MAX.x - 0.05, 0, FRAME_MAX.z - 0.1)
	src.add_faces(PackedVector3Array([a, Vector3(b.x, 0, a.z), b, a, b, Vector3(a.x, 0, b.z)]), Transform3D.IDENTITY)
	for f in _footprints():
		var c: Vector3 = f["pos"]
		var h: Vector2 = f["size"] / 2.0
		src.add_projected_obstruction(PackedVector3Array([
			Vector3(c.x - h.x, 0, c.z - h.y), Vector3(c.x + h.x, 0, c.z - h.y),
			Vector3(c.x + h.x, 0, c.z + h.y), Vector3(c.x - h.x, 0, c.z + h.y)]), 0.0, 1.0, false)
	var nm := NavigationMesh.new()
	nm.cell_size = 0.05
	nm.cell_height = 0.05
	nm.agent_radius = snappedf(0.4, 0.05)
	nm.agent_height = 1.0
	nm.agent_max_climb = 0.0
	nm.agent_max_slope = 45.0
	nm.edge_max_error = 0.5
	nm.region_min_size = 0.0
	NavigationServer3D.bake_from_source_geometry_data(nm, src)
	_results["nav_bake_ms"] = (Time.get_ticks_usec() - t0) / 1000.0
	_results["nav_polygons"] = nm.get_polygon_count()
	_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(_map, 0.05)
	NavigationServer3D.map_set_cell_height(_map, 0.05)
	NavigationServer3D.map_set_use_async_iterations(_map, false)
	NavigationServer3D.map_set_active(_map, true)
	_region = NavigationServer3D.region_create()
	NavigationServer3D.region_set_map(_region, _map)
	NavigationServer3D.region_set_navigation_mesh(_region, nm)


func _poll_navigation() -> void:
	_nav_frames += 1
	NavigationServer3D.map_force_update(_map)
	if NavigationServer3D.map_get_iteration_id(_map) <= 0:
		return
	var p := NavigationServer3D.map_get_closest_point(_map, SPAWN)
	if Vector2(p.x - SPAWN.x, p.z - SPAWN.z).length() > 0.01:
		return
	_nav_ready = true
	var t0 := Time.get_ticks_usec()
	var reached := 0
	var failed: Array = []
	for s in STATIONS:
		var wp := _work_point(s)
		var path := NavigationServer3D.map_get_path(_map, SPAWN, wp, true)
		var end: Vector3 = path[path.size() - 1] if path.size() > 0 else Vector3.INF
		if path.size() > 0 and Vector2(end.x - wp.x, end.z - wp.z).length() < 0.05:
			reached += 1
		else:
			failed.append(s["id"])
	_results["nav_verify"] = {"reached": reached, "total": STATIONS.size(), "failed": failed, "verify_ms": (Time.get_ticks_usec() - t0) / 1000.0, "polygons": _results["nav_polygons"]}
	_boot_prewarm_frames = 0               # ADR-0007 pre-warm: wait 2 drawn frames, polled


func _footprints() -> Array:
	var out: Array = []
	for s in STATIONS:
		out.append({"pos": s["pos"], "size": s.get("size", Vector2(1.0, 1.0))})
	for w in WALLS:
		out.append(w)
	return out


func _work_point(s: Dictionary) -> Vector3:
	var size: Vector2 = s.get("size", Vector2(1.0, 1.0))
	var p: Vector3 = s["pos"]
	match s["side"]:
		"back": return p + Vector3(0, 0, size.y / 2.0 + 0.45)
		"left": return p + Vector3(size.x / 2.0 + 0.45, 0, 0)
		"right": return p - Vector3(size.x / 2.0 + 0.45, 0, 0)
		"island_left": return p - Vector3(size.x / 2.0 + 0.45, 0, 0)
		_: return p + Vector3(size.x / 2.0 + 0.45, 0, 0)


# ---------------------------------------------------------------- world

func _build_world() -> void:
	var tex_t0 := Time.get_ticks_usec()
	for k in ["station", "figure", "ring", "token"]:
		_tex(k, Color.WHITE)
	_results["texgen_ms"] = (Time.get_ticks_usec() - tex_t0) / 1000.0
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.13, 0.1, 0.09)
	add_child(env)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.position = CAM_POS
	add_child(_camera)
	_camera.look_at(CAM_TARGET)
	# floor + counters: flat unshaded quads
	_flat(Vector3((FRAME_MIN.x + FRAME_MAX.x) / 2, 0, (FRAME_MIN.z + FRAME_MAX.z) / 2), Vector2(FRAME_MAX.x - FRAME_MIN.x, FRAME_MAX.z - FRAME_MIN.z), Color(0.55, 0.47, 0.38), 0.0)
	for w in WALLS:
		_block(w["pos"], w["size"], Color(0.26, 0.21, 0.18))
	_flat(Vector3(0, 0.9, 2.3), Vector2(8.0, 0.6), Color(0.45, 0.32, 0.22), 0.9)   # serving counter in front of guests
	for s in STATIONS:
		_station(s)
	for i in GUEST_X.size():
		_guest(Vector3(GUEST_X[i], 0, GUEST_Z), i)
	var barista := _figure(Vector3(0.0, 0, -5.4), Color(0.25, 0.45, 0.6), 1.7)   # behind the island
	_sprites.append(barista)
	_marker = _overlay_sprite(_tex("ring", Color.WHITE), Vector3.ZERO, 0.9, 1)
	_marker.rotation_degrees = Vector3(-90, 0, 0)
	_marker.visible = false
	add_child(_marker)
	for i in CENSUS:
		var n := _overlay_sprite(_tex("token", Color.WHITE), Vector3(-3.6 + (i % 15) * 0.5, 0.5 + (i / 15) * 0.25, 1.2), 0.3, 1)
		n.modulate = Color.from_hsv(float(i) / CENSUS, 0.5, 0.95)
		n.visible = false
		add_child(n)
		_census_nodes.append(n)


func _station(s: Dictionary) -> void:
	var size: Vector2 = s.get("size", Vector2(1.0, 1.0))
	_block(s["pos"], size * 0.96, s["color"].darkened(0.35))
	var spr := Sprite3D.new()
	spr.texture = _tex("station", Color.WHITE)
	spr.modulate = s["color"]
	spr.pixel_size = 0.9 / 128.0
	spr.scale.y = UPRIGHT_STRETCH
	spr.position = s["pos"] + Vector3(0, 0.9 + 0.45 * UPRIGHT_STRETCH, 0)   # icon stands on the block top
	spr.shaded = false
	add_child(spr)
	_sprites.append(spr)


func _guest(pos: Vector3, i: int) -> void:
	var g := _figure(pos, Color(0.75, 0.7, 0.65).lerp(Color.from_hsv(i * 0.23, 0.5, 0.9), 0.4), 1.6)
	_sprites.append(g)
	var token := _overlay_sprite(_tex("token", Color.WHITE), pos + Vector3(0, 1.6 * UPRIGHT_STRETCH + 0.4, 0), 0.55, 2)
	token.modulate = Color(0.96, 0.9, 0.78)
	add_child(token)
	var price := Label3D.new()
	price.text = "7"
	price.font_size = 64
	price.outline_size = 12
	price.pixel_size = 0.004
	price.modulate = Color(0.15, 0.1, 0.08)
	price.outline_modulate = Color(0.98, 0.95, 0.88)
	price.no_depth_test = true
	price.render_priority = 3
	price.outline_render_priority = 2
	price.shaded = false
	price.position = pos + Vector3(0, 1.6 * UPRIGHT_STRETCH + 0.4, 0.01)
	price.rotation_degrees.x = -PITCH_DEG
	add_child(price)
	if _price_label == null:
		_price_label = price


func _figure(pos: Vector3, color: Color, height: float) -> Sprite3D:
	var spr := Sprite3D.new()
	spr.texture = _tex("figure", Color.WHITE)
	spr.modulate = color
	spr.pixel_size = height / 256.0
	spr.centered = true
	spr.offset = Vector2(0, 128)
	spr.position = pos
	spr.scale.y = UPRIGHT_STRETCH
	spr.shaded = false
	add_child(spr)
	return spr


func _overlay_sprite(tex: Texture2D, pos: Vector3, width: float, priority: int) -> Sprite3D:
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.pixel_size = width / float(tex.get_width())
	spr.position = pos
	spr.rotation_degrees.x = -PITCH_DEG
	spr.no_depth_test = true
	spr.render_priority = priority
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	spr.shaded = false
	return spr


func _apply_mode(mode: String) -> void:
	var cut := SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	if mode == "discard":
		cut = SpriteBase3D.ALPHA_CUT_DISCARD
	elif mode == "blend":
		cut = SpriteBase3D.ALPHA_CUT_DISABLED
	for s in _sprites:
		s.alpha_cut = cut
	_results["mode"] = mode


func _flat(center: Vector3, size: Vector2, color: Color, y: float) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.position = Vector3(center.x, y, center.z)
	mi.material_override = _unshaded(color)
	add_child(mi)


func _block(pos: Vector3, size: Vector2, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, 0.9, size.y)
	mi.mesh = bm
	mi.position = pos + Vector3(0, 0.45, 0)
	mi.material_override = _unshaded(color)
	add_child(mi)


func _unshaded(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	return m


## Procedural soft-edged textures: painted-sprite stand-ins with real alpha gradients.
func _tex(kind: String, color: Color) -> Texture2D:
	var key := kind + color.to_html()
	if _tex_cache.has(key):
		return _tex_cache[key]
	var w := 128
	var h := 128
	if kind == "figure":
		h = 256
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var a := 0.0
			var c := color
			match kind:
				"station":
					var d := _rounded_rect_dist(Vector2(x, y), Vector2(w, h) / 2.0, Vector2(52, 52), 18.0)
					a = clampf(0.5 - d / 6.0, 0.0, 1.0)
					var r := Vector2(x, y).distance_to(Vector2(w, h) / 2.0)
					if r < 22.0:
						c = Color(0.35, 0.35, 0.35)
				"figure":
					var head := Vector2(x, y).distance_to(Vector2(64, 50)) - 34.0
					var body := _rounded_rect_dist(Vector2(x, y), Vector2(64, 170), Vector2(46, 80), 30.0)
					var d2 := minf(head, body)
					a = clampf(0.5 - d2 / 5.0, 0.0, 1.0)
				"ring":
					var r2 := Vector2(x, y).distance_to(Vector2(w, h) / 2.0)
					a = clampf(1.0 - absf(r2 - 50.0) / 8.0, 0.0, 1.0)
				"token":
					var r3 := Vector2(x, y).distance_to(Vector2(w, h) / 2.0)
					a = clampf((60.0 - r3) / 3.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, a * c.a))
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex


func _rounded_rect_dist(p: Vector2, center: Vector2, half: Vector2, radius: float) -> float:
	var q := (p - center).abs() - half + Vector2(radius, radius)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - radius


# ---------------------------------------------------------------- camera fit (ADR-0002 §3)

func _fit_camera() -> void:
	var v := get_viewport().get_visible_rect().size
	var avail := Vector2(v.x, v.y - TOP_RESERVE_DP)
	var p := avail
	if avail.x / avail.y > ASPECT_MAX:
		p.x = avail.y * ASPECT_MAX
	elif avail.x / avail.y < ASPECT_MIN:
		p.y = avail.x / ASPECT_MIN
	var p_center_y := TOP_RESERVE_DP + avail.y / 2.0
	var right := _camera.global_transform.basis.x
	var up := _camera.global_transform.basis.y
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in 8:
		var corner := Vector3(
			FRAME_MAX.x if i & 1 else FRAME_MIN.x,
			FRAME_MAX.y if i & 2 else FRAME_MIN.y,
			FRAME_MAX.z if i & 4 else FRAME_MIN.z) - _camera.global_position
		var q := Vector2(right.dot(corner), up.dot(corner))
		lo = lo.min(q)
		hi = hi.max(q)
	var f := hi - lo
	var c := (hi + lo) / 2.0
	var s := FILL_TARGET * minf(p.x / f.x, p.y / f.y)
	_camera.size = v.y / s
	_camera.h_offset = c.x
	_camera.v_offset = c.y + (p_center_y - v.y / 2.0) / s
	_results["kitchen_scale_dp_per_m"] = s


func _label_height_dp() -> float:
	if _price_label == null:
		return -1.0
	var h := _price_label.font_size * _price_label.pixel_size
	var base := _price_label.global_position
	var up := _price_label.global_transform.basis.y
	var a := _camera.unproject_position(base - up * h * 0.35)
	var b := _camera.unproject_position(base + up * h * 0.35)
	return a.distance_to(b)


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE          # ADR-0002 §6
	layer.add_child(root)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.85)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	_ui_title = _label(16)
	box.add_child(_ui_title)
	_ui_text = _label(13)
	box.add_child(_ui_text)
	_ui_buttons = HBoxContainer.new()
	_ui_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_ui_buttons)
	_ui_status = _label(11)
	_ui_status.modulate = Color(1, 1, 1, 0.6)
	box.add_child(_ui_status)


func _label(size: int) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _set_ui(title: String, text: String, buttons: Array) -> void:
	_ui_title.text = title
	_ui_text.text = text
	_ui_status.text = "сессия " + _session
	for c in _ui_buttons.get_children():
		c.queue_free()
	for b in buttons:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(0, 48)       # 48 dp target
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(b[1])
		_ui_buttons.add_child(btn)


# ---------------------------------------------------------------- JS / storage / report

func _eval(code: String) -> Variant:
	if not _web:
		return null
	return JavaScriptBridge.eval(code, true)


func _eval_json(code: String) -> Variant:
	var s: Variant = _eval(code)
	if typeof(s) != TYPE_STRING:
		return null
	return JSON.parse_string(s)


func _now_ms() -> float:
	var v: Variant = _eval("performance.now()")
	return float(v) if v != null else Time.get_ticks_msec()


func _dpr_text() -> String:
	var d: Variant = _eval("window.devicePixelRatio")
	return str(d) if d != null else "?"


func _read_save() -> Variant:
	if not _web:
		return null
	var s: Variant = JavaScriptBridge.eval("localStorage.getItem('%s')" % SAVE_KEY, true)
	if typeof(s) != TYPE_STRING:
		return null
	return JSON.parse_string(s)


func _write_save(d: Dictionary) -> void:
	if not _web:
		return
	var js := JSON.stringify(JSON.stringify(d))
	JavaScriptBridge.eval("localStorage.setItem('%s', %s)" % [SAVE_KEY, js], true)


func _load_session() -> String:
	if not _web:
		return "desktop"
	var s: Variant = JavaScriptBridge.eval("localStorage.getItem('tea_rush.spike_session')", true)
	if typeof(s) == TYPE_STRING and s != "":
		return s
	var id := "%08x" % randi()
	JavaScriptBridge.eval("localStorage.setItem('tea_rush.spike_session', '%s')" % id, true)
	return id


func _report(kind: String, data: Dictionary) -> void:
	var payload := {"session": _session, "kind": kind, "at_ms": _now_ms(), "data": data}
	var json := JSON.stringify(payload)
	if _web:
		_js.report(json)
	else:
		print("[spike report] ", json)


func _exit_tree() -> void:
	if _region.is_valid():
		NavigationServer3D.free_rid(_region)
	if _map.is_valid():
		NavigationServer3D.free_rid(_map)


## Dev only: `-- --shot=<path> [--mode=prepass|discard|blend]` saves a frame and quits.
func _debug_shot() -> void:
	var path := ""
	var mode := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			path = arg.substr(7)
		elif arg.begins_with("--mode="):
			mode = arg.substr(7)
	if path == "" or _frames != 20:
		return
	if mode != "":
		_apply_mode(mode)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
