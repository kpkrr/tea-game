# Story 015: Stinger ducking of Music (F5) and ambience layer (queue murmur, Paused/Results)

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

Дакинг скриптом по громкости шины Music (sidechain не используется): −6 dB, атака 0,05 с, спад 0,4 с, два стингера — минимум, не сумма (F5; на TILL FULL L = 1,2 с → −3,6 / −6 / −3 / 0 dB при τ = 0,03 / 0,6 / 1,4 / 1,6). Фон (Rule 15): `amb_room_loop` меню+партия, терраса у реки по `difficulty_progress`, гомон по очереди −30…−24 dB (огибающая 1 с); в Paused/Results фон −8 dB, гомон выключен; дакинг фона — только если Spike S3 (A3) подтвердил.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Forbidden (from ADR-0001): sidechain compression (not applicable to Sample SFX); ducking is scripted on the Music bus volume
- Required (from ADR-0003): all audio envelopes (layer fades, filter ramps, ducking) accumulate `GameClock.ui_dt` in `_process`; never `Tween`
- Required (from ADR-0001): A3 verdict from Spike S3 gates ambience ducking

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] TILL FULL, L = 1,2: τ = 0,03 / 0,6 / 1,4 / 1,6 → дакинг −3,6 / −6 / −3 / 0 dB (±0,01); два стингера — минимум; на паузе τ не растёт (AC 30)
- [ ] Гомон при очереди 0 / 2 / 4 = −30 / −27 / −24 dB, огибающая 1 с; в Paused и Results фон −8 dB, гомон выключен; в меню гомона нет (AC 39)
- [ ] Если A3 не подтверждён — дакинга фона нет (флаг конфига), дакинг Music работает

---

## Implementation Notes

- Формула F5 — audio GDD §F5.
- Длина стингера `L` — единственный источник: таблица стингеров (Rule 12).

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 013: запуск стингеров
- Story 016: пауза

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/audio/ducking_ambience_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003, 004, 010, 013
- Unlocks: None
