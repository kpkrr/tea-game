# Story 003: Safe area = видимый вьюпорт: coalesce resize, aspect из конфига, resize без сброса матча

> **Epic**: Platform Shell (Web)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/platform-integration-telegram-mini-app.md`
**Requirement**: `TR-platform-005`, `TR-platform-016`, `TR-platform-017`, `TR-flow-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
- Secondary: ADR-0002: Viewport, camera fit & 2.5D presentation (Last Verified 2026-09-30)
- Secondary: ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)
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

- [ ] `safe_area_changed(rect)` эмитится не чаще одного раза за `_process` (dirty-флаг на `size_changed`/resize/orientationchange); значение берётся из `DisplayServer.window_get_size()` (пиксели окна с DPR), `innerWidth/innerHeight` — только триггер; адресная строка не обрабатывается отдельно — «кухня ≥ 95 %» считается от видимого вьюпорта (TR-flow-015, TR-platform-005)
- [ ] `viewport_aspect_min`/`viewport_aspect_max` читаются из `ViewConfig` (`GameConfig.view`), литералов в коде нет; аспект вне диапазона обрабатывается letterbox-правилами ViewFit, а не отказом (TR-platform-016)
- [ ] Интеграционный тест: серия resize/ориентационных сигналов посреди RUNNING-матча не сбрасывает состояние матча (`t`, guests, счёт сохранены), `match_started` не повторяется (TR-platform-017)

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/platform_bridge.gd` (`_process` dirty-флаг, `get_safe_area`) — в срезе берётся `get_visible_rect()`; по ADR-0001 источник — `DisplayServer.window_get_size()`, привести и оставить `allow_hidpi` включённым. Конвертация в stretch-координаты — ViewFit (ADR-0002, другой эпик), потребитель не гадает. `ViewConfig` — из foundation-runtime 002. Статическая типизация, doc-комментарии (`##`) на публичном API. Telegram не трогаем (deferred).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- ViewFit и letterbox-математика — эпик viewport-camera
- Проверка поворота на реальном устройстве — story 008
- Orientation-block overlay — game-flow эпик

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/platform_bridge/platform_bridge_safe_area_test.gd` — must exist and pass (или документированный playtest)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001; foundation-runtime 002, 008
- Unlocks: Story 008
