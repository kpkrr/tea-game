# Story 005: Sync medium_share_of_remaining после плейтеста владельца

> **Epic**: Difficulty Curve & Session Pacing
> **Status**: Blocked
> **Blocked reason**: owner playtest — подтверждение владельцем ощущения слайса (0.75 vs GDD 0.5)
> **Layer**: Feature
> **Type**: Config/Data
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/difficulty-curve-session-pacing.md`
**Requirement**: `TR-pacing-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Константы — в подресурсах GameConfig (.tres), ConfigValidator собирает все ошибки с именем константы, модули получают конфиг конструктором, RNG — инъекцией (отдельные потоки guest_tier / guest_recipe), кривые — статические функции DifficultyCurve (не Curve).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: LOW (Resource/@export/duplicate_deep 4.5+ — сверить с breaking-changes.md)

Открытый пункт баланса: слайс использует `medium_share_of_remaining` = 0.75 (простых на t=90 22% вместо 45%, на плато 15% вместо 30%; `prototypes/tea-rush-vertical-slice/README.md`), GDD (Formula 3, Tuning Knobs) — 0.5. Любая из сторон правится только после подтверждения владельца.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: все значения из GDD Tuning Knobs — из подресурса GameConfig с sentinel-default и правилом ConfigValidator в том же изменении (from ADR-0004)
- Forbidden: литералы настроек в коде; глобальные `randf()/randi()/randomize()`; `load()`/`preload()` конфига внутри модуля; запись в конфиг (from ADR-0004)
- Guardrail: тесты строят конфиг через `ConfigFactory.valid()` + override, не читают .tres с диска (кроме одного интеграционного) (from ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/difficulty-curve-session-pacing.md`, scoped to this story:*

- [ ] После playtest зафиксировано решение владельца (0.5 или 0.75); значение в отгружаемом `game_config.tres` и в GDD `guest-ai-patience.md` (Formula 3, Tuning Knobs, AC 1) совпадают.
- [ ] Фикстуры и ожидаемые числа Formula 3 в тестах (AC 34–37, guest-sim story 007) пересчитаны под выбранное значение; smoke-check пройден.

---

## Implementation Notes

Если выбрано 0.75 — `/propagate-design-change` на GDD Guest AI (Formula 3 + Tuning Knobs + AC 1) и ADR-0004 примеры. Диапазон валидатора [0, 1] не меняется. Аналогичные till-связанные параметры в этом эпике не найдены.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Код выбора рецепта (guest-sim story 007)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Config/Data
**Required evidence**:
- smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Owner playtest; guest-sim story 001, 007
- Unlocks: См. таблицу зависимостей эпика
