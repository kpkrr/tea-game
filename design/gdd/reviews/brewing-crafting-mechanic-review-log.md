# Review Log — Brewing & Crafting Mechanic

## Review — 2026-09-28 — Verdict: APPROVED
Scope signal: M
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 2
Summary: Все обязательные секции на tier `standard` присутствуют (Formulas триггернута числовыми правилами `t_brew`). Таблица чайника (12/12 комбинаций состояние×классификация) покрыта Acceptance Criteria один-в-один. Единственный найденный блокер — отсутствие type-тегов и пути тестов у Acceptance Criteria — устранён в этой же сессии до утверждения.
Prior verdict resolved: First review
Findings:
- [FIXED] Acceptance Criteria: отсутствовали type-теги (`[Logic]`/`[Integration]`) и шапка с путём тестов/фикстурами — добавлены (37 `[Logic]`, 2 `[Integration]`, `tests/unit/brewing_crafting/` + `BrewingFixtures`), по образцу `order-recipe-system.md` и `player-control-barista-movement.md`
- [RECOMMENDED] Core Rule 6: "кадр симуляции" для фонового таймера чайника неоднозначен относительно "физического тика" в контракте Player Control Rule 8 — уточнить перед реализацией, чтобы избежать рассинхрона детерминизма тестов
- [RECOMMENDED] Dependencies: пометка `⚠️ (не спроектирована, provisional)` у Brewing & Crafting в `player-control-barista-movement.md` должна быть снята при следующем ревью того документа (уже отслежено в этой GDD и в session-state)
Reviewed-Content-Hash: design/gdd/brewing-crafting-mechanic.md 8acc0aa806d5cebd7cc36da33d3fd10aad640338
Reviewed-Content-Hash: design/registry/entities.yaml 81204727ca91e43291a357c315d680a8954f7e70
