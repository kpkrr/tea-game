# Story 006: Records screen, About panel and Send feedback row

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M (≈ half day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-007`, `TR-flow-017`, `TR-flow-021`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Три небольших экрана-листа: Records (рекорд, ≤ 5 последних смен, счётчики, серия), About (версия, авторы, лицензии с Godot MIT) и строки Settings `Send feedback` (скрыта при пустом `feedback_url`) / `About`. Данные статистики — эпик `player-stats` (геттеры).

**ADR Governing Implementation**: ADR-0005: Local persistence (SaveStore) (primary); also ADR-0004, ADR-0001
**ADR Decision Summary**:
- **ADR-0005** (Local persistence (SaveStore)): JSON-блоб SaveStore с `schema_version`, scope(owner) на префикс, localStorage на web. Поправка 2026-10-01: аддитивные ключи `tutorial.seen`, `ui.install_hint_shown`, `challenge.target` (GameFlow), `haptics.vibration_on`, `stats.*`; `schema_version` остаётся 1.
- **ADR-0004** (Data config & load-time validation): Конфиг — типизированные `.tres`-ресурсы под корнем `GameConfig`, валидация `ConfigValidator` собирает все ошибки. Поправка 2026-10-01: новый `FlowConfig` (feedback_url, game_url, challenge_max, recent_shifts_max, install_hint_after_shifts, results_count_up_s, share_card_size, fade-времена, how_to_play_cards).
- **ADR-0001** (Web build & platform shell): Все обращения к браузеру идут через PlatformBridge и JS-хелпер оболочки `window.teaRushPlatform` (try/catch, безопасные значения по умолчанию, вне web — no-op); `ready_reached` передаёт управление GameFlow, а не запускает партию. Поправка 2026-10-01 добавляет PWA, share, wake lock, orientation, launch param, open_external, vibrate.
**ADR Version**: ADR-0005: 2026-09-30, ADR-0004: 2026-09-30, ADR-0001: 2026-10-01

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0005] Web-путь: localStorage через хелпер оболочки `teaRushSave`; `SaveScope.declare_text` для строк. [ADR-0004] Custom `Resource` + `@export`, `ResourceLoader.load`; ничего post-cutoff. [ADR-0001] Web-экспорт single-thread; `JavaScriptBridge.create_callback` (объект держать в member), PWA-опции экспорта и `pwa_needs_update/pwa_update` — имена из знаний до 4.7, сверить с 4.7.2 (W2); user activation для share/open/install — проверка на устройстве (W1).

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: GameFlow владеет scope `tutorial`, `ui`, `challenge`; игровые данные читает только геттерами владельцев (Currency/Till/PlayerStats) *(from ADR-0005)*
- Forbidden: прямой доступ к чужим ключам SaveStore; `settings`/`haptics` scope у GameFlow (пишут AudioDirector/Haptics); повышение `schema_version` *(from ADR-0005)*
- Guardrail: запись — через общий flush шага 6 / page hide, отдельных flush-путей нет *(from ADR-0005)*
- Required: настраиваемые значения — в `FlowConfig` (`assets/data/config/flow.tres`) с валидатором; невалидное поле = `fail_boot` *(from ADR-0004)*
- Forbidden: хардкод флоу-значений (времена, лимиты, URL); подсказки загрузки и UI-строки — не в конфиге (shell / `tr()`) *(from ADR-0004)*
- Guardrail: валидатор собирает все ошибки за один проход *(from ADR-0004)*
- Required: всё браузерное — через PlatformBridge → `window.teaRushPlatform` (try/catch, safe default, вне web no-op); callback-объекты хранятся в member *(from ADR-0001)*
- Forbidden: `JavaScriptBridge` вне PlatformBridge; `NOTIFICATION_APPLICATION_*` на web; эмит сигналов из сырого JS-обработчика (только dirty-flag в `_process`) *(from ADR-0001)*
- Guardrail: Thread Support OFF; shell-хелпер определён до загрузчика движка *(from ADR-0001)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] Records: `★ BEST SCORE` крупно, до `recent_shifts_max` последних смен (новые сверху, `NEW!` у рекордных), Shifts played, Cups served, Days till filled, Current streak, Best streak; ноль смен — рекорд 0, «Play a shift to see it here», счётчики 0; повреждённый `stats.recent` — как ноль смен, без ошибок (TR-flow-007)
- [ ] About (из Settings): название, версия из `ProjectSettings` `application/config/version` (пусто → строка версии скрыта), авторы, список ассетов с лицензиями, упоминание Godot (MIT); прокрутка ↑↓/колесо/свайп; Back → Settings (TR-flow-017)
- [ ] Строка `Send feedback` в Settings над About открывает `FlowConfig.feedback_url` через `PlatformBridge.open_external()`; при пустом URL строки нет (дефолт до решения владельца — скрыта); блокировка вкладки браузером — без сообщений, остаёмся в игре, строка остаётся (TR-flow-021)
- [ ] Порядок фокуса Records/About — Back; все строки `tr()`; ≥ 14 dp на 360 dp ширины
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Поток данных: Records читает Currency `best_score` и PlayerStats геттеры (`recent`, счётчики, `streak`, `best_streak`); не читает ключи напрямую.
- **Владелец: AQ-09** (`feedback_url` не выбран) — история реализуема с пустым конфигом (строка скрыта), не Blocked; после решения владельца достаточно заполнить `flow.tres`.
- `open_external` вызывается в обработчике нажатия (user activation, W1) — проверка на устройстве в Story 013; вне web — `OS.shell_open`.
- Список лицензий — данные сцены/`tr()`-ключи; состав ассетов финализирует `art-assets`/`audio-juice`.
- Story 008 даёт реальный `open_external`; до неё — заглушка интерфейса.
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- `player-stats`: расчёт и хранение `stats.*`
- Story 013: проверка открытия вкладки на iOS/Android
- Story 004: сама панель Settings

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/records-about-feedback-evidence.md` + retained screenshot of each screen touched (9:20, 9:16, 1:1)
- Logic support: `tests/unit/game_flow/records_view_model_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001, 004; Story 008 для реального `open_external`; внешний: `player-stats`; owner: AQ-09 `feedback_url`
- Unlocks: 013
