# Story 001: PlatformBridge: автозагрузка, BootState Loading/Ready/Failed, off-web заглушки

> **Epic**: Platform Shell (Web)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/platform-integration-telegram-mini-app.md`
**Requirement**: `TR-platform-013`, `TR-platform-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
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

- [ ] `PlatformBridge` — единственный автозагружаемый узел (`process_priority = -200`); контракт: `is_visible()`, `get_safe_area()`, `is_booted()`, `prefers_reduced_motion()`, `asset_url()`, `mark_boot_complete()`, `fail_boot(msg)`
- [ ] `mark_boot_complete()` выполняется один раз: `Loading -> Ready`, эмитит `ready_reached` ровно один раз; повторный вызов и вызов из `Failed` игнорируются; `Ready` — это сигнал MatchLifecycle перейти в `IDLE` и далее принять `request_new_match()` (TR-platform-013, с учётом амендмента 2026-10-01: без автостарта)
- [ ] `fail_boot(msg)` -> `Failed`, `ready_reached` не эмитится, показывается нативный статичный экран «Could not load the game — please reload the page» (English), в debug добавляется `msg`
- [ ] Вне web (`OS.has_feature("web")` = false: редактор, тесты) все JS-пути пропускаются, `is_visible()` = true, `prefers_reduced_motion()` = false; один и тот же билд работает в браузере ПК и телефона (TR-platform-001: нет ветвления по устройству)

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/platform_bridge.gd` (140 строк): скелет, BootState, `mark_boot_complete`, `fail_boot`, `asset_url`. Заменить RU-строку в `fail_boot` на английскую. Инлайн `SAVE_JS` из среза убрать — хелпер переезжает в HTML-оболочку (story 004). Без Telegram-детекта (deferred). Модули не ссылаются на автозагрузку по имени — её использует только `MatchDirector._compose()` (ADR-0003). Статическая типизация, doc-комментарии (`##`) на публичном API. Telegram не трогаем (deferred).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: visibility/reduced motion
- Story 003: safe area
- Story 005: HTML-часть экрана ошибки и fade
- Telegram TR-platform-002/003/004/014/015 (deferred)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/platform_bridge/platform_bridge_boot_state_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002, 003, 005
