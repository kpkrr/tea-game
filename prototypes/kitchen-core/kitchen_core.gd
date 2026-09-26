extends Node3D
## PROTOTYPE — throwaway. Answers: is the tap-to-station tea kitchen fun?
## See README.md next to this file. Do not move into src/.
##
## The whole scene is built from code: grey boxes, an orthographic camera and a
## debug HUD. Every tunable number lives in TUNING.

const TUNING := {
	"walk_speed": 4.0,            # m/s
	"brew_time": 3.0,             # s per kettle brew
	"prices": {"simple": 2, "medium": 5, "complex": 9},
	"points_per_coin": 10,
	# Difficulty rises linearly from the first second: every value moves from
	# "start" to "end" over ramp_seconds. The guest flow is linear in guests per
	# minute (a linear spawn interval made the late game spike).
	# Playtest 2026-09-27: a flat first minute (6 guests/min) felt boring,
	# then the jump at 1:00 felt like a sudden boom.
	"ramp_seconds": 180.0,        # full difficulty at 3:00
	"guests_per_min_start": 8.0,
	"guests_per_min_end": 18.0,
	"patience_start": 50.0,       # s a guest waits
	"patience_end": 25.0,
	"weights_start": {"simple": 0.65, "medium": 0.35, "complex": 0.0},
	"weights_end": {"simple": 0.2, "medium": 0.4, "complex": 0.4},
	"max_strikes": 3,
	# Daily register. First playtest: one round = 222 s, ~84 coins (medium
	# effort). 250 keeps the day at ~3 rounds / ~10-11 min.
	# Paid upgrades (simulated by the boost panel): register capacity per level,
	# and a barista speed multiplier for walking and brewing per level.
	"register_levels": [250, 350, 500, 700],
	"speed_levels": [1.0, 1.15, 1.3, 1.5],
	"first_guest_delay": 1.0,
}

const RECIPES := {
	"simple": ["cup", "ready_tea"],
	"medium": ["cup", "leaf", "water100"],
	"complex": ["cup", "leaf", "water80", "additive"],
}
const DRINK_NAMES := {"simple": "Термос", "medium": "Заварной", "complex": "Особый"}
# One colour per recipe step (icons later). Stations are painted in the colour
# of the step they add, orders and cups show their steps as coloured squares.
const STEP_COLORS := {
	"cup": Color(0.95, 0.95, 0.95),
	"ready_tea": Color(0.6, 0.35, 0.85),
	"leaf": Color(0.3, 0.7, 0.3),
	"water100": Color(0.9, 0.3, 0.3),
	"water80": Color(0.3, 0.5, 0.95),
	"additive": Color(0.95, 0.85, 0.25),
}
const STATION_STEP := {
	"cups": "cup", "thermos": "ready_tea", "leaf": "leaf",
	"kettle100": "water100", "kettle80": "water80", "additive": "additive",
}
const GUEST_COLOR := Color(0.75, 0.7, 0.65)
const STEP_NAMES := {
	"cup": "чашка", "ready_tea": "термос", "leaf": "лист",
	"water100": "кипяток", "water80": "вода 80°", "additive": "добавка",
}

# Layout: portrait rectangle with a wide 2x4 island in the middle. "side" says
# which face the barista works from; each island column faces its own aisle.
# Ids starting with "slot" are empty counter slots: put a cup down, pick it up.
const SLOT_COLOR := Color(0.4, 0.28, 0.2)
const WALL_COLOR := Color(0.3, 0.24, 0.2)
const STATIONS := [
	{"id": "cups", "label": "Чашки", "pos": Vector3(-2.0, 0, -7.0), "side": "back"},
	{"id": "leaf", "label": "Лист", "pos": Vector3(1.5, 0, -7.0), "side": "back"},
	{"id": "kettle100", "label": "100°", "pos": Vector3(-3.5, 0, -4.5), "side": "left"},
	{"id": "slot_left", "label": "", "pos": Vector3(-3.5, 0, -2.0), "side": "left", "color": SLOT_COLOR},
	{"id": "trash", "label": "Мусорка", "pos": Vector3(-3.5, 0, 0.5), "side": "left", "color": Color(0.4, 0.4, 0.4)},
	{"id": "kettle80", "label": "80°", "pos": Vector3(3.5, 0, -4.5), "side": "right"},
	{"id": "slot_right", "label": "", "pos": Vector3(3.5, 0, -2.0), "side": "right", "color": SLOT_COLOR},
	# Island, 2x4: each column is worked from its own aisle.
	{"id": "thermos", "label": "Термос", "pos": Vector3(-0.5, 0, -4.5), "side": "island_left"},
	{"id": "slot_island_l1", "label": "", "pos": Vector3(-0.5, 0, -3.5), "side": "island_left", "color": SLOT_COLOR},
	{"id": "slot_island_l2", "label": "", "pos": Vector3(-0.5, 0, -2.5), "side": "island_left", "color": SLOT_COLOR},
	{"id": "slot_island_l3", "label": "", "pos": Vector3(-0.5, 0, -1.5), "side": "island_left", "color": SLOT_COLOR},
	{"id": "slot_island_r1", "label": "", "pos": Vector3(0.5, 0, -4.5), "side": "island_right", "color": SLOT_COLOR},
	{"id": "slot_island_r2", "label": "", "pos": Vector3(0.5, 0, -3.5), "side": "island_right", "color": SLOT_COLOR},
	{"id": "slot_island_r3", "label": "", "pos": Vector3(0.5, 0, -2.5), "side": "island_right", "color": SLOT_COLOR},
	{"id": "additive", "label": "Добавка", "pos": Vector3(0.5, 0, -1.5), "side": "island_right"},
]

