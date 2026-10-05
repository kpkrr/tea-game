# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30 (art-preview: perspective diorama camera, ADR-0002 amendment 2026-10-01)
extends RefCounted
## Pure screen-fit math (ADR-0002). 1 viewport unit = 1 dp.
## Perspective camera: fixed fov/pitch/yaw; only the distance D along the view
## axis and h_offset/v_offset are solved (amendment 2026-10-01, points 1-2).


## Playfield: the safe area clamped to aspect [amin, amax], centred.
static func playfield(safe: Rect2, amin: float, amax: float) -> Rect2:
	var size := safe.size
	var aspect := size.x / maxf(size.y, 1.0)
	if aspect < amin:
		size.y = size.x / amin
	elif aspect > amax:
		size.x = size.y * amax
	return Rect2(safe.get_center() - size / 2.0, size)


## Camera basis: x = right, y = up, z = -forward (Godot looks down -Z).
static func camera_basis(pitch_deg: float, yaw_deg: float) -> Basis:
	return Basis.from_euler(Vector3(-deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0.0), EULER_ORDER_YXZ)


## Screen point (dp) of a world point for distance d and offsets a, b.
static func project(p: Vector3, d: float, a: float, b: float, look_at: Vector3, basis: Basis, k: float, viewport: Vector2) -> Vector2:
	var q := p - look_at
	var z := -q.dot(basis.z) + d
	return Vector2(viewport.x / 2.0 + k * (q.dot(basis.x) - a) / z, viewport.y / 2.0 - k * (q.dot(basis.y) - b) / z)


static func _rect(corners: Array[Vector3], d: float, a: float, b: float, look_at: Vector3, basis: Basis, k: float, viewport: Vector2) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c in corners:
		var s := project(c, d, a, b, look_at, basis, k, viewport)
		lo = lo.min(s)
		hi = hi.max(s)
	return Rect2(lo, hi - lo)


static func _solve_d(corners: Array[Vector3], a: float, b: float, look_at: Vector3, basis: Basis, k: float,
		viewport: Vector2, fit_rect: Rect2, fill: float, d_lo: float) -> float:
	var lo := d_lo
	var hi := 1000.0
	for i in 32:
		var mid := (lo + hi) / 2.0
		var r := _rect(corners, mid, a, b, look_at, basis, k, viewport)
		var f := maxf(r.size.x / fit_rect.size.x, r.size.y / fit_rect.size.y)
		if f > fill:
			lo = mid
		else:
			hi = mid
	return (lo + hi) / 2.0


## Solve D, h/v offsets for one fit rect: {distance, h_offset, v_offset, near, kitchen_rect, depth_range}.
static func solve_camera(viewport: Vector2, fit_rect: Rect2, bounds: AABB, look_at: Vector3, basis: Basis,
		fov_deg: float, fill: float) -> Dictionary:
	var k := viewport.y / (2.0 * tan(deg_to_rad(fov_deg) / 2.0))
	var corners: Array[Vector3] = []
	var d_lo := 0.0
	for i in 8:
		corners.append(bounds.get_endpoint(i))
		d_lo = maxf(d_lo, 0.5 + (corners[i] - look_at).dot(basis.z))
	var a := 0.0
	var b := 0.0
	var d := 0.0
	for pass_i in 3:
		d = _solve_d(corners, a, b, look_at, basis, k, viewport, fit_rect, fill, d_lo)
		var e := fit_rect.get_center() - _rect(corners, d, a, b, look_at, basis, k, viewport).get_center()
		a -= e.x * d / k
		b += e.y * d / k
	d = _solve_d(corners, a, b, look_at, basis, k, viewport, fit_rect, fill, d_lo)
	var zr := Vector2(INF, -INF)
	for c in corners:
		var z := -(c - look_at).dot(basis.z) + d
		zr = Vector2(minf(zr.x, z), maxf(zr.y, z))
	return {
		"distance": d, "h_offset": a, "v_offset": b, "near": maxf(0.1, 0.5 * zr.x),
		"kitchen_rect": _rect(corners, d, a, b, look_at, basis, k, viewport), "depth_range": zr, "k": k,
	}


## Full fit with the Mode C rule: {playfield, fit_rect, camera (solve_camera dict), kitchen_rect, scale, reserved}.
static func fit(viewport: Vector2, safe: Rect2, bounds: AABB, look_at: Vector3, basis: Basis, fov_deg: float,
		amin: float, amax: float, fill: float, min_strip: float) -> Dictionary:
	var pf := playfield(safe, amin, amax)
	var fit_rect := pf
	var cam := solve_camera(viewport, fit_rect, bounds, look_at, basis, fov_deg, fill)
	var reserved: bool = cam.kitchen_rect.position.y - pf.position.y < min_strip
	if reserved:
		# Mode C: near-square screens reserve a HUD strip at the top.
		fit_rect = Rect2(pf.position + Vector2(0, min_strip), pf.size - Vector2(0, min_strip))
		cam = solve_camera(viewport, fit_rect, bounds, look_at, basis, fov_deg, fill)
	return {
		"playfield": pf, "fit_rect": fit_rect, "camera": cam, "kitchen_rect": cam.kitchen_rect,
		"scale": cam.k / cam.distance, "reserved": reserved,
	}


## Per-sprite upright stretch: 1 / cos(elevation of the ray camera -> pivot) (amendment point 4).
static func upright_stretch(camera_pos: Vector3, pivot: Vector3) -> float:
	var r := (pivot - camera_pos).normalized()
	return 1.0 / maxf(sqrt(1.0 - r.y * r.y), 0.2)
