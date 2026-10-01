# Story 006: Подача: matches → consume_held_cup → Served

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-007`, `TR-guest-008`, `TR-guest-010`, `TR-guest-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause
**ADR Decision Summary**: MatchDirector._process — единственный драйвер; GameClock (RefCounted) — единственный источник паузы (флаги hidden/frozen, без SceneTree.paused); фиксированный порядок тика; MatchLifecycle владеет политикой партии; типизированные синхронные сигналы, проводка только в _compose().
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (домен Core; `_process`, типизированные сигналы на RefCounted — до cutoff и без изменений в 4.4–4.7)

Подача любому гостю с совпадающим заказом. Точка взаимодействия — всегда слот гостя. `offer()` отвечает синхронно в шаге баристы, GuestSim разрешает как (a) шага 5 в том же кадре.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)
- Guardrail: запрос, меняющий партию (`request_new_match`), не вызывается реентерабельно из обработчика сигнала — ставится в очередь и применяется на шаге 0 (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] Гости A (cold_tea, Waiting), B (black_tea), C: чашка cold_tea подаётся по слоту A или C — `consume_held_cup()` ровно один раз, гость → Served в том же тике, эмит `served(recipe_id, remaining_fraction)` (AC 18–19).
- [ ] Несовпадающий заказ — отказ (`guest_refused`), чашка не списывается; попытка подачи в ENDED отклоняется.
- [ ] Гость с `t_since_spawn` = 45.0 (patience 50) и подача в том же шаге побеждают таймаут; интеракция всегда у слота гостя (Approaching-гость — `is_valid` по Rule 4/AC 17).
- [ ] Player Control (`barista.step`) обновляется раньше `guests.step` в тике (проверка порядка в `MatchDirector`, TR-guest-012).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/guest_sim.gd`: `can_serve`, `is_valid`, `offer`, сигналы `served`/`guest_served`/`guest_refused`. Контракт `offer_action() → ActionReply` — ADR-0003 §3. Зависимости `Brewing.held_match()` / `consume_held_cup()` инжектируются интерфейсом; в unit-тестах — фейки.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: путь к слоту
- currency epic: начисление по `served`
- Story 009: интеграция с реальной баристой

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/guest/guest-serve-offer_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 004, 005; brewing epic (held cup API); barista-control epic
- Unlocks: См. таблицу зависимостей эпика