# Unusable wall blocks filling the gaps between wall stations (placeholder —
# what goes there is decided later). Centre on the floor and x/z size in metres;
# edges sit on the 0.5 m grid lines like the stations.
const WALLS := [
	{"pos": Vector3(-3.25, 0, -7.0), "size": Vector2(1.5, 1.0)},
	{"pos": Vector3(-0.25, 0, -7.0), "size": Vector2(2.5, 1.0)},
	{"pos": Vector3(3.0, 0, -7.0), "size": Vector2(2.0, 1.0)},
	{"pos": Vector3(-3.5, 0, -5.75), "size": Vector2(1.0, 1.5)},
	{"pos": Vector3(-3.5, 0, -3.25), "size": Vector2(1.0, 1.5)},
	{"pos": Vector3(-3.5, 0, -0.75), "size": Vector2(1.0, 1.5)},
	{"pos": Vector3(-3.5, 0, 1.5), "size": Vector2(1.0, 1.0)},
	{"pos": Vector3(3.5, 0, -5.75), "size": Vector2(1.0, 1.5)},
	{"pos": Vector3(3.5, 0, -3.25), "size": Vector2(1.0, 1.5)},
	{"pos": Vector3(3.5, 0, 0.25), "size": Vector2(1.0, 3.5)},
]

const GUEST_X := [-2.4, -0.8, 0.8, 2.4]
const GUEST_Z := 3.2
const SERVE_Z := 1.55

# Walk grid for pathfinding around the island. Station boxes are 1x1 and sit on
# the 0.5 m grid lines, so a cell is solid exactly when its centre is inside one.
const GRID_MIN := Vector2(-4.0, -7.5)  # world x, z of the grid's top-left corner
const GRID_CELLS := Vector2i(16, 19)
const CELL := 0.5
const CLEARANCE_WEIGHT := 4.0  # path cost of a cell next to a station
const BODY_RADIUS := 0.4       # how close to a station the smoothed path may pass
const CAMERA_PITCH_DEG := 39.3  # matches the camera placement in _build_world
const CAMERA_VIEW_WIDTH := 8.8           # world metres visible across a portrait screen
const DESIGN_ASPECT := 540.0 / 960.0      # the portrait layout the view is framed for
const TAP_RADIUS := 42.0  # px in the 540x960 base resolution
const WORK_GAP := 0.45  # distance from a station face to where the barista stands

var _camera: Camera3D
var _barista: Node3D
var _barista_row: Node3D
var _barista_row_shown: Variant = null
var _barista_cup: MeshInstance3D
var _hud_label: Label
var _hint_label: Label
var _again_button: Button
var _register_bar: ProgressBar
var _register_label: Label
var _boost_register_label: Label
var _boost_speed_label: Label
var _game_over_box: CenterContainer
var _game_over_label: Label

var _elapsed := 0.0
var _spawn_timer := 0.0
var _running := true
var _coins := 0
var _points := 0
var _strikes := 0
var _served := 0
var _coins_missed := 0  # earned after the register was full

# Survive scene reloads, so the register fills across rounds within one run.
static var _register := 0
static var _best_points := 0
static var _register_level := 0
static var _speed_level := 0

var _held: Array = []
var _target_kind := ""          # "", "station" or "guest"
var _target_id: Variant = null  # station id (String) or guest slot (int)
var _pending_tap: Variant = null  # Vector2 screen position, handled in physics step

var _path: Array = []  # remaining Vector3 waypoints to the target
var _grid := AStarGrid2D.new()

var _stations := {}  # id -> {mat, base_color, label, base_text, interacts: Array[Vector3]}
var _kettles := {}   # id -> {state: "empty"|"brewing"|"done", t, steps}
var _slots := {}     # id -> {cup: Array (empty = nothing on the slot), mesh, label}
var _guests: Array = [null, null, null, null]


