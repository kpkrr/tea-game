# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Node
## Applies ViewFitMath to the camera on every safe-area change and tells the HUD
## where the playfield and kitchen are. Never touches match state.

signal playfield_changed(playfield: Rect2, kitchen_rect: Rect2)

const ViewFitMath := preload("view_fit_math.gd")

var kitchen_rect := Rect2()
var playfield := Rect2()
var scale := 1.0

var _camera: Camera3D
var _cfg: Resource
var _frame: Dictionary


func setup(camera: Camera3D, view_cfg: Resource) -> void:
	_camera = camera
	_cfg = view_cfg
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.position = view_cfg.camera_position
	_camera.look_at_from_position(view_cfg.camera_position, view_cfg.camera_look_at)
	_frame = ViewFitMath.project_frame(view_cfg.frame_bounds, view_cfg.camera_position, view_cfg.camera_pitch_deg)


func apply(safe: Rect2) -> void:
	var viewport := get_viewport().get_visible_rect().size
	var r := ViewFitMath.fit(viewport, safe, _frame, _cfg.viewport_aspect_min, _cfg.viewport_aspect_max,
		_cfg.kitchen_fill_target, _cfg.hud_min_strip_dp)
	_camera.size = r.size
	_camera.h_offset = r.h_offset
	_camera.v_offset = r.v_offset
	kitchen_rect = r.kitchen_rect
	playfield = r.playfield
	scale = r.scale
	playfield_changed.emit(playfield, kitchen_rect)
