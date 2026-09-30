# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Resource
## Guest flow, patience and lives (guest-ai-patience.md).

@export var guest_slot_count: int = -1
@export var max_guests_lost: int = -1
@export var onboarding_factor: float = NAN
@export var onboarding_duration: float = NAN
@export var medium_share_of_remaining: float = NAN
@export var patience_warn_threshold: float = NAN
@export var patience_urgent_threshold: float = NAN
@export var guest_walk_speed: float = NAN
@export var max_step_delta: float = NAN
