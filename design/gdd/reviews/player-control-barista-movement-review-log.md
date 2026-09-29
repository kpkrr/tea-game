# Review Log: Player Control / Barista Movement

## Review — 2026-09-28 — Verdict: APPROVED
Scope signal: L
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 2
Summary: Все 6 обязательных на `standard` секций присутствуют и формулы проверены на границах без вырождения. Найдены две некритичные документационные несостыковки — устаревший TODO про `systems-index.md` (уже сделано) и неснятая блок-аннотация на AC7 в `kitchen-station-layout.md` (пропагация в чужой документ).
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Двунаправленность: заметка «в systems-index.md не указано — добавить в §5d» устарела — Guest AI & Patience уже ссылается на Player Control в индексе.
- [RECOMMENDED] Dependencies: `kitchen-station-layout.md` AC7 всё ещё помечен «Заблокировано, пока Player Control не зафиксирует радиус агента», хотя Formula 2 здесь уже фиксирует `agent_radius` = 0.40 м — снять аннотацию при следующей правке/ревью Kitchen.
Reviewed-Content-Hash: design/gdd/player-control-barista-movement.md 2d44293a3e08316b0ecfae04c395405ff80dd8d0
Reviewed-Content-Hash: design/registry/entities.yaml ddf1bbaf1ff4c1332d33160a9c6ba73382233ec5

## Review — 2026-09-29 — Verdict: APPROVED (batch-fix, без отдельного прохода /design-review)
Scope signal: —
Specialists: none (batch-fix: три параллельных fork-правки + сверка grep)
Blocking items: 0 | Recommended: 0
Summary: Все открытые находки `gdd-cross-review-2026-09-29b.md` и `-29c.md`, касавшиеся этого документа, закрыты одним пакетом правок по всем MVP GDD (решение пользователя — выйти из цикла ревью). Итоговая сверка: `is_new_record` согласован Currency↔HUD↔registry, нет живых пометок «не спроектирована» у спроектированных систем, registry YAML валиден.
Prior verdict resolved: Yes
Findings:
- none
Reviewed-Content-Hash: design/gdd/player-control-barista-movement.md db3585406fef5f6f9b86c95ad817d920a79eaec9
Reviewed-Content-Hash: design/registry/entities.yaml 53c076ca63df672c5d1c9a52d22afecbeba952b3
