# Story 009: Pause button and Paused overlay (user pause via GameClock)

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-023`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: GameClock + MatchDirector with fixed tick order, no SceneTree.paused, typed signals, DI from the composition root; pause = hidden OR user_paused via single GameClock; sim_dt frozen on pause, ui_dt keeps running (0 while hidden).
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0006: Navigation & tap picking (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: No post-cutoff API dependency; signals and _process ordering are stable Godot 4.x.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

Кнопка паузы в полосе (и Escape/Enter на ПК): пауза = hidden ИЛИ user_paused через единый `GameClock`; только в Active; возврат вкладки не снимает паузу игрока; снимается только «Resume»; тапы по кухне на паузе игнорируются. Подпанели End shift?/Settings живут в epic `game-flow` — HUD лишь остаётся в Paused.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0003): `request_pause()`/`request_resume()` into MatchLifecycle; pause = hidden OR user_paused; never `SceneTree.paused`
- Required (from ADR-0006): modal overlay swallows kitchen taps (ModalInputBlocker, Story 004)
- Forbidden (from ADR-0003): a second pause flag outside GameClock

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] Active + гость Waiting (0.80) + чайник BREWING: пауза (кнопка или Escape) → HUD в Paused, оверлей с Resume, `remaining_fraction` и таймер чайника не меняются (AC 54)
- [ ] Paused: скрыть вкладку на 10 с и вернуть → всё ещё Paused, время не шло; в MatchEnd кнопка паузы неактивна (AC 55)
- [ ] Попап на 40 % и пульс кольца замирают на всё время паузы и продолжаются с той же фазы после Resume (AC 56)
- [ ] Тапы по кухне на паузе не доходят до Player Control

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — pause button/overlay.
- Состояние `Paused` ортогонально `Active` в state machine Story 002.
- Audio подписан на `paused_changed` (Story audio 016) — здесь только сигналы.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- epic game-flow: End shift?, Settings, Rotate overlay
- Story audio 016: звук на паузе

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/hud/hud_pause_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002, 004
- Unlocks: 010, 011
