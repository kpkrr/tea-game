# Story 004: HTML-оболочка: WebGL2-гейт, статичный fallback, JS-хелпер teaRushSave

> **Epic**: Platform Shell (Web)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/platform-integration-telegram-mini-app.md`
**Requirement**: `TR-platform-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
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

- [ ] В plain JS, строго ДО запроса loader-скрипта движка, на одноразовом canvas проверяется `getContext('webgl2')`; при неудаче рендерится статичная страница «Please update your browser» (English), ни `.wasm`, ни `.js` движка не запрашиваются (проверка по Network)
- [ ] Проба не ломает контекст движка (throwaway canvas или `WEBGL_lose_context`) и не мягче проверок сгенерированного 4.7.2 loader (`Engine`): сравнение зафиксировано в evidence
- [ ] Оболочка определяет `window.teaRushSave` (`available/read/write/backup`, все обращения к `localStorage` в try/catch) по контракту ADR-0005

---

## Implementation Notes

Новый шаблон оболочки `assets/web/shell.html` (custom HTML shell для export preset). Хелпер — перенести из `SAVE_JS` в `prototypes/tea-rush-vertical-slice/src/foundation/platform_bridge.gd` (ключи `tea_rush.save`, `tea_rush.save.corrupt`). Проверка: подменить браузерный флаг/запретить WebGL2 (Chrome `--disable-webgl2`/`--disable-gpu`) и убедиться, что fallback показан. Это закрывает открытый пункт ADR-0001 «WebGL2-unsupported fallback not yet verified».

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: экран загрузки и fade
- Story 006: export preset и публикация

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/shell-webgl2-gate-evidence.md` с retained screenshot + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 005, 008; foundation-runtime 007
