# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Wall-clock UTC seconds; the only gameplay-side reader of system time.
## Tests replace it by setting `fake_now`.

var fake_now := -1


func now_unix() -> int:
	return fake_now if fake_now >= 0 else int(Time.get_unix_time_from_system())
