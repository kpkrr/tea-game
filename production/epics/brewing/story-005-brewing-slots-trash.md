# Story 005: Слоты (безусловный обмен) и мусорка

> **Epic**: Brewing & Crafting
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/brewing-crafting-mechanic.md`
**Requirement**: `TR-brewing-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: Один драйвер MatchDirector._process с фиксированным порядком тика, GameClock (RefCounted, hidden/frozen) - единственный источник паузы, модули симуляции - RefCounted со step(dt), типизированные сигналы подключаются только в корне композиции, без SceneTree.paused и глобальной шины событий.
**ADR Version**: 2026-09-30
**Secondary ADRs**: ADR-0004 (Data config & load-time validation)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Node._process, process_priority, типизированные сигналы на RefCounted - до-cutoff API, без изменений 4.4-4.7. Post-cutoff API не используются.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0003): модули симуляции - RefCounted со step(dt), без _process/_physics_process и без чтения Time/OS/Engine.
- Required (from ADR-0003): кросс-модульные сигналы типизированы, подключаются только в MatchDirector._compose(), без CONNECT_DEFERRED, без лямбд и .bind() с RefCounted.
- Forbidden (from ADR-0003): get_tree().paused, _physics_process, autoload по имени внутри модулей.

---

## Acceptance Criteria

*From GDD `design/gdd/brewing-crafting-mechanic.md`, scoped to this story:*

- [ ] Слот: чашка в слоте + чашка в руках (любые, включая испорченные) -> обмен местами, отказа не бывает; пустой слот + чашка -> чашка в слоте, руки пусты; чашка в слоте + пустые руки -> чашка в руках, слот пуст (AC-4.1-4.3); слотов ровно 7 из данных layout.
- [ ] Мусорка (`trash`): чашка в процессе сборки, готовая к подаче или испорченная исчезает, руки пусты, новая не выдаётся; подтверждения нет, `consume_held_cup()` не вызывается (AC-7.1-7.3).
- [ ] Мусорка с пустыми руками -> отказ без сигнала отказа P9, состояние не меняется (AC-7.4); `trash` отсутствует в `station_types` для Order & Recipe, а станция `trash` на кухне ровно одна (AC-7.5).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/brewing.gd`: ветки `slot` и `trash` в `_decide`/`_execute` - мусорка восстановлена владельцем по срезу, GDD синхронизирован (Core Rule 7, добавлено 2026-10-01).

- Слот: всегда EXECUTE (`_decide` -> `feedback = false`); обмен `slots[id] <-> held`, сигналы `slot_changed` и `held_changed`.
- Мусорка: EXECUTE только если `held != null`; `held = null`, `held_changed`; `consume_held_cup()` НЕ вызывать (подачи не было).
- Проверка AC-7.5 пересекается с kitchen-layout: `trash` - станция `KitchenLayout`, но не входит в `station_types` рецептов; тест читает фикстуру layout и грамматику.
- Если audio-juice/HUD потребуют сигнал "чашка выброшена" - отдельный сигнал добавляется в их эпиках (вне scope).
- Занятость слотов принадлежит Brewing (layout только объявляет слоты).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: подача и `consume_held_cup()`.
- Story 007: сброс слотов.
- Kitchen-layout epic: размещение и геометрия `trash`/слотов.
- HUD/audio epics: иконки чашек на слотах, звук выброса.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/brewing_crafting/brewing_crafting_slots_trash_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002
- Unlocks: Story 007, 008
