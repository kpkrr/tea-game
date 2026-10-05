# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-10-01
extends RefCounted
## Playtest measurement for /balance-check till-day-cycle (2026-10-01): per
## match game-time length, guests served/lost, coins earned (before the till
## clamp); per till day, matches played and when the till filled. Shown on the
## results screen (iPhone has no console), printed, and on desktop appended to
## user://playtest_log.csv. Not a GDD feature.

const CSV_PATH := "user://playtest_log.csv"

var _scope: RefCounted
var _till: RefCounted
var _served := 0
var _lost := 0
var _earned := 0
var _day_matches := 0
var _day_play_s := 0
var _fill_match := 0
var _fill_play_s := 0
var _last_amount := 0


func _init(scope: RefCounted, till: RefCounted) -> void:
	_scope = scope
	_till = till
	scope.declare_int("day_matches", 0, 0, 1_000_000)
	scope.declare_int("day_play_s", 0, 0, 1_000_000_000)
	scope.declare_int("fill_match", 0, 0, 1_000_000)
	scope.declare_int("fill_play_s", 0, 0, 1_000_000_000)
	scope.declare_int("last_amount", 0, 0, 1_000_000)
	_day_matches = scope.read_int("day_matches")
	_day_play_s = scope.read_int("day_play_s")
	_fill_match = scope.read_int("fill_match")
	_fill_play_s = scope.read_int("fill_play_s")
	_last_amount = scope.read_int("last_amount")


func on_served() -> void:
	_served += 1


func on_left() -> void:
	_lost += 1


func on_coins_earned(n: int) -> void:
	_earned += n


## Call after the till's own match-start check: a till amount below the last
## seen one means the day was reset (00:00 UTC or the demo button).
func on_match_started() -> void:
	if _till.till_amount < _last_amount:
		_day_matches = 0
		_day_play_s = 0
		_fill_match = 0
		_fill_play_s = 0
	_served = 0
	_lost = 0
	_earned = 0


## Returns the results-screen line.
func on_match_ended(match_s: float) -> String:
	_day_matches += 1
	var secs := roundi(match_s)
	if _fill_match == 0 and _till.is_full:
		_fill_match = _day_matches
		_fill_play_s = _day_play_s + secs
	_day_play_s += secs
	_last_amount = _till.till_amount
	_save()
	var row := "%s,%d,%d,%d,%d,%d,%d,%d,%d" % [Time.get_datetime_string_from_system(true), secs,
		_served, _lost, _earned, _till.till_amount, _day_matches, _fill_match, _fill_play_s]
	print("playtest ", row)
	if not OS.has_feature("web"):
		_append_csv(row)
	var fill := "till not full"
	if _fill_match > 0:
		fill = "till full in match %d (%s of play)" % [_fill_match, _mmss(_fill_play_s)]
	return "Time: %s · served %d · earned %d\nDay: match %d · %s" % [_mmss(secs), _served,
		_earned, _day_matches, fill]


func _save() -> void:
	_scope.write_int("day_matches", _day_matches)
	_scope.write_int("day_play_s", _day_play_s)
	_scope.write_int("fill_match", _fill_match)
	_scope.write_int("fill_play_s", _fill_play_s)
	_scope.write_int("last_amount", _last_amount)


static func _mmss(s: int) -> String:
	return "%d:%02d" % [s / 60, s % 60]


static func _append_csv(row: String) -> void:
	var is_new := not FileAccess.file_exists(CSV_PATH)
	var f := FileAccess.open(CSV_PATH, FileAccess.READ_WRITE if not is_new else FileAccess.WRITE)
	if f == null:
		return
	if is_new:
		f.store_line("utc,match_s,served,lost,coins_earned,till_amount,day_match,fill_match,fill_play_s")
	f.seek_end()
	f.store_line(row)
