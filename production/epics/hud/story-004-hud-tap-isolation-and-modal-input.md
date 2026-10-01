# Story 004: Tap isolation: strips vs kitchen, modal overlays and restart grace

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-006`, `TR-hud-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Navigation & tap picking
**ADR Decision Summary**: NavMesh from data + direct NavigationServer3D queries, tap picking without physics, IDs (owner_id, index), fallback GridNavigator; input consumed by topmost UI before kitchen picking.
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Godot 4.7 gamepad-focus/device-ID input changes: verify Control.mouse_filter and _gui_input routing on touch.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

Тапы по элементам полос не доходят до кухни; при открытом модальном оверлее тапы получает только он; кнопки повторного старта принимают тап лишь после fade `results_fade_ms` (~250 мс) + `restart_input_grace_ms` (500 мс). Сами экраны итогов строит epic `game-flow` — здесь механизм и заглушка-оверлей для теста.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0006): UI consumes the tap first (`_gui_input`/`accept_event`); kitchen picking runs without physics only for unhandled taps
- Forbidden (from ADR-0006): physics raycasts for tap picking
- Required (from ADR-0003): grace timers accumulate `ui_dt` (run while match frozen), not wall-clock

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] Тап по элементу полосы над станцией не отправляет ни одного события в Layout/Player Control (AC 5)
- [ ] В Active без оверлея тап по полу/станции доходит до Player Control без изменений, действия полос не срабатывают (AC 6)
- [ ] При открытом оверлее тап в точке, совпадающей со станцией, получает только оверлей (AC 7)
- [ ] Тап по Play Again/Share/Menu, начатый раньше T + fade + grace или удерживаемый с момента до T, не выполняет действие; после — ровно один `request_new_match` (AC 51, 66 первая часть, 28)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — обработка ввода и блокировка.
- Экспортировать `ModalInputBlocker` (полноэкранный `Control` с `mouse_filter = STOP`), который открывает game-flow/Paused.
- Тест на заглушке оверлея; реальные кнопки Results — в epic game-flow.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Epic `game-flow`: содержимое экрана итогов, Share, Menu
- Story 009: оверлей Paused (использует этот блокер)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/hud/hud_tap_isolation_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002
- Unlocks: 009, 011
