# Balance Check: Economy (Currency: Coins & Score + Till & Day Cycle + Order & Recipe System)

**Date**: 2026-09-29
**Domain**: Economy
**Supersedes / follows**: `design/balance/balance-check-currency-coins-score-2026-09-29.md` (re-run after its High-priority fix)

## Data Sources Analyzed
- `design/registry/entities.yaml` — constants (`score_multiplier_base`=10, `till_capacity`=250, `daily_reset_time_utc`=0) and formulas (`recipe_price`, `score_earned`, `coins_earned`, `till_amount`)
- `design/gdd/currency-coins-score.md` — full GDD
- `design/gdd/order-recipe-system.md` — `price_table` (2/5/5/7/7), Formula 2 (`coins_per_sec`), price invariants
- `design/gdd/till-day-cycle.md` — Formulas 1–4, Open Questions
- `design/gdd/guest-ai-patience.md`, `design/gdd/hud-feedback-ui.md` — grep check that the earlier fix is propagated
- `design/balance/balance-check-currency-coins-score-2026-09-29.md` — prior report
- `assets/data/` — **ABSENT** (pre-implementation; values live only in GDDs/registry)

All figures are analytical estimates from the GDDs (economy-designer / systems-designer), **not** simulation or playtest data. No such source exists in the project yet.

## Health Summary: HEALTHY (one open Low risk, non-blocking)

The prior report's High-priority issue (mastery reduced matches per day) is fixed, and propagation is **verified**: grep finds no live references to `DayClosed`, «Приходите завтра» or till-blocking via `match_ended` in `guest-ai-patience.md` / `hud-feedback-ui.md`. The only matches are removal notes. Both Medium items are now resolved this session (see Fix Applied). One Low risk remains open.

## Outliers Detected

| Item/Value | Expected Range | Actual | Issue |
|---|---|---|---|
| `revenue_per_match_avg` | One calibrated figure | 75–90 (economy-designer) vs ~99 (systems-designer) | Two estimates, not reconciled. **Documented this session** (see Fix Applied) — resolved as two different bottleneck scenarios, not competing measurements |
| Average guest price trend within a match | Consistent across GDDs | Was: `order-recipe-system.md` claimed falls 6.0 → ~5.2, contradicting `till-day-cycle.md` Formula 3's rising trend | **Fixed this session** (see Fix Applied) — the 6.0→5.2 claim was mathematically impossible given `price_table` (2/5/7, max 7) and `complex_order_share(t)` ∈ [0, 0.40]. Corrected to ≈3.5→4.9, now consistent across both GDDs |
| Monetization / token assumption | Must not depend on a removed constraint | Daily cap no longer limits playtime, only coin growth | Open risk (creative-director, 2026-09-29), owner economy-designer |

## Degenerate Strategies Found
- **None new.**
- **Accepted by design:** a perfectly served medium recipe (5×10×2=100) outscores a complex recipe served at the patience edge (7×10×1=70) when `remaining_fraction > 0.4` (currency-coins-score.md AC 24).
- Confirmed without recomputation: cheap recipes never beat complex on throughput (price gap ×3.5 > execution-time gap ×1.9; `coins_per_sec` 0.333 / 0.625 / 0.700 at η=0).

## Progression Analysis

`till_amount` accumulation (till_capacity=250, match ≈222 s):

| Player | Coins/match | Matches to fill | Real time |
|---|---|---|---|
| Average | 75–90 | ≈2.8–3.3 | ≈9.3–11 min |
| Barista-bottleneck upper bound | ~99 | ≈2.5 | ≈8.4 min |
| Strong (~50 guests, 40% complex) | 225–245 | ≈1.0–1.1 | ≈3.7–4.1 min |

The till full state no longer blocks matches, so a strong player filling it in ~1 match is only a faster earning pace. Playtime is not reduced.

## Recommendations

| Priority | Issue | Suggested Fix | Impact | Status |
|---|---|---|---|---|
| High | Mastery reduced matches/day | Decouple match start from till fullness | Removes skill/playtime inversion | **Fixed; propagation verified** |
| Medium | 75–90 vs ~99 `revenue_per_match_avg` | Document them as different bottleneck scenarios; validate with a queue simulation or playtest | `till_capacity` calibration rationale is now explicit | **Documented 2026-09-29.** Validation still open |
| Medium | Guest price trend contradiction (6.0→5.2 vs rising) | Recompute from `price_table` + `complex_order_share(t)`; correct the wrong GDD | One of two GDDs stated a false, mathematically impossible claim | **Fixed 2026-09-29** — see Fix Applied below |
| Low | Monetization/token may assume the old playtime cap | Confirm before Progression & Upgrades / Monetization design | Avoids Alpha rework | Open |

## Values That Need Attention
- `revenue_per_match_avg` — keep 75–90 as the calibration input for `till_capacity`=250. Treat ~99 as a theoretical upper bound only. No value change until simulation/playtest data exists.
- `price_table` 2/5/5/7/7 — no change recommended. Both invariants hold (7 ≤ 8.05, 7 ≤ 8.0). The medium/complex score crossover is accepted.
- `avg_price_per_guest` — corrected trend is ≈3.5 (match start, `complex_order_share`=0) rising to ≈4.9 (plateau, `complex_order_share`=0.40). No `price_table` change; this was a documentation error, not a balance defect.

## Fix Applied (2026-09-29)

`design/gdd/till-day-cycle.md`:
1. **Formula 2**: added «Разница между 75–90 и ~99». 75–90 is limited by guest arrival rate and 3-strike loss. ~99 is limited by barista throughput and is an upper bound. Calibration uses 75–90 only.
2. **Open Questions**: the `revenue_per_match_avg` row is closed as documented, not recomputed. A new, narrower row is open: which bottleneck actually dominates real play. It needs a queue simulation or playtest before Alpha.
3. **Open Questions**: the guest price trend contradiction row is closed — see below.

`design/gdd/order-recipe-system.md`:
4. **Formulas** (pricing note): replaced the stale «падает с 6.0 до ~5.2» claim, which was mathematically impossible against `price_table` (2/5/7, max 7) and `complex_order_share(t)` ∈ [0, 0.40] (`difficulty-curve-session-pacing.md` Formula 4), with the recomputed trend: `avg_price_per_guest` ≈3.5 at match start → ≈4.9 at plateau (using `p_medium = p_simple = (1 − complex_order_share) × 0.5`, `guest-ai-patience.md` Formula 3). This now matches the 4.2/4.9 values `till-day-cycle.md` Formula 3 already used.

No registry values changed, so `/propagate-design-change` is not required for this edit.

Re-run `/balance-check` after fixes to verify.
