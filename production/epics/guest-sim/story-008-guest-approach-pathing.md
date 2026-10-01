# Story 008: Подход гостя к слоту по Navigator, нет пути → Waiting

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-006`, `TR-guest-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Navigation & tap picking
**Secondary ADRs**: ADR-0003: Match simulation — clock, tick order, pause (Version 2026-09-30)
**ADR Decision Summary**: Пути гостей через интерфейс Navigator (NavServerNavigator / FakeNavigator), NavMesh из данных, запасной GridNavigator; модули не вызывают NavigationServer3D напрямую; ID целей (owner_id, index).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: MEDIUM (NavigationServer3D на web — проверено в spike ADR-0006)

Гость идёт к слоту со скоростью 3,0 м/с по `Navigator`; если пути нет — сразу Waiting + запись в лог (терпение уже тикает).

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: путь гостя — через интерфейс `Navigator`; в тестах `FakeNavigator` (from ADR-0006)
- Forbidden: прямые вызовы `NavigationServer3D` вне `NavServerNavigator`; `NavigationAgent3D` у гостей (from ADR-0006)
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] `FakeNavigator` доводит гостя до слота за 6.0 с → Approaching ровно 6.0 с, затем Waiting; терпение тикало всё это время (AC 15).
- [ ] `FakeNavigator` «пути нет» (`reached = false`) → гость сразу Waiting, одна строка лога (AC 16).
- [ ] Гость в Approaching: подача невозможна до прихода (AC 17); уходящие (`departing`) идут к выходу со своей скоростью и удаляются по прибытии.

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/guest_sim.gd`: `_walk` (в слайсе — 1D по X через `guest_spawn_x/guest_slot_x/guest_exit_x`). В продакшене путь строит `Navigator.shortest_to`/`find_path` (ADR-0006), скорость `guest_walk_speed` из конфига. Позиция гостя публикуется для вью (story 010). Интеграционный тест с `NavServerNavigator` на реальном NavMesh + юнит-вариант с FakeNavigator.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- kitchen-layout/foundation-runtime: NavMesh и Pathing
- Story 010: анимация по направлению

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/guest/guest-approach-pathing_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 004, 005; foundation-runtime/kitchen-layout (Navigator, Pathing)
- Unlocks: См. таблицу зависимостей эпика
