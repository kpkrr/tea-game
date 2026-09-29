# Review Log: HUD & Feedback UI

## Review — 2026-09-29 — Verdict: APPROVED
Scope signal: L
Specialists: none (lean mode)
Blocking items: 1 (resolved same session) | Recommended: 2
Summary: Cross-checked every value the GDD cites against its owning upstream GDD and the registry (till_fill_ratio arithmetic, patience thresholds, recipe_price range and per-recipe values, guest state names, all Game Feel timings) — all confirmed consistent. Bidirectionality was verified for all declared dependencies except one: player-control-barista-movement.md declares itself a Hard downstream dependent of HUD with a concrete UI Requirements contract (world-space target outline + floor destination ring) that was entirely absent from hud-feedback-ui.md and from systems-index.md's dependency list for HUD. Fixed in-session: added as the 8th Hard dependency across Quick Reference, Overview, a new Core Rule 15, States table, Interactions, Dependencies, Visual/Audio, UI Requirements, Acceptance Criteria (AC 48-50), Cross-References, Open Questions (#6, exact visual TBD), qa-lead notes, and systems-index.md's dependency list. Also fixed a related registry gap: several entities (`recipe_price`, `remaining_fraction`, `till_amount`, `till_capacity`, `patience_warn_threshold`, `patience_urgent_threshold`) had "Read by HUD" in their own notes but did not list `design/gdd/hud-feedback-ui.md` in `referenced_by` — corrected.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Dependencies/Interactions/Core Rules/UI Requirements: missing Hard dependency on Player Control / Barista Movement (world-space selected-target outline, floor destination ring) — contract was already fully specified upstream in `player-control-barista-movement.md` UI Requirements but never pulled into this GDD; fixed same session (Core Rule 15, AC 48-50, 8th dependency row, systems-index.md updated).
- [RECOMMENDED] Registry (`design/registry/entities.yaml`): `referenced_by` arrays for `recipe_price`, `remaining_fraction`, `till_amount`, `till_capacity`, `patience_warn_threshold`, `patience_urgent_threshold` didn't include `hud-feedback-ui.md` despite each entry's `notes:` field saying "Read by HUD" — fixed same session, values themselves were already consistent.
- [RECOMMENDED] Open Question #1 (restart-signal owner, blocks AC 28) and Open Question #2 (exit-impulse duration) remain open — both already correctly scoped as non-blocking by the GDD itself with an owner and a resolution point (`/ux-design` for HUD, pre-epics); tracked, not re-litigated here.

Reviewed-Content-Hash: design/gdd/hud-feedback-ui.md cab01a36231ffb0c8da3f99dfb5815617e783875
Reviewed-Content-Hash: design/registry/entities.yaml bcf2e04922b89244cc056853d2f13935e431d3af

## Review — 2026-09-29 — Verdict: APPROVED (after in-session revision)
Scope signal: L
Specialists: none (lean mode)
Blocking items: 1 (resolved same session) | Recommended: 1
Summary: Full re-review (doc and registry both changed since the last log entry, due to `/propagate-design-change` propagating till-day-cycle.md Core Rule 4/5). Verified all 8 hard dependencies bidirectionally (incl. player-control-barista-movement.md's Core Rule 15 contract, confirmed word-for-word), checked till_fill_ratio at both boundaries, confirmed the removed "Приходите завтра"/DayClosed state is consistently gone from every other section. Found one leftover: the Game Feel "smooth" list still cited a shared fade-in timing for "both full-screen overlays (match end, Приходите завтра)" — the second target no longer exists. It survived the propagation sweep because the phrase wrapped across a line break, so a single-line grep for "Приходите завтра" never matched it. Fixed in-session.
Prior verdict resolved: Yes — this review is against document/registry state that changed after the prior APPROVED entry; the prior entry's own finding (Player Control dependency) remains fixed and was re-verified here.
Findings:
- [BLOCKING] Game Feel ("Что должно быть плавным"): stale reference to a second full-screen overlay ("Приходите завтра") that Core Rule 13/14 removed entirely — fixed same session, now cites only the match-end overlay.
- [RECOMMENDED] Cross-document: five upstream GDDs (kitchen-station-layout.md, brewing-crafting-mechanic.md, currency-coins-score.md, till-day-cycle.md, platform-integration-telegram-mini-app.md) still tag HUD & Feedback UI as "не спроектирована"/⚠️ despite systems-index.md showing it Approved — stale annotations in sibling docs, not fixed here (out of this review's scope); suggested for a `/consistency-check` pass or manual touch-up.

Reviewed-Content-Hash: design/gdd/hud-feedback-ui.md 7cbd486f3e7c43b7c61a230eea2b92b9e5e5ceb2
Reviewed-Content-Hash: design/registry/entities.yaml ff50645403ed7367d621347f425d75230f34cda6
