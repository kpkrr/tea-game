# Story 005: Rng (именованные потоки, инъекция) и UtcClock

> **Epic**: Foundation Runtime (Clock, Director, Config, Save)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: — (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD)
**Requirement**: ADR-0004 (Rng injection); ADR-0007 (единственный читатель `Time` — UtcClock)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
- Secondary: ADR-0007: Performance & load budgets (Last Verified 2026-09-30)
**ADR Decision Summary**: GameConfig + подресурсы .tres с sentinel-дефолтами; ConfigValidator собирает ВСЕ ошибки с dotted-путём; Rng инжектируется, именованные потоки; config — конструкторная инъекция.
**ADR Version**: 2026-09-30 (Last Verified)

**Engine**: Godot 4.7.2 | **Risk**: LOW (engine overall HIGH)
**Engine Notes**: Неверные типы в .tres молча приводятся ("abc"→0.0) — нужен CI-тест на shipped-значения; Resource.duplicate_deep() (4.5) только в тестах; загрузка в тестах с CACHE_MODE_IGNORE_DEEP.

**Control Manifest Rules (this layer)**:
- Required (from ADR-0004): каждое тюнинг-значение из GameConfig-подресурса, `@export` со статическим типом и sentinel-дефолтом; новое поле шипится вместе с правилом валидатора
- Forbidden (from ADR-0004): литералы тюнинга в коде; `load()`/`preload()`/`ResourceLoader` для конфига вне ConfigLoader; глобальные `randf()`/`randi()`/`randomize()`; запись в config-объект
- Guardrail (from ADR-0004): `ResourceLoader.load` конфига на spike-устройстве добавляет < 50 мс к TTI
- Required (from ADR-0007): только `PerfProbe` и инжектируемые clock-адаптеры (production `UtcClock`) читают `Time`

---

## Acceptance Criteria

*From the TR-IDs / ADR guidelines above, scoped to this story:*

- [ ] `Rng.derive(match_seed, stream)` детерминирован, разные имена потоков дают разные seed (splitmix64); один и тот же seed воспроизводит последовательность `randf()` и `randi_range()`; `randf()` < 1.0 всегда
- [ ] `Rng.fake_values` подменяет поток в тестах; `randi_range(a,b)` не выходит за границы включительно
- [ ] `UtcClock.now_unix()` — единственная точка чтения системного времени в геймплее; `fake_now` подменяет его в тестах
- [ ] CI-grep по `src/` падает на глобальные `randf(`/`randi(`/`randomize(` и на `RandomNumberGenerator.new()` вне `rng.gd`

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/rng.gd` и `prototypes/tea-rush-vertical-slice/src/foundation/utc_clock.gd`. Вынести тестовую подмену (`fake_values`/`fake_now`) — оставить как есть либо заменить на подкласс/адаптер, если иначе нарушается «test-only API в prod-коде»; решение — в PR. CI-grep — скрипт в `tools/ci/` + шаг в `.github/workflows/tests.yml`. Статическая типизация везде, doc-комментарии (`##`) на публичном API, зависимости через конструктор (DI), без синглтонов.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Использование потоков `guest_tier`/`guest_recipe` — Guest AI эпик
- Till и дневной сброс — Till эпик

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/rng/rng_streams_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 008
