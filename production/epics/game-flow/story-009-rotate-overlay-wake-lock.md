# Story 009: Rotate-your-phone overlay and wake lock during a match

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: S (≤ 2h)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-014`, `TR-flow-020`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Оверлей «Rotate your phone» (M3) на touch-устройствах в ландшафте с пользовательской паузой партии и wake lock только во время идущей партии (M9). Вся JS-часть — Story 008.

**ADR Governing Implementation**: ADR-0001: Web build & platform shell (primary); also ADR-0003, ADR-0006
**ADR Decision Summary**:
- **ADR-0001** (Web build & platform shell): Все обращения к браузеру идут через PlatformBridge и JS-хелпер оболочки `window.teaRushPlatform` (try/catch, безопасные значения по умолчанию, вне web — no-op); `ready_reached` передаёт управление GameFlow, а не запускает партию. Поправка 2026-10-01 добавляет PWA, share, wake lock, orientation, launch param, open_external, vibrate.
- **ADR-0003** (Match simulation — clock, tick order, pause): GameClock + MatchDirector с фиксированным порядком тика, без `SceneTree.paused`, типизированные сигналы, DI через `_compose()`. Поправка 2026-10-01: состояние `IDLE`, `request_new_match/quit/resume`, `match_ended(reason)`, `ui_dt` для UI над паузой, wake lock из `_compose()`.
- **ADR-0006** (Navigation & tap picking): Тап по кухне — математика без физики; блокирующие экраны — `MOUSE_FILTER_STOP`, неблокирующие оверлеи — `MOUSE_FILTER_IGNORE` (поправка 2026-10-01).
**ADR Version**: ADR-0001: 2026-10-01, ADR-0003: 2026-09-30, ADR-0006: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0001] Web-экспорт single-thread; `JavaScriptBridge.create_callback` (объект держать в member), PWA-опции экспорта и `pwa_needs_update/pwa_update` — имена из знаний до 4.7, сверить с 4.7.2 (W2); user activation для share/open/install — проверка на устройстве (W1). [ADR-0003] Стандартный `Node`/`Tween`; `Tween` допустим только вне партии (IDLE/меню); над паузой — статично (`ui_dt = 0`). [ADR-0006] `Control.mouse_filter`; ничего post-cutoff для этого потока.

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: всё браузерное — через PlatformBridge → `window.teaRushPlatform` (try/catch, safe default, вне web no-op); callback-объекты хранятся в member *(from ADR-0001)*
- Forbidden: `JavaScriptBridge` вне PlatformBridge; `NOTIFICATION_APPLICATION_*` на web; эмит сигналов из сырого JS-обработчика (только dirty-flag в `_process`) *(from ADR-0001)*
- Guardrail: Thread Support OFF; shell-хелпер определён до загрузчика движка *(from ADR-0001)*
- Required: GameFlow пишет в MatchLifecycle только `request_new_match()`, `request_quit_match()`, `request_resume()`; сигналы — типизированные, подключаются в `_compose()` (DI, без синглтон-поиска) *(from ADR-0003)*
- Forbidden: `SceneTree.paused`; анимация на raw `delta`/`Tween` поверх паузы (Settings из паузы и confirm — статичные); результаты — на `ui_dt` *(from ADR-0003)*
- Guardrail: presentation-узлы `process_priority` ≥ 0 *(from ADR-0003)*
- Required: блокирующие экраны — полноэкранный `Control` с `MOUSE_FILTER_STOP`; неблокирующие оверлеи — `MOUSE_FILTER_IGNORE` *(from ADR-0006)*
- Forbidden: пропуск нажатия в кухню через блокирующий экран *(from ADR-0006)*
- Guardrail: вне `RUNNING` `flush(false)` тоже отбрасывает нажатия (defence in depth) *(from ADR-0006)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] `orientation_blocked_changed(true)` → полноэкранный оверлей (иконка + `Rotate your phone`) поверх любого экрана, `MOUSE_FILTER_STOP`, мгновенно; в `RUNNING` подключено `lifecycle.request_pause()`; в меню/разделах/итогах побочных эффектов нет (TR-flow-014)
- [ ] Обратный поворот в портрет снимает оверлей, но **не** снимает паузу: виден оверлей паузы до Resume; на ПК (`pointer: fine`) оверлея нет даже при окне шире высоты (TR-flow-014)
- [ ] `set_wake_lock(true)` на `match_started` и `paused_changed(false)`, `set_wake_lock(false)` на `paused_changed(true)` и `match_ended(*)`; связка в `_compose()`; тест фиксирует последовательность вызовов (TR-flow-020)
- [ ] Слой и wake lock не падают при unsupported API (вне web) — no-op
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Связка выполняется в `_compose()` (ADR-0003 amendment): `PlatformBridge.orientation_blocked_changed(true)` → `request_pause()`; `false` ничего не делает.
- Слой рисует Godot (ему нужна пауза; оболочка о партии не знает).
- Re-acquire при возврате вкладки — на стороне shell (Story 008).
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 008: реализация wake lock/orientation в shell
- Story 013: проверка W4/W5 на устройстве

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/game_flow/rotate_overlay_wake_lock_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 008; внешние: `foundation-runtime` (MatchLifecycle)
- Unlocks: 013
