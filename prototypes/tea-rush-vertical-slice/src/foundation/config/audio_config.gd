# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Resource
## Music and mix (hud.md Audio, ADR-0001).

@export var music_path: String = ""
@export var music_file_name: String = ""
@export var music_lowpass_cutoff_hz: float = NAN
@export var music_lowpass_ramp_s: float = NAN
@export var music_volume_db: float = NAN
@export var sfx_volume_db: float = NAN
