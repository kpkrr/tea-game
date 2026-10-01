# Story 010: Till full! banner and last-strike vignette (with reduced motion)

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-flow-013`, `TR-flow-023`, `TR-hud-022`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: GameClock + MatchDirector with fixed tick order, no SceneTree.paused, typed signals, DI from the composition root; pause = hidden OR user_paused via single GameClock; sim_dt frozen on pause, ui_dt keeps running (0 while hidden).
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)
- ADR-0006: Navigation & tap picking (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: No post-cutoff API dependency; signals and _process ordering are stable Godot 4.x.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

M2: плашка Till full! Great day (2 с, звон, вибрация, не останавливает партию, не ловит тапы). M12: при `guests_lost == max − 1` — виньетка (fade-in 400 мс) и сердцебиение (фаза от AudioDirector), замирают на паузе; reduced motion — без пульса (альфа 0,3 статична), пульс колец тоже отключаем (TR-hud-022).

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0003): banners/vignette use game-time; freeze on pause
- Required (from ADR-0004): `max_guests_lost` read, durations from HudConfig
- Required (from ADR-0006): banner has `mouse_filter = IGNORE`, never captures taps

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] `Served` +7 монет при 245/250 → в этом кадре плашка Till full! Great day ☕ ~2,4 с, матч не останавливается, тап сквозь плашку доходит до кухни (AC 70, F9)
- [ ] `guests_lost` = 2 при `max = 3` → в том же кадре виньетка (fade-in 400 мс) и хук сердцебиения; жетоны у стен не затемняются (AC 72)
- [ ] reduced motion: два скриншота с интервалом 500 мс — альфа 0,3, пиксель-в-пиксель одинаково (AC 73); пульс колец терпения отключён
- [ ] Виньетка и плашка замирают на паузе; Open→Full и `is_new_record` в одном тике показывают оба акцента (AC 41)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — vignette/banners, if present; иначе новая реализация по `design/ux/hud.md` E19/E21.
- Фаза пульса виньетки = `AudioDirector.heartbeat_phase()` (audio Story 009); при `music_on=false` — свободный 1 Гц от кадра страйка.
- Вибрацию вызывает Haptics (audio Story 017), HUD только эмитит `day_filled`/событие.
- HUD skin art (icons, frames, fonts, tokens sprites) comes from epic `art-assets`; use placeholder `StyleBox`/flat shapes until it lands.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- audio-juice: звон, сердцебиение, вибрация
- game-flow: NEW BEST попап владеет HUD, но строка итогов — game-flow

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel: `production/qa/evidence/hud-till-full-banner-last-strike-vignette-evidence.md` + retained screenshot/clip + lead sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003, 007, 009
- Unlocks: None
