# Story 003: ConfigValidator: все ошибки списком, NaN-sentinel, dotted-пути

> **Epic**: Foundation Runtime (Clock, Director, Config, Save)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: — (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD)
**Requirement**: ADR-0004 (инфраструктура; TR-IDs эпика `TR-guest-016`/`TR-brewing-010` валидируются как поле конфига)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: GameConfig + подресурсы .tres с sentinel-дефолтами; ConfigValidator собирает ВСЕ ошибки с dotted-путём; Rng инжектируется, именованные потоки; config — конструкторная инъекция.
**ADR Version**: 2026-09-30 (Last Verified)

**Engine**: Godot 4.7.2 | **Risk**: LOW (engine overall HIGH)
**Engine Notes**: Неверные типы в .tres молча приводятся ("abc"→0.0) — нужен CI-тест на shipped-значения; Resource.duplicate_deep() (4.5) только в тестах; загрузка в тестах с CACHE_MODE_IGNORE_DEEP.

**Control Manifest Rules (this layer)**:
- Required (from ADR-0004): каждое тюнинг-значение из GameConfig-подресурса, `@export` со статическим типом и sentinel-дефолтом; новое поле шипится вместе с правилом валидатора
- Forbidden (from ADR-0004): литералы тюнинга в коде; `load()`/`preload()`/`ResourceLoader` для конфига вне ConfigLoader; глобальные `randf()`/`randi()`/`randomize()`; запись в config-объект
- Guardrail (from ADR-0004): `ResourceLoader.load` конфига на spike-устройстве добавляет < 50 мс к TTI

---

## Acceptance Criteria

*From the TR-IDs / ADR guidelines above, scoped to this story:*

- [ ] `ConfigValidator.validate(config)` возвращает ВСЕ найденные ошибки (не останавливается на первой); каждая ошибка называет dotted-путь константы (напр. `guest.max_step_delta`) и код
- [ ] Непереданное поле (sentinel `NAN`/`-1`/`Vector3(NAN..)`) -> ошибка `missing`; значение вне диапазона/нефинитное -> `range`; перекрёстные инварианты (aspect_min < aspect_max, max_step_delta > 0) проверяются
- [ ] Валидатор работает одинаково в debug и release (никаких `assert` вместо ошибок); `ConfigFactory.valid()` даёт 0 ошибок, а каждое обнулённое поле — ровно ожидаемую ошибку (параметризованный тест по полям)

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/config_validator.gd` (182 строки) в `src/foundation/config/config_validator.gd`. Сверить покрытие: по правилу на каждое поле из story 002. Помнить из ADR-0004: типы в .tres молча приводятся ("abc"->0.0), поэтому диапазонные проверки обязательны, а не только проверка на sentinel. Статическая типизация везде, doc-комментарии (`##`) на публичном API, зависимости через конструктор (DI), без синглтонов.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: проверка shipped `.tres`
- MatchDirector, вызывающий `fail_boot()` при ошибках — story 009

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/config/config_validator_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002
- Unlocks: Story 004, 009