func _ready() -> void:
	var root := get_tree().root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(540, 960)
	if not OS.has_feature("web"):
		get_window().size = Vector2i(432, 768) * maxi(1, roundi(DisplayServer.screen_get_scale()))
		get_window().move_to_center()

	_build_world()
	for def: Dictionary in STATIONS:
		_build_station(def)
	for w: Dictionary in WALLS:
		var block := Node3D.new()
		block.position = w.pos
		add_child(block)
		# Match the 1.2 m visual depth of station boxes and sit a bit lower, so
		# stations read as full-size where they overlap the wall.
		# Along the wall, stop 0.1 m short at each end: that is where the wider
		# station boxes reach, and coplanar faces would cover their edges.
		var visual := Vector3(1.2 if w.size.x == 1.0 else w.size.x - 0.2, 0.95, 1.2 if w.size.y == 1.0 else w.size.y - 0.2)
		_add_box(block, visual, Vector3(0, 0.475, 0), WALL_COLOR, false)
	for id: String in ["kettle100", "kettle80"]:
		_kettles[id] = {"state": "empty", "t": 0.0, "steps": []}
	_build_grid()
	_build_barista()
	_build_hud()
	_spawn_timer = TUNING.first_guest_delay
	if _register_full():
		_running = false
		_game_over_label.text = "Касса полна.\nЧайная закрыта до завтра.\n\nРекорд: %d" % _best_points
		_again_button.visible = false
		_game_over_box.visible = true
	_maybe_take_screenshot()


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_pending_tap = mb.position


func _physics_process(_delta: float) -> void:
	if _pending_tap == null:
		return
	var screen_pos: Vector2 = _pending_tap
	_pending_tap = null
	# Fat-finger picking: the station or guest whose top is nearest on screen
	# wins, so boxes hidden behind island neighbours and their labels are easy
	# to hit. Only a tap far from everything counts as a floor tap.
	var best_dist := TAP_RADIUS
	var best_kind := ""
	var best_id: Variant = null
	for def: Dictionary in STATIONS:
		var d := screen_pos.distance_to(_camera.unproject_position(def.pos + Vector3(0, 1.0, 0)))
		if d < best_dist:
			best_dist = d
			best_kind = "station"
			best_id = def.id
	for i in _guests.size():
		if _guests[i] != null:
			var d := screen_pos.distance_to(_camera.unproject_position(Vector3(GUEST_X[i], 1.6, GUEST_Z)))
			if d < best_dist:
				best_dist = d
				best_kind = "guest"
				best_id = i
	if best_kind == "station":
		_on_station_tapped(best_id)
		return
	if best_kind == "guest":
		_on_guest_tapped(best_id)
		return

	var from := _camera.project_ray_origin(screen_pos)
	var to := from + _camera.project_ray_normal(screen_pos) * 100.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit.is_empty():
		return
	var body: Object = hit.collider
	match body.get_meta("kind", ""):
		"station":
			_on_station_tapped(body.get_meta("id"))
		"guest":
			_on_guest_tapped(body.get_meta("id"))
		"floor":
			_on_floor_tapped(hit.position)


func _process(delta: float) -> void:
	if _running:
		_elapsed += delta
		_update_spawning(delta)
		_update_guests(delta)
		_update_kettles(delta)
		_update_barista(delta)
	_update_labels()


# --- Taps -------------------------------------------------------------------

func _on_station_tapped(id: String) -> void:
	var st: Dictionary = _stations[id]
	if not _can_use_station(id):
		_flash(st.mat, st.base_color)
		_show_hint(_why_not(id))
		return
	# Island stations have a work spot on each side: take the shorter walk.
	var best_path: Array = []
	var best_len := INF
	for spot: Vector3 in st.interacts:
		var path := _find_path(spot)
		var length := _path_length(path)
		if length < best_len:
			best_len = length
			best_path = path
	_set_target("station", id, best_path)


func _on_guest_tapped(slot: int) -> void:
	if _guests[slot] == null:
		return
	var g: Dictionary = _guests[slot]
	if _held != RECIPES[g.recipe]:
		_flash(g.mat, g.base_color)
		_show_hint("Гость ждёт: %s (%s)" % [DRINK_NAMES[g.recipe], _held_to_text(RECIPES[g.recipe])])
		return
	_set_target("guest", slot, _find_path(Vector3(GUEST_X[slot], 0, SERVE_Z)))


## Walk to any free spot. Taps outside the walk grid or inside a station go to
## the nearest reachable cell instead.
func _on_floor_tapped(point: Vector3) -> void:
	var grid_max := GRID_MIN + Vector2(GRID_CELLS) * CELL
	var spot := Vector3(
		clampf(point.x, GRID_MIN.x + 0.3, grid_max.x - 0.3), 0,
		clampf(point.z, GRID_MIN.y + 0.3, grid_max.y - 0.3))
	_set_target("floor", null, _find_path(spot))


func _set_target(kind: String, id: Variant, path: Array) -> void:
	_target_kind = kind
	_target_id = id
	_path = path


