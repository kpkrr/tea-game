# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Pure screen-fit math (ADR-0002). 1 viewport unit = 1 dp.


## Playfield: the safe area clamped to aspect [amin, amax], centred.
static func playfield(safe: Rect2, amin: float, amax: float) -> Rect2:
	var size := safe.size
	var aspect := size.x / maxf(size.y, 1.0)
	if aspect < amin:
		size.y = size.x / amin
	elif aspect > amax:
		size.x = size.y * amax
	return Rect2(safe.get_center() - size / 2.0, size)


## Frame bounds projected onto the camera's right/up axes: {size: F, center: c}
## with c relative to the camera axis.
static func project_frame(bounds: AABB, cam_pos: Vector3, pitch_deg: float) -> Dictionary:
	var p := deg_to_rad(pitch_deg)
	var up := Vector3(0, cos(p), -sin(p))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in 8:
		var q := bounds.get_endpoint(i) - cam_pos
		var v := Vector2(q.x, q.dot(up))
		lo = lo.min(v)
		hi = hi.max(v)
	return {"size": hi - lo, "center": (hi + lo) / 2.0}


## Full fit: {playfield, fit_rect, scale (dp per metre), size (ortho), h_offset, v_offset, kitchen_rect, reserved}.
static func fit(viewport: Vector2, safe: Rect2, frame: Dictionary, amin: float, amax: float,
		fill: float, min_strip: float) -> Dictionary:
	var pf := playfield(safe, amin, amax)
	var f: Vector2 = frame.size
	var fit_rect := pf
	var s := fill * minf(pf.size.x / f.x, pf.size.y / f.y)
	var top0 := (pf.size.y - f.y * s) / 2.0
	var reserved := top0 < min_strip
	if reserved:
		# Mode C: near-square screens reserve a HUD strip at the top.
		fit_rect = Rect2(pf.position + Vector2(0, min_strip), pf.size - Vector2(0, min_strip))
		s = fill * minf(fit_rect.size.x / f.x, fit_rect.size.y / f.y)
	var c: Vector2 = frame.center
	var centre := fit_rect.get_center()
	return {
		"playfield": pf,
		"fit_rect": fit_rect,
		"scale": s,
		"size": viewport.y / s,
		"h_offset": c.x - (centre.x - viewport.x / 2.0) / s,
		"v_offset": c.y + (centre.y - viewport.y / 2.0) / s,
		"kitchen_rect": Rect2(centre - f * s / 2.0, f * s),
		"reserved": reserved,
	}
