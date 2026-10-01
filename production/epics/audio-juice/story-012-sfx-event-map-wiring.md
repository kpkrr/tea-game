# Story 012: SFX event map: station/guest/till events to sounds with variations

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)
- ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

Подключение событий Brewing/Kitchen/GuestSim/Till/Player Control/HUD (`sfx_hint`) к `SfxPool` по таблице audio GDD §A; звуки ввода и наград играют в кадре события (не квантуются); `sfx_guest_leave` всегда; в MVP нет шагов; `trash` с пустыми руками — тишина; серия звуков чайника (brew loop с панорамой).

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0001): SFX/voice/stinger/ambience use Sample playback (QOA), variations + pitch chosen in code; no `AudioStreamRandomizer`/`AudioStreamPolyphonic`
- Required (from ADR-0003): subscribe to typed signals; order of subscribers does not matter
- Required (from ADR-0004): event→sound table is data (`AudioConfig`/resource), not hardcoded

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] Каждая строка таблицы §A срабатывает на свой триггер в кадре события (headless-интеграция с fake-системами); отдельный звук на каждое HUD-событие (TR-hud-018)
- [ ] `sfx_guest_leave` звучит на каждом уходе независимо от лимитера голосов (AC 34 часть); `trash` пустыми руками — без звука
- [ ] `play()` для тапа и наград — в кадре события; на устройстве задержка касание → звук ≤ 80 мс (AC 43)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/audio_director.gd` + `.../foundation/config/audio_config.gd` (bring to standards: static typing, doc comments, DI of GameClock/AudioConfig/SaveScope/backend) — slice event hooks.
- Таблица данных: id, шина, вариации, pitch/vol, класс, макс/кулдаун.
- Подписывается на `sfx_hint` из hud Story 006.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 013: награды/стингеры
- Story 014: голоса
- Story 011: ассеты

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/audio/sfx_event_map_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 010
- Unlocks: 013, 014
