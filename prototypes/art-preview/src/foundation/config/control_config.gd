# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Resource
## Barista movement and tap picking (player-control-barista-movement.md, ADR-0006).

@export var base_walk_speed: float = NAN
@export var speed_multiplier: float = NAN
@export var work_gap: float = NAN
@export var clearance_margin: float = NAN
@export var agent_radius: float = NAN
@export var pick_radius_factor: float = NAN
@export var path_end_tolerance: float = NAN
@export var guest_anchor_height: float = NAN
