# Story 002: Visibility-сигнал через JavaScriptBridge (visibilitychange + pagehide) и reduced motion

> **Epic**: Platform Shell (Web)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/platform-integration-telegram-mini-app.md`
**Requirement**: `TR-platform-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
- Secondary: ADR-0003: Match simulation — clock, tick order, pause (Last Verified 2026-09-30)
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

- [ ] `visibility_changed(bool)` эмитится синхронно из JS-callback (`create_callback`, handler `func(args: Array)`), только при реальной смене состояния; `visibilitychange` и `pagehide` (как `visible=false`) сходятся в один сигнал, дубликаты не эмитятся
- [ ] Начальное состояние берётся из `document.visibilityState` при старте (страница, открытая в фоновой вкладке, стартует скрытой)
- [ ] `JavaScriptObject`-callback'и (visibility, pagehide, reduced-motion) лежат в member-переменных весь срок жизни страницы; юнит-тест подменяемого адаптера проверяет dedupe; `NOTIFICATION_APPLICATION_*` нигде не используются (CI-grep)
- [ ] `prefers_reduced_motion()` инициализируется из `matchMedia('(prefers-reduced-motion: reduce)')`, `reduced_motion_changed(bool)` эмитится только при реальной смене (второй `create_callback`)

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/platform_bridge.gd` (`_ready` регистрация слушателей, `_on_js_visibility`, `_on_js_pagehide`, `_on_js_reduced_motion`, `_set_visible`). Для unit-теста выделить тонкий JS-адаптер (DI), чтобы dedupe тестировался без браузера; реальный путь — в web smoke и spike (story 008). Hidden-время не должно попадать в симуляцию: `MatchLifecycle` обрабатывает сигнал синхронно (ADR-0003), это проверяет foundation-runtime 008. Статическая типизация, doc-комментарии (`##`) на публичном API. Telegram не трогаем (deferred).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: реальная проверка на устройстве (backgrounding/foregrounding)
- Реакция MatchLifecycle на сигнал — Guest AI/Lifecycle эпик

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/platform_bridge/platform_bridge_visibility_test.gd` — must exist and pass (или документированный playtest)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 008; foundation-runtime 009
