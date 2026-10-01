# Story 016: Pause and hidden tab for all audio (stream_paused, UI bus alive)

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: GameClock + MatchDirector with fixed tick order, no SceneTree.paused, typed signals, DI from the composition root; pause = hidden OR user_paused via single GameClock; sim_dt frozen on pause, ui_dt keeps running (0 while hidden).
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0001: Web build & platform shell (Last Verified 2026-10-01)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: No post-cutoff API dependency; signals and _process ordering are stable Godot 4.x.

Расширение паузы пилота (Story 005) на всё аудио: в синхронном колбэке `paused_changed` все плееры (музыка, фон, сердцебиение, звуки в полёте), кроме шины UI, получают `stream_paused`; на пользовательской паузе UI-клики звучат; на скрытой вкладке — тишина, включая UI и вибрацию; возврат вкладки не снимает пользовательскую паузу.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0003): handle `paused_changed` synchronously in the callback
- Required (from ADR-0003): all audio envelopes (layer fades, filter ramps, ducking) accumulate `GameClock.ui_dt` in `_process`; never `Tween`
- Required (from ADR-0001): Page Visibility via shell helper; hidden = silence

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] `paused_changed(true)`: все плееры кроме UI — `stream_paused = true` до выхода из колбэка; после Resume позиции совпадают до сэмпла; клик UI на паузе звучит (AC 21)
- [ ] 100 кадров `ui_dt = 0` с идущим кроссфейдом/срезом/дакингом — огибающие не меняются и продолжаются с тех же значений (AC 22)
- [ ] Стингер звучит, вкладка скрыта → всё на паузе, включая UI; после возврата стингер доигрывает остаток; при пользовательской паузе остаётся пауза (AC 23)

---

## Implementation Notes

- Порт паузы из `prototypes/tea-rush-vertical-slice/src/presentation/audio_director.gd` + `.../foundation/config/audio_config.gd` (bring to standards: static typing, doc comments, DI of GameClock/AudioConfig/SaveScope/backend).
- Интеграция в headless 4.7.2 с `AudioServer` + ручная проверка скрытия вкладки в evidence Spike S2.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- hud Story 009: кнопка паузы
- Story 017: вибрация на паузе (там своё условие)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/audio/audio_pause_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002, 005, 010
- Unlocks: None
