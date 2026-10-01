# Story 011: Content: produce SFX, UI, stingers, archetype voices and ambience (QOA)

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Config/Data
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-006`, `TR-audio-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets
**ADR Decision Summary**: 60/30 fps targets, ms-per-system CPU table, draw calls <= 180, .pck <= 11 MB, load <= 21.5 MB, Low/Mid/High quality tiers, PerfProbe; 2026-10-01 audio amendment: music <= 6.0 MB as a file set outside .pck, music CPU <= 2.5 ms/frame (provisional), <= 16 one-shot SFX, Sample PCM ~35 MB / <= 90 s.
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0001: Web build & platform shell (Last Verified 2026-10-01)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Frame-time and per-system ms are provisional until a weak-Android run; measure with PerfProbe on the reference device.

Контентная история по audio GDD §A/§B/§D: фоли-SFX (станции, чайники, чашка, слоты, мусорка, дверь, уход, касса), награды (`sfx_reward_coin_{02,05,07}`, `sfx_reward_star_01`), UI, 4 стингера (NEW BEST 0,8 с, NEW RECORD 2,0 с, TILL FULL 1,2 с, SHIFT OVER 1,5 с), невербальные голоса 4 архетипов (3 варианта, ≈ 69 × 0,6 с), сердцебиение, фон (`amb_room_loop`, терраса у реки день/вечер (вода, ветер, птицы / сверчки, фонари), гомон). WAV 48 кГц/24 бит → импорт QOA, Sample; мелодические SFX только из пентатоники F–G–A–C–D.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0001): SFX/voice/stinger/ambience use Sample playback (QOA), variations + pitch chosen in code; no `AudioStreamRandomizer`/`AudioStreamPolyphonic`
- Required (from ADR-0007): Sample assets <= 90 s total, decoded PCM ~35 MB; .pck <= 11 MB (audio ~2.6 MB)
- Required (from audio GDD §D): naming `<prefix>_<source>_<action>[_<variant>]_<nn>`, folders `assets/audio/{sfx,ui,vo,amb}`, `provenance.yaml` entry per file

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] Все события из audio GDD §A/§B имеют ассет с нужным числом вариантов; монеты = аккорды F / F+A / F–A–C, очки — стеклянный тембр (не металл) (AC 24 контент, Rule 11)
- [ ] Дочистка: тишина ≤ 5 мс до атаки, fade-in 2 мс, fade-out 10–30 мс, без клиппинга/DC, шум < −60 дБ, петли без щелчков; ebur128-скрипт по `assets/audio/` — каждая категория в цели ±1 LU и не выше пика (AC 40)
- [ ] Слепой тест: монеты ≠ очки, Served ≠ уход — 5 из 5 (AC 45 часть); сигналы держат энергию 1–5 кГц, смысл не ниже 150 Гц (AC 42)
- [ ] Импорт: все `sfx_/ui_/vo_/amb_` — Sample (QOA); `provenance.yaml` заполнен для каждого файла (AC 5, 41)

---

## Implementation Notes

- Инструменты/промпты — audio GDD §D (скелеты SFX и голоса).
- Разбить выпуск на партии по категориям; порядок: награды/уход/Served → станции → голоса → фон.
- Не блокирует кодовые истории: они работают на placeholder-ассетах.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 012: подключение
- Story 006: музыка

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

- Depends on: 003 (Sample/QOA verdict)
- Unlocks: 012, 013, 014, 015, 018
