# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Resource
## Static kitchen layout (kitchen-station-layout.md). Positions are world XZ metres.
## stations: {id, type, pos: Vector2, size: Vector2, side, top}; type "slot" = empty cup slot.
## walls / countertops: {pos: Vector2, size: Vector2} — walls block nav, countertops are visual.

@export var stations: Array = []
@export var walls: Array = []
@export var countertops: Array = []
@export var countertop_height: float = NAN
@export var front_counter: Dictionary = {}
@export var floor_rect: Rect2 = Rect2(NAN, NAN, 0, 0)
@export var nav_rect: Rect2 = Rect2(NAN, NAN, 0, 0)
@export var guest_slot_x: PackedFloat32Array = PackedFloat32Array()
@export var guest_z: float = NAN
@export var serve_z: float = NAN
@export var guest_spawn_x: float = NAN
@export var guest_exit_x: float = NAN
@export var barista_start: Vector3 = Vector3(NAN, NAN, NAN)
@export var till_anchor: Vector3 = Vector3(NAN, NAN, NAN)
## Every non-slot station type must be a recipe step (order-recipe-system.md).
@export var station_types: PackedStringArray = PackedStringArray()
