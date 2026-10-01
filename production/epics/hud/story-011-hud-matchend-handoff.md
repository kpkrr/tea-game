# Story 011: MatchEnd hand-off: freeze overlays, is_new_record flag, popup completion

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-016`, `TR-hud-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: GameClock + MatchDirector with fixed tick order, no SceneTree.paused, typed signals, DI from the composition root; pause = hidden OR user_paused via single GameClock; sim_dt frozen on pause, ui_dt keeps running (0 while hidden).
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- none

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: No post-cutoff API dependency; signals and _process ordering are stable Godot 4.x.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

На `match_ended` HUD переходит в MatchEnd, замораживает жетоны/кольца, доигрывает идущие попапы и отдаёт `is_new_record` (готовый флаг из Currency) оверлею итогов из epic `game-flow`; `match_started` возвращает в Active.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0003): `is_new_record` read as ready flag from Currency, never recomputed in HUD
- Required (from ADR-0003): state transitions in the frame of the signal

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] Два+ гостя потеряны подряд перед концом: импульс каждого доигрывается до появления оверлея (AC 43)
- [ ] `is_new_record` читается как флаг Currency; HUD не сравнивает score/best сам (AC 26 по части источника)
- [ ] Play Again → один `request_new_match`, HUD остаётся в MatchEnd до `match_started`, затем Active (AC 28)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — match end transition.
- Тест на заглушке оверлея и fake Currency.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- epic game-flow: верстка и анимация итогов (накрутка, NEW RECORD штамп)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/hud/hud_matchend_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002, 004, 006, 009
- Unlocks: None
