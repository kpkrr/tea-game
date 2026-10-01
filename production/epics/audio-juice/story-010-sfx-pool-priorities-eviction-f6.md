# Story 010: SFX pool: P0-P4 classes, 16-slot cap, F6 eviction and dedupe

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-010`, `TR-audio-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets
**ADR Decision Summary**: 60/30 fps targets, ms-per-system CPU table, draw calls <= 180, .pck <= 11 MB, load <= 21.5 MB, Low/Mid/High quality tiers, PerfProbe; 2026-10-01 audio amendment: music <= 6.0 MB as a file set outside .pck, music CPU <= 2.5 ms/frame (provisional), <= 16 one-shot SFX, Sample PCM ~35 MB / <= 90 s.
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0001: Web build & platform shell (Last Verified 2026-10-01)
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Frame-time and per-system ms are provisional until a weak-Android run; measure with PerfProbe on the reference device.

`SfxPool`: ≤ 16 одновременных one-shot (музыка, фон, сердцебиение не считаются); классы P0 (UI 2 / стингеры 2) и P1 (уход, порча — 2) не вытесняются; P2 подтверждения ввода, P3 награды (4), P4 фоли (4) + голоса (2); вытеснение F6: старший P4 первым, fade 20 мс; повтор того же `sfx_id` чаще 50 мс пропускается (кроме наград); вариации и pitch — в коде через инъекционный RNG.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0001): SFX/voice/stinger/ambience use Sample playback (QOA), variations + pitch chosen in code; no `AudioStreamRandomizer`/`AudioStreamPolyphonic`
- Required (from ADR-0004/0003): dependencies injected (FakeClock, seeded RNG, fake audio backend recording play/stop/stream_paused/set_bus_*); no real `AudioServer` in unit tests
- Guardrail (from ADR-0007): <= 16 one-shot SFX at once; pool preallocated at boot (no allocation in event path)

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] Пул 16/16 (4 фоли + 2 голоса): тап (P2) → в том же кадре уходит старший P4 (fade 20 мс), тап звучит; новый P4 при полном пуле без P4-жертв отбрасывается; при упоре в `cap(P3)` жертва среди P3 (AC 36)
- [ ] P0/P1 никогда не жертвы (сверх потолка — отбрасываются); повтор `sfx_id` через 49 мс пропущен, через 50 мс звучит, награды без пропуска; музыка/фон/сердцебиение не занимают слоты (AC 37)
- [ ] Seed 42, событие с 3 вариантами, 30 срабатываний в двух прогонах → одинаковые индексы и `pitch_scale` (AC 6)
- [ ] Интеграция S3: при 20+ событиях/с звучит ≤ 16 (лог пула)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/audio_director.gd` + `.../foundation/config/audio_config.gd` (bring to standards: static typing, doc comments, DI of GameClock/AudioConfig/SaveScope/backend) — slice SFX helper (`_play_sfx`) → `SfxPool`.
- Таблица классов — audio GDD Rule 14, формула — F6; потолки — `AudioConfig`.
- Результат spike S3 задаёт `max_polyphony` и режим Sample.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 012: карта событий → звук
- Story 014: лимитер голосов (F4 — допуск до пула)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/audio/sfx_pool_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003, 004
- Unlocks: 012, 013, 014, 015
