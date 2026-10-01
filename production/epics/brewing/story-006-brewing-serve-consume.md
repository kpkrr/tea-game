# Story 006: consume_held_cup: подача очищает руки ровно один раз

> **Epic**: Brewing & Crafting
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/brewing-crafting-mechanic.md`
**Requirement**: `TR-brewing-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: Один драйвер MatchDirector._process с фиксированным порядком тика, GameClock (RefCounted, hidden/frozen) - единственный источник паузы, модули симуляции - RefCounted со step(dt), типизированные сигналы подключаются только в корне композиции, без SceneTree.paused и глобальной шины событий.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Node._process, process_priority, типизированные сигналы на RefCounted - до-cutoff API, без изменений 4.4-4.7. Post-cutoff API не используются.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0003): модули симуляции - RefCounted со step(dt), без _process/_physics_process и без чтения Time/OS/Engine.
- Required (from ADR-0003): кросс-модульные сигналы типизированы, подключаются только в MatchDirector._compose(), без CONNECT_DEFERRED, без лямбд и .bind() с RefCounted.

---

## Acceptance Criteria

*From GDD `design/gdd/brewing-crafting-mechanic.md`, scoped to this story:*

- [ ] Внешний вызов `consume_held_cup()` мгновенно делает руки пустыми и эмитит `held_changed`; без вызова чашка не исчезает и не меняется сама по себе (AC-5.1-5.2).
- [ ] Гость-адресат ушёл, `consume_held_cup()` не вызывается -> чашка остаётся в руках (AC-E7).
- [ ] Контракт "ровно один раз на подачу": вызов при пустых руках - нарушение контракта (`push_error` в debug, без побочных эффектов и сигнала); `held_match()` возвращает ID рецепта по `RecipeBook.matches`, для испорченной чашки и пустых рук - `&""`.

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/brewing.gd`: `consume_held_cup`, `held_match`.

- Подача инициируется GuestSim (он знает гостя и цену); Brewing только очищает руки. Brewing не эмитит событие подачи.
- `consume_held_cup()` должен быть идемпотентно безопасным, но громко сообщать о повторном вызове - это защита от двойного начисления в Currency.
- `held_match()` - чтение для GuestSim/HUD; не мутирует.
- Интеграция "подача совпадающей чашки вызывает `consume_held_cup()` ровно один раз" (AC-I1) - после готовности guest-sim, см. story 008.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Guest-sim epic: подача, сопоставление с гостем, начисление.
- Story 008: интеграционная проверка exactly-once.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/brewing_crafting/brewing_crafting_serve_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 008; guest-sim epic
