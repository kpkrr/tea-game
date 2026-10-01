# Story 001: GuestConfig: ресурс и валидация при загрузке

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-002`, `TR-guest-017`, `TR-guest-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Константы — в подресурсах GameConfig (.tres), ConfigValidator собирает все ошибки с именем константы, модули получают конфиг конструктором, RNG — инъекцией (отдельные потоки guest_tier / guest_recipe), кривые — статические функции DifficultyCurve (не Curve).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (Resource/@export/duplicate_deep 4.5+ — сверить с breaking-changes.md)

Константы Guest AI живут в подресурсе `GameConfig.guest`. Невалидное значение — ошибка загрузки с именем константы, партия не стартует.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: все значения из GDD Tuning Knobs — из подресурса GameConfig с sentinel-default и правилом ConfigValidator в том же изменении (from ADR-0004)
- Forbidden: литералы настроек в коде; глобальные `randf()/randi()/randomize()`; `load()`/`preload()` конфига внутри модуля; запись в конфиг (from ADR-0004)
- Guardrail: тесты строят конфиг через `ConfigFactory.valid()` + override, не читают .tres с диска (кроме одного интеграционного) (from ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] Отгружаемый data file загружается без ошибок: `guest_slot_count` = 4, `max_guests_lost` = 3, пары порогов (warn 0.60, urgent 0.25), `max_step_delta` = 0.25, `medium_share_of_remaining` = 0.5 (GDD AC 1).
- [ ] Пары порогов (warn, urgent) вне допустимых, `max_guests_lost` = 0, `medium_share_of_remaining` = −0.1 или 1.2, NaN/INF/пропущенный ключ — ошибка с именем константы; `ConfigValidator` собирает все ошибки сразу (AC 2, 4).
- [ ] Фикстура Kitchen с 3 или 5 точками очереди при `guest_slot_count` = 4 — ошибка загрузки; слоты имеют стабильные ID (AC 3).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/guest_config.gd` (поля: guest_slot_count, max_guests_lost, onboarding_factor, onboarding_duration, medium_share_of_remaining, patience_warn/urgent_threshold, guest_walk_speed, max_step_delta). Привести к стандартам: статическая типизация, sentinel-default, doc-комментарии, правило в `ConfigValidator` в том же изменении. Значение `medium_share_of_remaining` в отгружаемом .tres = 0.5 по GDD (слайс использует 0.75 — см. difficulty-curve story 005). Порт `game_config.tres` секции guest — данные, не литералы.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004–007: использование констант в логике
- difficulty-curve story 001: валидация DifficultyConfig

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Logic
**Required evidence**:
- `tests/unit/guest/guest-config-validation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: foundation-runtime (GameConfig, ConfigValidator, ConfigFactory)
- Unlocks: См. таблицу зависимостей эпика
