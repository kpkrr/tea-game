# Epic: Audio & Juice Feedback

> **Layer**: Presentation
> **GDD**: design/gdd/audio-juice-feedback.md
> **Architecture Module**: AudioDirector · Haptics
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 15 / 16 active
> **Status**: Ready
> **Stories**: 18 stories

## Overview

Адаптивная музыка из 4 stems по прогрессу сложности, трек меню, шины и mute-слои, cartoon-фоли и голоса гостей с лимитером, раздельные награды за монеты и очки, дакинг под стингеры, сердцебиение на последнем страйке, вибрация по карте событий. Сначала spike S1–S3 (AudioStreamSynchronized на web, QOA, CPU), затем пилот музыки.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Web build & platform shell | Single-thread web-экспорт, HTML-оболочка, проверка WebGL2, экран загрузки, Page Visibility, PWA/share/wake lock через хелпер оболочки | HIGH |
| ADR-0003: Match simulation — clock, tick order, pause | GameClock + MatchDirector, фиксированный порядок тика, без SceneTree.paused, типизированные сигналы, DI через корень композиции | LOW |
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |
| ADR-0007: Performance & load budgets | 60/30 fps, мс на систему, draw calls ≤ 180, .pck ≤ 11 МБ, загрузка ≤ 21,5 МБ, уровни качества Low/Mid/High, PerfProbe | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-audio-001 | Музыка партии — 4 stems (120 BPM, F major, 96,0 с) в одном AudioStreamSynchronized, Stream; слои вступают по difficulty_progress с порогами 0/0,03/0,25/1,0 (F1) | ADR-0001, ADR-0007 (поправка 2026-10-01) ✅ |
| TR-audio-002 | Переход слоя квантуется к ближайшему такту и нарастает stem_fade_bars (2) такта; огибающие по ui_dt, без Tween (F2) | ADR-0001, ADR-0003 (поправка 2026-10-01) ✅ |
| TR-audio-003 | Отдельный трек меню (Stream), с начала на каждый заход, fade-in 1 с; меню→партия 0,6 с, партия→меню 0,8 с | ADR-0001 (поправка 2026-10-01) ✅ |
| TR-audio-004 | Последний страйк: S4 гаснет, LP на Music 2500 Гц за 0,4 с, −3 dB, сердцебиение 1 Гц на SFX; match_ended: LP 800 Гц за 0,3 с, сердцебиение гаснет 0,3 с | ADR-0001, ADR-0003 (поправка 2026-10-01) ✅ |
| TR-audio-005 | Шины Master ← Music; Master ← SFX ← {Voice, UI, Stinger, Amb}; mute: muted → Master, music_on → Music, sfx_on → SFX | ADR-0001, ADR-0005 (поправка 2026-10-01) ✅ |
| TR-audio-006 | SFX/голоса/стингеры/фон — Sample (QOA), вариации и pitch выбираются в коде (без Randomizer/Polyphonic) | ADR-0001 (поправка 2026-10-01) ✅ |
| TR-audio-007 | Награды разделены: монеты — аккорд только по цене (2 → F, 5 → F+A, 7 → F–A–C); очки — стеклянный тембр, высота по серии combo_window_s 6,0 (F3) | GDD/UX — ADR не требуется |
| TR-audio-008 | Лимитер голосов F4: ≤ 2 реплики, зазор 0,25 с, кулдаун гостя 2,5 с, p(order) падает с очередью; leaving проходит всегда; RNG внедряется | ADR-0003 (поправка 2026-10-01) ✅ |
| TR-audio-009 | Дакинг музыки под стингер — скриптом по громкости шины Music (−6 dB, атака 0,05, спад 0,4 с, F5); sidechain не используется | ADR-0001 (поправка 2026-10-01) ✅ |
| TR-audio-010 | Полифония ≤ 16 одноразовых звуков, классы P0–P4 с потолками; вытеснение F6 (P0/P1 не вытесняются, старший P4 первым, fade 20 мс) | ADR-0007 (поправка 2026-10-01) ✅ |
| TR-audio-011 | Пауза/скрытая вкладка: stream_paused для музыки, фона, сердцебиения и звуков в полёте в синхронном колбэке; на пользовательской паузе шина UI работает | ADR-0003 (поправка 2026-10-01) ✅ |
| TR-audio-012 | Вибрация по карте событий audio GDD §C: haptics.vibration_on + navigator.vibrate, интервал ≥ 300 мс, слияние событий кадра | ADR-0001, ADR-0005 (поправка 2026-10-01) ✅ |
| TR-audio-013 | Бюджеты: музыка ≤ 6,0 МБ набором файлов после загрузки; .pck ≤ 11,0 МБ; CPU музыки ≤ 2,5 мс/кадр; Sample PCM ≈ 35 МБ / ≤ 90 с суммарно | ADR-0007 (поправка 2026-10-01) ✅ |
| TR-hud-024 | Кнопка звука: mute = шина Master; состояние `settings.muted` (bool, по умолчанию false) в SaveStore, schema_version без изменений | ADR-0001, ADR-0005 ✅ |
| TR-hud-027 | Один зацикленный музыкальный трек (`music_jazz_main.ogg`): старт с начала после первого жеста игрока и загрузки файла; пауза игрока и скрытая вкладка ставят музыку на паузу, возобновление — с той же позиции; на итогах (MatchEnd) трек продолжает играть под low-pass фильтром шины Music (частота среза и время нарастания — конфиг, нарастание по ui_dt); «Играть снова» — фильтр снят, трек с начала; mute = шина Master во всех состояниях; шины Master → Music, SFX | ADR-0001, ADR-0003, ADR-0004 ✅ |
| TR-hud-028 | Бюджет музыки: файл ≤ 2,7 МБ вне `.pck`, загружается после ready_reached (не входит в 13,5 МБ загрузки и холодный TTI ≤ 20 с); воспроизведение Stream (сжатые пакеты ≈ 2,7 МБ в wasm-куче, без PCM), декод + микс ≤ 1,0 мс/кадр на эталонном устройстве (предварительно); `.pck` ≤ 3,0 МБ целиком под остальной контент; разблокировка web-аудио на iOS Safari, отсутствие треска и стоимость загрузки проверяются на устройстве | ADR-0007 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/presentation/audio_director.gd`
- `prototypes/tea-rush-vertical-slice/src/foundation/config/audio_config.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [Spike S1: 4 stems in AudioStreamSynchronized on web devices](story-001-spike-s1-synchronized-stems-web.md) | Integration | Ready | ADR-0001, ADR-0007 | L |
| 002 | [Spike S2: loop seam drift, ramp clicks, stream_paused and hidden tab](story-002-spike-s2-loop-seam-ramp-pause.md) | Integration | Ready | ADR-0001, ADR-0003 | M |
| 003 | [Spike S3: Sample SFX latency, bus mute on Sample, max_polyphony, QOA decode](story-003-spike-s3-sample-latency-bus-mute-polyphony.md) | Integration | Ready | ADR-0001, ADR-0007 | M |
| 004 | [Bus layout, mute layers, AudioConfig, settings persistence and HUD mute button](story-004-audio-buses-mute-settings-and-button.md) | Integration | Ready | ADR-0001, ADR-0005, ADR-0004 | M |
| 005 | [Music pilot: single looped track (fetch, first gesture, pause, MatchEnd low-pass, restart)](story-005-music-pilot-single-track-loop.md) | Integration | Ready | ADR-0001, ADR-0003, ADR-0004, ADR-0007 | L |
| 006 | [Content: produce 4 match stems + menu track (F major, 120 BPM)](story-006-content-music-stems-and-menu-track.md) | Config/Data | Ready | ADR-0007, ADR-0001 | L |
| 007 | [Adaptive stems: layer gains by difficulty_progress (F1) and bar-quantised fades (F2)](story-007-adaptive-stems-layers-f1-f2.md) | Logic | Ready | ADR-0001, ADR-0003, ADR-0007 | L |
| 008 | [Music states: last-strike squeeze, match_ended low-pass, quit, menu<->match](story-008-music-state-transitions-last-strike-results.md) | Logic | Ready | ADR-0001, ADR-0003, ADR-0004 | M |
| 009 | [Heartbeat loop on last strike (1 Hz, beat-quantised, phase for HUD vignette)](story-009-heartbeat-loop-beat-quantised.md) | Logic | Ready | ADR-0001, ADR-0003 | S |
| 010 | [SFX pool: P0-P4 classes, 16-slot cap, F6 eviction and dedupe](story-010-sfx-pool-priorities-eviction-f6.md) | Logic | Ready | ADR-0007, ADR-0001, ADR-0003 | L |
| 011 | [Content: produce SFX, UI, stingers, archetype voices and ambience (QOA)](story-011-content-sfx-ui-stingers-voices-ambience.md) | Config/Data | Ready | ADR-0007, ADR-0001 | L |
| 012 | [SFX event map: station/guest/till events to sounds with variations](story-012-sfx-event-map-wiring.md) | Integration | Ready | ADR-0001, ADR-0003, ADR-0004 | M |
| 013 | [Rewards and stingers: coin chords by price, star pitch ladder (F3), NEW BEST / TILL FULL / results](story-013-rewards-stingers-coin-chord-star-ladder.md) | Logic | Ready | ADR-0003, ADR-0004 | M |
| 014 | [Guest voice limiter (F4) and barista cooldown](story-014-voice-limiter-f4.md) | Logic | Ready | ADR-0003, ADR-0004 | M |
| 015 | [Stinger ducking of Music (F5) and ambience layer (queue murmur, Paused/Results)](story-015-stinger-ducking-and-ambience.md) | Logic | Ready | ADR-0001, ADR-0003 | M |
| 016 | [Pause and hidden tab for all audio (stream_paused, UI bus alive)](story-016-pause-hidden-tab-all-audio.md) | Integration | Ready | ADR-0003, ADR-0001 | M |
| 017 | [Haptics: vibration event map, merge rule, settings toggle](story-017-haptics-vibration-event-map.md) | Logic | Ready | ADR-0001, ADR-0005, ADR-0004 | M |
| 018 | [Audio budgets check: export scan, file-set size, CPU probe, polyphony/PCM, loudness](story-018-audio-budgets-and-export-check.md) | Integration | Ready | ADR-0007, ADR-0001 | M |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/audio-juice-feedback.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/story-readiness production/epics/audio-juice/story-001-*.md`, then `/dev-story`.
