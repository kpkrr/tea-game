# Оценка осуществимости: адаптивная многослойная музыка на web

> **Автор**: godot-specialist · **Дата**: 2026-10-01 · Проверено на установленном 4.7.2.stable (`--dump-extension-api` + headless-пробы). Рантайм на web — «needs verification».

## Подтверждено на 4.7.2 (desktop, headless)

- Есть `AudioStreamSynchronized` (MAX_STREAMS = 32, `set_sync_stream` / `set_sync_stream_volume`), `AudioStreamInteractive`, `AudioStreamPlaylist`, `AudioEffectCompressor.sidechain`, `AudioEffectHardLimiter`, `AudioStreamPlayer.max_polyphony` / `playback_type`.
- `can_be_sampled()`: Ogg и WAV — true; Synchronized, Interactive, Playlist, Polyphonic, Randomizer — **false** → мета-стримы только в Stream-режиме; `MusicPlayer` явно ставит `PLAYBACK_TYPE_STREAM`.
- `AudioStreamOggVorbis.load_from_buffer(bytes)` → `set_sync_stream(i, …)` работает с загруженным в рантайме файлом.
- Уточнение: `output_latency.web` в ADR-0001 = 100 мс (200 — запасной шаг A7); в `project.godot` сейчас дефолт 50.

## 1. Синхронные стемы

**Рекомендация — `AudioStreamSynchronized`**: все стемы микшируются в одном mix-вызове, синхронность по сэмплам — конструктивная. Несколько `AudioStreamPlayer` — нет (разъедутся на лупе).
- Стемы одинаковой длины в сэмплах, `loop = true` каждому в коде. Выравнивание на шве после Vorbis (pre-skip/padding) — проверить.
- `AudioStreamInteractive` для меню↔матч в MVP не нужен.
- CPU (оценка): одна Ogg-декодировка в wasm ≈ 0,3–0,6 мс/кадр, 4 стема ≈ 1,5–2,5 мс — **выше лимита ADR-0007 (1,0 мс)**. Пропускаются ли стемы на −80 dB — проверить; считаем, что платим за все N. В no-threads-сборке микс на главном потоке → риск треска растёт с N (A7).

## 2. Загрузка вне `.pck`

Работает: скачать **все** стемы → собрать Synchronized → `play()` (добавлять стем в играющий поток нельзя). 4 × 2,6 МБ ≈ 10 МБ ломает строку «музыка ≤ 2,7 МБ» ADR-0007 → луп 60–90 с, 64–80 kbps, фоновые стемы моно ≈ 0,5–0,9 МБ на стем. Тело запроса держать по одному стему.

## 3. Кроссфейд слоёв

`set_sync_stream_volume` из `_process` по `ui_dt` (без Tween, ADR-0003). Ступень ≈ один mix-блок — проверить на щелчки. Громкость хранится в ресурсе (общая для всех его player'ов). `stream_paused` работает и для мета-стрима.

## 4. Эффекты на шинах

LowPass, Compressor, Limiter дешёвые, но **работают только для Stream-аудио**. SFX в Sample-режиме идут мимо микшера движка → **sidechain-дакинг от SFX не работает**, Limiter на Master не ограничит сумму. Дакинг — скриптом (событие → ramp громкости шины Music / стемов); Limiter/Compressor — только на Music. Действуют ли громкость и mute шины на Sample-SFX — A3, проверить.

## 5. SFX

Оставить **Sample** (Stream добавил бы ≈ 85–100 мс к отклику). Задержка Sample ≈ 20–80 мс на Android — замерить. Вариации выбирать случайно в коде (Randomizer/Polyphonic тихо переводят в Stream). Один `AudioStreamPlayer` на тип звука, `max_polyphony` 3–4 + пул; соблюдается ли `max_polyphony` в Sample — проверить.

## 6. Рекомендация и фолбэки

- **Основной путь**: Synchronized, 3–4 коротких стема (Stream), SFX в Sample, дакинг скриптом, LowPass на Music.
- **Фолбэк 1**: 2–3 готовых трека интенсивности на одной сетке; кроссфейд двух player'ов с `seek(pos)` за 0,5–1 с.
- **Фолбэк 2**: один трек + фильтр и громкость по сложности.

## Spike на устройстве

- **S1**: Android RD + iPhone — 4 стема + пачка SFX, матч 3 мин при 100/200 мс: нет треска; дельта кадра с музыкой против лимита.
- **S2**: 10+ кругов лупа — стемы не разъезжаются; ramp без щелчков; `stream_paused` / скрытие вкладки.
- **S3**: задержка тап→SFX в Sample; громкость/mute шины на Sample-SFX (A3); `max_polyphony` ограничивает one-shot'ы.

**Нужны поправки**: ADR-0007 (размер музыки, CPU на N стемов), ADR-0001 (дакинг скриптом, sidechain не работает для Sample-SFX).
