# Story 007: Adaptive stems: layer gains by difficulty_progress (F1) and bar-quantised fades (F2)

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-001`, `TR-audio-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)
- ADR-0007: Performance & load budgets (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

Партийная музыка: `AudioStreamSynchronized` из 4 stems, слои вступают по `difficulty_progress` с порогами 0 / 0,03 / 0,25 / 1,0 (F1); переход квантуется к ближайшему такту (2,0 с) и нарастает `stem_fade_bars` = 2 такта (F2); гейны — линейно по dB; слои только добавляются. Если stems не догрузились к `match_started` — партия без музыки, при загрузке старт с такта 0 с гейнами по текущему dp.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0001): one `AudioStreamSynchronized`, loop=true set in code, layer gain via `set_sync_stream_volume` from `AudioDirector._process`
- Required (from ADR-0003): all audio envelopes (layer fades, filter ramps, ducking) accumulate `GameClock.ui_dt` in `_process`; never `Tween`
- Required (from ADR-0004/0003): dependencies injected (FakeClock, seeded RNG, fake audio backend recording play/stop/stream_paused/set_bus_*); no real `AudioServer` in unit tests

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] F1: dp ∈ {0; 0,029; 0,03; 0,249; 0,25; 0,999; 1,0} → слышны S1 / S1 / S1–2 / S1–2 / S1–3 / S1–3 / S1–4 (0 dB), остальные −80 dB; число включённых слоёв не убывает при t 0…300 с без страйков (AC 7, 8)
- [ ] F2: `music_pos` 37,3 → старт 38,0; 38,0 → 38,0; 95,1 → 0,0 следующего круга; нарастание 4,0 с; 100 кадров при `ui_dt = 0` — огибающие не меняются (AC 9, 22)
- [ ] Поздняя загрузка: stems готовы при dp = 0,3 → старт с 0, слои S1–S3 (AC 20)
- [ ] В `src/audio/` нет `create_tween()` (скан) (AC 22)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/audio_director.gd` + `.../foundation/config/audio_config.gd` (bring to standards: static typing, doc comments, DI of GameClock/AudioConfig/SaveScope/backend) — single-stream player → `MusicDirector` с Synchronized.
- Формулы — чистые функции `StemMath` (F1/F2), тестируются отдельно от узлов.
- Активный вердикт Spike S1/S2 задаёт фолбэк-путь (накопительные миксы, ≤ 2 декодера) — интерфейс `StemPlayer` скрывает различие.
- Данные stems — из Story 006 (для тестов достаточно fake).

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 008: S4 гаснет на последнем страйке, фильтр
- Story 009: сердцебиение
- Story 016: пауза

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/audio/stem_layers_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001, 002, 004, 005
- Unlocks: 008, 009, 018
