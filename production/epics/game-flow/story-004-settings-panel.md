# Story 004: Settings panel: Music / Sound effects / Vibration (menu and pause)

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M (≈ half day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-004`, `TR-flow-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Одна панель Settings с двух входов (меню, пауза): три строки P18 Toggle Row, применяются сразу, сохраняются через владельцев ключей. Строка Vibration скрыта без `navigator.vibrate`. Строки Send feedback и About добавляет Story 006.

**ADR Governing Implementation**: ADR-0005: Local persistence (SaveStore) (primary); also ADR-0001, ADR-0003
**ADR Decision Summary**:
- **ADR-0005** (Local persistence (SaveStore)): JSON-блоб SaveStore с `schema_version`, scope(owner) на префикс, localStorage на web. Поправка 2026-10-01: аддитивные ключи `tutorial.seen`, `ui.install_hint_shown`, `challenge.target` (GameFlow), `haptics.vibration_on`, `stats.*`; `schema_version` остаётся 1.
- **ADR-0001** (Web build & platform shell): Все обращения к браузеру идут через PlatformBridge и JS-хелпер оболочки `window.teaRushPlatform` (try/catch, безопасные значения по умолчанию, вне web — no-op); `ready_reached` передаёт управление GameFlow, а не запускает партию. Поправка 2026-10-01 добавляет PWA, share, wake lock, orientation, launch param, open_external, vibrate.
- **ADR-0003** (Match simulation — clock, tick order, pause): GameClock + MatchDirector с фиксированным порядком тика, без `SceneTree.paused`, типизированные сигналы, DI через `_compose()`. Поправка 2026-10-01: состояние `IDLE`, `request_new_match/quit/resume`, `match_ended(reason)`, `ui_dt` для UI над паузой, wake lock из `_compose()`.
**ADR Version**: ADR-0005: 2026-09-30, ADR-0001: 2026-10-01, ADR-0003: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0005] Web-путь: localStorage через хелпер оболочки `teaRushSave`; `SaveScope.declare_text` для строк. [ADR-0001] Web-экспорт single-thread; `JavaScriptBridge.create_callback` (объект держать в member), PWA-опции экспорта и `pwa_needs_update/pwa_update` — имена из знаний до 4.7, сверить с 4.7.2 (W2); user activation для share/open/install — проверка на устройстве (W1). [ADR-0003] Стандартный `Node`/`Tween`; `Tween` допустим только вне партии (IDLE/меню); над паузой — статично (`ui_dt = 0`).

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: GameFlow владеет scope `tutorial`, `ui`, `challenge`; игровые данные читает только геттерами владельцев (Currency/Till/PlayerStats) *(from ADR-0005)*
- Forbidden: прямой доступ к чужим ключам SaveStore; `settings`/`haptics` scope у GameFlow (пишут AudioDirector/Haptics); повышение `schema_version` *(from ADR-0005)*
- Guardrail: запись — через общий flush шага 6 / page hide, отдельных flush-путей нет *(from ADR-0005)*
- Required: всё браузерное — через PlatformBridge → `window.teaRushPlatform` (try/catch, safe default, вне web no-op); callback-объекты хранятся в member *(from ADR-0001)*
- Forbidden: `JavaScriptBridge` вне PlatformBridge; `NOTIFICATION_APPLICATION_*` на web; эмит сигналов из сырого JS-обработчика (только dirty-flag в `_process`) *(from ADR-0001)*
- Guardrail: Thread Support OFF; shell-хелпер определён до загрузчика движка *(from ADR-0001)*
- Required: GameFlow пишет в MatchLifecycle только `request_new_match()`, `request_quit_match()`, `request_resume()`; сигналы — типизированные, подключаются в `_compose()` (DI, без синглтон-поиска) *(from ADR-0003)*
- Forbidden: `SceneTree.paused`; анимация на raw `delta`/`Tween` поверх паузы (Settings из паузы и confirm — статичные); результаты — на `ui_dt` *(from ADR-0003)*
- Guardrail: presentation-узлы `process_priority` ≥ 0 *(from ADR-0003)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] Переключатели Music / Sound effects / Vibration вызывают `AudioDirector.set_music_on/set_sfx_on` и `Haptics.set_enabled` сразу, показывают текст ON/OFF, вся строка ≥ 56 dp кликабельна, значения переживают перезагрузку страницы (TR-flow-004)
- [ ] Settings из паузы открывается панелью над замороженной кухней, не снимает паузу; Back возвращает на паузу; `clock.sim_dt` за это время = 0 и панель статична (без Tween) (TR-flow-004)
- [ ] При `PlatformBridge.can_vibrate() == false` строки Vibration нет вовсе (не серая); порядок фокуса Back → Music → SFX → Vibration → … (TR-flow-005)
- [ ] GameFlow не держит scope `settings`/`haptics`; слышимость = `!muted && channel_on` проверяется интеграционным тестом с AudioDirector-заглушкой (TR-flow-004)
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Settings пишет только через сеттеры AudioDirector/Haptics (ADR-0005 amendment, «One writer per prefix»); ключи `settings.music_on`, `settings.sfx_on`, `haptics.vibration_on`.
- Над паузой `ui_dt = 0`: никаких raw-delta анимаций (ADR-0003 amendment); из меню допустим cross-fade.
- `can_vibrate()` предоставляет PlatformBridge (Story 008); до неё — заглушка `false`/`true` через интерфейс.
- Зависит от эпика `audio-juice` (AudioDirector сеттеры) и Haptics (в эпике `hud`/`audio-juice`).
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 006: Send feedback, About, строка версии
- Story 005: пауза и confirm
- `audio-juice`/`hud`: реализация AudioDirector/Haptics

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/settings-panel-evidence.md` + retained screenshot of each screen touched (9:20, 9:16, 1:1)
- Logic support: `tests/integration/game_flow/settings_panel_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001; Story 008 для реального `can_vibrate()`; внешние: `audio-juice`
- Unlocks: 005, 006