func _can_use_station(id: String) -> bool:
	match id:
		"cups":
			return _held.is_empty()
		"thermos", "leaf":
			return _held == ["cup"]
		"additive":
			return _held == ["cup", "leaf", "water80"]
		"trash":
			return not _held.is_empty()
		"kettle100", "kettle80":
			var k: Dictionary = _kettles[id]
			if k.state == "empty":
				return _held == ["cup", "leaf"]
			# Busy kettle: take the tea, or swap in a new cup with leaf.
			return _held.is_empty() or _held == ["cup", "leaf"]
	if id in _slots:
		# Put down, pick up, or swap what's in hand with what's on the slot.
		return not (_held.is_empty() and _slots[id].cup.is_empty())
	return false


# --- Barista ----------------------------------------------------------------

func _update_barista(delta: float) -> void:
	if _target_kind == "":
		return
	var step: float = TUNING.walk_speed * _speed() * delta
	while not _path.is_empty() and step > 0.0:
		var waypoint: Vector3 = _path[0]
		var dist := _barista.position.distance_to(waypoint)
		if dist <= step:
			_barista.position = waypoint
			step -= dist
			_path.pop_front()
		else:
			_barista.position = _barista.position.move_toward(waypoint, step)
			step = 0.0
	if not _path.is_empty():
		return
	if _perform_target():
		_target_kind = ""


## Runs the action at the reached target. Returns false while the barista
## should keep waiting there (standing at a kettle that is still brewing).
func _perform_target() -> bool:
	if _target_kind == "floor":
		return true
	if _target_kind == "guest":
		var slot: int = _target_id
		if _guests[slot] != null and _held == RECIPES[_guests[slot].recipe]:
			_serve(slot)
		return true

	var id: String = _target_id
	var kettle: Dictionary = _kettles.get(id, {})
	if not kettle.is_empty() and kettle.state == "brewing" and (_held.is_empty() or _held == ["cup", "leaf"]):
		return false  # wait at the kettle until the tea is ready
	if not _can_use_station(id):
		_flash(_stations[id].mat, _stations[id].base_color)
		_show_hint(_why_not(id))
		return true

	match id:
		"cups":
			_held = ["cup"]
		"thermos":
			_held.append("ready_tea")
		"leaf":
			_held.append("leaf")
		"additive":
			_held.append("additive")
		"trash":
			_held = []
		"kettle100", "kettle80":
			# Take the ready tea (if any), then start brewing the cup in hand (if any).
			var ready: Array = kettle.steps if kettle.state == "done" else []
			if not _held.is_empty():
				var steps := _held.duplicate()
				steps.append("water100" if id == "kettle100" else "water80")
				kettle.steps = steps
				kettle.state = "brewing"
				kettle.t = TUNING.brew_time / _speed()
			else:
				kettle.steps = []
				kettle.state = "empty"
			_held = ready
	if id in _slots:
		var slot_state: Dictionary = _slots[id]
		var on_slot: Array = slot_state.cup
		slot_state.cup = _held
		_held = on_slot
	return true


# --- Pathfinding ------------------------------------------------------------

func _build_grid() -> void:
	_grid.region = Rect2i(Vector2i.ZERO, GRID_CELLS)
	_grid.cell_size = Vector2(CELL, CELL)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for x in GRID_CELLS.x:
		for y in GRID_CELLS.y:
			var c := _cell_center(Vector2i(x, y))
			for def: Dictionary in STATIONS:
				if absf(c.x - def.pos.x) < 0.5 and absf(c.z - def.pos.z) < 0.5:
					_grid.set_point_solid(Vector2i(x, y), true)
			for w: Dictionary in WALLS:
				if absf(c.x - w.pos.x) < w.size.x / 2.0 and absf(c.z - w.pos.z) < w.size.y / 2.0:
					_grid.set_point_solid(Vector2i(x, y), true)
	# Cells touching an obstacle cost more, so routes keep to the middle of aisles.
	for x in GRID_CELLS.x:
		for y in GRID_CELLS.y:
			var cell := Vector2i(x, y)
			if _grid.is_point_solid(cell):
				continue
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					var n := cell + Vector2i(dx, dy)
					if _grid.region.has_point(n) and _grid.is_point_solid(n):
						_grid.set_point_weight_scale(cell, CLEARANCE_WEIGHT)


func _world_to_cell(p: Vector3) -> Vector2i:
	var c := Vector2i(floori((p.x - GRID_MIN.x) / CELL), floori((p.z - GRID_MIN.y) / CELL))
	return c.clamp(Vector2i.ZERO, GRID_CELLS - Vector2i.ONE)


func _cell_center(c: Vector2i) -> Vector3:
	return Vector3(GRID_MIN.x + (c.x + 0.5) * CELL, 0, GRID_MIN.y + (c.y + 0.5) * CELL)


## Waypoints from the barista to target: grid cell centres, ending exactly on
## target. If target is inside a station, stops at the nearest reachable cell.
func _find_path(target: Vector3) -> Array:
	var goal := _world_to_cell(target)
	var ids := _grid.get_id_path(_world_to_cell(_barista.position), goal, true)
	var path: Array = []
	for i in range(1, ids.size() - 1):  # skip own cell and target cell, go straight to target
		path.append(_cell_center(ids[i]))
	if not ids.is_empty() and ids[-1] != goal:
		path.append(_cell_center(ids[-1]))
	else:
		path.append(target)
	return _smooth_path(path)


