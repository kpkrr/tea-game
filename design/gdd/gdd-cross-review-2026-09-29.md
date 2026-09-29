# Cross-GDD Review Report

**Date**: 2026-09-29
**Mode**: full (consistency + design theory + scenario walkthrough)
**Workflow tier**: standard
**GDDs reviewed**: 10 of 10 system GDDs present (+ `game-concept.md`, `systems-index.md`, `design/registry/entities.yaml`)
**Systems covered**: Kitchen & Station Layout, Platform Integration, Order & Recipe, Player Control / Barista Movement, Brewing & Crafting, Guest AI & Patience, Difficulty Curve & Session Pacing, Currency: Coins & Score, Till & Day Cycle, HUD & Feedback UI
**Pillars**: P1 Хаос за стойкой · P2 Цена видна в чашке · P3 Одна касса, одно правило · P4 Монеты за работу, очки за мастерство
**Anti-pillars**: ресурсная экономика · продление партии за донат · конвертация фантомных монет · длинные рецепты/сюжет · кооп в MVP

**Method**: Phase 2, 3 and 4 ran as parallel `game-designer` sub-agents on
pre-extracted section slices. Every Blocking finding was re-verified by the
orchestrator against the source GDD text (line numbers below are as of this
date). The entity registry was non-empty and was used as the conflict
baseline. Edge Cases / Open Questions / Visual-Audio / Game Feel / UI
Requirements were read by targeted grep only, not in full. All balance
numbers are analytical (Little's law, mean values) — no queue simulation or
playtest data exists yet.

---

## Consistency Issues

### Blocking (must resolve before architecture begins)

🔴 **C1 — Guest in `Approaching` is invisible while their patience already drains and they can already be served**
- `hud-feedback-ui.md` Core Rule 4 (l. 88–89): «До `Waiting` (состояние `Approaching`) жетон не показывается — терпение ещё не считается»; Rule 5 — ring appears with the token on `Waiting`; AC 8.
- `guest-ai-patience.md` Core Rule 4 (l. 69): «Терпение в пути уже убывает»; Rule 5 (l. 73–74) allows serving any guest «в Approaching или Waiting»; AC 15/18.
- Consequence: patience is lost invisibly and the player can serve a guest whose order is not shown (P3 violation; breaks Guest AI Game Feel guarantee «≥60% от сигнала тревоги до ухода»). HUD AC 10/13 also do not cover `Approaching` → `Served`/`Leaving`.
- Options: (a) show token + ring from spawn; (b) start patience and allow serving only from `Waiting`.

🔴 **C2 — No owner for match start / restart**
- Dependent: Currency Rule 7 (`match_score` reset), Brewing AC-E4, Difficulty (t = 0), Player Control (Idle), Till (reset check «между партиями»), HUD AC 28 (already BLOCKED, HUD Open Question #1).
- Guest AI owns only `match_ended`; the very first match start is not specified either.
- Options: (a) extend Guest AI & Patience with an incoming «start match» rule; (b) a separate Match Lifecycle ADR / mini-GDD.

### Warnings

- ⚠️ **W1** `systems-index.md` l. 84–88 — Till still described as «≈5× доход за эталонную 2-минутную партию» and «закрытие дня («Чайная закрыта до завтра»)». Stale since the 2026-09-29 Till revision. *Quick fix.*
- ⚠️ **W2** `systems-index.md` l. 156, 217 and `till-day-cycle.md` Dependencies «Двунаправленность» paragraph — still list Guest AI / `match_ended` as a hard dependency of Till, contradicting Till's own dependency table after Core Rule 4/5 changed. *Quick fix.*
- ⚠️ **W3** `game-concept.md` l. 260 («MVP: 1 кухня, 3 напитка»), l. 322 (Scope Tiers) and `systems-index.md` l. 190 vs `game-concept.md` l. 304 («5 напитков в 3 уровнях сложности»). *Quick fix.*
- ⚠️ **W4** `difficulty-curve-session-pacing.md` Summary — «с 8» guests/min vs Rule 2 and registry 7→18. Difficulty AC 4 fixture «start 8» looks stale too. *Quick fix.*
- ⚠️ **W5** `difficulty-curve-session-pacing.md` l. 125 («18 из game-concept»), l. 142, and `guest-ai-patience.md` l. 167–168, 194, 223, 261 cite `game-concept.md` as the source of curve numbers that it does not contain.
- ⚠️ **W6** Stale «не спроектирована» / «провизорный» markers in all 8 upstream GDDs; Till AC 34, Order & Recipe AC 39–41, Player Control AC 40 marked Blocked on systems that are now Approved. `guest-ai-patience.md` l. 167 «Difficulty (ещё не спроектирована)», AC 45 «Currency не спроектирована».
- ⚠️ **W7** One-directional edges: Difficulty → HUD (`difficulty_progress`) absent in HUD; Player Control → Platform (acknowledged in PC); Order & Recipe AC 40 / Interactions expect `recipes_by_tier` from Difficulty, but Guest AI is the caller; Platform Interactions table lacks the Guest AI row present in its Dependencies.
- ⚠️ **W8** Two pause sources: Guest AI Rule 11 pauses itself and notifies Player Control, while Player Control listens to Platform directly; Brewing and HUD (AC 42) do not declare their pause source.
- ⚠️ **W9** `hud-feedback-ui.md` Core Rule 5 / AC 11–12 «цвет — по порогам» vs HUD Visual (l. 396) and `guest-ai-patience.md` (l. 497, AC 47) «не сменой оттенка». Wording ambiguity (colour vs lightness/icon).
- ⚠️ **W10** `currency-coins-score.md` l. 70, 415, 450 — «закрытие дня». Stale. *Quick fix.*
- ⚠️ **W11** Currency cites wrong Guest AI rule numbers: Served is Rule 5 (not 8), tick order is Rule 8 (not 9).
- ⚠️ **W12** `systems-index.md` l. 74–75, 232–233 — onboarding «встроен в Difficulty», but Difficulty Rule 5 delegates it to Guest AI; «одношаговые напитки» contradicts `cold_tea` = 3 steps. Two names in use: `onboarding_factor` / `onboarding_multiplier`.
- ⚠️ **W13** Registry notes still carry pre-revision Till text: `max_guests_lost` («… и Till через `match_ended`»), `daily_reset_time_utc` («Closed»), `till_capacity` («5 матчей»). Till notes «game-concept будет исправлен» / «guest-ai ещё не обновлён» are outdated (both done).
- ⚠️ **W14** `systems-index.md` Progress Tracker — «reviewed 7 / approved 8» while 10 are Approved. *Quick fix.*
- ⚠️ **W15** `platform-integration-telegram-mini-app.md` Tuning Knobs reference Kitchen AC#8; the intended criterion is AC#10.
- ⚠️ **W16** `currency-coins-score.md` Interactions l. 98 — Progression «Потребляет сумму кассы (не `score_earned`) для стоимости прокачки» contradicts Core Rule 6 of the same GDD (l. 61, «потратить нельзя») and `game-concept.md` («за донат, не за Tea Coin»). Phase 3 rated this Blocking; downgraded to Warning here because Progression is Alpha and no MVP system implements spending — but the ledger-vs-wallet question must be settled before Backend & Persistence.

### Info
- Difficulty AC 17: 8.2135 vs exact 8.2129 (within tolerance).
- `systems-index.md` says pathing «по сетке», GDD uses NavMesh.
- `systems-index.md` HUD prose mentions a «счётчик монет», which HUD Rule 10 forbids.
- HUD Rule 2 cites Currency AC 33, which is a performance AC.
- Guest AI ↔ Difficulty edge direction in the index is inverted relative to the GDDs.

### Verified consistent
All key numbers agree across GDDs and registry: Difficulty curves (7→18, 50→25 s, 0→40%, 180 s, k = 2, spawn intervals); 3.0 s / 2.0 s / 4 m/s; 7 cup slots, 4 guest slots, 3 strikes; onboarding 30 s × 0.5; thresholds 0.6 / 0.25; `time_to_complete`, `avg_time(p)`; average price 3.5 → 4.9; revenue 84 / 245; 250 ≈ 3.03 matches. Ownership of `till_amount`, `match_score`, `guests_lost`, tick order, «Full не блокирует партии», `consume_held_cup` exactly once — consistent. All 10 GDDs have a filled Cross-References table.

---

## Game Design Issues

### Blocking
None (see W16 above for the one item Phase 3 rated Blocking).

### Warnings

- ⚠️ **D1 Difficulty spike (3e)** — `difficulty-curve-session-pacing.md`: three curves share one ease-in and peak together. Pressure index (guests/min × order time / patience) rises ×2.6 between 120 s and 180 s (2.57 → 6.66); barista capacity is exceeded from ~50 s. The average player dies around 150 s — at the steepest point. The «sawtooth» from game-concept is absent.
- ⚠️ **D2 Plateau is inert / possibly endless (3e)** — Difficulty + Guest AI: queue throughput ≤ 4 slots / 25 s ≈ 9.6 guests/min, so `guests_per_minute_end` = 18 is nearly inert. With `t_step` 2.0 s lives run out in ~58–79 s of plateau; with `t_step` ≤ ~1.52 s the match is endless and `best_score` unbounded. Quantitative threshold for Difficulty Open Question #4.
- ⚠️ **D3 Score measures endurance, not speed (3e/P4)** — `currency-coins-score.md` Formula 1: on a saturated plateau guests are served at `remaining_fraction` ≈ 0, erasing the speed bonus. The «сильный ~3500–4500» estimate is ~40% high.
- ⚠️ **D4 Strong-player estimate is impossible (3d)** — `till-day-cycle.md` Formula 2/3 (l. 236, 245) and `currency-coins-score.md` l. 171 assume «~50 гостей» by 180–222 s. Integrating `guests_per_minute(t)` with onboarding gives **≈43 guests spawned by 222 s** (re-computed: 42.8). The average player (20 served + 3 lost) ends near 150 s, not 222 s. A realistic strong player earns ~130 coins and fills the till in ~1.9 matches, not ~1. The till/playtime decoupling decision stands, but its justification is overstated.
- ⚠️ **D5 Paid speed makes the record buyable (3f/P4)** — Progression tier ×1.5 barista speed gives `t_step` ≈ 1.5 s = the endless-plateau threshold (D2). Conflicts with P4 «Рекорд нельзя купить». Resolve before the Progression & Upgrades GDD (leagues alone may not contain it).
- ⚠️ **D6 Attention budget (3b)** — 6 concurrently active tasks at plateau (move, track 4 patience rings, build steps, 2 teapots, 7 slots, choose whom to serve) vs a comfortable 4. Slots/teapots are formally optional but demand (+178%) forces their use; cups parked in slots have no recipe tokens.
- ⚠️ **D7 Till rule not visible on the till (3f/P3)** — an unfilled till never resets (deliberate: `till-day-cycle.md` Core Rule 7, l. 91–96; Edge Cases l. 312–317) so the limit is «per fill, refilled at most once per day», not a daily cap; the 00:00 UTC reset time is never shown to the player. Framing «дневной лимит» in game-concept vs actual rule, and P3's «Если правило нельзя показать на кассе, его нет».
- ⚠️ **D8 Till loop has no payoff in MVP (3a)** — coins buy nothing and the record is local only; the MVP core hypothesis («сыграть ~3 партии до заполнения кассы») leans on a motivation that does not yet exist. Record is the real primary driver.
- ⚠️ **D9 Lives indicator undefined (3b)** — Guest AI Game Feel refers to a `guests_lost` counter «(HUD)», while HUD names `match_score` «единственный обязательный постоянный виджет».

### Info
- No GDD has a dedicated Player Fantasy section (advisory at `standard`); Overview + Game Feel were used.
- Speculative pre-brewing is bounded to ~2–3 cups — healthy mastery, but not described in Brewing Edge Cases.
- Cheap-vs-complex triage is a real choice (cheap ×1.9 guests/s, complex ×1.8 score/s). Clean.
- No incentive to stall, restart or lose on purpose (≈7 coins/min in onboarding vs ~30 later). Clean.
- 7 slots drift toward depth vs P1, but no anti-pillar violated; the name «Crafting» risks reading as the anti-pillar.
- Player fantasy is coherent across all 10 GDDs; the MDA «Submission» entry actually describes Completion/Achievement.
- Teapot utilisation ~0.13, not 0.45.
- Coins burned above capacity are not counted anywhere — residual monetization risk: the «ты заработал бы X» lever now lives in overflow, not in a play lock.

### Verified clean
Anti-pillars (recipes ≤ 5 steps, no paid continuation, no co-op/story, infinite ingredients); no degenerate strategies in MVP; fantasy tone consistent.

---

## Cross-System Scenario Issues

Scenarios walked: 6
1. Serve on the same tick patience expires
2. Third guest leaves while holding a finished cup / teapot mid-brew → `match_ended` → restart
3. Serve that overflows the till, then further serves in Full
4. Daily reset at 00:00 UTC during a match / on return to app
5. App backgrounded mid-match (pause of all timers)
6. New tap retargets the barista mid-action

### Blockers
🔴 **S1 = C1** — Guest AI × HUD: serving a guest whose order is not displayed (scenario 1/2 step «guest spawn → Approaching»).

🔴 **S2 = C2** — all systems: after `match_ended`, no system owns starting the next match (scenario 2, final step).

🔴 **S3 Serve while till is Full** — HUD × Till × Currency (scenario 3)
- `hud-feedback-ui.md` Core Rule 11 (l. 134–135): «`+coins_earned` летит к кассе» on every serve.
- Till does not grow in Full; `till-day-cycle.md` Visual/Audio has no row for «Served при Full»; partial overflow also animates the full `coins_earned`.
- Contradictory messaging in the state a strong player spends most of the day in (P3).
- Options: Till exposes `coins_added` (actual increment) for HUD to animate; or an explicit «не влезло» visual.

### Warnings
- ⚠️ **S4 New-record indicator not computable** — Currency × HUD: HUD Rule 13 (l. 143–144) compares with «предыдущий `best_score`», HUD Rule 2 forbids caching, Currency Rule 7 updates `best_score` in place on the same `match_ended`. HUD Edge Cases / AC 41 also show a record indicator mid-match, Currency UI Requirements only on the results screen. Options: `is_new_record` in the payload, or an explicit cache exception.
- ⚠️ **S5 Frame order** — Player Control × Guest AI: Guest AI Rule 8 «подача побеждает» holds only inside Guest AI; whether Player Control's Holding proposal or the Guest AI tick runs first in a frame is undefined (one-tick window).
- ⚠️ **S6 Till reset during a paused match** — Till × Guest AI × Platform: the reset check runs «при возврате в приложение», which coincides with Platform's visibility signal; Till needs to know whether a match is active but removed its Guest AI dependency.
- ⚠️ **S7 No delta clamp after resume** — all timed systems: if the WebView freezes JS before «hidden» is processed, the first frame after return can drain every guest's patience at once → 3 strikes → instant `match_ended`.

### Info
- Brewing does not listen to `match_ended`: teapots finish under the results overlay; «teapot ready» sound may play behind it.
- Till bar grows at serve time while the coin reaches the till ~400 ms later.
- Coins from serves after midnight in a match started with a full till are lost — documented simplification.
- HUD «гаснет при следующем Served-рендере» contradicts its own Rule 2 (render every frame).
- Save granularity is implicit (coins saved on each serve, score not) — no contradiction, worth stating.
- Brewing does not state which yes/no answer on exit corresponds to «wait».

Verified clean: simultaneous serves; till filling on the same tick as `match_ended`; cup kept when a guest leaves; background brewing on retarget; pause behaviour (6 systems agree on *what* pauses); no double rewards.

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| hud-feedback-ui.md | C1/S1 (Approaching), S3 (+coins in Full), S4, W9, D9 | Consistency | Blocking |
| guest-ai-patience.md | C1/S1, C2 (likely owner of match start), W5, W8 | Consistency | Blocking |
| till-day-cycle.md | S3 (Served-in-Full visual), W2, D4, D7, S6 | Consistency | Blocking |
| currency-coins-score.md | W10, W11, W16, D3, D4 | Consistency / Design Theory | Warning |
| difficulty-curve-session-pacing.md | W4, W5, D1, D2 | Design Theory | Warning |
| systems-index.md *(index, not a system GDD)* | W1, W2, W3, W12, W14 | Consistency | Warning |

---

## Verdict: FAIL

Three blocking issues must be resolved before `/create-architecture`. All
three are local contract gaps across 3–4 GDDs, not design overhauls.

### Required actions before re-running
1. **HUD + Guest AI (C1/S1)** — choose one model for `Approaching` (visible from spawn, or patience/serving only from `Waiting`) and align HUD Rule 4/5, AC 8/10/13 and Guest AI Rule 4/5, AC 15/18.
2. **Match lifecycle (C2/S2)** — assign the owner of match start and restart (rule in Guest AI & Patience or a Match Lifecycle ADR); unblock HUD AC 28; list the event in Currency, Brewing, Difficulty, Player Control, Till dependencies.
3. **Till + HUD (S3)** — specify what the player sees when serving while Full (and on partial overflow) and which quantity HUD animates (`coins_earned` vs actual till increment).

Then re-run `/review-all-gdds since-last-review`.
