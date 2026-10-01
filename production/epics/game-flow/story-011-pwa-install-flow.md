# Story 011: PWA install: export preset, Install app row and one-time hint

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L (≈ 1 day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

PWA-установка (M7): настройка PWA в web-экспорте (manifest, иконки, `standalone`, `portrait`, правило обновления «при следующем запуске»), строка `⊕ Install app` в меню, одноразовая плашка после N-й смены на итогах (Android — Install/Not now; iOS — инструкция). Скрыто в standalone.

**ADR Governing Implementation**: ADR-0001: Web build & platform shell (primary); also ADR-0005, ADR-0004
**ADR Decision Summary**:
- **ADR-0001** (Web build & platform shell): Все обращения к браузеру идут через PlatformBridge и JS-хелпер оболочки `window.teaRushPlatform` (try/catch, безопасные значения по умолчанию, вне web — no-op); `ready_reached` передаёт управление GameFlow, а не запускает партию. Поправка 2026-10-01 добавляет PWA, share, wake lock, orientation, launch param, open_external, vibrate.
- **ADR-0005** (Local persistence (SaveStore)): JSON-блоб SaveStore с `schema_version`, scope(owner) на префикс, localStorage на web. Поправка 2026-10-01: аддитивные ключи `tutorial.seen`, `ui.install_hint_shown`, `challenge.target` (GameFlow), `haptics.vibration_on`, `stats.*`; `schema_version` остаётся 1.
- **ADR-0004** (Data config & load-time validation): Конфиг — типизированные `.tres`-ресурсы под корнем `GameConfig`, валидация `ConfigValidator` собирает все ошибки. Поправка 2026-10-01: новый `FlowConfig` (feedback_url, game_url, challenge_max, recent_shifts_max, install_hint_after_shifts, results_count_up_s, share_card_size, fade-времена, how_to_play_cards).
**ADR Version**: ADR-0001: 2026-10-01, ADR-0005: 2026-09-30, ADR-0004: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0001] Web-экспорт single-thread; `JavaScriptBridge.create_callback` (объект держать в member), PWA-опции экспорта и `pwa_needs_update/pwa_update` — имена из знаний до 4.7, сверить с 4.7.2 (W2); user activation для share/open/install — проверка на устройстве (W1). [ADR-0005] Web-путь: localStorage через хелпер оболочки `teaRushSave`; `SaveScope.declare_text` для строк. [ADR-0004] Custom `Resource` + `@export`, `ResourceLoader.load`; ничего post-cutoff.

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: всё браузерное — через PlatformBridge → `window.teaRushPlatform` (try/catch, safe default, вне web no-op); callback-объекты хранятся в member *(from ADR-0001)*
- Forbidden: `JavaScriptBridge` вне PlatformBridge; `NOTIFICATION_APPLICATION_*` на web; эмит сигналов из сырого JS-обработчика (только dirty-flag в `_process`) *(from ADR-0001)*
- Guardrail: Thread Support OFF; shell-хелпер определён до загрузчика движка *(from ADR-0001)*
- Required: GameFlow владеет scope `tutorial`, `ui`, `challenge`; игровые данные читает только геттерами владельцев (Currency/Till/PlayerStats) *(from ADR-0005)*
- Forbidden: прямой доступ к чужим ключам SaveStore; `settings`/`haptics` scope у GameFlow (пишут AudioDirector/Haptics); повышение `schema_version` *(from ADR-0005)*
- Guardrail: запись — через общий flush шага 6 / page hide, отдельных flush-путей нет *(from ADR-0005)*
- Required: настраиваемые значения — в `FlowConfig` (`assets/data/config/flow.tres`) с валидатором; невалидное поле = `fail_boot` *(from ADR-0004)*
- Forbidden: хардкод флоу-значений (времена, лимиты, URL); подсказки загрузки и UI-строки — не в конфиге (shell / `tr()`) *(from ADR-0004)*
- Guardrail: валидатор собирает все ошибки за один проход *(from ADR-0004)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] Export preset: `progressive_web_app/enabled`, display `standalone`, orientation `portrait`, иконки 144/180/512, цвет темы Ember Dusk; `ensure_cross_origin_isolation_headers` off; ключи сверены с 4.7.2 class reference (W2); generated service worker кэширует и файл музыки рядом с `index.html` (W3) (TR-flow-018)
- [ ] Меню: строка `⊕ Install app` только пока `can_prompt_install()` (обновляется по `install_availability_changed`); нажатие → `prompt_install()`; в standalone строки нет (TR-flow-018)
- [ ] На итогах после `FlowConfig.install_hint_after_shifts` (3)-й смены один раз показывается плашка (`ui.install_hint_shown` пишется при показе): Android — `Install` / `Not now`; iOS (`is_ios()`) — «Tap Share ⤴ then Add to Home Screen»; в standalone и при повторе — нет; порядок фокуса Menu → Install → Not now (TR-flow-018)
- [ ] Обновление: при boot, если `pwa_needs_update()`, `pwa_update()` вызывается только пока GameFlow в меню до первой партии; `pwa_update_available` в сессии лишь логируется; сохранения не затрагиваются (TR-flow-018)
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Имена `pwa_needs_update/pwa_update/pwa_update_available` и ключи preset — из знаний до 4.7 — **сверить** с 4.7.2 (W2) до реализации; если API нет — задокументировать отклонение и идти фолбэком «обновление при следующей загрузке страницы».
- `beforeinstallprompt` перехватывается shell-ом при загрузке (Story 008).
- Вызов `prompt_install()` — из обработчика нажатия (user activation; W1 на устройстве, Story 013).
- Адрес игры в manifest `start_url` — относительный; **owner: game URL** для прод-деплоя, не блокирует.
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 008: `beforeinstallprompt` и `is_standalone` в shell
- Story 013: проверка W1–W3 на устройстве
- `art-assets`: сами иконки PWA (здесь плейсхолдеры)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/game_flow/pwa_install_flow_test.gd` OR playtest doc
- Evidence doc: `production/qa/evidence/pwa-install-flow-evidence.md` (retained screenshot of each screen touched, 9:20 / 9:16 / 1:1)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002, 007, 008
- Unlocks: 013
