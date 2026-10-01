# Story 008: Spike на слабом Android: visibility, resize, localStorage, WebGL2-fallback, бюджеты

> **Epic**: Platform Shell (Web)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/platform-integration-telegram-mini-app.md`
**Requirement**: `TR-platform-001`, `TR-platform-011`, `TR-platform-012`, `TR-platform-017`, `TR-platform-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
- Secondary: ADR-0007: Performance & load budgets (Last Verified 2026-09-30)
- Secondary: ADR-0005: Local persistence (SaveStore) (Last Verified 2026-09-30)
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

- [ ] На представительном слабом Android (ref. device ADR-0007, штатный мобильный браузер) записаны: cold/warm time-to-interactive, размер загрузки, touch-to-engine latency; результаты добавлены в `## Spike Results` ADR-0001 и в ADR-0007 (frame-time, per-system мс, draw calls, RD boot sub-budget перестают быть provisional или пересматриваются — не превышаются молча)
- [ ] Подтверждено на устройстве: `visibilitychange` через `create_callback` срабатывает между кадрами на Android Chrome; скрытие вкладки ≥ 10 с и возврат -> sim advances by 0; `localStorage`-запись в hide-callback переживает закрытие вкладки; приватный режим не ломает загрузку
- [ ] Подтверждено на устройстве: WebGL2-fallback показан без запроса движка (TR-platform-011); поворот/resize посреди матча не сбрасывает матч (TR-platform-017); Loading->Ready без белой вспышки (TR-platform-018) — retained screenshots/видео
- [ ] Расхождения с допущениями «Android = iPhone» оформлены как баги/амендменты ADR; если числа нарушают бюджеты — решение по contingency order ADR-0007 записано

---

## Implementation Notes

Предусловие: боевая сборка со stories 001–006 и `perf_probe`-пресет (story 007), MatchDirector из foundation-runtime 008. Закрывает открытые пункты ADR-0001 (fallback, mid-match rotation, create_callback на Android Chrome) и ADR-0007 (провизорные числа, `Engine.max_fps` на web, реальная метрика памяти, Brotli/gzip у хоста). Протокол — по ADR-0001 Validation Criteria и ADR-0005 Verification (2)–(4). Evidence-файл ведётся вручную владельцем/QA; агент без физического устройства эту историю закрыть не может. Если слабый Android недоступен — решение владельца об явном принятии риска фиксируется в evidence (на iPhone функциональная часть уже проверена 2026-09-30).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Оптимизация по итогам замеров — отдельные задачи по contingency order ADR-0007
- Desktop-браузеры кроме smoke

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `` — must exist and pass (или документированный playtest)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 002, 003, 004, 005, 006, 007; foundation-runtime 007, 008, 009
- Unlocks: Epic DoD; ADR-0007 переход из provisional
