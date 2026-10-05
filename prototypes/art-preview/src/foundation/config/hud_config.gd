# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends Resource
## HUD and feedback timings (design/ux/hud.md). Times in seconds.

@export var hud_row_height_dp: int = -1
@export var hud_button_size_dp: int = -1
@export var hud_margin_dp: int = -1
@export var score_digit_height_dp: int = -1
@export var score_display_cap: int = -1
@export var strike_icon_dp: int = -1
@export var price_label_scale: float = NAN
@export var approaching_token_scale: float = NAN
@export var leaving_pulse_s: float = NAN
@export var strike_pulse_s: float = NAN
@export var leaving_pulse_stagger_s: float = NAN
@export var popup_s: float = NAN
@export var popup_max_concurrent: int = -1
@export var pause_dim_alpha: float = NAN
@export var results_fade_s: float = NAN
@export var restart_input_grace_s: float = NAN
@export var flash_s: float = NAN
@export var marker_s: float = NAN
