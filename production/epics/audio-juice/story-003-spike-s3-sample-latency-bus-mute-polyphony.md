# Story 003: Spike S3: Sample SFX latency, bus mute on Sample, max_polyphony, QOA decode

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-006`, `TR-audio-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0007: Performance & load budgets (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

Третий spike: задержка касание → Sample-SFX ≤ 80 мс; действует ли громкость/mute шины на Sample-звуки (A3, нужно для дакинга фона и mute Master); `max_polyphony` ограничивает one-shot'ы; QOA-декод и память Sample PCM (~35 МБ).

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0001): SFX/voice/stinger/ambience use Sample playback (QOA), variations + pitch chosen in code; no `AudioStreamRandomizer`/`AudioStreamPolyphonic`
- Required (from ADR-0007): <= 16 one-shot SFX at once; Sample PCM ~35 MB / <= 90 s total
- Required (from ADR-0001): A3 - `set_bus_mute(Master)` silences both Stream music and Sample SFX on web

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] Задержка касание → звук ≤ 80 мс на обоих телефонах (съёмка 240 fps) (AC 43, 38)
- [ ] При 20+ событиях/с одновременно звучит ≤ 16 SFX (лог пула), треска нет (AC 38)
- [ ] Громкость и mute шины действуют на Sample-звуки (A3); результат определяет, возможен ли дакинг фона (Rule 15, OQ6)
- [ ] Измерены пик памяти Sample PCM и время декода QOA при Boot pre-warm

---

## Implementation Notes

- Метод: feasibility doc §5 и §Spike S3; ассеты — placeholder WAV/QOA.
- Результат: вердикт в evidence, правка ADR-0001/0007 и audio GDD OQ6 (дакинг фона да/нет).

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 010: боевой SFX-пул
- Story 015: дакинг

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/audio/spike_s3_sample_test.gd` OR playtest doc
- Additionally: `production/qa/evidence/spike-s3-sample-latency-bus-mute-polyphony-evidence.md` (device/measurement log)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: 010, 011, 015
