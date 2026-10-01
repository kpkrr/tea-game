# Story 007: Назначение recipe_id, онбординг 15 с, RNG

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-014`, `TR-guest-018`, `TR-guest-020`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**Secondary ADRs**: ADR-0003: Match simulation — clock, tick order, pause (Version 2026-09-30)
**ADR Decision Summary**: Константы — в подресурсах GameConfig (.tres), ConfigValidator собирает все ошибки с именем константы, модули получают конфиг конструктором, RNG — инъекцией (отдельные потоки guest_tier / guest_recipe), кривые — статические функции DifficultyCurve (не Curve).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (Resource/@export/duplicate_deep 4.5+ — сверить с breaking-changes.md)

Formula 3: два независимых потока RNG (tier, recipe). До `onboarding_duration` = 15 с — только simple и спавн ×1,0. Выходы DifficultyCurve перепроверяются при спавне с откатом к базовым значениям.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: все значения из GDD Tuning Knobs — из подресурса GameConfig с sentinel-default и правилом ConfigValidator в том же изменении (from ADR-0004)
- Forbidden: литералы настроек в коде; глобальные `randf()/randi()/randomize()`; `load()`/`preload()` конфига внутри модуля; запись в конфиг (from ADR-0004)
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] `complex_order_share` = 0, t = 45, r = 0.0 / 0.4999 / 0.5 / 0.9999 → simple / simple / medium / medium; при share 0.5 границы по формуле p_simple/p_medium/p_complex (AC 34–35).
- [ ] FakeRng всегда r = 0.99, t < 15 → все заказы simple; гость в t = 14.75 остаётся simple; ровно при t = 15 действует roll (AC 29–31).
- [ ] Второй бросок (выбор внутри уровня) детерминирован при заданных значениях; два прогона с одним seed идентичны (AC 36–37); потоки `guest_tier` и `guest_recipe` раздельные.
- [ ] `FakeDifficulty.complex_order_share` = 1.3 / `patience_max` ≤ 0 / NaN на спавне → откат к базовым значениям + запись в лог (Rule 12, AC 4).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/guest_sim.gd`: `pick_recipe` (два RNG, `p_medium = (1 − p_complex) × medium_share_of_remaining`), `_spawn`. Заменить `randf()/randi_range()` на инжектируемый `Rng` (ADR-0004); CI-grep на запрет глобального `randf`. `onboarding_*` — из конфига, не литералы. Значение medium_share — из .tres (0.5 по GDD); слайс 0.75 — см. difficulty-curve story 005 (Blocked). Каждый fallback логируется (счётчик для AC 21 difficulty-curve).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- recipe-book epic: сами рецепты и `recipes_by_tier`
- difficulty-curve story 005: значение medium_share

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/guest/recipe-assignment-onboarding_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001, 004; recipe-book epic (recipes_by_tier); difficulty-curve story 002
- Unlocks: См. таблицу зависимостей эпика
