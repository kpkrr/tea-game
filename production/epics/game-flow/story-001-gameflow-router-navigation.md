# Story 001: GameFlow router, navigation rules and `tr()` catalog

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M (≈ half day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-001`, `TR-flow-006`, `TR-flow-010`, `TR-flow-026`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Фундамент модуля GameFlow: корневой узел-роутер экранов, правила назад/Escape/release, единый каталог `tr()`-ключей и `reduced_motion`-переходы. Все остальные истории ставят экраны на этот каркас. Кода среза нет — пишется с нуля в `src/`.

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause (primary); also ADR-0006, ADR-0001, ADR-0004
**ADR Decision Summary**:
- **ADR-0003** (Match simulation — clock, tick order, pause): GameClock + MatchDirector с фиксированным порядком тика, без `SceneTree.paused`, типизированные сигналы, DI через `_compose()`. Поправка 2026-10-01: состояние `IDLE`, `request_new_match/quit/resume`, `match_ended(reason)`, `ui_dt` для UI над паузой, wake lock из `_compose()`.
- **ADR-0006** (Navigation & tap picking): Тап по кухне — математика без физики; блокирующие экраны — `MOUSE_FILTER_STOP`, неблокирующие оверлеи — `MOUSE_FILTER_IGNORE` (поправка 2026-10-01).
- **ADR-0001** (Web build & platform shell): Все обращения к браузеру идут через PlatformBridge и JS-хелпер оболочки `window.teaRushPlatform` (try/catch, безопасные значения по умолчанию, вне web — no-op); `ready_reached` передаёт управление GameFlow, а не запускает партию. Поправка 2026-10-01 добавляет PWA, share, wake lock, orientation, launch param, open_external, vibrate.
- **ADR-0004** (Data config & load-time validation): Конфиг — типизированные `.tres`-ресурсы под корнем `GameConfig`, валидация `ConfigValidator` собирает все ошибки. Поправка 2026-10-01: новый `FlowConfig` (feedback_url, game_url, challenge_max, recent_shifts_max, install_hint_after_shifts, results_count_up_s, share_card_size, fade-времена, how_to_play_cards).
**ADR Version**: ADR-0003: 2026-09-30, ADR-0006: 2026-09-30, ADR-0001: 2026-10-01, ADR-0004: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0003] Стандартный `Node`/`Tween`; `Tween` допустим только вне партии (IDLE/меню); над паузой — статично (`ui_dt = 0`). [ADR-0006] `Control.mouse_filter`; ничего post-cutoff для этого потока. [ADR-0001] Web-экспорт single-thread; `JavaScriptBridge.create_callback` (объект держать в member), PWA-опции экспорта и `pwa_needs_update/pwa_update` — имена из знаний до 4.7, сверить с 4.7.2 (W2); user activation для share/open/install — проверка на устройстве (W1). [ADR-0004] Custom `Resource` + `@export`, `ResourceLoader.load`; ничего post-cutoff.

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: GameFlow пишет в MatchLifecycle только `request_new_match()`, `request_quit_match()`, `request_resume()`; сигналы — типизированные, подключаются в `_compose()` (DI, без синглтон-поиска) *(from ADR-0003)*
- Forbidden: `SceneTree.paused`; анимация на raw `delta`/`Tween` поверх паузы (Settings из паузы и confirm — статичные); результаты — на `ui_dt` *(from ADR-0003)*
- Guardrail: presentation-узлы `process_priority` ≥ 0 *(from ADR-0003)*
- Required: блокирующие экраны — полноэкранный `Control` с `MOUSE_FILTER_STOP`; неблокирующие оверлеи — `MOUSE_FILTER_IGNORE` *(from ADR-0006)*
- Forbidden: пропуск нажатия в кухню через блокирующий экран *(from ADR-0006)*
- Guardrail: вне `RUNNING` `flush(false)` тоже отбрасывает нажатия (defence in depth) *(from ADR-0006)*
- Required: всё браузерное — через PlatformBridge → `window.teaRushPlatform` (try/catch, safe default, вне web no-op); callback-объекты хранятся в member *(from ADR-0001)*
- Forbidden: `JavaScriptBridge` вне PlatformBridge; `NOTIFICATION_APPLICATION_*` на web; эмит сигналов из сырого JS-обработчика (только dirty-flag в `_process`) *(from ADR-0001)*
- Guardrail: Thread Support OFF; shell-хелпер определён до загрузчика движка *(from ADR-0001)*
- Required: настраиваемые значения — в `FlowConfig` (`assets/data/config/flow.tres`) с валидатором; невалидное поле = `fail_boot` *(from ADR-0004)*
- Forbidden: хардкод флоу-значений (времена, лимиты, URL); подсказки загрузки и UI-строки — не в конфиге (shell / `tr()`) *(from ADR-0004)*
- Guardrail: валидатор собирает все ошибки за один проход *(from ADR-0004)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] `ready_reached` → GameFlow показывает Main Menu (заглушка экрана допустима), партия не стартует (MatchLifecycle остаётся `IDLE`); HUD-экран E18 не создаётся (TR-flow-001)
- [ ] Стек экранов глубиной ≤ 2; Escape/Back ведёт назад по таблице Interaction Map (раздел → меню; About → Settings; Settings из паузы → пауза; confirm → пауза), в меню и на итогах — ничего; кнопка «назад» браузера не перехватывается — `popstate` не слушаем (TR-flow-010)
- [ ] Базовая кнопка P17 срабатывает по release внутри кнопки (срыв пальцем отменяет), Enter/Space на фокусе; порядок фокуса и стартовый фокус задаются на экран (TR-flow-010)
- [ ] Весь текст — ключи `tr()`, единый каталог (`assets/i18n/en.csv` или эквивалент), языка нет; тест-линтер находит `Label.text`/`Button.text` с литеральной строкой в `src/game_flow/` (TR-flow-006)
- [ ] Переходы меню↔раздел 200 мс и Results→Menu 300 мс берутся из `FlowConfig.menu_fade_s/match_fade_s`; при `PlatformBridge.prefers_reduced_motion()` — мгновенно; подписка на `reduced_motion_changed` (TR-flow-026)
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Корень `GameFlow` создаётся в `_compose()`; зависимости (MatchLifecycle, PlatformBridge, SaveScope×3, FlowConfig, геттеры Currency/Till/PlayerStats) инжектируются, синглтон-поиска нет.
- Строки только через `tr()`-ключи; переводов нет, но ключи с первого дня (F3).
- Переход меню↔раздел и fade допустимы на raw `delta`/`Tween` только пока `state == IDLE`/до `ready_reached`; над паузой — без анимации (ADR-0003 amendment).
- Блокирующие экраны — `MOUSE_FILTER_STOP` (ADR-0006 amendment).
- Зависит от эпика `foundation-runtime` (MatchLifecycle c `IDLE`/`on_ready_reached`, PlatformBridge `ready_reached`, `prefers_reduced_motion`, ConfigLoader с `FlowConfig`).
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 002: содержимое Main Menu
- Story 003–007: содержимое остальных экранов
- `art-assets`: скин кнопок/панелей (здесь — серый плейсхолдер-скин)
- `hud`: кнопка паузы и оверлей паузы внутри партии (Story 005 добавляет пункты меню паузы)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/game_flow/gameflow_router_navigation_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Эпик `foundation-runtime` (MatchLifecycle/PlatformBridge/ConfigLoader) — внешняя зависимость
- Unlocks: 002, 003, 004, 005, 006, 007
