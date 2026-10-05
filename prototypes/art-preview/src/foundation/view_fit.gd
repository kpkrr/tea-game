# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30 (art-preview: painted plate + matched perspective camera, ADR-0002 amendment 2026-10-01)
extends Node
## The kitchen is a painted plate rendered for ONE camera (tools/blockout.gd, yaw 0,
## pitch 52, fov 30, 768x1376 frame). The plate is zoomed onto the work area and
## the camera keeps that exact pose; an off-axis frustum shows the same window of
## the plate, so 3D sprites land on the painted pixels at any aspect.

signal playfield_changed(playfield: Rect2, kitchen_rect: Rect2)

const ViewFitMath := preload("view_fit_math.gd")
const PLATE_PX := Vector2(2304, 3456)          # art/plate.png (plate-v14, GPT outpaint of the v9 frame)
# Wide backdrop (art/plate_wide.png, GPT outpaint) spans these plate px around the plate.
const WIDE_PX := Rect2(-1920, 0, 6144, 3456)
const CAM_PX := Rect2(384, 704, 1536, 2752)      # the original v9 frame inside it; camera calibrated on it (pitch 43, fov 30, D 27.4)
const WORK_PX := Rect2(404, 1444, 1490, 1330)      # plate px: stations, counters, guest row
const SCENE_PX := Rect2(184, 854, 1936, 2550)      # plate px: kitchen + cliffs, water, stairs, terrace (desktop)
const PLATE_FOV := 30.0
const PLATE_PITCH := 43.0
const PLATE_DISTANCE := 27.4
const PLATE_V_OFFSET := 0.0

## Dev aid (`--shift-y=px`): forces the plate + camera shift (overrides the automatic one).
static var dev_shift_y := -1.0
# UI s7 (design/ux/ui-redesign-s7-port.md section 5): when the hanging order plaques would cover the
# kitchen (wide screens), plate + camera move down - never a blurred fill. The kitchen top is the
# top of the back-row station signs: painted item tops (phone reference 360x800: y = 315 dp) - 38 dp.
const SHIFT_REF_VP := Vector2(360, 800)
const ITEM_TOP_REF_DP := 315.0      # art/ui_s7/masks: min top of cups / leaf jars in the 360x800 frame
const SIGN_ABOVE_ITEM_DP := 38.0    # board 36 dp + 3 dp gap - 1 dp (mock10.base3)
const UI_BOTTOM_DP := 160.0         # order plaques + stickers bottom (68 bar + 30 + 4 + 56 + ~2)
const SHIFT_MARGIN_DP := 40.25      # calibrated: 1024x640 (1280x800 window) -> 89 dp, the owner-approved frame (s7c)

var kitchen_rect := Rect2()
var playfield := Rect2()
var scale := 1.0
var plate_rect := Rect2()   # where the plate is drawn, in viewport dp

var _camera: Camera3D
var _cfg: Resource


func setup(camera: Camera3D, view_cfg: Resource) -> void:
	_camera = camera
	_cfg = view_cfg
	var basis := ViewFitMath.camera_basis(PLATE_PITCH, 0.0)
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.far = view_cfg.camera_far_m
	_camera.near = 5.0
	_camera.basis = basis
	_camera.position = view_cfg.camera_look_at + basis.z * PLATE_DISTANCE
	_camera.v_offset = PLATE_V_OFFSET


func apply(safe: Rect2) -> void:
	var vp := get_viewport().get_visible_rect().size
	var xf := plate_xform(vp)
	var s := xf.get_scale().x
	plate_rect = Rect2(xf.origin, PLATE_PX * s)
	# Visible window of the plate (plate px) -> off-axis frustum of the plate camera.
	var win := Rect2(-xf.origin / s, vp / s)
	var unit := 2.0 * _camera.near * tan(deg_to_rad(PLATE_FOV) / 2.0) / CAM_PX.size.y   # near-plane metres per plate px
	_camera.projection = Camera3D.PROJECTION_FRUSTUM
	_camera.size = win.size.y * unit
	var c := win.get_center() - CAM_PX.get_center()
	_camera.frustum_offset = Vector2(c.x, -c.y) * unit
	playfield = ViewFitMath.playfield(safe, _cfg.viewport_aspect_min, _cfg.viewport_aspect_max)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in 8:
		var p := _camera.unproject_position(_cfg.frame_bounds.get_endpoint(i))
		lo = lo.min(p)
		hi = hi.max(p)
	kitchen_rect = Rect2(lo, hi - lo).intersection(Rect2(Vector2.ZERO, vp))
	scale = s
	playfield_changed.emit(playfield, kitchen_rect)


## Plate px -> viewport dp. The work area (all stations, counters, guest row) always
## fits the screen on both axes. Where the plate is larger than the screen it is
## cropped around the work area; where it is smaller (tall phones: height, desktop
## windows: width) the gap is filled by a blurred copy (KitchenView). Tall screens
## bottom-align the plate so the gap sits at the top, behind the HUD.
static func plate_xform(vp: Vector2, shift := NAN) -> Transform2D:
	var xf := _base_xform(vp)
	if is_nan(shift):
		shift = shift_y(vp)
	xf.origin.y += shift
	return xf


## Vertical shift (dp) of plate + camera for this viewport.
static func shift_y(vp: Vector2) -> float:
	var forced := _shift_y()
	if forced > 0.0:
		return forced
	var ref := _base_xform(SHIFT_REF_VP)
	var item_plate_y := (ITEM_TOP_REF_DP - ref.origin.y) / ref.get_scale().y
	var xf := _base_xform(vp)
	var kitchen_top := xf.origin.y + item_plate_y * xf.get_scale().y - SIGN_ABOVE_ITEM_DP
	return maxf(0.0, UI_BOTTOM_DP + SHIFT_MARGIN_DP - kitchen_top)


static func _base_xform(vp: Vector2) -> Transform2D:
	# Phones frame the work area; wide (desktop) windows blend toward the whole
	# scene — cliffs, water, terrace — so the kitchen is smaller but the mood shows.
	var t := clampf((vp.x / vp.y - 0.6) / 0.4, 0.0, 1.0)
	var r := Rect2(WORK_PX.position.lerp(SCENE_PX.position, t), WORK_PX.size.lerp(SCENE_PX.size, t))
	var s := minf(vp.x / r.size.x, vp.y / r.size.y)
	# Never leave empty margins: the plate (outpainted on all sides) always covers the screen.
	s = maxf(s, maxf(vp.x / WIDE_PX.size.x, vp.y / PLATE_PX.y))
	var o := vp / 2.0 - r.get_center() * s
	if PLATE_PX.x * s >= vp.x:
		o.x = clampf(o.x, vp.x - PLATE_PX.x * s, 0.0)
	else:   # wider than the plate: the wide backdrop continues it; keep the work area centred inside the backdrop
		o.x = clampf(o.x, vp.x - WIDE_PX.end.x * s, -WIDE_PX.position.x * s)
	if PLATE_PX.y * s >= vp.y:
		o.y = clampf(o.y, vp.y - PLATE_PX.y * s, 0.0)
	else:
		o.y = vp.y - PLATE_PX.y * s
	return Transform2D(0.0, Vector2(s, s), 0.0, o)


static func _shift_y() -> float:
	if dev_shift_y < 0.0:
		dev_shift_y = 0.0
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--shift-y="):
				dev_shift_y = float(arg.trim_prefix("--shift-y="))
	return dev_shift_y


func get_camera_position() -> Vector3:
	return _camera.position
