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

## Review — 2026-09-29 — Verdict: NEEDS REVISION (revised in session)
Scope signal: M
Specialists: none (lean mode)
Blocking items: 3 | Recommended: 8
Summary: Re-review after /balance-check (no-block Full) and C2 propagation, driven by gdd-cross-review-2026-09-29b.md. Core clamp and Open→Full rules are sound; blockers were contract gaps at the HUD boundary (what is animated when coins overflow) and an unimplementable reset trigger. User decisions: Till emits coins_added (0 at Full), overflow shown as a coin "bounce" without a number; reset checked only on match_started and cold start (return-to-app branch removed); D4 and overflow accounting deferred to Open Questions. Propagated to HUD Rule 11 / Visual §6 / AC 22, 22a and the registry note for daily_reset_time_utc.
Prior verdict resolved: Yes (prior Formula 3 window finding re-filed under D4 Open Question; Dependencies staleness fixed)
Findings:
- [BLOCKING] Visual/Audio, Core Rule 2: S3 — no visual for Served at Full / partial overflow; HUD animated full coins_earned → fixed (coins_added + bounce)
- [BLOCKING] Core Rule 6, Edge Cases, Dependencies: N3 — reset "on return to app if match not active" had no declared inputs → fixed (match_started + cold start only)
- [BLOCKING] Acceptance Criteria: N9 — AC 7/24 described "attempt to start a match"; no AC for match_started trigger → fixed (AC 6/7/24 rewritten, AC 38–41 added)
- [RECOMMENDED] Rule 5, Interactions, Dependencies, UX flag, Cross-References: N6 stale "HUD not designed"/"Приходите завтра"/match_ended text → fixed
- [RECOMMENDED] AC 34 still Blocked on HUD → unblocked
- [RECOMMENDED] Core Rule 1: persisted full_since_utc unspecified → added
- [RECOMMENDED] Core Rule 6 / States: reset applies only to Full, not stated in rule → fixed
- [RECOMMENDED] Visual/Audio Full→Open: reset now visible at match_started → fixed
- [RECOMMENDED] Formulas 2/3, AC 20–22: D4 overstated strong-player (≈43 guests, not ~50) and match length (~150 s, not 222 s) → flagged, Open Question
- [RECOMMENDED] Summary: D7 "daily limit" framing vs never-resetting Open till → not changed
- [RECOMMENDED] Registry till_capacity note (222 s) and systems-index l. 84–88 (W1) → not changed
Reviewed-Content-Hash: design/gdd/till-day-cycle.md 0bb1c5657e1ddd7703d4cd8e9cd1deb7e20bc9f8
Reviewed-Content-Hash: design/registry/entities.yaml 0f5ce2f38a6a29f10cb24d6d92e0fe07a54cd318

## Review — 2026-09-29 — Verdict: APPROVED (batch-fix, без отдельного прохода /design-review)
Scope signal: —
Specialists: none (batch-fix: три параллельных fork-правки + сверка grep)
Blocking items: 0 | Recommended: 0
Summary: Все открытые находки `gdd-cross-review-2026-09-29b.md` и `-29c.md`, касавшиеся этого документа, закрыты одним пакетом правок по всем MVP GDD (решение пользователя — выйти из цикла ревью). Итоговая сверка: `is_new_record` согласован Currency↔HUD↔registry, нет живых пометок «не спроектирована» у спроектированных систем, registry YAML валиден.
Prior verdict resolved: Yes
Findings:
- none
Reviewed-Content-Hash: design/gdd/till-day-cycle.md a729df77e110f5286c2cd6af7545e689d1c11a09
Reviewed-Content-Hash: design/registry/entities.yaml 53c076ca63df672c5d1c9a52d22afecbeba952b3
