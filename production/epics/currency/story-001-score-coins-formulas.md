# Story 001: Формулы очков и монет + CurrencyConfig

> **Epic**: Currency: Coins & Score
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/currency-coins-score.md`
**Requirement**: `TR-currency-001`, `TR-currency-002`, `TR-currency-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation; ADR-0003: Match simulation — clock, tick order, pause
**ADR Decision Summary**: Тюнинг-значения — типизированные `Resource` (`.tres`) с sentinel-дефолтами; один чистый `ConfigValidator` собирает все ошибки во всех сборках; конфиг неизменяем и инъектируется через конструкторы.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Post-cutoff: только `Resource.duplicate_deep()` (4.5) в тестовых фикстурах. Sentinel: `-1` для int, `NAN` для float; неверные типы молча приводятся — нужен CI-тест на shipped `.tres`.

**Control Manifest Rules (this layer)**:
- Required: каждое тюнинг-значение из GDD — `@export` поле `Resource` со статическим типом и sentinel-дефолтом; новое поле поставляется вместе с правилом валидатора (from ADR-0004)
- Required: конфиг инъектируется через конструктор; в юнит-тестах — фабрика `ConfigFactory.valid()` + оверрайды, не загрузка `.tres` (from ADR-0004)
- Forbidden: числовые литералы тюнинг-значений в коде, `load()`/`preload()` конфига внутри модуля, запись в конфиг (from ADR-0004)
- Required: модуль — `RefCounted`, без `_process`/`_physics_process`, без чтения `Time`/`OS`/`Engine` (from ADR-0003)
- Required: сигналы типизированы, соединяются только в `MatchDirector._compose()`, без `CONNECT_DEFERRED`, без лямбд и `.bind()` (from ADR-0003)
- Forbidden: глобальный event bus, `get_tree().paused`, ссылки на autoload по имени (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/currency-coins-score.md`, scoped to this story:*

- [ ] `coins_earned = recipe_price(recipe_id)` без модификаторов: 2 для `cold_tea`, 7 для `black_tea_lemon`/`green_tea_lemon`, совпадает с `recipe_price` для всех 5 рецептов (GDD AC 2, 15–17)
- [ ] `score_earned = round_half_up(price × score_multiplier_base × (1 + rf))`: `green_tea_lemon`@0.4 → 98; `black_tea`@0.5732 → 79; `cold_tea`@0.025 → 21 (граница .5 вверх); `cold_tea`@0 → 20, не 0 (AC 3, 10–12, 19); результат — `int` (AC 13)
- [ ] `score_multiplier_base` читается из `CurrencyConfig` (sentinel `-1`, значение 10 в `currency.tres`), литерала `10` в коде формулы нет; валидатор ловит отсутствующее/≤ 0 значение (AC 34)

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/feature/currency.gd` (`static func score_for`) и `prototypes/tea-rush-vertical-slice/src/foundation/config/currency_config.gd`. Объём: порт + статическая типизация, doc-комментарии на публичном API, правило в `ConfigValidator` (`currency.score_multiplier_base`: `missing`, `range ≥ 1`), файл `assets/data/config/currency.tres`, тесты. Слайсовая `floori(x + 0.5)` — корректный half-up для неотрицательных значений; оставить и покрыть граничным тестом `20.5 → 21`. Класс `CurrencyConfig` размещается в `src/foundation/config/` (ADR-0004 §1). Цена берётся через инъектируемый recipe book (`recipe_price(recipe_id) -> int`) — контракт Order & Recipe.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: реакция на `served`, эмиссия сигналов
- Story 004: `best_score`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/currency/currency_formulas_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Config-фундамент (`GameConfig`/`ConfigValidator`) и Recipe book из соответствующих эпиков
- Unlocks: Story 002, 003
