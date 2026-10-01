# Story 018: Audio budgets check: export scan, file-set size, CPU probe, polyphony/PCM, loudness

> **Epic**: Audio & Juice Feedback
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/audio-juice-feedback.md`
**Requirement**: `TR-audio-013`, `TR-hud-028`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets
**ADR Decision Summary**: 60/30 fps targets, ms-per-system CPU table, draw calls <= 180, .pck <= 11 MB, load <= 21.5 MB, Low/Mid/High quality tiers, PerfProbe; 2026-10-01 audio amendment: music <= 6.0 MB as a file set outside .pck, music CPU <= 2.5 ms/frame (provisional), <= 16 one-shot SFX, Sample PCM ~35 MB / <= 90 s.
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0001: Web build & platform shell (Last Verified 2026-10-01)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Frame-time and per-system ms are provisional until a weak-Android run; measure with PerfProbe on the reference device.

Автоматическая и устройственная проверка бюджетов (ADR-0007 audio amendment): музыка рядом с `index.html`, не в `.pck`, набор ≤ 6,0 МБ; `.pck` ≤ 11,0 МБ; CPU музыки ≤ 2,5 мс/кадр (Mid); Sample PCM ≈ 35 МБ / ≤ 90 с; `music_jazz_main.ogg` не в экспорте; provenance на каждый ассет; импорт-скан (music = Stream, остальное = Sample).

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Guardrail (from ADR-0007): music set <= 6.0 MB, .pck <= 11.0 MB, music CPU <= 2.5 ms/frame (provisional), Sample PCM ~35 MB / <= 90 s
- Required (from ADR-0007): CI checks a file LIST for music (not one file name)
- Required (from ADR-0001): music not in .pck; fetched after `ready_reached`

---

## Acceptance Criteria

*From `design/gdd/audio-juice-feedback.md`, scoped to this story:*

- [ ] Скан экспорта: музыка рядом с `index.html`, в `.pck` нет; суммарно ≤ 6,0 МБ; `music_jazz_main.ogg` не попадает; на каждый аудиоассет есть запись в `provenance.yaml` (AC 41)
- [ ] Скан импорта: `music_*` — Stream; `sfx_/ui_/vo_/amb_` — Sample; нет `AudioStreamRandomizer`/`AudioStreamPolyphonic`; в `src/audio/` нет `create_tween()` (AC 5, 22)
- [ ] PerfProbe на Mid-устройстве: decode+mix+filter ≤ 2,5 мс/кадр; запись 3-минутной партии −16 ±2 LUFS-I, ≤ −1 dBTP, без клиппинга > 1 мс (AC 40); evidence с цифрами (TR-hud-028: ≤ 1,0 мс для одного трека — пилот)

---

## Implementation Notes

- CI-скрипт в `tools/ci/` (список файлов, `ebur128`).
- Запускается после Story 006/011 (контент); до них — на placeholder.
- Значения бюджетов — из ADR-0007, не копировать в код.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 006/011: производство контента
- Epic `performance` (общие бюджеты кадра)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/audio/audio_budget_scan_test.gd` OR playtest doc
- Additionally: `production/qa/evidence/audio-budgets-and-export-check-evidence.md` (device/measurement log)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 005, 006, 007, 011
- Unlocks: None
