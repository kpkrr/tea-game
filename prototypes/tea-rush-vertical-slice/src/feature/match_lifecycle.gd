# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Match policy (ADR-0003): BOOTING -> RUNNING -> ENDED -> RUNNING...
## Two orthogonal pause reasons: tab hidden and user pause.

signal match_started()
signal match_ended()
signal paused_changed(paused: bool)

enum State { BOOTING, RUNNING, ENDED }

var state := State.BOOTING

var _clock: RefCounted
var _pending_start := false
var _hidden := false
var _user_paused := false


func _init(clock: RefCounted) -> void:
	_clock = clock


func is_user_paused() -> bool:
	return _user_paused


func is_paused() -> bool:
	return _hidden or _user_paused


## Queues a new match; accepted only after a match ended (or once at boot).
func request_new_match() -> void:
	if state == State.RUNNING or _pending_start:
		return
	_pending_start = true


func on_ready_reached() -> void:
	if state == State.BOOTING:
		_pending_start = true


## Tick step 0: applies a queued start.
func apply_pending() -> void:
	if not _pending_start:
		return
	_pending_start = false
	var was := is_paused()
	_user_paused = false
	_clock.reset()
	_sync_pause(was)
	state = State.RUNNING
	match_started.emit()


func on_guests_lost_reached() -> void:
	if state != State.RUNNING:
		return
	_clock.freeze()
	state = State.ENDED
	match_ended.emit()


func on_visibility_changed(visible: bool) -> void:
	var was := is_paused()
	_hidden = not visible
	_sync_pause(was)


func request_pause() -> void:
	if state != State.RUNNING or _user_paused:
		return
	var was := is_paused()
	_user_paused = true
	_sync_pause(was)


func request_resume() -> void:
	if not _user_paused:
		return
	var was := is_paused()
	_user_paused = false
	_sync_pause(was)


func _sync_pause(was: bool) -> void:
	var now := is_paused()
	if now == was:
		return
	if now:
		_clock.pause()
	else:
		_clock.resume()
	paused_changed.emit(now)
