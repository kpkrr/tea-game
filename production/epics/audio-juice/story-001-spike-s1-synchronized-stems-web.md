# Story 001: Spike S1: 4 stems in AudioStreamSynchronized on web devices

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-001`, `TR-audio-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0007: Performance & load budgets (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

Первый spike до производства музыки (audio GDD OQ1, `design/audio/adaptive-music-feasibility-2026-10-01.md` §Spike): доказать, что 4 Ogg-stem в одном `AudioStreamSynchronized` (Stream, не Sample) играют на web без треска и укладываются в CPU-бюджет на Android RD и iPhone. Результат — вердикт go / фолбэк (4 накопительных микса, ≤ 2 декодера).

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0001): `AudioStreamSynchronized` with explicit `playback_type = PLAYBACK_TYPE_STREAM` (meta-streams report `can_be_sampled() = false`)
- Guardrail (from ADR-0007): music decode + mix + filter avg <= 2.5 ms/frame on Mid devices (provisional)
- Forbidden (from ADR-0001): treating the spike as production code — keep it under `prototypes/` or a debug scene, not `src/`

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] Тестовая сцена с 4 placeholder-stem (96,0 с, 120 BPM, любой контент) играет одним `play()`; 3-минутный матч при нагрузке 100/200 мс на кадр на Android mid-range и iPhone Safari — без треска (AC 11 часть, ADR-0001 S1)
- [ ] Измерена дельта кадра с музыкой vs без (PerfProbe): число против лимита 2,5 мс; при превышении — вердикт фолбэк (накопительные миксы, ≤ 2 декодера)
- [ ] Записан вердикт go/fallback + цифры в `production/qa/evidence/spike-s1-synchronized-stems-web-evidence.md`; ADR-0001/0007 amendment помечены Verified/Changed

---

## Implementation Notes

- Method: `design/audio/adaptive-music-feasibility-2026-10-01.md` §Spike на устройстве.
- Headless-часть (Integration): статический скан импорта — все `music_*` в Stream; стемы одной длины ±1 сэмпл.
- Результат блокирует Story 006 (производство stems) и 007.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 002: шов loop, рампы, stream_paused
- Story 003: Sample SFX
- Story 006: боевой контент

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/audio/spike_s1_stems_test.gd` OR playtest doc
- Additionally: `production/qa/evidence/spike-s1-synchronized-stems-web-evidence.md` (device/measurement log)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: 002, 006, 007
