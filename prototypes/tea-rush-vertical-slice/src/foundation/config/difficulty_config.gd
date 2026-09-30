# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Resource
## Ease-in difficulty ramp (difficulty-curve-session-pacing.md).

@export var ramp_duration: float = NAN
@export var curve_exponent: float = NAN
@export var guests_per_minute_start: float = NAN
@export var guests_per_minute_end: float = NAN
@export var patience_max_start: float = NAN
@export var patience_max_end: float = NAN
@export var complex_share_start: float = NAN
@export var complex_share_end: float = NAN