## Drops grid waypoints the barista can skip: from each point, walk straight to
## the farthest later waypoint that has a clear line (keeping BODY_RADIUS off
## every station). Turns the grid staircase into straight, natural lines.
func _smooth_path(points: Array) -> Array:
	var result: Array = []
	var from := _barista.position
	var i := 0
	while i < points.size():
		var j := points.size() - 1
		while j > i and not _clear_line(from, points[j]):
			j -= 1
		result.append(points[j])
		from = points[j]
		i = j + 1
	return result


func _clear_line(a: Vector3, b: Vector3) -> bool:
	var a2 := Vector2(a.x, a.z)
	var b2 := Vector2(b.x, b.z)
	var margin := Vector2(BODY_RADIUS, BODY_RADIUS)
	for def: Dictionary in STATIONS:
		if _segment_hits_box(a2, b2, Vector2(def.pos.x, def.pos.z), Vector2(0.5, 0.5) + margin):
			return false
	for w: Dictionary in WALLS:
		if _segment_hits_box(a2, b2, Vector2(w.pos.x, w.pos.z), w.size / 2.0 + margin):
			return false
	return true


## Slab test: does segment a-b touch the box centred at c with half-extents half?
func _segment_hits_box(a: Vector2, b: Vector2, c: Vector2, half: Vector2) -> bool:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	for axis in 2:
		var lo := c[axis] - half[axis]
		var hi := c[axis] + half[axis]
		if absf(d[axis]) < 0.000001:
			if a[axis] < lo or a[axis] > hi:
				return false
		else:
			var ta := (lo - a[axis]) / d[axis]
			var tb := (hi - a[axis]) / d[axis]
			t0 = maxf(t0, minf(ta, tb))
			t1 = minf(t1, maxf(ta, tb))
			if t0 > t1:
				return false
	return true


func _path_length(path: Array) -> float:
	var total := 0.0
	var prev := _barista.position
	for p: Vector3 in path:
		total += prev.distance_to(p)
		prev = p
	return total


func _update_kettles(delta: float) -> void:
	for id: String in _kettles:
		var k: Dictionary = _kettles[id]
		if k.state == "brewing":
			k.t -= delta
			if k.t <= 0.0:
				k.state = "done"


# --- Guests -----------------------------------------------------------------

## Difficulty 0..1, linear in round time.
func _ramp() -> float:
	return clampf(_elapsed / TUNING.ramp_seconds, 0.0, 1.0)


