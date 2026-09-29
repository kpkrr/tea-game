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

## Review — 2026-09-29 — Verdict: APPROVED (batch-fix, без отдельного прохода /design-review)
Scope signal: —
Specialists: none (batch-fix: три параллельных fork-правки + сверка grep)
Blocking items: 0 | Recommended: 0
Summary: Все открытые находки `gdd-cross-review-2026-09-29b.md` и `-29c.md`, касавшиеся этого документа, закрыты одним пакетом правок по всем MVP GDD (решение пользователя — выйти из цикла ревью). Итоговая сверка: `is_new_record` согласован Currency↔HUD↔registry, нет живых пометок «не спроектирована» у спроектированных систем, registry YAML валиден.
Prior verdict resolved: Yes
Findings:
- none
Reviewed-Content-Hash: design/gdd/order-recipe-system.md 1485dcda4bdfde6a5915d535a9d5af66f19c826e
Reviewed-Content-Hash: design/registry/entities.yaml 53c076ca63df672c5d1c9a52d22afecbeba952b3
