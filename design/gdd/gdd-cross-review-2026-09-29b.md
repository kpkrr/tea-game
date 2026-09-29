# Cross-GDD Review Report — Re-review

**Date**: 2026-09-29 (second run of the day; baseline `gdd-cross-review-2026-09-29.md`)
**Mode**: since-last-review (consistency + design theory + scenario walkthrough)
**Workflow tier**: standard
**GDDs reviewed**: 6 of 10 system GDDs present in scope (changed since baseline): Guest AI & Patience, HUD & Feedback UI, Till & Day Cycle, Currency: Coins & Score, Brewing & Crafting, Player Control / Barista Movement (+ `systems-index.md`, `design/registry/entities.yaml`). Difficulty Curve and Platform Integration grepped for the new terms only. **Not checked**: `kitchen-station-layout.md`, `order-recipe-system.md`, systems-index Progress Tracker (W14) and l. 84–88 (W1), registry notes `till_capacity` / `daily_reset_time_utc` (W13 remainder).
**Pillars**: P1 Хаос за стойкой · P2 Цена видна в чашке · P3 Одна касса, одно правило · P4 Монеты за работу, очки за мастерство

**Method**: Phase 2 (+ Phase 4 re-walk) and Phase 3 ran as parallel `game-designer` sub-agents reading the diff since the baseline and the in-scope GDDs directly (orchestrator did not pre-load full GDDs). The Phase 2 agent hit its turn limit and delivered a partial report; unchecked items are listed above. The blocker and N1, N2, N3, N5, N8 were re-verified by the orchestrator against source text.

---

## Closure of prior findings

| ID | Status | Evidence |
|---|---|---|
| C1/S1 Approaching invisible | **CLOSED** | guest-ai:74–80 (Rule 4 «читаем с момента спавна»); hud:83–100 (Rule 4/5); HUD AC 8/10; Guest AI AC 46/47 |
| C2/S2 Match start owner | **CLOSED (contract) / PARTIAL (propagation)** | guest-ai:150–170 (Rule 13), AC 50–52; HUD States, AC 28 unblocked, OQ #1 closed; Currency :84/:92; Brewing :308–311; Till :123/:256–258/:307–309; PC Dependencies. Difficulty (unchanged) already reads `t` from Guest AI. See N1, N4–N7 |
| S3 +coins while Full | **OPEN** | hud:133–141 Rule 11 unchanged; no Till Visual/Audio row |
| S4 New-record indicator | **OPEN** | hud:146–148 vs currency:85, HUD Rule 2 |
| S5 Frame order | **CLOSED** | guest-ai:102–106, AC 49 |
| S6 Till reset during paused match | **PARTIAL** | Rule exists at till:307–309 but inputs undeclared (N3) |
| S7 Delta clamp | **CLOSED** | guest-ai:135–140, :144, AC 1/3/53; Brewing :315–317; PC Edge Case; registry `max_step_delta` 0.25 |
| W2 Till ↔ match_ended | **PARTIAL** | Index and core tables fixed; leftovers till:83, :377, :488 (N6) |
| W6 «не спроектирована» | **PARTIAL** | Fixed in Guest AI; still till:75, :124, :362, :377, :567; platform:98, :204, :258 |
| W8 Two pause sources | **PARTIAL** | Fixed in PC and Brewing :312–317; leftovers brewing:300–302, hud:306–311, HUD AC 42 (N2) |
| W10 Currency «закрытие дня» | **OPEN** | currency:70, :415, :450 |
| W11 Currency rule numbers | **OPEN** | currency:42 (Rule 8 → 5), :231 and :393 (Rule 9 → 8). Rule 13 was appended, so no citation was newly broken |
| W13 Registry notes | **PARTIAL** | `max_guests_lost` fixed; rest not checked |
| W1, W14 | **NOT CHECKED** | not in diff |
| D1–D9 | **UNCHANGED** | Diff did not touch balance, economy, payoff or the lives widget |

---

## Consistency Issues

### Blocking
🔴 **S3 — Serve while till is Full / partial overflow** (HUD × Till × Currency)
- `hud-feedback-ui.md` Rule 11 (l. 138): «`+coins_earned` летит к кассе» on every serve.
- `till-day-cycle.md` clamps the increment to 0 / remainder (l. 56–64); Visual/Audio (l. 390–394) has no «Served при Full» or partial-overflow row; Impact Moments (l. 444) «+N монет… у кассы» ignores the clamp.
- Contradictory messaging in the state a strong player spends most of the day in (P3).
- Options: (a) Till exposes `coins_added` (actual increment) and HUD animates that; (b) explicit «не влезло» visual.

