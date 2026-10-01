# Story 007: PerfProbe: feature-gated сбор кадров и per-system мс

> **Epic**: Platform Shell (Web)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/platform-integration-telegram-mini-app.md`
**Requirement**: ADR-0007 (governing; прямых TR-ID в эпике нет — инфраструктура замера бюджетов)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets
**ADR Decision Summary**: 60 fps цель / 30 fps пол, мс на систему, draw calls ≤ 180, boot-total ≤ 21.5 МБ, .pck ≤ 11.0 МБ, движок ≤ 10.5 МБ; PerfProbe только под feature-тегом perf_probe; CI size gate.
**ADR Version**: 2026-09-30 (Last Verified)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (engine overall HIGH)
**Engine Notes**: Post-cutoff APIs: none (Performance monitors, Time.get_ticks_usec). Frame-time/per-system ms и RD boot sub-budget остаются provisional до прогона на слабом Android; таймер в web огрублён (~0.1–1 мс).

**Control Manifest Rules (this layer)**:
- Required (from ADR-0001): single-thread export (Thread Support OFF), Canvas Resize Policy Adaptive; один visibility-сигнал только через `JavaScriptBridge.create_callback` + `document.visibilitychange` (+ `pagehide`); JS-callback-объекты хранятся в member; callback принимает один `args: Array`
- Forbidden (from ADR-0001): `NOTIFICATION_APPLICATION_FOCUS_IN/OUT`/`_PAUSED`/`_RESUMED` на web; синхронный emit `safe_area_changed` из JS-handler; SharedArrayBuffer-пути; опора на `OS.is_userfs_persistent()`
- Guardrail (from ADR-0001/0007): cold ready на слабом устройстве — цели ADR-0007; boot-total ≤ 21.5 МБ, движок ≤ 10.5 МБ, `.pck` ≤ 11.0 МБ
- Forbidden (from ADR-0007): создание `PerfProbe` по любому условию, кроме feature-тега `perf_probe`

---

## Acceptance Criteria

*From the TR-IDs / ADR guidelines above, scoped to this story:*

- [ ] `PerfProbe` создаётся и вызывается только из `MatchDirector` и только при feature-теге `perf_probe`; в релизе без тега он `null`, единственный оверхед — проверка на null (тест на обоих конфигурациях)
- [ ] Собирает окна ≥ 600 кадров: среднее и p99 frame time, per-system мс (по `step()`), draw calls (`RENDER_TOTAL_DRAW_CALLS_IN_FRAME`), и выводит отчёт в лог/консоль в формате, пригодном для вставки в evidence
- [ ] Пороги (75, 96 МБ, 21.5 МБ, draw calls 180) читаются из единого constants-файла, не литералы в тестах и зонде

---

## Implementation Notes

Новый модуль `src/foundation/perf_probe.gd` (в срезе нет — писать по ADR-0007 §8). Только он и инжектируемые clock-адаптеры читают `Time.get_ticks_usec()`; учесть огрубление таймера в браузерах (≈0.1–1 мс) — потому окна ≥ 600 кадров. Подтвердить, что тег `perf_probe` в perf-пресете экспорта работает на web (`OS.has_feature`). Подключение из `_compose()` — в рамках foundation-runtime 008 (здесь API и хук `begin_frame/end_frame/mark(system)`).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: прогон на устройстве и занесение чисел в ADR-0007
- Census-тест worst-case сцены — перф-эпик рендера

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/perf_probe/perf_probe_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 008
