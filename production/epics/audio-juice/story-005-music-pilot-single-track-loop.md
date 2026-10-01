# Story 005: Music pilot: single looped track (fetch, first gesture, pause, MatchEnd low-pass, restart)

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-hud-027`, `TR-hud-028`, `TR-audio-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web export, HTML shell, autoplay unlock on first gesture, music outside .pck; amendments add adaptive stems in one AudioStreamSynchronized, bus layout Master<-Music / Master<-SFX<-{Voice,UI,Stinger,Amb}, scripted ducking, Haptics via PlatformBridge.vibrate().
**ADR Version**: 2026-10-01
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)
- ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)
- ADR-0007: Performance & load budgets (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web audio: SFX use Sample playback (no bus effects), music uses explicit PLAYBACK_TYPE_STREAM; iOS Safari unlock, stream_paused and AudioStreamSynchronized behaviour on device are UNVERIFIED (spikes S1-S3, A1-A4).

Пилот музыки на одном треке (`music_jazz_main.ogg`, 2,61 МБ, 204,8 с — временная замена до stems, Story 006/007): загрузка вне `.pck` после `ready_reached` через `PlatformBridge.asset_url()` + HTTPRequest; старт с начала после первого жеста и загрузки; пауза/скрытая вкладка → `stream_paused`; на MatchEnd — low-pass на Music (800 Гц, ramp 0,3 с по `ui_dt`); Play Again — фильтр снят, трек с начала. Та же машина состояний затем переносится на stems/трек меню (TR-audio-003).

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0001): music stored next to index.html, not in .pck; absolute URL from PlatformBridge; first-gesture unlock; explicit `PLAYBACK_TYPE_STREAM`
- Required (from ADR-0003): low-pass ramp on `ui_dt` (log-linear 20 000 Hz -> cutoff), frozen on hidden; `paused_changed` -> `stream_paused` in the callback
- Guardrail (from ADR-0007): music file <= 2.7 MB outside .pck; decode+mix <= 1.0 ms/frame on RD (provisional); not counted in the 13.5 MB load or cold TTI <= 20 s

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] Музыка не стартует до первого жеста и загрузки файла; затем играет с начала и зациклена (HUD AC 77)
- [ ] Пауза игрока и скрытая вкладка ставят поток на паузу; возобновление — с той же позиции (HUD AC 58)
- [ ] `match_ended`: фильтр включён, `cutoff_hz` нарастает от 20 000 до `music_lowpass_cutoff_hz` (800) за `music_lowpass_ramp_s` (0,3) по `ui_dt`; «Играть снова» — фильтр снят, трек с начала (HUD AC 58)
- [ ] Загрузка упала и повтор через 5 с упал → сессия без музыки, без сообщения об ошибке, SFX звучат (AC 20 часть)
- [ ] Девайс (iOS Safari + Android): нет треска, стоимость загрузки и разблокировка AudioContext записаны в evidence; декод+микс ≤ 1,0 мс/кадр (TR-hud-028)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/audio_director.gd` + `.../foundation/config/audio_config.gd` (bring to standards: static typing, doc comments, DI of GameClock/AudioConfig/SaveScope/backend) — music player, LP filter ramp, `start_music_fetch`.
- Экспорт исключает `assets/audio/music/*` из .pck; CI/export копирует файл рядом с `index.html`.
- Фильтр: `AudioEffectLowPassFilter` slot 0 на Music, выключен по умолчанию.
- Заметка: TR-hud-027/028 формулируют единственный трек; в финале `music_jazz_main.ogg` снимается с экспорта (audio GDD Rule 17), а состояния/бюджеты переезжают на stems (Story 007/008/018).

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 007: stems и слои
- Story 008: последний страйк, меню↔партия переходы
- Story 016: общая пауза всех звуков
- epic game-flow: трек меню UI

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/audio/music_pilot_test.gd` OR playtest doc
- Additionally: `production/qa/evidence/music-pilot-single-track-loop-evidence.md` (device/measurement log)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 004
- Unlocks: 007, 008, 016, 018
