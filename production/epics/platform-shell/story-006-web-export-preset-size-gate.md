# Story 006: Web export preset, PWA-опции и CI size gate

> **Epic**: Platform Shell (Web)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/platform-integration-telegram-mini-app.md`
**Requirement**: `TR-platform-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
- Secondary: ADR-0007: Performance & load budgets (Last Verified 2026-09-30)
**ADR Decision Summary**: Single-thread web-экспорт; HTML-оболочка гейтит WebGL2, показывает экран загрузки и скрывает белую вспышку; PlatformBridge отдаёт один visibility-сигнал через JavaScriptBridge.create_callback + Page Visibility API.
**ADR Version**: 2026-10-01 (Last Verified)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: JavaScriptBridge.create_callback (args: Array), Thread Support OFF, Canvas Resize Policy Adaptive; NOTIFICATION_APPLICATION_* на web сломаны (godot#87014); callback-объект хранить в member; HTTPS обязателен.

**Control Manifest Rules (this layer)**:
- Required (from ADR-0001): single-thread export (Thread Support OFF), Canvas Resize Policy Adaptive; один visibility-сигнал только через `JavaScriptBridge.create_callback` + `document.visibilitychange` (+ `pagehide`); JS-callback-объекты хранятся в member; callback принимает один `args: Array`
- Forbidden (from ADR-0001): `NOTIFICATION_APPLICATION_FOCUS_IN/OUT`/`_PAUSED`/`_RESUMED` на web; синхронный emit `safe_area_changed` из JS-handler; SharedArrayBuffer-пути; опора на `OS.is_userfs_persistent()`
- Guardrail (from ADR-0001/0007): cold ready на слабом устройстве — цели ADR-0007; boot-total ≤ 21.5 МБ, движок ≤ 10.5 МБ, `.pck` ≤ 11.0 МБ

---

## Acceptance Criteria

*From the TR-IDs / ADR guidelines above, scoped to this story:*

- [ ] `export_presets.cfg`: Web, Thread Support OFF, Canvas Resize Policy Adaptive (`html/canvas_resize_policy=2`), custom HTML shell из story 004, PWA standalone/portrait включены, cross-origin isolation headers выключены; экспорт строится headless одной командой и запускается по HTTPS (plain HTTP вне localhost отклоняется loader'ом)
- [ ] CI-скрипт gzip-6 измеряет boot-набор (`.wasm`, `.js`, `.pck`, shell) и падает при > 21.5 МБ суммарно, > 10.5 МБ у движка, > 11.0 МБ у `.pck`; пороги лежат в одном constants-файле, не разбросаны по коду (ADR-0007)
- [ ] Smoke check: собранная страница открывается по одному URL на ПК- и телефонном браузере (TR-platform-001), публикация на выбранный HTTPS-хост отдаёт `.wasm` со сжатием (Brotli/gzip) — зафиксировано в `production/qa/smoke-[date].md`

---

## Implementation Notes

Имена PWA-опций и членов `JavaScriptBridge.pwa_*` взяты из знаний до 4.7 — сверить с class reference 4.7.2 (ADR-0001 амендмент, W2/W3), чтобы service worker кэшировал всё нужное. Актуальные пороги берутся из последних амендментов ADR-0007 (21.5 / 10.5 / 11.0 МБ). Размерный гейт писать вместе с `/test-setup` follow-up (workflow `.github/workflows/tests.yml` пока только gdUnit4). Хост — решение владельца (host-agnostic по ADR-0001); не привязываться к конкретному.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: реальное измерение на слабом Android
- Story 007: PerfProbe
- Контент игры, влияющий на размер .pck

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Smoke check pass: `production/qa/smoke-[date].md`
- Доп. автотест: `tools/ci/size_gate_test.sh`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004
- Unlocks: Story 008
