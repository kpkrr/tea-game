# Story 009: Интеграция: партия от старта до match_ended с реальными подсистемами

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-012`, `TR-guest-013`, `TR-guest-015`, `TR-guest-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
**ADR Decision Summary**: MatchDirector._process — единственный драйвер; GameClock (RefCounted) — единственный источник паузы (флаги hidden/frozen, без SceneTree.paused); фиксированный порядок тика; MatchLifecycle владеет политикой партии; типизированные синхронные сигналы, проводка только в _compose().
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (домен Core; `_process`, типизированные сигналы на RefCounted — до cutoff и без изменений в 4.4–4.7)

Проверка тик-порядка и жизненного цикла на реальных модулях, собранных в `MatchDirector._compose()`.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)
- Guardrail: запрос, меняющий партию (`request_new_match`), не вызывается реентерабельно из обработчика сигнала — ставится в очередь и применяется на шаге 0 (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] Бариста в Holding приходит к гостю, чей заказ совпадает, в том же кадре, где у гостя истекает терпение — подача побеждает (AC 45, 49).
- [ ] Новая партия: `match_started` сбрасывает Brewing/Currency/Barista, GuestSim очищает гостей и спавнит первого в том же тике; после `guests_lost` = 3: заморозка, `match_ended` один раз, Play again → `request_new_match()` запускает чистую партию (AC 44, 50–52).
- [ ] Hide вкладки посреди партии: `t` и терпение стоят, после show первый кадр отбрасывается; `request_quit_match()` даёт `match_ended(&"quit")` и возврат в IDLE (AC 33, 54, 58).

---

## Implementation Notes

Использовать настоящие `MatchDirector`, `MatchLifecycle`, `GameClock`, `GuestSim`, `Brewing`, `BaristaController` (headless сцена, `step(0.25)`). Без моков логики — только фейки платформы (visibility). Порт: сценарные проверки из слайса (`prototypes/tea-rush-vertical-slice/tests` если есть) — использовать как источник сценариев.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- hud/game-flow epics: оверлеи итогов и меню

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/guest/match-flow-integration_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 002–007; barista-control, brewing, currency epics; foundation-runtime (MatchDirector)
- Unlocks: См. таблицу зависимостей эпика
