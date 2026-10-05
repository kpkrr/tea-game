# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Seeded random stream (ADR-0004). Named streams derive their seed with
## splitmix64 so guest tier and recipe rolls never share a sequence.

var _rng := RandomNumberGenerator.new()
## When non-empty, randf() pops from here (test injection).
var fake_values: Array[float] = []


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value


static func derive(match_seed: int, stream: String) -> int:
	return splitmix64(match_seed ^ stream.hash())


static func splitmix64(x: int) -> int:
	x = x + -7046029254386353131  # 0x9E3779B97F4A7C15
	x = (x ^ ((x >> 30) & 0x3FFFFFFFF)) * -4658895280553007687  # 0xBF58476D1CE4E5B9
	x = (x ^ ((x >> 27) & 0x1FFFFFFFFF)) * -7723592293110705685  # 0x94D049BB133111EB
	return x ^ ((x >> 31) & 0x1FFFFFFFF)


## Uniform in [0, 1).
func randf() -> float:
	if not fake_values.is_empty():
		return fake_values.pop_front()
	return minf(_rng.randf(), 0.99999994)


func randi_range(from: int, to: int) -> int:
	return clampi(from + floori(randf() * (to - from + 1)), from, to)
