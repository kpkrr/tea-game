# Story 014: Guest voice limiter (F4) and barista cooldown

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Match simulation - clock, tick order, pause
**ADR Decision Summary**: GameClock + MatchDirector with fixed tick order, no SceneTree.paused, typed signals, DI from the composition root; pause = hidden OR user_paused via single GameClock; sim_dt frozen on pause, ui_dt keeps running (0 while hidden).
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: No post-cutoff API dependency; signals and _process ordering are stable Godot 4.x.

`VoicePool`: ≤ 2 одновременные реплики, зазор 0,25 с, кулдаун гостя 2,5 с, вероятность `order` падает с очередью (p = 1; 1; 0,75; 0,5; 0,25 для n_waiting 0…4); `leaving` проходит всегда (вытесняет старшую `order` за 30 мс); реплики баристы — общий кулдаун 8 с, отключаемы; RNG внедряется, при раннем отказе `rng()` не вызывается.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0004/0003): dependencies injected (FakeClock, seeded RNG, fake audio backend recording play/stop/stream_paused/set_bus_*); no real `AudioServer` in unit tests
- Required (from ADR-0004): all limiter numbers from AudioConfig
- Required (from ADR-0003): RNG injected; early rejection must not consume RNG (determinism)

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] 2 реплики `order` звучат, приходит `leaving` → допущена, старшая `order` гаснет за 30 мс; 2 `urgent` + `served` → отклонена; 2 `leaving` + третья → отклонена, но `sfx_guest_leave` звучит (AC 31)
- [ ] `urgent` через 0,1 с отклоняется, через 0,25 допускается; тот же гость 2,4 с — отказ, 2,5 с — допуск; `leaving` игнорирует зазоры (AC 32)
- [ ] `p(order)` для n_waiting 0…4 = 1; 1; 0,75; 0,5; 0,25; seed 42 и 1000 попыток — число допусков = эталон (AC 33)
- [ ] 4 гостя в `urgent` в одном кадре → ≤ 2 реплик (AC 34); бариста 7,9 с — отказ, 8,0 с — допуск, при `barista_voice_enabled=false` — 0 вызовов (AC 35); pitch голоса ∈ [0,97; 1,03] (AC 6)

---

## Implementation Notes

- Формула F4 — audio GDD §F4; тест-эталон 1000 попыток хранить как константу-fixture.
- Голоса в классе P4 (потолок 2) — Story 010.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 010: пул и вытеснение
- Story 011: ассеты голосов

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/audio/voice_limiter_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 010, 012
- Unlocks: None