func _update_spawning(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	var free: Array = []
	for i in _guests.size():
		if _guests[i] == null:
			free.append(i)
	if free.is_empty():
		_spawn_timer = 0.5
		return
	_spawn_guest(free.pick_random())
	_spawn_timer = 60.0 / lerpf(TUNING.guests_per_min_start, TUNING.guests_per_min_end, _ramp())


func _pick_recipe() -> String:
	var weights := {}
	var total := 0.0
	for r: String in RECIPES:
		weights[r] = lerpf(TUNING.weights_start[r], TUNING.weights_end[r], _ramp())
		total += weights[r]
	var roll := randf() * total
	for r: String in RECIPES:
		roll -= weights[r]
		if roll <= 0.0:
			return r
	return "simple"


func _spawn_guest(slot: int) -> void:
	var recipe := _pick_recipe()
	var patience := lerpf(TUNING.patience_start, TUNING.patience_end, _ramp())
	var color := GUEST_COLOR

	var body := StaticBody3D.new()
	body.position = Vector3(GUEST_X[slot], 0, GUEST_Z)
	body.set_meta("kind", "guest")
	body.set_meta("id", slot)
	add_child(body)
	_add_box(body, Vector3(0.9, 1.6, 0.8), Vector3(0, 0.8, 0), color, true)
	var mat: StandardMaterial3D = (body.get_child(1) as MeshInstance3D).material_override

	var order_row := _make_step_row(2.3)
	body.add_child(order_row)
	_fill_step_row(order_row, RECIPES[recipe])
	var label := _label3d("%d мон." % TUNING.prices[recipe], 20)
	label.position = Vector3(0, 2.8, 0)
	body.add_child(label)

	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(1.0, 0.15, 0.15)
	bar.mesh = bar_mesh
	var bar_mat := _mat(Color.GREEN)
	bar.material_override = bar_mat
	bar.position = Vector3(0, 1.85, 0)
	body.add_child(bar)

	_guests[slot] = {
		"recipe": recipe, "patience": patience, "max": patience,
		"body": body, "mat": mat, "base_color": color, "bar": bar, "bar_mat": bar_mat,
	}


func _update_guests(delta: float) -> void:
	for i in _guests.size():
		if _guests[i] == null:
			continue
		var g: Dictionary = _guests[i]
		g.patience -= delta
		var ratio := maxf(g.patience / g.max, 0.0)
		g.bar.scale.x = maxf(ratio, 0.01)
		g.bar_mat.albedo_color = Color.RED.lerp(Color.GREEN, ratio)
		if g.patience <= 0.0:
			_remove_guest(i)
			_strikes += 1
			if _strikes >= TUNING.max_strikes:
				_game_over()
				return


func _serve(slot: int) -> void:
	var g: Dictionary = _guests[slot]
	var price: int = TUNING.prices[g.recipe]
	var ratio := maxf(g.patience / g.max, 0.0)
	var paid := clampi(_capacity() - _register, 0, price)
	_register += paid
	_coins += paid
	_coins_missed += price - paid
	_points += roundi(price * TUNING.points_per_coin * (1.0 + ratio))
	_served += 1
	_held = []
	_remove_guest(slot)


func _remove_guest(slot: int) -> void:
	_guests[slot].body.queue_free()
	_guests[slot] = null


func _game_over() -> void:
	_running = false
	_target_kind = ""
	var new_best := _points > _best_points
	_best_points = maxi(_best_points, _points)
	var text := "Партия окончена\n\nВремя: %d с\nОбслужено: %d\nМонет за партию: %d\nОчки: %d%s\nРекорд: %d" % [
		int(_elapsed), _served, _coins, _points, "  — новый рекорд!" if new_best else "", _best_points]
	text += "\nБусты: касса ур. %d, скорость ур. %d" % [_register_level, _speed_level]
	if _coins_missed > 0:
		text += "\nНе влезло в кассу: %d" % _coins_missed
	if _register_full():
		text += "\n\nКасса полна.\nЧайная закрыта до завтра."
	_game_over_label.text = text
	_again_button.visible = not _register_full()
	_game_over_box.visible = true


func _register_full() -> bool:
	return _register >= _capacity()


func _capacity() -> int:
	return TUNING.register_levels[_register_level]


func _speed() -> float:
	return TUNING.speed_levels[_speed_level]


## Test-only stand-in for the daily reset.
func _new_day() -> void:
	_register = 0
	get_tree().reload_current_scene()


# --- Labels -----------------------------------------------------------------

func _update_labels() -> void:
	for id: String in _kettles:
		var k: Dictionary = _kettles[id]
		var st: Dictionary = _stations[id]
		match k.state:
			"empty":
				st.label.text = st.base_text
			"brewing":
				st.label.text = "%.1f с\n%s" % [k.t, st.base_text]
			"done":
				st.label.text = "ГОТОВО\n%s" % st.base_text
		st.cup_mesh.visible = k.state != "empty"
		if st.shown != k.steps:
			_fill_step_row(st.row, k.steps)
			st.shown = k.steps.duplicate()

	for id: String in _slots:
		var sl: Dictionary = _slots[id]
		sl.mesh.visible = not sl.cup.is_empty()
		if sl.shown != sl.cup:
			_fill_step_row(sl.row, sl.cup)
			sl.shown = sl.cup.duplicate()

	if _barista_row_shown != _held:
		_fill_step_row(_barista_row, _held)
		_barista_row_shown = _held.duplicate()
	_barista_cup.visible = not _held.is_empty()

	_register_bar.value = _register
	_register_label.text = "Касса полна — играй на рекорд" if _register_full() else "Касса: %d / %d" % [
		_register, _capacity()]
	_register_bar.max_value = _capacity()
	_boost_register_label.text = "Касса: ур. %d (%d)" % [_register_level, _capacity()]
	_boost_speed_label.text = "Скорость: ур. %d (×%.2f)" % [_speed_level, _speed()]
	# A bigger register reopens a closed shop — the future purchase moment.
	if _game_over_box.visible and not _register_full() and not _again_button.visible:
		_again_button.visible = true
	_hud_label.text = "Время: %d с    Ушли: %d/%d\nМонеты: %d    Очки: %d\nСложность: %d%%    FPS: %d" % [
		int(_elapsed), _strikes, TUNING.max_strikes, _coins, _points, roundi(_ramp() * 100),
		Engine.get_frames_per_second()]


func _held_to_text(steps: Array) -> String:
	var names: PackedStringArray = []
	for s: String in steps:
		names.append(STEP_NAMES[s])
	return " + ".join(names)


# --- Scene building ---------------------------------------------------------

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.14, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.6)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.shadow_enabled = true
	add_child(light)

	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)
	add_child(_camera)
	_camera.position = Vector3(0, 9, 8.6)
	_camera.look_at(Vector3(0, 0, -2.4))

	var floor_body := StaticBody3D.new()
	floor_body.set_meta("kind", "floor")
	add_child(floor_body)
	_add_box(floor_body, Vector3(8.2, 0.1, 11.6), Vector3(0, -0.05, -1.8), Color(0.55, 0.45, 0.35), true)
	var counter := Node3D.new()
	add_child(counter)
	_add_box(counter, Vector3(7.0, 1.0, 0.6), Vector3(0, 0.5, 2.3), Color(0.45, 0.3, 0.2), false)


