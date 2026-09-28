# Review Log — Order & Recipe System

## Review — 2026-09-28 — Verdict: APPROVED
Scope signal: M (producer should verify — fan-out to whole MVP economy chain pushes real risk toward L)
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 3
Summary: Все 6 обязательных секций на tier `standard` присутствуют. Арифметика Formula 1/2 и все ценовые инварианты (AC 11–17) перепроверены вручную — расхождений нет. Двунаправленность зависимости с Kitchen & Station Layout подтверждена.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Edge Cases: `is_valid_next=false` даёт два разных реальных поведения (жёсткая блокировка vs мягкое разрешение+порча) — контракт не уточняет, какое из них гарантировано; решить при дизайне Brewing & Crafting Mechanic
- [RECOMMENDED] Tuning Knobs: секция отсутствует (advisory на `standard`) — временные значения (price_table, пороги 1.15/1.6, t_step/t_brew) стоит свести в одну секцию
- [RECOMMENDED] Acceptance Criteria: AC 32–33 не тестируют явно, что повторно взятый шаг (например, второй `cup`) даёт `is_valid_next=false`
Reviewed-Content-Hash: design/gdd/order-recipe-system.md 68432144f35be143aeb5b42a0c87ded7bb336194
Reviewed-Content-Hash: design/registry/entities.yaml fb457ac755969d44d38ccc1dee1c66ef5478e44f
