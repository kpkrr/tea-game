# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Resource
## Viewport fit and HUD strip knobs (ADR-0002). Sentinels mark missing values.

@export var viewport_aspect_min: float = NAN
@export var viewport_aspect_max: float = NAN
@export var kitchen_fill_target: float = NAN
@export var playfield_min_fill: float = NAN
@export var min_tap_target: int = -1
@export var hud_min_strip_dp: int = -1
@export var camera_pitch_deg: float = NAN
@export var camera_position: Vector3 = Vector3(NAN, NAN, NAN)
@export var camera_look_at: Vector3 = Vector3(NAN, NAN, NAN)
## World AABB that must stay visible (floor, counters, sprite tops, guests, till).
@export var frame_bounds: AABB = AABB(Vector3(NAN, NAN, NAN), Vector3.ZERO)
@export var background_color: Color = Color(NAN, NAN, NAN)