func _build_station(def: Dictionary) -> void:
	var color: Color = STEP_COLORS[STATION_STEP[def.id]] if def.id in STATION_STEP else def.color
	if String(def.id).begins_with("slot") and (floori(def.pos.x) + floori(def.pos.z)) % 2 == 0:
		color = color.lightened(0.12)  # checker neighbouring shelves so each cell reads
	var body := StaticBody3D.new()
	body.position = def.pos
	body.set_meta("kind", "station")
	body.set_meta("id", def.id)
	add_child(body)
	_add_box(body, Vector3(1.2, 1.0, 1.2), Vector3(0, 0.5, 0), color, true)
	var mat: StandardMaterial3D = (body.get_child(1) as MeshInstance3D).material_override

	var label := _label3d(def.label, 32)
	label.position = Vector3(0, 1.7, 0)
	body.add_child(label)

	var reach := 0.5 + WORK_GAP
	var p: Vector3 = def.pos
	var interacts: Array = []
	match def.side:
		"back":
			interacts = [p + Vector3(0, 0, reach)]
		"left":
			interacts = [p + Vector3(reach, 0, 0)]
		"right":
			interacts = [p - Vector3(reach, 0, 0)]
		"island_left":
			interacts = [p - Vector3(reach, 0, 0)]
		"island_right":
			interacts = [p + Vector3(reach, 0, 0)]
	_stations[def.id] = {
		"mat": mat, "base_color": color, "label": label, "base_text": def.label,
		"interacts": interacts,
	}

	# Slots and kettles hold a cup: show it and its steps on top.
	var is_slot := String(def.id).begins_with("slot")
	var is_kettle := String(def.id).begins_with("kettle")
	if is_slot or is_kettle:
		var cup_mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.2
		cyl.bottom_radius = 0.16
		cyl.height = 0.3
		cup_mesh.mesh = cyl
		cup_mesh.material_override = _mat(Color(0.3, 0.8, 0.9))
		cup_mesh.position = Vector3(0, 1.15, 0)
		cup_mesh.visible = false
		body.add_child(cup_mesh)
		var row := _make_step_row(1.55)
		body.add_child(row)
		if is_slot:
			_slots[def.id] = {"cup": [], "mesh": cup_mesh, "row": row, "shown": null}
		else:
			label.position.y = 2.35  # keep the brew timer clear of the step row
			_stations[def.id].merge({"cup_mesh": cup_mesh, "row": row, "shown": null})


func _build_barista() -> void:
	_barista = Node3D.new()
	_barista.position = Vector3(-1.75, 0, 0.75)
	add_child(_barista)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.2
	body.mesh = capsule
	body.material_override = _mat(Color(0.95, 0.95, 0.85))
	body.position.y = 0.6
	_barista.add_child(body)

	_barista_cup = MeshInstance3D.new()
	var cup := CylinderMesh.new()
	cup.top_radius = 0.15
	cup.bottom_radius = 0.12
	cup.height = 0.25
	_barista_cup.mesh = cup
	_barista_cup.material_override = _mat(Color(0.3, 0.8, 0.9))
	_barista_cup.position.y = 1.4
	_barista.add_child(_barista_cup)

	_barista_row = _make_step_row(1.85)
	_barista.add_child(_barista_row)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_hud_label = Label.new()
	_hud_label.position = Vector2(12, 8)
	_hud_label.add_theme_font_size_override("font_size", 22)
	layer.add_child(_hud_label)

	_hint_label = Label.new()
	_hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_hint_label.offset_top = 146
	_hint_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 26)
	_hint_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	_hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint_label.add_theme_constant_override("outline_size", 8)
	layer.add_child(_hint_label)


	_game_over_box = CenterContainer.new()
	_game_over_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_over_box.visible = false
	layer.add_child(_game_over_box)
	var panel := PanelContainer.new()
	_game_over_box.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	_game_over_label = Label.new()
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(_game_over_label)
	_again_button = Button.new()
	_again_button.text = "Ещё раз"
	_again_button.add_theme_font_size_override("font_size", 28)
	_again_button.pressed.connect(func() -> void: get_tree().reload_current_scene())
	vbox.add_child(_again_button)
	var new_day := Button.new()
	new_day.text = "Новый день (тест)"
	new_day.add_theme_font_size_override("font_size", 20)
	new_day.pressed.connect(_new_day)
	vbox.add_child(new_day)

	# The register: always on screen, in the free band above the kitchen.
	_register_bar = ProgressBar.new()
	_register_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_register_bar.offset_top = 104
	_register_bar.offset_bottom = 136
	_register_bar.offset_left = 12
	_register_bar.offset_right = -12
	_register_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.95, 0.75, 0.2)
	_register_bar.add_theme_stylebox_override("fill", fill)
	layer.add_child(_register_bar)
	_register_label = Label.new()
	_register_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_register_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_register_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_register_label.add_theme_font_size_override("font_size", 20)
	_register_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_register_label.add_theme_constant_override("outline_size", 6)
	_register_bar.add_child(_register_label)

	# Boost panel: stands in for paid upgrades, adjustable mid-round.
	var boosts := VBoxContainer.new()
	boosts.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	boosts.offset_top = -120
	boosts.offset_bottom = -16
	boosts.offset_left = 12
	boosts.offset_right = -12
	boosts.add_theme_constant_override("separation", 8)
	layer.add_child(boosts)
	_boost_register_label = _add_boost_row(boosts, func(d: int) -> void:
		_register_level = clampi(_register_level + d, 0, TUNING.register_levels.size() - 1))
	_boost_speed_label = _add_boost_row(boosts, func(d: int) -> void:
		_speed_level = clampi(_speed_level + d, 0, TUNING.speed_levels.size() - 1))


