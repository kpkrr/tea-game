# Story 013: Rewards and stingers: coin chords by price, star pitch ladder (F3), NEW BEST / TILL FULL / results

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: GameClock + MatchDirector with fixed tick order, no SceneTree.paused, typed signals, DI from the composition root; pause = hidden OR user_paused via single GameClock; sim_dt frozen on pause, ui_dt keeps running (0 while hidden).
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: No post-cutoff API dependency; signals and _process ordering are stable Godot 4.x.

Pillar 4: монеты — аккорд только по цене (2 → F, 5 → F+A, 7 → F–A–C), от серии не зависит; очки — стеклянный `sfx_reward_star_01` через 60 мс после монет, высота по серии (F3, окно `combo_window_s` 6,0). Касса: `till_add` при `coins_added > 0`, иначе `till_bounce`. Стингеры: NEW BEST (+100 мс после звезды, один раз за партию), TILL FULL (раз в день), NEW RECORD (в кадре штампа, +800 мс от оверлея), SHIFT OVER.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0004/0003): dependencies injected (FakeClock, seeded RNG, fake audio backend recording play/stop/stream_paused/set_bus_*); no real `AudioServer` in unit tests
- Required (from ADR-0001): SFX/voice/stinger/ambience use Sample playback (QOA), variations + pitch chosen in code; no `AudioStreamRandomizer`/`AudioStreamPolyphonic`
- Required (from ADR-0003): series time measured on game time `t` (pause between serves does not break a series)

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] Серия 0…5, подача за 2 / 5 / 7 монет → `coin_02` / `coin_05` / `coin_07`; выбор не зависит от серии (AC 24)
- [ ] F3: подачи при t = 0, 5, 10, 15, 20, 25, 30 → `star_pitch_scale` 1,0; 1,1225; 1,3348; 1,4983; 1,6818; 2,0; 2,0 (±0,0001); интервал 6,0 с продолжает, 6,01 с сбрасывает; Leaving сбрасывает серию, уже звучащий звук не прерывается (AC 25, 26)
- [ ] Звезда в кадре `coins + 60 мс`; `coins_added = 0` → монеты молчат, `till_bounce`, лестница очков растёт (AC 27)
- [ ] `record_passed` → NEW BEST через 100 мс, один раз за партию; TILL FULL один раз за день, возможен снова после сброса; TILL FULL + NEW BEST в одном кадре — звучат оба; NEW RECORD/SHIFT OVER по времени оверлея; `quit` — стингеров нет (AC 28, 29, 15, 16)

---

## Implementation Notes

- F3: `star_pitch_scale = 2^(k/12)`-лестница по ступеням пентатоники — точные формулы в audio GDD §F3.
- Порядок и сдвиги P16 общие с HUD — константы из `AudioConfig`/HudConfig.
- Порядок стингеров на шине Stinger (P0, не вытесняются).

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 015: дакинг под стингер
- Story 011: ассеты
- hud Story 006: визуальные попапы

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/audio/rewards_stingers_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 008, 010, 012
- Unlocks: 015
