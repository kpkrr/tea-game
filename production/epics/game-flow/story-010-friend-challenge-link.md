# Story 010: Friend challenge link `?beat=N`

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M (≈ half day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-024`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Приём вызова по ссылке (M13): чтение `?beat=`, валидация, сохранение `challenge.target`, очистка адреса, строка в меню, итог на экране результатов, сброс при выполнении. Формирование самой ссылки для шаринга — Story 012.

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

- [ ] На старте GameFlow читает `get_launch_param("beat")`; целое 1…`FlowConfig.challenge_max` (1 000 000) → `challenge.target = N` (новая ссылка заменяет старый), иначе игнор (пусто, 0, отрицательное, нецелое, слишком большое, нечисло); после чтения всегда `clear_launch_params()` (TR-flow-024)
- [ ] Перезагрузка страницы не применяет вызов повторно (параметра в адресе нет); в установленной PWA параметра нет — вызов не меняется
- [ ] Меню при `challenge.target > 0` показывает `⚔ Beat your friend: N`; при 0 строки нет (TR-flow-024)
- [ ] На итогах: `match_score > target` → `You beat your friend's N!` + стингер рекорда и `challenge.target = 0` (строка в меню исчезает); иначе `Friend's score: N`; равенство — не выполнено (TR-flow-024)
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Валидация значения — задача GameFlow, не PlatformBridge (ADR-0001 amendment); чистая функция `parse_beat(raw, max) -> int` для юнит-теста.
- Scope `challenge` принадлежит GameFlow (ADR-0005); SaveStore клампит ключ 0…1 000 000.
- **Owner: game URL не выбран** (ссылку для друга формирует Story 012) — сам приём параметра не зависит от URL, реализуем полностью.
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 012: построение `<url>/?beat=<score>` и текст шаринга
- Story 002/007: рендер строки в меню/итогах (слоты готовы)
- Story 013: проверка W6 на устройстве

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/game_flow/friend_challenge_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002, 007, 008
- Unlocks: 013
