# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Daily till (till-day-cycle.md): fills to capacity, then Full until the first
## 00:00 UTC after it filled. Full never blocks play; score keeps counting.

signal coins_added(amount: int, earned: int)
signal became_full()
signal was_reset()

const DAY := 86400

var till_amount: int:
	get: return _amount
var till_capacity: int:
	get: return _cfg.till_capacity
var is_full: bool:
	get: return _full
## Coins that actually entered the till during the current match.
var match_added: int:
	get: return _match_added

var _cfg: Resource
var _scope: RefCounted
var _utc: RefCounted
var _amount := 0
var _full := false
var _full_since := 0
var _match_added := 0


func _init(till_cfg: Resource, scope: RefCounted, utc: RefCounted) -> void:
	_cfg = till_cfg
	_scope = scope
	_utc = utc
	scope.declare_int("amount", 0, 0, till_cfg.till_capacity)
	scope.declare_string("day_state", "open", PackedStringArray(["open", "full"]))
	scope.declare_int("full_since_utc", 0, 0, 1 << 40)
	_amount = scope.read_int("amount")
	_full = scope.read_string("day_state") == "full"
	_full_since = scope.read_int("full_since_utc")
	# Repair inconsistent saves toward defaults.
	if _full and (_amount != till_capacity or _full_since == 0):
		_full = _amount == till_capacity
		_full_since = _utc.now_unix() if _full else 0
	if not _full:
		_full_since = 0
	_save()
	check_reset()  # cold start


func fill_ratio() -> float:
	return float(_amount) / till_capacity


func on_coins_earned(n: int) -> void:
	var before := _amount
	_amount = mini(_amount + n, till_capacity)
	_match_added += _amount - before
	coins_added.emit(_amount - before, n)
	if not _full and _amount == till_capacity:
		_full = true
		_full_since = _utc.now_unix()
		became_full.emit()
	_save()


func on_match_started() -> void:
	_match_added = 0
	check_reset()


## Resets a Full till once the first daily reset moment after filling has passed
## (many missed days = one reset). Called only at match start and cold start.
func check_reset() -> void:
	if not _full:
		return
	var hour: int = _cfg.daily_reset_time_utc * 3600
	var next_reset := (floori(float(_full_since - hour) / DAY) + 1) * DAY + hour
	if _utc.now_unix() >= next_reset:
		_amount = 0
		_full = false
		_full_since = 0
		_save()
		was_reset.emit()


## Debug only: the "new day" button for demos.
func debug_new_day() -> void:
	_amount = 0
	_full = false
	_full_since = 0
	_save()
	was_reset.emit()


func _save() -> void:
	_scope.write_int("amount", _amount)
	_scope.write_string("day_state", "full" if _full else "open")
	_scope.write_int("full_since_utc", _full_since)
