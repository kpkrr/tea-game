# Story 002: Main Menu screen, status line and persistence warning

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M (≈ half day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-001`, `TR-flow-002`, `TR-flow-009`, `TR-flow-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Главное меню: Play / Records / Settings / How to Play, строка статуса `Best` / `Till A/C` / серия, режим Full с временем до нового дня, предупреждение о невозможности сохранения. Визуальный скин — эпик `art-assets`; здесь структура и данные.

**ADR Governing Implementation**: ADR-0005: Local persistence (SaveStore) (primary); also ADR-0003, ADR-0006
**ADR Decision Summary**:
- **ADR-0005** (Local persistence (SaveStore)): JSON-блоб SaveStore с `schema_version`, scope(owner) на префикс, localStorage на web. Поправка 2026-10-01: аддитивные ключи `tutorial.seen`, `ui.install_hint_shown`, `challenge.target` (GameFlow), `haptics.vibration_on`, `stats.*`; `schema_version` остаётся 1.
- **ADR-0003** (Match simulation — clock, tick order, pause): GameClock + MatchDirector с фиксированным порядком тика, без `SceneTree.paused`, типизированные сигналы, DI через `_compose()`. Поправка 2026-10-01: состояние `IDLE`, `request_new_match/quit/resume`, `match_ended(reason)`, `ui_dt` для UI над паузой, wake lock из `_compose()`.
- **ADR-0006** (Navigation & tap picking): Тап по кухне — математика без физики; блокирующие экраны — `MOUSE_FILTER_STOP`, неблокирующие оверлеи — `MOUSE_FILTER_IGNORE` (поправка 2026-10-01).
**ADR Version**: ADR-0005: 2026-09-30, ADR-0003: 2026-09-30, ADR-0006: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0005] Web-путь: localStorage через хелпер оболочки `teaRushSave`; `SaveScope.declare_text` для строк. [ADR-0003] Стандартный `Node`/`Tween`; `Tween` допустим только вне партии (IDLE/меню); над паузой — статично (`ui_dt = 0`). [ADR-0006] `Control.mouse_filter`; ничего post-cutoff для этого потока.

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: GameFlow владеет scope `tutorial`, `ui`, `challenge`; игровые данные читает только геттерами владельцев (Currency/Till/PlayerStats) *(from ADR-0005)*
- Forbidden: прямой доступ к чужим ключам SaveStore; `settings`/`haptics` scope у GameFlow (пишут AudioDirector/Haptics); повышение `schema_version` *(from ADR-0005)*
- Guardrail: запись — через общий flush шага 6 / page hide, отдельных flush-путей нет *(from ADR-0005)*
- Required: GameFlow пишет в MatchLifecycle только `request_new_match()`, `request_quit_match()`, `request_resume()`; сигналы — типизированные, подключаются в `_compose()` (DI, без синглтон-поиска) *(from ADR-0003)*
- Forbidden: `SceneTree.paused`; анимация на raw `delta`/`Tween` поверх паузы (Settings из паузы и confirm — статичные); результаты — на `ui_dt` *(from ADR-0003)*
- Guardrail: presentation-узлы `process_priority` ≥ 0 *(from ADR-0003)*
- Required: блокирующие экраны — полноэкранный `Control` с `MOUSE_FILTER_STOP`; неблокирующие оверлеи — `MOUSE_FILTER_IGNORE` *(from ADR-0006)*
- Forbidden: пропуск нажатия в кухню через блокирующий экран *(from ADR-0006)*
- Guardrail: вне `RUNNING` `flush(false)` тоже отбрасывает нажатия (defence in depth) *(from ADR-0006)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] Меню показывает кнопки Play (primary, стартовый фокус), Records, Settings, How to Play; при `tutorial.seen = true` от меню до `request_new_match()` — ровно 1 тап (TR-flow-001, TR-flow-002)
- [ ] Строка статуса: `★ Best N · ● Till A/C` (+ `🔥 N`, если `displayed_streak > 0`; `🔥 N · fill the till to keep it`, если серия жива, а касса не полна); значения совпадают с HUD; первый запуск — `Best 0 · Till 0/250` без прочерков (TR-flow-009)
- [ ] При Full — `Till C/C · New day in Hh Mm`, пересчёт раз в минуту (<1 мин → `New day in <1m`); при показе меню и когда отсчёт дошёл до 0 — вызывается `Till.check_day_reset()` и строка обновляется без перезагрузки (TR-flow-009)
- [ ] При `SaveStore.persistent == false` внизу строка `Progress can't be saved in this browser` ≥ 14 dp; иначе строки нет (TR-flow-011)
- [ ] Экран корректен на 9:20, 9:16 и 1:1 без обрезки/горизонтальной прокрутки, текст ≥ 14 dp, фокус-контур 3 dp (часть AC 12, 31 спека)
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Данные: Currency `best_score`, Till `till_amount/capacity/state/time_to_reset` (Formula 6), PlayerStats `displayed_streak` (Formula 2) — только геттеры; GameFlow ключи владельцев не читает (ADR-0005 §1).
- Строка вызова `⚔ Beat your friend: N` и `⊕ Install app` добавляются Story 010 и 011 в зарезервированные слоты.
- Музыка меню и первый жест — любая кнопка меню; клип/воспроизведение — эпик `audio-juice`, здесь только не блокировать событие.
- Таймер «New day in» — `Timer` на реальном времени (вне партии), 60 с.
- Зависит от эпиков `currency`, `till`/`player-stats` (геттеры), `foundation-runtime` (`SaveStore.persistent`).
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 010: строка вызова `?beat=`
- Story 011: строка Install app
- `art-assets`: арт-заставка и неоновая вывеска, пергаментные пилюли (art-bible §7.6)
- `audio-juice`: трек меню

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/main-menu-status-line-evidence.md` + retained screenshot of each screen touched (9:20, 9:16, 1:1)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001; внешние: `currency`, `till`, `player-stats`
- Unlocks: 003, 010, 011
