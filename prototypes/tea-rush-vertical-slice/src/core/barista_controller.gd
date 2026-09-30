# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Idle / Walking / Holding (player-control-barista-movement.md). Last tap wins,
## no queue. In Holding the target owner is offered the action every step and
## answers EXECUTE, WAIT or REFUSE.

signal target_changed(target: Dictionary)   # {} = no target
signal arrived_floor(point: Vector3)

enum State { IDLE, WALKING, HOLDING }
enum Reply { EXECUTE, WAIT, REFUSE }

var position: Vector3
var facing := Vector2(0, 1)   # XZ direction of the last movement
var state := State.IDLE
var target := {}

var _path := PackedVector3Array()
var _layout: RefCounted
var _pathing: RefCounted
var _cfg: Resource
## Owner router: is_valid(target) -> bool (shows its own refusal), offer(target) -> Reply.
var _router: Object


func _init(layout: RefCounted, pathing: RefCounted, control_cfg: Resource, router: Object) -> void:
	_layout = layout
	_pathing = pathing
	_cfg = control_cfg
	_router = router
	position = layout.cfg.barista_start


func speed() -> float:
	return _cfg.base_walk_speed * _cfg.speed_multiplier


func reset() -> void:
	position = _layout.cfg.barista_start
	facing = Vector2(0, 1)
	_set_idle()


## An accepted tap redirects immediately from the current position.
func tap(t: Dictionary) -> void:
	if t.kind == &"floor":
		var r: Dictionary = _pathing.path(position, t.point)
		if r.points.is_empty():
			return
		_path = r.points
		target = {"kind": &"floor", "point": r.points[-1]}
		state = State.WALKING
		target_changed.emit(target)
		return
	if state == State.HOLDING and _same(t, target):
		_router.is_valid(t)  # re-check shows refusal if needed; holding continues
		return
	if not _router.is_valid(t):
		return  # rejected: current order continues untouched
	var spots: Array = [_layout.guest_serve_points[t.id]] if t.kind == &"guest" else _layout.stations[t.id].spots
	var r: Dictionary = _pathing.shortest_to(position, spots)
	if r.is_empty() or not r.reached:
		push_error("no path to target %s" % [t])
		return
	_path = r.points
	target = t.duplicate()
	state = State.WALKING if not _path.is_empty() else State.HOLDING
	target_changed.emit(target)


func step(dt: float) -> void:
	if state == State.WALKING:
		var left := speed() * dt
		while left > 0.0 and not _path.is_empty():
			var to := _path[0]
			var d := position.distance_to(to)
			if d > 0.0001:
				facing = Vector2(to.x - position.x, to.z - position.z).normalized()
			if d <= left:
				position = to
				left -= d
				_path.remove_at(0)
			else:
				position = position.move_toward(to, left)
				left = 0.0
		if _path.is_empty():
			if target.kind == &"floor":
				arrived_floor.emit(position)
				_set_idle()
				return
			state = State.HOLDING
	if state == State.HOLDING:
		match _router.offer(target):
			Reply.EXECUTE, Reply.REFUSE:
				_set_idle()


## The guest we were heading to left or was served by someone else.
func on_target_vanished(guest_slot: int) -> void:
	if not target.is_empty() and target.kind == &"guest" and target.id == guest_slot:
		_set_idle()


func stop() -> void:
	_set_idle()


func is_waiting() -> bool:
	return state == State.HOLDING


func _set_idle() -> void:
	var had := not target.is_empty()
	state = State.IDLE
	target = {}
	_path = PackedVector3Array()
	if had:
		target_changed.emit(target)


func _same(a: Dictionary, b: Dictionary) -> bool:
	return not b.is_empty() and a.kind == b.kind and a.get("id") == b.get("id")
