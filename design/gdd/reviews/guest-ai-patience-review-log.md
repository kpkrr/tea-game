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

## Review — 2026-09-29 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: none (lean mode)
Blocking items: 2 | Recommended: 5
Summary: Re-review after the 2026-09-29 cross-GDD review flagged this GDD. Formulas and ACs still hold. Both blockers were cross-system contract gaps, not internal errors: a guest in Approaching drained patience and could be served while HUD hid them, and no system owned match start/restart. All items were revised in the same session with user decisions (visible from spawn; Guest AI owns match start via Rule 13; single game time + max_step_delta; PC before Guest AI in frame). Downstream GDDs (HUD, Currency, Brewing, Player Control, Till, Difficulty) still need propagation before re-review.
Prior verdict resolved: Yes (2026-09-28 APPROVED items unaffected)
Findings:
- [BLOCKING → REVISED] Rule 4/5, UI Requirements, AC 46/47: guest readable from spawn (order token + patience ring in Approaching) — C1
- [BLOCKING → REVISED] new Rule 13, Edge Cases, AC 50–52: match start (auto on kitchen/safe-area ready; request_new_match from HUD; match_started once) — C2
- [RECOMMENDED → REVISED] Rule 11, Rule 12, AC 53/54: single game time for all match timers; max_step_delta = 0.25 s clamp (registry)
- [RECOMMENDED → REVISED] Rule 8, AC 49: Player Control updates before Guest AI; "execute" is step (1) of the same frame's tick
- [RECOMMENDED → REVISED] Formulas/Interactions/Dependencies/Game Feel/AC 45: stale "не спроектирована"/"ПРОВИЗОРНЫЙ" and game-concept-as-source references removed
- [RECOMMENDED → REVISED] Двунаправленность: HUD entry closed; propagation list for 6 GDDs added
- [RECOMMENDED → REVISED] Header Last Updated
Reviewed-Content-Hash: design/gdd/guest-ai-patience.md 692584298ea4f4b22e0722cfe01800e46cbf5156
Reviewed-Content-Hash: design/registry/entities.yaml 0dc4b715606c96addec472b84a44fc2edda3869b

## Review — 2026-09-29 — Verdict: APPROVED (batch-fix, без отдельного прохода /design-review)
Scope signal: —
Specialists: none (batch-fix: три параллельных fork-правки + сверка grep)
Blocking items: 0 | Recommended: 0
Summary: Все открытые находки `gdd-cross-review-2026-09-29b.md` и `-29c.md`, касавшиеся этого документа, закрыты одним пакетом правок по всем MVP GDD (решение пользователя — выйти из цикла ревью). Итоговая сверка: `is_new_record` согласован Currency↔HUD↔registry, нет живых пометок «не спроектирована» у спроектированных систем, registry YAML валиден.
Prior verdict resolved: Yes
Findings:
- none
Reviewed-Content-Hash: design/gdd/guest-ai-patience.md eee6922832d0bd999b7f0ef6368de10312be8111
Reviewed-Content-Hash: design/registry/entities.yaml 53c076ca63df672c5d1c9a52d22afecbeba952b3
