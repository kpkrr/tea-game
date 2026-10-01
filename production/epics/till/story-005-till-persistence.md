# Story 005: Сохранение кассы между запусками

> **Epic**: Till & Day Cycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/till-day-cycle.md`
**Requirement**: `TR-till-009`, `TR-till-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Local persistence (SaveStore)
**ADR Decision Summary**: `SaveStore` — in-memory модель с owner-scope (`SaveScope`), один версионированный JSON-блоб, валидация каждого ключа с дефолтом, flush раз за тик (шаг 6) и при скрытии страницы; backend: `localStorage` (web) / `user://` (desktop) / `MemoryBackend` (тесты).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web-путь persistence — HIGH (`localStorage` через helper HTML-шелла, не `user://`). В юнит-тестах только `MemoryBackend`; `WebStorageBackend` покрыт on-device spike. JSON-числа возвращаются как float — читать через валидатор.

**Control Manifest Rules (this layer)**:
- Required: доступ к сохранению только через инъектированный `SaveScope`; каждый ключ объявлен (`declare_*`) с default и диапазоном до первого чтения (from ADR-0005)
- Required: владелец сам не вызывает `flush_if_dirty()`; flush — шаг 6 тика и скрытие страницы (from ADR-0005)
- Forbidden: запись `match_score` и внутриматчевого состояния в SaveStore; `user://` на web; владелец не создаёт backend (from ADR-0005)

---

## Acceptance Criteria

*From GDD `design/gdd/till-day-cycle.md`, scoped to this story:*

- [ ] `till.amount`, `till.day_state`, `till.full_since_utc` объявлены в scope `till` с default/диапазоном и пишутся при каждом изменении; `amount = 150` Open переживает «перезапуск» (пересоздание `SaveStore` на том же `MemoryBackend`), Full остаётся Full до сброса (AC 29, 30)
- [ ] Первый запуск (нет сохранения) → Open, `amount = 0` (AC 28); Open-день не меняет `full_since_utc` (пуст)
- [ ] Повреждённые данные чинятся к default: `day_state = "full"` при `amount != capacity` или `full_since_utc = 0` → состояние выравнивается по сумме; невалидный ключ → default + один лог, валидные ключи сохраняются; записи Served+Full в одном тике = один `write_blob`

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/till.gd` (`_init` с `declare_*` и блоком «Repair inconsistent saves», `_save`). Ключи и владение — ADR-0005 §6. Не вызывать flush из Till. Интеграционный тест с реальным `SaveStore` + `MemoryBackend`. Поведение `localStorage` на устройстве — вне истории (on-device spike ADR-0005).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- `WebStorageBackend`/`FileBackend` — Foundation-эпик SaveStore

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/till/till_persistence_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002, 003, 004; SaveStore из Foundation
- Unlocks: Закрытие эпика; currency story 006
