# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Derived kitchen geometry: work spots, pick anchors and hit boxes, all from
## KitchenConfig. IDs only — no nodes cross module boundaries.

var stations := {}        # id -> {id, type, pos: Vector2, size, side, top, spots: Array[Vector3], anchor: Vector3, box: AABB}
var station_ids: Array[StringName] = []
var slot_ids: Array[StringName] = []
var kettle_ids: Array[StringName] = []
var guest_serve_points: Array[Vector3] = []
var guest_anchors: Array[Vector3] = []
var guest_boxes: Array[AABB] = []
var blockers: Array[AABB] = []   # countertops, walls, front counter, till: taps there = floor
var cfg: Resource


func _init(kitchen_cfg: Resource, control_cfg: Resource) -> void:
	cfg = kitchen_cfg
	var reach: float = 0.5 + control_cfg.work_gap
	for s: Dictionary in kitchen_cfg.stations:
		var id := StringName(s.id)
		var pos: Vector2 = s.pos
		var dir: Vector3
		match String(s.side):
			"back": dir = Vector3(0, 0, 1)
			"left", "island_right": dir = Vector3(1, 0, 0)
			"right", "island_left": dir = Vector3(-1, 0, 0)
		var half_reach: float = (s.size.x if dir.x != 0.0 else s.size.y) / 2.0 - 0.5 + reach
		var st := {
			"id": id, "type": StringName(s.type), "pos": pos, "size": s.size, "side": s.side, "top": float(s.top),
			"spots": [Vector3(pos.x, 0, pos.y) + dir * half_reach],
			"anchor": Vector3(pos.x, s.top, pos.y),
			"box": AABB(Vector3(pos.x - s.size.x / 2.0, 0, pos.y - s.size.y / 2.0), Vector3(s.size.x, s.top, s.size.y)),
		}
		stations[id] = st
		station_ids.append(id)
		if st.type == &"slot":
			slot_ids.append(id)
		elif String(st.type).begins_with("water_"):
			kettle_ids.append(id)
	station_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	var h: float = kitchen_cfg.countertop_height
	for c: Dictionary in kitchen_cfg.countertops:
		blockers.append(AABB(Vector3(c.pos.x - c.size.x / 2.0, 0, c.pos.y - c.size.y / 2.0), Vector3(c.size.x, h, c.size.y)))
	var fc: Dictionary = kitchen_cfg.front_counter
	blockers.append(AABB(Vector3(fc.pos.x - fc.size.x / 2.0, 0, fc.pos.y - fc.size.y / 2.0), Vector3(fc.size.x, fc.height, fc.size.y)))
	for i in kitchen_cfg.guest_slot_x.size():
		var x: float = kitchen_cfg.guest_slot_x[i]
		guest_serve_points.append(Vector3(x, 0, kitchen_cfg.serve_z))
		guest_anchors.append(Vector3(x, control_cfg.guest_anchor_height, kitchen_cfg.guest_z))
		guest_boxes.append(AABB(Vector3(x - 0.45, 0, kitchen_cfg.guest_z - 0.4), Vector3(0.9, 1.6, 0.8)))


func station_type(id: StringName) -> StringName:
	return stations[id].type


## Nav obstacles: station and wall footprints as Rect2 on XZ.
func footprints() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for id: StringName in station_ids:
		var s: Dictionary = stations[id]
		out.append(Rect2(s.pos - s.size / 2.0, s.size))
	for w: Dictionary in cfg.walls:
		out.append(Rect2(w.pos - w.size / 2.0, w.size))
	return out
