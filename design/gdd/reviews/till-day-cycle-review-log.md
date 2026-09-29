# Review Log: Till & Day Cycle

## Review — 2026-09-29 — Verdict: APPROVED
Scope signal: L
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 2
Summary: Tick ordering for Closing→Closed was cross-checked against the literal text of guest-ai-patience.md Rule 9 (Served processed before end-of-match check) and confirmed correct. Both upstream dependencies (Currency: Coins & Score, Guest AI & Patience) are bidirectional and verified on disk. All Formula 1 clamping examples check out arithmetically. Two non-blocking issues found: the Formula 3 calibration window (t≈90–150s) contradicts the ~222s average match duration used as the calibration anchor elsewhere in the same Formulas section, and the Dependencies section's claim that systems-index.md still needs a Phase 5d update is stale — the index already lists both dependencies.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Formulas (Formula 3, recipe_mix): stated "typical overload window t≈90–150s" contradicts the ~222s average match duration cited as the calibration anchor in the same Formulas intro; difficulty-curve-session-pacing.md's own complex_order_share(t) table shows 10% at t=90 rising to ≈27.8% at t=150, so anchoring near the start of that window likely understates avg_price_per_guest and revenue_per_match_avg — compounds the existing Open Question #1 disagreement (75–90 vs ≈99).
- [RECOMMENDED] Dependencies (paragraph after Bidirectionality table): states systems-index.md "currently only lists Currency: Coins & Score" pending a Phase 5d update — but systems-index.md (lines 156, 217) already lists both dependencies, with an explicit note that Guest AI & Patience was added during this system's design. Sentence is stale.

Reviewed-Content-Hash: design/gdd/till-day-cycle.md 87013656c4e87d68f16d339a9b70fa1e7573465b
Reviewed-Content-Hash: design/registry/entities.yaml 0888626b3b1304118d74711324f4236123213517
