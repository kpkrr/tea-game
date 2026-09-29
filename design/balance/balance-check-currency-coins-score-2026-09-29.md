# Balance Check: Currency: Coins & Score (+ Till & Day Cycle)

**Date**: 2026-09-29
**Domain**: Economy

## Data Sources Analyzed
- `design/registry/entities.yaml` — constants (`score_multiplier_base`=10, `till_capacity`=250, `daily_reset_time_utc`=0) and formulas (`recipe_price`, `score_earned`, `coins_earned`, `till_amount`)
- `design/gdd/currency-coins-score.md` — full GDD (Formulas, economy-designer balance validation, Edge Cases, Open Questions)
- `design/gdd/order-recipe-system.md` — `price_table` (2/5/5/7/7), Formula 2 (`coins_per_sec`)
- `design/gdd/till-day-cycle.md` — till mechanics, Formula 1–4, Open Questions
- `design/gdd/hud-feedback-ui.md` — confirms `till_fill_ratio` contract, day state
- `design/gdd/systems-index.md` — Progression & Upgrades tiers (250/350/500/700)
- `assets/data/` — **ABSENT** (pre-implementation stage; values live only in GDD/registry)
- `design/balance/` — **ABSENT** prior to this report (no earlier `/balance-check` to build on)

All figures below are analytical estimates already computed inside the GDDs (economy-designer / systems-designer), **not** simulation or playtest data — no such source exists in the project yet.

## Health Summary: CONCERNS

Formulas are internally consistent and already self-validated at design-review time. One severe, previously undocumented asymmetry was found (see Outliers row 1), plus several already-open but unreconciled figures.

## Outliers Detected

| Item/Value | Expected Range | Actual | Issue |
|---|---|---|---|
| Matches/day for a strong player | Skill should buy *more* play, not less | `revenue_per_match_avg` for a strong player (225–245 coins) filled the till (250) in **~1.0–1.1 matches**, vs ~2.8–3.3 for an average player | Not flagged in any of the three GDDs read. Average player got ~3 matches/day; strong player effectively got one — mastery *shortened* available daily play (before this fix) |
| `revenue_per_match_avg` | One calibrated figure | Two unreconciled formula estimates: 75–90 (economy-designer) vs ~99 (systems-designer, throughput model) | `till_capacity`=250 calibrated on the first estimate; the second gives `matches_to_fill`≈2.5 instead of 2.8–3.3. Already an open question, unresolved |
| Day length target | `game-concept.md`: "~5 matches (~10 min)" | Real match length (~222s) makes 5 matches ≈18.5 min — incompatible with 10 min; `till-day-cycle.md` resolved in favor of ~3 matches/~11 min but `game-concept.md` source text not corrected | Already an open question, fix not applied to source doc |
| Sinks for `coins_earned`/`till_amount` | An economy usually has a sink scaling with the faucet | No sink existed in MVP — Tea Coin is earn-only (Core Rule 6); `till_amount` resets to 0 on Full→Open with no persistent wallet | Deliberate MVP scope choice (Progression & Upgrades not in MVP), but it is the only "sink" in the system and it is invisible/uncontrollable by the player |

## Degenerate Strategies Found
- **None found** in the coin/score formulas — economy-designer's throughput analysis shows cheap recipes are never more efficient than complex ones even accounting for better `remaining_fraction` (price gap ×3.5 > execution-time gap ×1.9). Confirmed in the GDD itself, not recomputed here.
- **Found but accepted by design**: a perfectly-served medium recipe (5×10×2=100) can outscore a complex recipe served at the guest's patience edge (7×10×1=70) when `remaining_fraction > 0.4` — documented as an intentional consequence of the 2/5/5/7/7 price table (AC 24, currency-coins-score.md), not a defect.

## Progression Analysis

`till_amount` accumulation per day (till_capacity=250, match ≈222s):

| Player | Coins/match | Matches to fill till | Real time to fill |
|---|---|---|---|
| Average | 75–90 | ≈2.8–3.3 | ≈9.3–11 min |
| Strong (alt. model ≈99) | 99 | ≈2.5 | ≈8.4 min |
| Strong (stated, ~50 guests, 40% complex) | 225–245 | ≈1.0–1.1 | ≈3.7–4.1 min |

Before the fix applied below, the day *closed entirely* (no new matches) once the till filled — inverting the usual retention curve: higher skill meant less play per day.

## Recommendations

| Priority | Issue | Suggested Fix | Impact | Status |
|---|---|---|---|---|
| High | Strong player got ~1 match/day vs ~3 for average | Decouple the match-start gate from till fullness — till stops growing at capacity but new matches remain playable until the next `daily_reset_time_utc` | Removes the mastery-punishes-playtime inversion | **Applied** — see below |
| Medium | Two unreconciled `revenue_per_match_avg` estimates (75–90 vs ~99) | Reconcile formula models or get a real playtest/queue-simulation number before Alpha | `till_capacity` calibration rests on an unvalidated figure | Open |
| Medium | `game-concept.md` "~5 matches" not corrected after `till-day-cycle.md` decision | Update `game-concept.md` wording to "~3 matches" | Doc drift for new team members | **Done 2026-09-29** |
| Low | `till_amount` burns on daily reset with no player-facing explanation | HUD note: communicate that the accumulated amount is capped by design, not lost to a bug | Doesn't block MVP, affects perceived fairness | Open |

## Fix Applied (High priority, 2026-09-29)

`design/gdd/till-day-cycle.md` Core Rule 4/5 changed: reaching `till_capacity` no longer blocks starting new matches or triggers a day-closed screen. States collapsed from Open/Closing/Closed to Open/Full. `till_amount` stops growing at capacity; `match_score`/`best_score` and new matches are unaffected until the next `daily_reset_time_utc` resets `till_amount` to 0.

**Propagation required before this can be committed / go through `/design-review` again:**
1. `design/gdd/guest-ai-patience.md` lists Till & Day Cycle as a `match_ended` recipient — that dependency edge is now stale.
2. `design/gdd/hud-feedback-ui.md` defines a blocking `DayClosed` state and a "Приходите завтра" overlay with AC 27/29/32/33/34 tied to the old Closing→Closed behavior — needs rework into a non-blocking "till full" indicator.
3. Pillar 3 framing ("одна касса, одно правило, играть после которого нельзя ни в каком режиме") is diluted by this change — flagged for creative-director review.

**Resolved 2026-09-29** (manual propagation — `/propagate-design-change` could not diff an untracked file, and no ADRs exist): (1) and (2) edited; (3) creative-director verdict — consistent with canonical Pillar 3, pillar text unchanged; `game-concept.md` prose rewritten and the Submission aesthetic reframed as the daily "fill the till" goal. New open risk for economy-designer: the daily limit no longer caps playtime, so confirm that monetization and the token did not depend on it.

Re-run `/balance-check` after fixes to verify.
