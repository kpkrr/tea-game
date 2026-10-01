# Story 002: Spike S2: loop seam drift, ramp clicks, stream_paused and hidden tab

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-001`, `TR-audio-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

Второй spike: 10+ кругов loop без расхождения stems на шве (≤ 5 мс), рампы гейнов без щелчков, `stream_paused` и скрытая вкладка на Stream и Sample, разблокировка AudioContext на iOS (A1–A4 из ADR-0001).

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0003): pause/hidden handled in the synchronous `paused_changed` callback (`stream_paused = true`)
- Required (from ADR-0001): loop set in code on every stem; no `Tween` for ramps
- Forbidden: relying on iOS hardware silent-switch override (A4: record, do not fight)

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] 10 минут / 6+ кругов: расхождение stems на шве ≤ 5 мс по записи, щелчков нет (AC 11)
- [ ] Гейн-рампы `set_sync_stream_volume` по `ui_dt` без щелчков на обоих телефонах
- [ ] `stream_paused` на Stream-плеере ставит на паузу и возобновляет с той же позиции; скрытие вкладки глушит звук в колбэке, возврат не снимает пользовательскую паузу (ADR-0001 A1–A2)
- [ ] iOS Safari: музыка стартует на первом касании (A1); поведение silent switch записано (A4)

---

## Implementation Notes

- Запись — внешний рекордер/loopback; метод — feasibility doc §Spike S2.
- Результат: evidence-файл с таблицей устройство × наблюдение.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 001: CPU/треск 4 stems
- Story 016: рабочая реализация паузы в AudioDirector

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/audio/spike_s2_loop_test.gd` OR playtest doc
- Additionally: `production/qa/evidence/spike-s2-loop-seam-ramp-pause-evidence.md` (device/measurement log)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001
- Unlocks: 007, 016
