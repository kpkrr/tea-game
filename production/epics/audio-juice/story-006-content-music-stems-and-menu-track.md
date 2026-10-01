# Story 006: Content: produce 4 match stems + menu track (F major, 120 BPM)

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Config/Data
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-001`, `TR-audio-003`, `TR-audio-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets
**ADR Decision Summary**: 60/30 fps targets, ms-per-system CPU table, draw calls <= 180, .pck <= 11 MB, load <= 21.5 MB, Low/Mid/High quality tiers, PerfProbe; 2026-10-01 audio amendment: music <= 6.0 MB as a file set outside .pck, music CPU <= 2.5 ms/frame (provisional), <= 16 one-shot SFX, Sample PCM ~35 MB / <= 90 s.
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0001: Web build & platform shell (Last Verified 2026-10-01)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Frame-time and per-system ms are provisional until a weak-Android run; measure with PerfProbe on the reference device.

Контентная история: создать/сгенерировать и свести 4 stems партии (`music_match_{bed,groove,bass,lead}_stem.ogg`, 48 тактов = 96,0 с, одинаковая длина ±1 сэмпл, бесшовный loop) и трек меню `music_menu_golden_hour_loop` (32 такта, 64 с). Ogg Vorbis 48 кГц ≈ 100 кбит/с; набор ≤ 6,0 МБ. Запускать после вердикта Spike S1.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0007): music file set <= 6.0 MB after load, stored outside .pck
- Required (from audio GDD Rule 17): every asset has a `provenance.yaml` record (tool/version/date/prompt/seed/licence snapshot) — no record, no asset in the build
- Forbidden: recognisable-voice cloning; artist/game names in prompts

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] 4 stems: Rhodes+пэд+щётки / kick+хэты+шейкер / бас+чопы / труба+флейта+ooh; одна тональность F major, 120 BPM, по 96,0 с ±1 сэмпл, loop без щелчков (3 прохода) (AC 10)
- [ ] Трек меню 64 с, соло Rhodes + винил, та же тональность; loudness: stems вместе −18 LUFS-I / ≤ −3 dBTP, меню −20 LUFS-I (Rule 16)
- [ ] Суммарный размер набора ≤ 6,0 МБ; записи в `audio-source/provenance.yaml` для каждого файла (AC 41)
- [ ] Проверка на динамике телефона при 50 % громкости: слои различимы, S3 баса слышен через гармоники (AC 42)

---

## Implementation Notes

- Источники/инструменты — решение audio-director; сырые генерации в `audio-source/` (`.gdignore`).
- Результат кладётся в `assets/audio/music/`; `music_jazz_main.ogg` остаётся в `_reference/` и не попадает в экспорт (Rule 17).
- Если Spike S1 вернул фолбэк — вместо 4 stems свести 4 накопительных микса (S1, S1+2, S1+2+3, S1+2+3+4).

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 007: воспроизведение и слои
- Story 011: SFX/голоса/фон

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (verdict)
- Unlocks: 007, 018
