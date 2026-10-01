# Story 004: Shipped game_config.tres: CI-проверка и включение в web-экспорт

> **Epic**: Foundation Runtime (Clock, Director, Config, Save)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: — (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD)
**Requirement**: ADR-0004 (Risks: тихое приведение типов)
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

- [ ] Интеграционный тест грузит реальный `assets/data/config/game_config.tres` через `ConfigLoader` и получает 0 ошибок валидатора
- [ ] Тест падает (проверено мутацией: обнулить одно поле) и перечисляет путь поля
- [ ] Все `assets/data/config/*.tres` включены в export preset (Export all resources или явный include); проверка наличия файлов в экспортированном `.pck` описана в evidence platform-shell story 008

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/data/` (значения .tres среза) в `assets/data/config/`, сверив с `entities.yaml` и GDD Tuning Knobs. Тест — `tests/integration/config/shipped_config_test.gd`; грузить с `CACHE_MODE_IGNORE_DEEP`. Граница с `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` — для деревьев с диска (ADR-0004).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: сами правила валидатора
- Тюнинг значений — дело feature-эпиков и balance-check

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/config/shipped_config_test.gd` — must exist and pass (или документированный playtest)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002, 003
- Unlocks: Story 009
