# Story 009: Heartbeat loop on last strike (1 Hz, beat-quantised, phase for HUD vignette)

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

Сердцебиение `sfx_heartbeat_loop` (SFX, `heartbeat_volume_db`, период ровно 1,0 с): стартует на ближайшей доле после входа в LastStrike, fade-in 400 мс, гаснет за 0,3 с на `match_ended`, замирает на паузе; фаза для HUD = `music_pos mod 1,0`; при `music_on=false` — свободный 1 Гц от кадра страйка.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0001): heartbeat is a Sample on SFX; quantisation only for layers and heartbeat (input/reward sounds are NOT quantised)
- Required (from ADR-0003): all audio envelopes (layer fades, filter ramps, ducking) accumulate `GameClock.ui_dt` in `_process`; never `Tween`
- Required (from ADR-0003): phase accumulates sim-independent `ui_dt` and stops while hidden/paused

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] Сердцебиение активно: период 1,0 с, `heartbeat_phase() = music_pos mod 1,0` для HUD; при `music_on = false` период 1,0 с от кадра страйка (AC 14)
- [ ] `match_ended`: сердцебиение → −80 за 0,3 с, в Results не звучит (AC 15)
- [ ] Замирает на паузе/скрытой вкладке и продолжается с той же фазой; 1→3 страйка в одном кадре с `match_ended` не запускает его (AC 17)

---

## Implementation Notes

- Публичный API `AudioDirector.heartbeat_phase() -> float` для hud Story 010 (виньетка).
- Тест на fake clock + fake backend.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- hud Story 010: виньетка
- Story 011: сам ассет

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/audio/heartbeat_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 008
- Unlocks: None
