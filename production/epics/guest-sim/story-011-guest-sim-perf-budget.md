# Story 011: Бюджет Guest AI ≤ 0,5 мс avg / 1,0 мс p99

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-022`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets
**ADR Decision Summary**: Бюджет GuestSim 0,50 мс avg / 1,00 мс p99 на кадр (провизорно до прогона на слабом Android); PerfProbe измеряет мс на систему.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: MEDIUM (цифры кадра провизорные до прогона на слабом Android)

Замер через PerfProbe на сценарии 4 гостя, 18 гост/мин, 180 с. Цифры провизорные до прогона на слабом Android (ADR-0007).

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: замер через PerfProbe; GuestSim 0,50 мс avg / 1,00 мс p99 (from ADR-0007)
- Forbidden: аллокации словарей/массивов на кадр в горячем пути `step()` без необходимости (from ADR-0007)
- Guardrail: цифры провизорные до прогона на слабом Android — результат фиксировать как замер, не как приёмку (from ADR-0007)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] Headless/debug-замер `GuestSim.step` на 180 с: среднее ≤ 0,5 мс, p99 ≤ 1,0 мс (AC 48, ADVISORY); результат записан.
- [ ] Горячий путь `step()` без аллокаций на кадр сверх необходимого (проверка на code-review).

---

## Implementation Notes

Подключить `PerfProbe` (foundation-runtime); результат — в `production/qa/evidence/guest-sim-perf.md`. На web-сборке повторить после появления слабого Android — до этого не приёмка, а замер.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- perf-profile на всей игре

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Integration
**Required evidence**:
- `tests/integration/guest/guest-sim-perf-budget_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 004–008
- Unlocks: См. таблицу зависимостей эпика
