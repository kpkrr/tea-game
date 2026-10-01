# Story 008: PlatformBridge game-flow capabilities and `teaRushPlatform` shell helper

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L (≈ 1 day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-014`, `TR-flow-018`, `TR-flow-019`, `TR-flow-020`, `TR-flow-021`, `TR-flow-024`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Эта история **владеет добавлением JS-возможностей** в PlatformBridge и HTML-оболочку: хелпер `window.teaRushPlatform` (PWA install, share prepare/share, wake lock, pointer/orientation, launch param + `clearParams`, openUrl, vibrate) и GDScript-API из поправки ADR-0001 от 2026-10-01. Вне web — все no-op/«unsupported». Поведение экранов строят Stories 009–012.

**ADR Governing Implementation**: ADR-0001: Web build & platform shell (primary); also ADR-0003
**ADR Decision Summary**:
- **ADR-0001** (Web build & platform shell): Все обращения к браузеру идут через PlatformBridge и JS-хелпер оболочки `window.teaRushPlatform` (try/catch, безопасные значения по умолчанию, вне web — no-op); `ready_reached` передаёт управление GameFlow, а не запускает партию. Поправка 2026-10-01 добавляет PWA, share, wake lock, orientation, launch param, open_external, vibrate.
- **ADR-0003** (Match simulation — clock, tick order, pause): GameClock + MatchDirector с фиксированным порядком тика, без `SceneTree.paused`, типизированные сигналы, DI через `_compose()`. Поправка 2026-10-01: состояние `IDLE`, `request_new_match/quit/resume`, `match_ended(reason)`, `ui_dt` для UI над паузой, wake lock из `_compose()`.
**ADR Version**: ADR-0001: 2026-10-01, ADR-0003: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0001] Web-экспорт single-thread; `JavaScriptBridge.create_callback` (объект держать в member), PWA-опции экспорта и `pwa_needs_update/pwa_update` — имена из знаний до 4.7, сверить с 4.7.2 (W2); user activation для share/open/install — проверка на устройстве (W1). [ADR-0003] Стандартный `Node`/`Tween`; `Tween` допустим только вне партии (IDLE/меню); над паузой — статично (`ui_dt = 0`).

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: всё браузерное — через PlatformBridge → `window.teaRushPlatform` (try/catch, safe default, вне web no-op); callback-объекты хранятся в member *(from ADR-0001)*
- Forbidden: `JavaScriptBridge` вне PlatformBridge; `NOTIFICATION_APPLICATION_*` на web; эмит сигналов из сырого JS-обработчика (только dirty-flag в `_process`) *(from ADR-0001)*
- Guardrail: Thread Support OFF; shell-хелпер определён до загрузчика движка *(from ADR-0001)*
- Required: GameFlow пишет в MatchLifecycle только `request_new_match()`, `request_quit_match()`, `request_resume()`; сигналы — типизированные, подключаются в `_compose()` (DI, без синглтон-поиска) *(from ADR-0003)*
- Forbidden: `SceneTree.paused`; анимация на raw `delta`/`Tween` поверх паузы (Settings из паузы и confirm — статичные); результаты — на `ui_dt` *(from ADR-0003)*
- Guardrail: presentation-узлы `process_priority` ≥ 0 *(from ADR-0003)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] `teaRushPlatform` определён в `index.html` до загрузчика; каждый метод в try/catch, безопасный дефолт; `beforeinstallprompt` перехватывается при загрузке страницы (до движка) и сохраняется; вне web (editor/tests) весь API возвращает «unsupported»/no-op без ошибок
- [ ] GDScript API PlatformBridge: `can_prompt_install/prompt_install/is_standalone/is_ios`, `share_prepare/share_prepared/can_share_files` + `share_finished(result)`, `set_wake_lock`, `is_coarse_pointer/is_orientation_blocked` + `orientation_blocked_changed`, `get_launch_param/clear_launch_params`, `open_external`, `can_vibrate/vibrate`; все сигналы эмитятся только при смене значения
- [ ] `orientation_blocked_changed` = coarse pointer И ширина окна > высоты, считается из `DisplayServer.window_get_size()` в том же dirty-flag проходе, что и safe area, не из сырого JS-обработчика; эмит один раз за кадр на смену
- [ ] Wake lock в shell: флаг «wanted», `navigator.wakeLock.request('screen')` только при `visibilityState == 'visible'`, повторный запрос на `visibilitychange`; unsupported → тихий no-op; `JavaScriptObject` callbacks хранятся в member; юнит-тест на фейковом бэкенде проверяет контракт и no-op off-web
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Следовать таблице capabilities в ADR-0001 amendment 2026-10-01 дословно (имена методов, `share_finished` значения `&"shared"|&"cancelled"|&"downloaded"|&"copied"|&"failed"`).
- Доступ к `teaRushPlatform` один раз через `JavaScriptBridge.get_interface`; объект держать как untyped.
- Base64 PNG через `Marshalls.raw_to_base64`; `share()` синхронный в обработчике нажатия.
- PWA-опции экспорта (manifest, иконки 144/180/512, `standalone`, `portrait`) — в Story 011; `activation overlay` (`set_activation_overlay`) строится только если W1 провален (Story 013).
- Зависит от `foundation-runtime` (базовый PlatformBridge и shell `index.html`): история **расширяет** их.
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 009: использование `orientation_blocked_changed` и wake lock в GameFlow/MatchLifecycle
- Story 010–012: логика вызова/PWA/share
- Story 013: верификация на устройстве

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/unit/game_flow/platformbridge_flow_capabilities_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Эпик `foundation-runtime` (PlatformBridge + shell) — внешняя зависимость
- Unlocks: 004, 006, 009, 010, 011, 012, 013