### Warnings
- ⚠️ **N1 — First-match trigger is circular and undeclared.** guest-ai:154–156 «тот же триггер, по которому HUD переходит `Inactive` → `Active`»; hud:181 defers back to Guest AI. No system emits «кухня и safe area готовы». Platform has a `Ready` state (platform:85–87) but its Guest AI row (platform:207) lists only visibility. Options: (a) Rule 13 cites Platform `Ready` + kitchen scene loaded, declared on both sides; (b) a bootstrap owner emits «world ready» (ADR). Related: Rule 12 load error → «партия не стартует» leaves HUD in `Inactive` with no error state.
- ⚠️ **N2 — «Single pause source» contradicted by leftover text.** guest-ai:127–133 «единственный источник паузы… Другие системы не слушают сигнал Platform напрямую… анимации и пульсация колец (HUD)». brewing:300–302 still says «Platform Integration, сигнал паузы — soft-зависимость Player Control» next to the new bullet; hud:306–311 and HUD AC 42 key on the Platform signal; HUD Dependencies do not list game time. HUD animations therefore have no clamp after a WebView freeze. Options: (a) delete brewing:300–304, rebase HUD Edge Case/AC 42 on game time and declare it; (b) explicitly exempt HUD presentation animations with their own clamp.
- ⚠️ **N3 — Till cannot implement its own reset rule.** till:307–309 needs «партия не активна» and «при возврате в приложение», but Till consumes only `match_started` (till:123, :356), explicitly not `match_ended`, and declares no Platform dependency; Platform downstream (platform:199–207) has no Till row. Options: (a) add `match_ended` or an `is_match_active` query + visibility-return signal, both sides; (b) drop the return-to-app branch and check only at `match_started` and cold start.
- ⚠️ **N4 — HUD Dependencies contradict themselves.** hud:359 Guest AI row lists only `guests_lost`, `match_ended` (missing `match_started`, Approaching visibility per hud:199); hud:363 adds Guest AI as downstream but hud:365–367 says «зависимых систем у неё нет»; hud:343–345 claims all upstreams are confirmed both ways. Guest AI Upstream (guest-ai:472–478) has no HUD row although `request_new_match` is required for every match after the first.
- ⚠️ **N5 — Currency shows `best_score` on a start screen that no longer exists.** currency:370 «Экран старта партии и итоговый экран | При старте партии» vs guest-ai:156 «стартового экрана нет»; HUD has no such state. Options: remove the row, or add a HUD rule for `best_score` in `Active` (conflicts with HUD Rule 10).
- ⚠️ **N6 — Stale text in Till** (*quick fix*). till:83 (propagation to Guest AI/HUD still «нужно»), :124 and :362 «HUD *(не спроектирована)*… требует `/propagate-design-change`», :377 «Ни одна из четырёх downstream-систем ещё не спроектирована», :476 «Приходите завтра», :488 «guest-ai пока перечисляет Till как получателя `match_ended`» (false since guest-ai:114–117). No `match_started` row in Till Cross-References.
- ⚠️ **N7 — New edges missing from tables.** brewing:158, :341 Guest AI rows lack `match_started` and game time (declared Hard at guest-ai:195, :487); currency:269 lacks `match_ended`/`match_started` (present at :92), Cross-References :390–394 lack `match_started`; registry `max_step_delta.referenced_by` lists only guest-ai though Brewing :315 and PC Edge Case cite it.
- ⚠️ **N8 — Guest visibility in `MatchEnd` disagrees.** hud:183 «жетоны, кольца скрываются вместе с гостями» vs guest-ai:107–113, :431–436 (frozen guests stay in place until Rule 13 removes them). Options: HUD hides only tokens/rings, or Guest AI hides guests at `match_ended`.
- ⚠️ **N9 — Till ACs not updated.** till:516 (AC 7) and :548 (AC 24) say «попытка начать партию / возврат в приложение», not `match_started`; no AC for «партия на паузе в фоне считается активной».
- ⚠️ **S4 — New-record indicator not computable** (open from baseline). Options: `is_new_record` in the `match_ended` payload, or an explicit cache exception in HUD Rule 2.
- ⚠️ **W10, W11** — still open, see closure table.

### Info
- Status labels: index says «Needs Revision», Guest AI/HUD headers say «In Revision».
- guest-ai:459–462 Edge Cases «Данные» omit `max_step_delta` ≤ 0, which Rule 12 (:144) validates.
- Difficulty :268 «2-я–5-я за день» implies a 5-match daily cap that no longer exists; its Cross-References (:403) don't cite Guest AI Rule 11/13.
- hud:312 «matches_lost» should be `guests_lost`; hud:337 «гаснет при следующем Served-рендере» is doubly stale.
- currency:82 state table has no Idle → Frozen transition although :235 / AC 22 describe a match ending in Idle (pre-existing).
- Brewing's position in the frame order is unspecified (unreachable in practice).

---

## Game Design Issues

### Blocking
None.

