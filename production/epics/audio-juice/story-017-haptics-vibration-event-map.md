# Story 017: Haptics: vibration event map, merge rule, settings toggle

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0005: Local persistence (SaveStore) (Last Verified 2026-09-30)
- ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

`Haptics` (модуль Presentation, ключ `haptics.vibration_on`): `PlatformBridge.vibrate()` через инъекцию; интервал ≥ 300 мс; события одного кадра объединяются (побеждает большая сумма длительностей; `[35,80,35]`=150); мин. 20 мс. Карта: касса полна 40; NEW BEST 30; уход (страйк) 35; начало последнего страйка `[35,80,35]`; конец партии 60; включение Vibration → 20. Не вибрируют: подача, монеты, отказ, порча, UI.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0001): vibration only through PlatformBridge (`navigator.vibrate` guarded, no-op on iOS Safari)
- Required (from ADR-0005): `haptics.vibration_on` owned by Haptics, default per ADR-0005 amendment, additive key
- Required (from ADR-0004): durations (`till_full_vibration_ms`, `new_best_vibration_ms`) from HudConfig

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] Вибрации нет при `vibration_on = false`, без `navigator.vibrate`, на паузе и скрытой вкладке (AC 44)
- [ ] Страйки при t = 0 и 0,2 → 1 вызов (интервал ≥ 300 мс); уход (35) и начало последнего страйка в одном кадре → только `[35, 80, 35]` (AC 44)
- [ ] Подача, монеты, отказ, порча, UI не вибрируют; включение Vibration в Settings → 20 (AC 44)

---

## Implementation Notes

- Тест на fake `vibrate()` и fake clock.
- Подписки: `day_filled`, `record_passed`, `guests_lost_changed`, `match_ended`.
- Переключатель в Settings — epic game-flow.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- epic game-flow: экран Settings
- hud Story 010: визуалы

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/audio/haptics_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 004
- Unlocks: None
