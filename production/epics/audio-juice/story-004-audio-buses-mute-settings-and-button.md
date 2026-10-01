# Story 004: Bus layout, mute layers, AudioConfig, settings persistence and HUD mute button

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-005`, `TR-hud-024`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0005: Local persistence (SaveStore) (Last Verified 2026-09-30)
- ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/audio_director.gd` + `.../foundation/config/audio_config.gd` (bring to standards: static typing, doc comments, DI of GameClock/AudioConfig/SaveScope/backend)

Шины Master ← Music; Master ← SFX ← {Voice, UI, Stinger, Amb} (гейны Voice −3, UI −6, Amb −14 dB); mute: `muted` → Master, `music_on` → Music, `sfx_on` → SFX; `settings.muted` (bool, default false) в SaveStore без смены schema_version; кнопка звука в HUD (иконка меняет форму) вызывает `set_muted()`.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0001): every player uses bus Music/SFX/Voice/UI/Stinger/Amb, never `Master`; bus indices resolved once by name
- Required (from ADR-0005): `settings.muted/music_on/sfx_on` owned by AudioDirector, scope `settings`, additive keys with defaults, schema_version stays 1
- Required (from ADR-0004): `AudioConfig` sub-resource validated at load (ranges, dB values)
- Forbidden (from ADR-0001): any player with `bus = "Master"`

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] В `default_bus_layout.tres` есть Master, Music, SFX, Voice, UI, Stinger, Amb с маршрутизацией и гейнами по Rule 1; скан сцен/скриптов не находит плеера с `bus = "Master"` (AC 1)
- [ ] Все 8 комбинаций `muted/music_on/sfx_on`: слышимость шины = `¬muted ∧ *_on` (AC 2); `music_on=false`, `sfx_on=true` → TILL FULL звучит (Stinger), Music заглушён (AC 3)
- [ ] Позиция заглушённого потока продолжает идти: 10 с `ui_dt` при `muted` — stems сдвинулись на 10,0 с, гейны по F1 (AC 4)
- [ ] Кнопка звука: в том же кадре SFX и музыка пропадают, иконка меняет форму; после перезагрузки `settings.muted` сохранён (HUD AC 57); `is_muted()` читается HUD каждый кадр

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/audio_director.gd` + `.../foundation/config/audio_config.gd` (bring to standards: static typing, doc comments, DI of GameClock/AudioConfig/SaveScope/backend) — bus/mute/`set_muted`/`is_muted`.
- Индексы шин — один раз по имени `get_bus_index`.
- Тест Logic-части (8 комбинаций) на fake backend; скан шин — Integration на headless 4.7.2 с реальным `AudioServer`.
- Кнопка в HUD — слот из hud Story 003; здесь логика и подключение.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 005: музыка
- Story 013+: SFX на шинах
- epic game-flow: переключатели Music/SFX в Settings (вызывают сеттеры отсюда)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/audio/audio_mute_layers_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation: save-store, data-config)
- Unlocks: 005, 007, 008, 010, 015
