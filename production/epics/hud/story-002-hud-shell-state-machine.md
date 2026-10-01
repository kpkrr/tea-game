# Story 002: HUD shell, state machine and pause-aware animation clock

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-001`, `TR-hud-003`, `TR-hud-004`, `TR-hud-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: GameClock + MatchDirector with fixed tick order, no SceneTree.paused, typed signals, DI from the composition root; pause = hidden OR user_paused via single GameClock; sim_dt frozen on pause, ui_dt keeps running (0 while hidden).
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0002: Viewport, camera fit & 2.5D presentation (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: No post-cutoff API dependency; signals and _process ordering are stable Godot 4.x.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

Корневой узел HUD: слои экранных полос и мировых оверлеев, состояния Inactive → Active → MatchEnd → Active (+ Paused ортогонально), значения читаются каждый кадр без кэша, все анимации считают время по `GameClock` (замирают на паузе).

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0003): HUD only reads upstream state in `_process` (priority 0, after MatchDirector); no own copy of game state
- Forbidden (from ADR-0003): `SceneTree.paused`, `Tween`/`create_timer` for gameplay-synchronised animation — animate from accumulated `GameClock` time
- Required (from ADR-0002): screen-space bars are separate from world-space overlays; world never enters the strips
- Required (from ADR-0003): subscribe to typed signals (`ready_reached`, `match_started`, `match_ended`, `paused_changed`) via injected references

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] `ready_reached` ещё не пришёл → состояние `Inactive`, ничего не рендерится; после него → `Active` (GDD AC 30)
- [ ] `match_ended` → `MatchEnd` в том же кадре, жетоны и кольца скрываются; `match_started` → `Active` (AC 31)
- [ ] `match_score = 40` без события: отображается ровно 40 из апстрима этого кадра; после `Served` 40→60 следующий кадр показывает 60 без задержки (AC 3–4)
- [ ] Анимация, запущенная до паузы (попап на 40 %), не продвигается при `ui_dt`-паузе/скрытой вкладке и продолжается с той же фазы (AC 42, 56)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — разнести монолит слайса на узлы: `HudRoot`, `StripLayer`, `WorldOverlayLayer`, `HudAnimClock`.
- `HudAnimClock` аккумулирует `GameClock` dt (sim для игровых анимаций, `ui_dt` только где GDD явно говорит); никакого `Tween` на синхронизируемых анимациях.
- Проекция мир→экран для оверлеев — через `ViewFit`/камеру из ADR-0002; HUD не хранит позиции.
- Тест: fake `GameClock` + fake Currency/GuestSim, проверка рендер-шага по кадрам.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 003: содержимое верхней полосы
- Story 004: маршрутизация тапов
- Story 009: кнопка паузы и оверлей Paused
- Story 011: передача в Results (game-flow)
- HUD skin art (icons, frames, fonts, tokens sprites) comes from epic `art-assets`; use placeholder `StyleBox`/flat shapes until it lands.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/hud/hud_state_machine_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001
- Unlocks: 003, 004, 005, 006, 007, 008, 009, 010, 011
