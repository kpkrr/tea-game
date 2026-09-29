# Cross-GDD Review Report — since-last-review

**Date**: 2026-09-29 (third run of the day; baseline `gdd-cross-review-2026-09-29b.md`)
**Mode**: since-last-review (`bash .claude/scripts/review-scope.sh`)
**Workflow tier**: standard
**Changed GDDs (per review-scope.sh)**: `hud-feedback-ui.md`, `till-day-cycle.md`
**Declared dependencies pulled into scope**: `guest-ai-patience.md`, `systems-index.md`. (`review-scope.sh` also emitted `hud-feedback-ui.md -> movement.md` — a false positive; no such file exists in `design/gdd/`. The real dependency this line was trying to name, `player-control-barista-movement.md`, was already fully verified against `hud-feedback-ui.md` during this session's `/design-review` and is not re-covered here.)
**GDDs reviewed**: 4 of 12 present (`hud-feedback-ui.md`, `till-day-cycle.md`, `guest-ai-patience.md` read directly against the named findings; `systems-index.md` read for status/dependency-table consistency). The remaining 8 GDDs were **not** re-read this pass — their open findings from `gdd-cross-review-2026-09-29b.md` are carried forward unchanged below, not re-verified.
**Method**: Direct verification against source text by the orchestrator (no sub-agents spawned) — appropriate for this pass's narrow, closure-tracking scope (verifying named findings S3/S4/N2/N3/N4/N6/N9 against two specific edited documents), matching the precedent set in `gdd-cross-review-2026-09-29b.md` itself, which used the same direct-verification method for several of its own findings (N1, N2, N3, N5, N8).

---

## Closure of prior findings (baseline: `gdd-cross-review-2026-09-29b.md`)

| ID | Status | Evidence |
|---|---|---|
| S3 — Serve while till is Full / partial overflow | **CLOSED** | `till-day-cycle.md` Core Rule 2 (l. 57–69): emits `coins_added` separately from `coins_earned`, clamped to remaining capacity; Visual/Audio (l. 442) adds the partial-overflow row. `hud-feedback-ui.md` Core Rule 11 rewritten around `coins_added`, bounce-without-number on overflow, no number at `coins_added = 0`. Numeric examples agree word-for-word (e.g. `till_amount=248`, `coins_earned=7` → `coins_added=2`, overflow 5) |
| S4 — New-record indicator not computable | **CLOSED on HUD's side / PARTIAL overall** | `hud-feedback-ui.md` Core Rule 13, AC 26/41, Formulas Read-only inputs and Open Question 8 now specify an explicit `is_new_record` (bool) input from Currency, computed by Currency at its own comparison point before/at the `best_score` update — this makes HUD's own contract precise and implementable (previously "match_score > предыдущий best_score" was uncomputable under HUD's own no-cache Core Rule 2, since `currency-coins-score.md` Core Rule 7 / AC 30 updates `best_score := match_score` at the exact same `match_ended` event HUD reads from). **Not closed**: `currency-coins-score.md` does not yet declare or emit `is_new_record` — this is a one-directional dependency until propagated. HUD correctly did not edit `currency-coins-score.md` itself (outside its delegated scope this session) and instead tracked the gap as Open Question 8 |
| N2 — Two pause sources for HUD | **CLOSED in HUD** | Edge Case ("фон приложения") rewritten: HUD no longer described as listening to the Platform Integration background signal directly; now cites the unified game time owned by `guest-ai-patience.md` Rule 11 (which already named "пульсация колец (HUD)" as an example of what pauses via game time). Dependencies/Interactions tables updated to list game time as an input from Guest AI |
| N3 — Till cannot implement its own reset rule | **CLOSED** | `till-day-cycle.md` Core Rule 6 (l. 96–109) dropped the "at return-to-app, if match not active" branch entirely — the system now checks the `daily_reset_time_utc` crossing only at `match_started` and cold start, both of which it can actually observe. AC 6, 7, 24 rewritten to match |
| N4 — HUD Dependencies contradict themselves | **CLOSED** | The self-contradicting sentence ("HUD & Feedback UI ... зависимых систем у неё нет" directly beside a "Guest AI & Patience *(downstream)*" row two lines above) was rewritten — Dependencies now states Guest AI & Patience as HUD's sole downstream, consistently |
| N6 — Stale text in Till (items 1–2 of 3) | **CLOSED** | (1) `guest-ai-patience.md` Interactions (l. 199) now excludes Till from `match_ended` recipients, listing only `match_started` — confirmed by direct grep, no remaining "Till ... match_ended" pairing. (2) `hud-feedback-ui.md`'s `DayClosed` state and "Приходите завтра" overlay are removed throughout (Core Rule 13/14, States table, UI Requirements, Visual/Audio, asset list) — confirmed no live (non-historical) reference remains. (Item 3, the `game-concept.md` "~5 партий" wording, was already closed per `till-day-cycle.md`'s own Open Questions table and is unrelated to this session's edits) |
| N9 — Till ACs not updated | **CLOSED** | AC 6/7 (l. 568–570) now key on `match_started`, not "попытка начать партию"/"возврат в приложение"; AC 24 (l. 601) explicitly covers "партия на паузе в фоне считается активной" |
| N1 — First-match trigger circular and undeclared | **OPEN, unchanged** | `guest-ai-patience.md` and `platform-integration-telegram-mini-app.md` were not in this pass's changed-file scope; not re-verified |
| N5 — Currency shows `best_score` on a start screen that no longer exists | **OPEN, unchanged** | `currency-coins-score.md` unmodified since the b-report |
| N7 — New edges missing from dependency tables (Brewing, Currency) | **OPEN, unchanged** | Same — files not in this pass's scope |
| N8 — Guest visibility in `MatchEnd` disagrees | **OPEN** | `hud-feedback-ui.md` States table (`MatchEnd` row) still reads "world-space элементы партии (жетоны, кольца) скрываются вместе с гостями", which reads as guests themselves disappearing. `guest-ai-patience.md` Rule 9 (l. 107–113) keeps guests frozen in place, visible, until the next `match_started` removes them (Rule 13, l. 161–163). Not fixed this pass — tracked as Recommended in this session's `/design-review` of HUD, not blocking (likely masked in practice by the full-screen overlay) |
| W10, W11 — Currency stale rule numbers / "закрытие дня" wording | **OPEN, unchanged** | `currency-coins-score.md` unmodified |
| N1-D — Accidental "Играть снова" tap skips results/record moment | **OPEN** | Not addressed in this session's HUD revision; tracked as Recommended |
| N2-D — Overlapping guest tokens in narrow portrait layout | **OPEN** | Same — tracked as Recommended, no Edge Case added yet |
| D9 | **OPEN, unchanged** | Tangential to Difficulty Curve & Session Pacing, not in this pass's scope |

---

## Consistency Issues

### Blocking
None.

### Warnings
⚠️ **S4 propagation gap (HUD × Currency)** — `hud-feedback-ui.md` now declares `is_new_record` as a Hard, read-only input from `currency-coins-score.md` (Core Rule 13, Dependencies, Cross-References, Open Question 8), but `currency-coins-score.md` does not declare or compute this value anywhere in its own Detailed Design, Formulas, or Dependencies sections. This is a one-directional dependency exactly analogous to the Player Control gap HUD closed earlier this session — it needs a `/propagate-design-change` (or `/design-system` revision) pass on `currency-coins-score.md` to become bidirectional. Until then, AC 26/41 in HUD are not fully testable end-to-end (the input they require doesn't exist upstream yet) — same shape as the now-closed AC 28 gap that HUD's own qa-lead notes previously tracked and resolved.

---

## Game Design Issues

### Blocking
None.

### Warnings
Carried forward unchanged from `gdd-cross-review-2026-09-29b.md` (not re-verified this pass, since the source files are outside this pass's changed-file scope):
- N1-D — "Играть снова" has no input grace window, risking an accidental skip of the results/new-record overlay during frantic end-of-match tapping.
- N2-D — Guest order tokens/rings can visually overlap when a walking guest's path crosses an occupied slot in the narrow 9:20 safe area; no Edge Case addresses this.
- D9 — still undefined, tangential to Difficulty Curve & Session Pacing.

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| currency-coins-score.md | S4 propagation — `is_new_record` not yet declared/emitted; also carries forward N5, N7, W10, W11 unchanged | Consistency | Warning |
| guest-ai-patience.md | N1 (circular first-match trigger), N8 (HUD's stale "guests hide with tokens" claim vs. Guest AI's actual frozen-in-place behavior) | Consistency | Warning |
| hud-feedback-ui.md | N1-D (accidental restart tap), N2-D (overlapping guest tokens) | Design Theory | Warning |

systems-index status: this pass does not change any status beyond what this session's `/design-review hud-feedback-ui.md` already set (HUD → Approved). `till-day-cycle.md`'s own assigned findings (S3, N3, N6, N9) all verified closed in this pass, but its systems-index status is left as-is (`Needs Revision`) — flipping it to Approved is a `/design-review` decision (full completeness + implementability check), not something this cross-doc pass unilaterally asserts. `guest-ai-patience.md` remains `Needs Revision` (N1, N8 still open).

---

## Verdict: CONCERNS

The one blocking item carried from the prior report (S3) is closed and confirmed bidirectionally consistent. No new blocking issues were found in the two changed documents or their cascading dependencies. Everything remaining is Warning-level: one partially-closed item (S4, closed on HUD's side, waiting on a Currency-side propagation) plus several previously-known, unchanged warnings in files this pass did not touch.

### Recommended before the next full run
1. Propagate `is_new_record` into `currency-coins-score.md` (declare, compute at the `best_score` comparison point, register in `design/registry/entities.yaml`) — closes S4 completely.
2. Run a full (non-`since-last-review`) `/review-all-gdds` once `currency-coins-score.md` and `guest-ai-patience.md` are next revised, to re-verify N1, N5, N7, N8, W10, W11 against their current text — this pass explicitly did not re-check them.