### Status of D1–D9
All **UNCHANGED**. Notes:
- D1: patience drain unchanged; visible reaction window at plateau grows ~19 → 25 s (+32%) because walk time is no longer hidden. Walk time still unverified (Guest AI OQ #11).
- D2: earlier order visibility lets players approach the capacity model, making the endless-plateau threshold (`t_step` ≈ 1.52 s) easier to reach — Difficulty OQ #4 more pressing.
- D6: ceiling still 4 rings, average rises toward 4 and rings now move.
- D9: still undefined (guest-ai:638–639, :654 vs hud:124, :331) and **dropped from the HUD revision tracker** (hud:3 lists only S3/S4).

### Warnings
- ⚠️ **N1-D — «Играть снова» can be tapped by accident, skipping results and the new-record moment.** Button «всегда активной» (hud:146–149), overlay fades in ~250 ms (:573), AC 7 routes every overlay tap to the button, and the match ends mid frantic tapping (guest-ai:640–641). AC 28 guards only a second tap. The record overlay is P4's reward moment. Options: input grace window 400–600 ms as a HUD knob; enable after fade-in + tap-down/tap-up; require a press that starts after `match_ended`.
- ⚠️ **N2-D — Moving tokens/rings of walking guests can overlap waiting guests.** Token «следует за гостем в пути» (hud:90–91); in portrait 9:20 a guest walking to a far slot passes in front of occupied slots; at plateau (~1 guest / 3.3 s) routine. Options: dim/shrink tokens in Approaching; fixed draw order with Waiting on top; route spawn paths behind occupied slots. Verify in AC 47 screenshots.

### Info
- Serving at a distance: an Approaching guest turns Served when the barista reaches the slot while the guest is still metres away — now much more frequent. Options: «cup flies» juice, hold barista until arrival, snap guest to slot.
- No voluntary exit from a match except killing the app; a record run lost that way is lost (`best_score` updates only at `match_ended`). Record as a deliberate Edge Case in Currency/Platform.
- `max_step_delta` makes game time slower than real time below 4 fps — future leaderboard cheat vector (analogous to D5). Flag for Leaderboard & Leagues GDD (game-time/wall-time ratio as anti-cheat signal).

### Verified clean
No new faucet or sink; no double payout on restart (guests removed «без событий Served/Leaving»); no restart-scumming incentive (`request_new_match` only after `match_ended`, onboarding income lowest, first recipe fixed); serving in Approaching banks no extra patience; single game time removes timer drift; `max_step_delta` balance-neutral at normal fps; no anti-pillar violated; P3 improved by C1; fantasy coherent (no start screen matches «обучение встроено в начало каждой партии»).

---

## Cross-System Scenario Issues

Scenarios walked: 5
1. `match_ended` → «Играть снова» → `request_new_match` → `match_started` → reset
2. App backgrounded / long WebView freeze → resume
3. Serve while till Full / partial overflow
4. Daily reset crossing at `match_started`
5. First launch → first match

### Blockers
🔴 **Scenario 3 — HUD × Till × Currency**: S3 (see Consistency).

### Warnings
- ⚠️ Scenario 1 — HUD × Guest AI: N8 (guest visibility under the overlay); N1-D (accidental restart).
- ⚠️ Scenario 2 — HUD × Guest AI × Platform: N2 (HUD animations on Platform signal, no clamp after freeze-without-signal, violates HUD AC 42).
- ⚠️ Scenario 4 — Till × Guest AI × Platform: N3 (return-to-app branch unimplementable), N9 (ACs).
- ⚠️ Scenario 5 — Guest AI × HUD × Platform × Currency: N1 (circular trigger), N5 (start screen); load error leaves HUD in `Inactive` with no error state.

### Info
- Scenario 1: two `request_new_match` in the same step while in MatchEnd — AC 52 covers only an active match.
- Scenario 1: Brewing's frame position relative to Guest AI's reset unspecified (pots frozen in MatchEnd, so not reachable).
- Scenario 4 cold start with yesterday's Full till: auto-start sends `match_started` → reset check runs. OK.

### Verified clean
Restart sequence order and recipients identical across HUD, Currency, Brewing, Till, PC and Guest AI tables; double tap guarded (HUD AC 28, Guest AI AC 52); Guest AI, Brewing, PC and Difficulty agree on pause + clamp (Difficulty AC 20 `step(0.25)`); Difficulty needs no signal (`t` from Guest AI).

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| hud-feedback-ui.md | S3, S4, N2, N4, N8, D9, N1-D, N2-D | Consistency / Design Theory | Blocking |
| till-day-cycle.md | S3 (Visual/Audio row), N3, N6, N9 | Consistency | Blocking |
| guest-ai-patience.md | N1, N4 (HUD upstream row), N8 | Consistency | Warning |
| currency-coins-score.md | N5, N7, W10, W11 | Consistency | Warning |
| brewing-crafting-mechanic.md | N2, N7 | Consistency | Warning |

systems-index not re-statused (user decision): HUD, Till, Guest AI remain «Needs Revision»; Currency and Brewing remain «Approved».

---

## Verdict: FAIL

C1 and C2 are closed. One blocker remains: **S3**, local to HUD × Till. Everything else is warnings, mostly incomplete propagation of the C2 fix.

### Required actions before re-running
1. **Till + HUD (S3)**: decide which quantity HUD animates on serve (`coins_earned` vs actual till increment `coins_added`) and what the player sees on serve while Full and on partial overflow; add the Till Visual/Audio row; align HUD Rule 11 and Till Impact Moments.

Recommended in the same pass (warnings): N1 (first-match trigger), N2 (pause leftovers), N3 (Till inputs), N4/N7 (dependency tables), N6/N9 (Till stale text and ACs), S4 (`is_new_record`), N8. Then re-run `/review-all-gdds since-last-review`.
