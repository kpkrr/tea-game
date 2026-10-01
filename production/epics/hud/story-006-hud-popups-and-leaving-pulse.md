# Story 006: Coin/score popups, overflow bounce and leaving pulse (snap vs smooth)

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-014`, `TR-hud-015`, `TR-hud-017`, `TR-hud-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: GameClock + MatchDirector with fixed tick order, no SceneTree.paused, typed signals, DI from the composition root; pause = hidden OR user_paused via single GameClock; sim_dt frozen on pause, ui_dt keeps running (0 while hidden).
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0002: Viewport, camera fit & 2.5D presentation (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: No post-cutoff API dependency; signals and _process ordering are stable Godot 4.x.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

События `Served`/`Leaving` дают визуальный отклик: попапы монет и очков с полным значением сразу и дугой ~400 мс, overflow (касса Full) — отскок без числа; негативный импульс при уходе; два ухода в одном кадре — со сдвигом 100 мс. Каждое событие HUD эмитит отдельный хук для звука (реализует epic audio-juice).

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Forbidden (from ADR-0003): `SceneTree.paused`, `Tween`/`create_timer` for gameplay-synchronised animation — animate from accumulated `GameClock` time
- Required (from ADR-0003): popups subscribe to `Served`/`coins_added`/`score_earned` typed signals; no polling of events
- Guardrail (from ADR-0002): popup pool reuse, no per-popup node allocation in hot path

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] `Served` 5 монет + 87 очков: оба числа появляются сразу с полным значением и идут дугой ~400 мс; монетный и очковый попапы различимы цветом и/или иконкой (AC 22, 23)
- [ ] Overflow (`coins_added = 0`): отскок без числа монет, очки растут (TR-hud-015)
- [ ] Два `Leaving` в одном кадровом окне — старты импульсов сдвинуты на ~100 мс; импульс не блокирует ввод и не останавливает другие таймеры (AC 14, 15, 40)
- [ ] `Served` и `match_ended` в одном тике: попап доигрывает дугу поверх оверлея итогов (AC 39)
- [ ] Smooth/snap: счёт и страйки — snap; попапы, кольцо, заполнение кассы — smooth от игрового времени (TR-hud-017)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — popups и pulse.
- Длительности (`popup_arc_ms` 400, `leaving_pulse_stagger_ms` 100) из HudConfig.
- Экспортировать сигналы `sfx_hint(event_id)` — подключает AudioDirector в Story audio 012 (TR-hud-018: отдельный звук на событие).
- Длительность импульса ухода в GDD не зафиксирована (qa-lead note 1): выбрать из HudConfig, зафиксировать в evidence.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- epic audio-juice: сами звуки
- Story 005: жетон/кольцо

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel: `production/qa/evidence/hud-popups-and-leaving-pulse-evidence.md` + retained screenshot/clip + lead sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002, 005
- Unlocks: 011
