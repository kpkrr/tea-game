# Story 005: Pause menu extension and End shift confirm

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M (≈ half day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Расширение оверлея паузы (Resume / Settings / Main Menu) и диалог P19 «End shift?». Выход = `request_quit_match()` → `match_ended(&"quit")`: очки и смена засчитываются, итоги пропускаются, сразу меню.

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause (primary); also ADR-0006, ADR-0005
**ADR Decision Summary**:
- **ADR-0003** (Match simulation — clock, tick order, pause): GameClock + MatchDirector с фиксированным порядком тика, без `SceneTree.paused`, типизированные сигналы, DI через `_compose()`. Поправка 2026-10-01: состояние `IDLE`, `request_new_match/quit/resume`, `match_ended(reason)`, `ui_dt` для UI над паузой, wake lock из `_compose()`.
- **ADR-0006** (Navigation & tap picking): Тап по кухне — математика без физики; блокирующие экраны — `MOUSE_FILTER_STOP`, неблокирующие оверлеи — `MOUSE_FILTER_IGNORE` (поправка 2026-10-01).
- **ADR-0005** (Local persistence (SaveStore)): JSON-блоб SaveStore с `schema_version`, scope(owner) на префикс, localStorage на web. Поправка 2026-10-01: аддитивные ключи `tutorial.seen`, `ui.install_hint_shown`, `challenge.target` (GameFlow), `haptics.vibration_on`, `stats.*`; `schema_version` остаётся 1.
**ADR Version**: ADR-0003: 2026-09-30, ADR-0006: 2026-09-30, ADR-0005: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0003] Стандартный `Node`/`Tween`; `Tween` допустим только вне партии (IDLE/меню); над паузой — статично (`ui_dt = 0`). [ADR-0006] `Control.mouse_filter`; ничего post-cutoff для этого потока. [ADR-0005] Web-путь: localStorage через хелпер оболочки `teaRushSave`; `SaveScope.declare_text` для строк.

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: GameFlow пишет в MatchLifecycle только `request_new_match()`, `request_quit_match()`, `request_resume()`; сигналы — типизированные, подключаются в `_compose()` (DI, без синглтон-поиска) *(from ADR-0003)*
- Forbidden: `SceneTree.paused`; анимация на raw `delta`/`Tween` поверх паузы (Settings из паузы и confirm — статичные); результаты — на `ui_dt` *(from ADR-0003)*
- Guardrail: presentation-узлы `process_priority` ≥ 0 *(from ADR-0003)*
- Required: блокирующие экраны — полноэкранный `Control` с `MOUSE_FILTER_STOP`; неблокирующие оверлеи — `MOUSE_FILTER_IGNORE` *(from ADR-0006)*
- Forbidden: пропуск нажатия в кухню через блокирующий экран *(from ADR-0006)*
- Guardrail: вне `RUNNING` `flush(false)` тоже отбрасывает нажатия (defence in depth) *(from ADR-0006)*
- Required: GameFlow владеет scope `tutorial`, `ui`, `challenge`; игровые данные читает только геттерами владельцев (Currency/Till/PlayerStats) *(from ADR-0005)*
- Forbidden: прямой доступ к чужим ключам SaveStore; `settings`/`haptics` scope у GameFlow (пишут AudioDirector/Haptics); повышение `schema_version` *(from ADR-0005)*
- Guardrail: запись — через общий flush шага 6 / page hide, отдельных flush-путей нет *(from ADR-0005)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] Пауза показывает Resume (primary, фокус) / Settings / Main Menu; Resume и Escape на панели → `request_resume()`; Settings → Story 004 панель, Back → пауза (TR-flow-008)
- [ ] Main Menu → confirm «End shift?» с текстом «Your score and coins so far are kept.», фокус на Cancel, ←/→ меняют фокус; Cancel/Escape → пауза; End shift → `request_quit_match()` (TR-flow-008)
- [ ] End shift приводит к одному `match_ended(&"quit")`: рекорд обновляется, если побит, статистика +1 смена, итоги не показываются, открывается Main Menu; quit вне `RUNNING` игнорируется (интеграционный тест с реальным MatchLifecycle) (TR-flow-008)
- [ ] Диалог и пауза блокируют ввод в кухню (`MOUSE_FILTER_STOP`), без анимаций при `ui_dt = 0`; End shift оформлен рамкой «опасное действие», не только цветом
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- `request_quit_match()` принимается только в `RUNNING`, применяется на шаге 0 следующего кадра даже при паузе (ADR-0003 amendment); при одновременном `guests_lost` побеждает `lost` — тогда GameFlow показывает итоги, не меню. Слушать `match_ended(reason)` и ветвиться по причине.
- Кнопка паузы в HUD и сам оверлей паузы принадлежат эпику `hud`; GameFlow добавляет пункты и диалог. Если оверлей паузы ещё не готов — тест против заглушки.
- Зависит от `guest-sim`/`currency`/`player-stats` для проверки «очки засчитаны».
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 004: панель Settings
- Story 007: итоги при `lost`
- `hud`: кнопка паузы, оверлей паузы, правила паузы на возврат вкладки

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/game_flow/pause_end_shift_test.gd` OR playtest doc
- Evidence doc: `production/qa/evidence/pause-menu-end-shift-evidence.md` (retained screenshot of each screen touched, 9:20 / 9:16 / 1:1)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001, 004; внешние: `hud` (оверлей паузы), `foundation-runtime` (`request_quit_match`)
- Unlocks: None
