# Story 006: Плейтест темпа: ≤ X потерь до t = 120, заметность смены заказов

> **Epic**: Difficulty Curve & Session Pacing
> **Status**: Blocked
> **Blocked reason**: Open Question #2 GDD — значения X, Y не заданы
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M
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

AC 22–23 GDD: ≥ 5 тестеров × 3 партии; не автоматизируется. Порог X (потери до t = 120) и Y (% дожитий) не определены — до этого история не готова к выполнению.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: все значения из GDD Tuning Knobs — из подресурса GameConfig с sentinel-default и правилом ConfigValidator в том же изменении (from ADR-0004)
- Forbidden: литералы настроек в коде; глобальные `randf()/randi()/randomize()`; `load()`/`preload()` конфига внутри модуля; запись в конфиг (from ADR-0004)
- Guardrail: тесты строят конфиг через `ConfigFactory.valid()` + override, не читают .tres с диска (кроме одного интеграционного) (from ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/difficulty-curve-session-pacing.md`, scoped to this story:*

- [ ] ≥ 5 плейтестеров по 3 партии; до t = 120 средний тестер теряет ≤ X гостей и ≥ Y% партий доживают до t = 120 (X, Y заданы владельцем).
- [ ] ≥ 4 из 5 описывают смену заказов около 15 с как «разогрев кончился»; никто не называет её лагом и не описывает сложность как отдельный «тикающий» объект.

---

## Implementation Notes

Отчёт по шаблону `/playtest-report`, сохранить в `production/qa/evidence/pacing-playtest-evidence.md`. Совмещать с playtest по story 005 (medium_share).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Автоматизированные тесты кривых (stories 002–004)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/pacing-playtest-evidence-evidence.md` + sign-off (retained screenshot)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 004, 005; полная партия в сборке
- Unlocks: См. таблицу зависимостей эпика
