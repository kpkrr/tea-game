# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Pure functions of match time (difficulty-curve-session-pacing.md Formulas 1-4).


static func progress(d: Resource, t: float) -> float:
	return pow(clampf(t / d.ramp_duration, 0.0, 1.0), d.curve_exponent)


static func guests_per_minute(d: Resource, t: float) -> float:
	var v: float = lerpf(d.guests_per_minute_start, d.guests_per_minute_end, progress(d, t))
	return v if v > 0.0 else d.guests_per_minute_start


static func patience_max(d: Resource, t: float) -> float:
	var v: float = lerpf(d.patience_max_start, d.patience_max_end, progress(d, t))
	return v if v > 0.0 else d.patience_max_start


static func complex_order_share(d: Resource, t: float) -> float:
	return clampf(lerpf(d.complex_share_start, d.complex_share_end, progress(d, t)), 0.0, 1.0)