## One "label [-] [+]" row; change(delta) applies the step.
func _add_boost_row(parent: Control, change: Callable) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 22)
	row.add_child(label)
	for d in [-1, 1]:
		var b := Button.new()
		b.text = "−" if d < 0 else "+"
		b.custom_minimum_size = Vector2(64, 44)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(change.bind(d))
		row.add_child(b)
	return label


## Adds a box to parent: child 0 is the collider (if requested), then the mesh.
## Callers read the mesh as get_child(1), so pickable boxes need with_collider.
func _add_box(parent: Node3D, size: Vector3, offset: Vector3, color: Color, with_collider: bool) -> void:
	if with_collider:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		shape.position = offset
		parent.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _mat(color)
	mesh.position = offset
	parent.add_child(mesh)


## Frames the whole kitchen in any window shape: fit by width on portrait
## screens, by height on wider ones (desktop browser), so nothing is cut off.
func _fit_camera() -> void:
	var view := get_viewport().get_visible_rect().size
	if view.x / view.y > DESIGN_ASPECT:
		_camera.keep_aspect = Camera3D.KEEP_HEIGHT
		_camera.size = CAMERA_VIEW_WIDTH / DESIGN_ASPECT
	else:
		_camera.keep_aspect = Camera3D.KEEP_WIDTH
		_camera.size = CAMERA_VIEW_WIDTH


## A row of coloured squares that always faces the camera and draws on top.
func _make_step_row(height: float) -> Node3D:
	var row := Node3D.new()
	row.position.y = height
	row.rotation_degrees.x = -CAMERA_PITCH_DEG
	return row


func _fill_step_row(row: Node3D, steps: Array) -> void:
	for child in row.get_children():
		child.queue_free()
	if steps.is_empty():
		return
	var size := 0.3
	var gap := 0.06
	var width := steps.size() * size + (steps.size() - 1) * gap
	row.add_child(_row_quad(Vector2(width + 0.12, size + 0.12), Vector3(0, 0, -0.01), Color(0.1, 0.08, 0.07)))
	for i in steps.size():
		var x := -width / 2.0 + size / 2.0 + i * (size + gap)
		row.add_child(_row_quad(Vector2(size, size), Vector3(x, 0, 0), STEP_COLORS[steps[i]]))


func _row_quad(size: Vector2, offset: Vector3, color: Color) -> MeshInstance3D:
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = size
	quad.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.no_depth_test = true
	m.render_priority = 1 if offset.z == 0.0 else 0
	quad.material_override = m
	quad.position = offset
	return quad


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m


func _label3d(text: String, size: int) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = 10
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	return l


func _flash(mat: StandardMaterial3D, base: Color) -> void:
	mat.albedo_color = Color(1.0, 0.15, 0.15)
	create_tween().tween_property(mat, "albedo_color", base, 0.6)


var _hint_tween: Tween

## Shows why a tap did nothing, fading out after a moment.
func _show_hint(text: String) -> void:
	_hint_label.text = text
	_hint_label.modulate.a = 1.0
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_interval(1.2)
	_hint_tween.tween_property(_hint_label, "modulate:a", 0.0, 0.4)


func _why_not(id: String) -> String:
	var name: String = _stations[id].base_text
	if id in _slots:
		return "Нечего поставить — руки пустые"
	match id:
		"cups":
			return "Руки заняты — поставь чашку в слот или выкинь"
		"thermos", "leaf":
			return "Сначала возьми чашку" if _held.is_empty() else "%s: нужна пустая чашка" % name
		"additive":
			return "Добавка: нужна чашка с листом и водой 80°"
		"trash":
			return "Руки пустые"
		"kettle100", "kettle80":
			if _kettles[id].state == "empty":
				return "%s: нужна чашка с листом" % name
			return "%s занят — для замены нужна чашка с листом" % name
	return "Нельзя"


## Dev aid: `-- --shot=/path.png` saves a frame after a few seconds and quits.
func _maybe_take_screenshot() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			await get_tree().create_timer(9.0).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--shot="))
			get_tree().quit()
