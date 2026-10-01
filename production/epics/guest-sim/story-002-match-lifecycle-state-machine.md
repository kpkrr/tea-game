# Story 002: MatchLifecycle: состояния BOOTING/IDLE/RUNNING/ENDED и команды

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-019`, `TR-guest-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
**ADR Decision Summary**: MatchDirector._process — единственный драйвер; GameClock (RefCounted) — единственный источник паузы (флаги hidden/frozen, без SceneTree.paused); фиксированный порядок тика; MatchLifecycle владеет политикой партии; типизированные синхронные сигналы, проводка только в _compose().
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (домен Core; `_process`, типизированные сигналы на RefCounted — до cutoff и без изменений в 4.4–4.7)

Политика партии: `ready_reached` → IDLE (без автостарта), старт только через `request_new_match()` (очередь, шаг 0), `match_ended(reason)` с `guests_lost | quit` (поправка game-flow 2026-10-01).

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)
- Guardrail: запрос, меняющий партию (`request_new_match`), не вызывается реентерабельно из обработчика сигнала — ставится в очередь и применяется на шаге 0 (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] `match_started` эмитится ровно один раз на старт; дубликаты `request_new_match()` во время RUNNING или при уже стоящей заявке игнорируются (одна debug-строка).
- [ ] `on_ready_reached()` переводит BOOTING → IDLE без старта; `request_new_match()` принимается только в IDLE/ENDED (AC 50, 57).
- [ ] `on_guests_lost_reached()` в RUNNING: `clock.freeze()`, ENDED, `match_ended(&"guests_lost")` ровно один раз; повторные вызовы и вызов вне RUNNING — no-op (AC 51–52).
- [ ] `request_quit_match()` принимается только в RUNNING, ставится в очередь, на шаге 0: `freeze`, очистка `_user_paused`, `match_ended(&"quit")` → IDLE; после любого `match_ended` сигнал не повторяется (AC 55–58).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/match_lifecycle.gd` (есть BOOTING/RUNNING/ENDED, `request_new_match`, `apply_pending`, `on_guests_lost_reached`). Расширить: состояние IDLE, `ready_reached` без автостарта, `request_quit_match()`, аргумент `reason` у `match_ended`. Никаких реентерабельных вызовов из обработчиков — только очередь. `state` — `_private` поле с getter. Сигналы подключаются только в `MatchDirector._compose()` (foundation-runtime).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: пауза (hidden/user)
- Story 009: интеграция с реальными подсистемами
- hud/game-flow epics: кнопки и меню, вызывающие команды

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/guest/match-lifecycle-state-machine_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001; foundation-runtime (GameClock)
- Unlocks: См. таблицу зависимостей эпика
