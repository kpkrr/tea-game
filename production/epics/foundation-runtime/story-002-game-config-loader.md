# Story 002: GameConfig, подресурсы и ConfigLoader + ConfigFactory

> **Epic**: Foundation Runtime (Clock, Director, Config, Save)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: — (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD)
**Requirement**: `TR-guest-016`, `TR-brewing-010` (значение `max_step_delta` живёт в конфиге)
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

- [ ] `GameConfig` — корневой `Resource` с подресурсом на владельца (view, kitchen, control, recipes, brewing, guest, difficulty, currency, till, hud, audio); каждое поле `@export` со статическим типом и sentinel-дефолтом (`NAN` / `-1`)
- [ ] `ConfigLoader.load_config(path)` возвращает `{config, errors}`; отсутствующий файл или неверный тип скрипта -> `config == null` и ошибка `missing`; грузит с `CACHE_MODE_IGNORE_DEEP` в тестах
- [ ] `ConfigFactory.valid()` строит полностью валидный in-memory `GameConfig` без чтения диска; тесты копируют его через `duplicate_deep()` и переопределяют поля
- [ ] Значение `max_step_delta` (0,25 с) объявлено в конфиге (guest/brewing-секция по реестру) и читается из `GameConfig`, а не из кода

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/*` (game_config.gd, *_config.gd, recipe_def.gd, config_loader.gd) в `src/foundation/config/`. Ресурсы срезa уже с sentinel-дефолтами — сверить список полей с GDD Tuning Knobs и `design/registry/entities.yaml`, добавить недостающие (ADR-0004: литералы тюнинга запрещены). Новый `tests/helpers/config_factory.gd`. Статическая типизация везде, doc-комментарии (`##`) на публичном API, зависимости через конструктор (DI), без синглтонов. Sentinel-дефолты НЕЛЬЗЯ менять на реальные значения (ADR-0004).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: правила `ConfigValidator`
- Story 004: shipped `assets/data/config/*.tres` и интеграционный тест
- Feature-эпики добавляют свои поля вместе со своими правилами валидатора

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/config/config_loader_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 003, 004, 008
