# Story 008: Music states: last-strike squeeze, match_ended low-pass, quit, menu<->match

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-004`, `TR-audio-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)
- ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

Переходы музыки (Rules 6–9): меню-трек с начала на каждый заход (fade-in 1 с), меню→партия 0,6 с, партия→меню 0,8 с; `guests_lost == max−1` → S4 гаснет (0,5 с), LP 20 000 → 2500 Гц за 0,4 с (экспоненциально по частоте), Music −3 dB; `match_ended(lost)` → LP 800 Гц за 0,3 с; `quit` — без стингера, stems гаснут 0,8 с; Play Again — фильтр снят, stems с 0, только S1.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0003): all audio envelopes (layer fades, filter ramps, ducking) accumulate `GameClock.ui_dt` in `_process`; never `Tween`
- Required (from ADR-0004): cutoff/ramp/dB values from AudioConfig
- Required (from ADR-0003): reacts to `guests_lost_changed`, `match_ended(reason)`, `match_started` typed signals

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] dp = 1, `guests_lost_changed(2)`: LastStrike, S4 → −80 за 0,5 с, LP 20 000 → 2500 Гц за 0,4 с (середина ≈ 7071 Гц), Music −3 dB; `pitch_scale` stems и BPM не меняются (AC 13)
- [ ] LastStrike → `match_ended(lost)`: LP 2500 → 800 Гц за 0,3 с; `match_ended(quit)` (в т. ч. из паузы) — ни одного вызова стингера, stems гаснут за 0,8 с, стартует меню (AC 15 часть, 16)
- [ ] 1 страйк + в одном кадре `guests_lost_changed(2)` и `match_ended` → сразу Results (800 Гц), LastStrike не вызывался (AC 17)
- [ ] Results (800 Гц, серия 4) → `match_started`: LP 20 000, stems с 0, только S1, первая подача — звезда pitch 1,0; меню→партия 0,6 с, партия→меню 0,8 с (AC 18, 19); меню-трек: тишина до жеста, затем с 0 fade-in 1 с, повторный вход — снова с 0 (AC 12)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/audio_director.gd` + `.../foundation/config/audio_config.gd` (bring to standards: static typing, doc comments, DI of GameClock/AudioConfig/SaveScope/backend) — LP ramp and MatchEnd handling.
- Состояния Boot/Menu/Match.Ramp/Match.LastStrike/Results/Paused ⟂/Hidden ⟂ — таблица в audio GDD States and Transitions.
- Экспоненциальный срез: `f = f0 * (f1/f0)^(t/T)`.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 009: сердцебиение
- Story 013: стингеры итогов NEW RECORD/SHIFT OVER
- Story 016: пауза

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/audio/music_states_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 004, 005, 007
- Unlocks: 009, 013
