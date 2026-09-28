# Review Log — Guest AI & Patience

## Review — 2026-09-28 — Verdict: APPROVED
Scope signal: L, на грани XL
Specialists: none (lean mode)
Blocking items: 0 (1 найден, устранён в этой же сессии) | Recommended: 0 (2 найдены, устранены в этой же сессии)
Summary: Все 6 обязательных секций tier `standard` присутствуют (Formulas триггернута числовыми правилами спавна/терпения/вероятностей). Формулы перепроверены вручную на граничных значениях и сверены с `order-recipe-system.md` — совпадают. Все заявленные двунаправленные зависимости подтверждены чтением пяти смежных GDD. Единственный найденный блокер — устаревший флаг про Kitchen & Station Layout (Open Question #1 и производные формулировки в 4 других местах), который на деле уже был закрыт в самой Kitchen 2026-09-28, но не синхронизирован в этом документе — исправлено. Обе рекомендации (валидация `medium_share_of_remaining`, отсутствующая секция Tuning Knobs) также закрыты до утверждения.
Prior verdict resolved: First review
Findings:
- [FIXED] Interactions / Dependencies / «Двунаправленность» / Cross-References / Open Question #1: документ утверждал, что Kitchen & Station Layout не фиксирует число точек очереди гостей, хотя Kitchen уже перечисляет ровно 4 точки со стабильными ID и точку выхода (добавлено 2026-09-28 в той же сессии) — все пять мест переписаны как «сходится», Open Question #1 закрыт, устаревший флаг убран из `entities.yaml` (`guest_slot_count`)
- [FIXED] Rule 12 / AC 3: `medium_share_of_remaining` не входил в список констант, валидируемых при загрузке, хотя Formula 3 использует его как множитель и выход за `[0, 1]` даёт вырожденные вероятности — добавлен в Rule 12 и в AC 3
- [FIXED] Tuning Knobs: секция отсутствовала (advisory на `standard`) — добавлена, 7 констант с baseline/диапазоном/эффектом
Reviewed-Content-Hash: design/gdd/guest-ai-patience.md e491b8d0d0f27862e5ff57dba25cbc0f4389d62d
Reviewed-Content-Hash: design/registry/entities.yaml 971155f80f4da025875f0787f300e44fecb340be
