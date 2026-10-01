# Story 007: Results overlay: count-up, “to beat”, buttons with grace

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L (≈ 1 day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-012`, `TR-flow-026`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Экран итогов M1: порядок строк, накрутка счёта ≤ 0,8 с с пропуском по тапу, `NEW RECORD!` либо `Best N · X to beat`, касса/чашки, зарезервированные слоты строк вызова и серии (наполняют Story 010 и эпик player-stats), кнопки Play Again / Share / Menu с grace P4. Всё на `ui_dt`.

**ADR Governing Implementation**: ADR-0003: Match simulation — clock, tick order, pause (primary); also ADR-0004, ADR-0006
**ADR Decision Summary**:
- **ADR-0003** (Match simulation — clock, tick order, pause): GameClock + MatchDirector с фиксированным порядком тика, без `SceneTree.paused`, типизированные сигналы, DI через `_compose()`. Поправка 2026-10-01: состояние `IDLE`, `request_new_match/quit/resume`, `match_ended(reason)`, `ui_dt` для UI над паузой, wake lock из `_compose()`.
- **ADR-0004** (Data config & load-time validation): Конфиг — типизированные `.tres`-ресурсы под корнем `GameConfig`, валидация `ConfigValidator` собирает все ошибки. Поправка 2026-10-01: новый `FlowConfig` (feedback_url, game_url, challenge_max, recent_shifts_max, install_hint_after_shifts, results_count_up_s, share_card_size, fade-времена, how_to_play_cards).
- **ADR-0006** (Navigation & tap picking): Тап по кухне — математика без физики; блокирующие экраны — `MOUSE_FILTER_STOP`, неблокирующие оверлеи — `MOUSE_FILTER_IGNORE` (поправка 2026-10-01).
**ADR Version**: ADR-0003: 2026-09-30, ADR-0004: 2026-09-30, ADR-0006: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: [ADR-0003] Стандартный `Node`/`Tween`; `Tween` допустим только вне партии (IDLE/меню); над паузой — статично (`ui_dt = 0`). [ADR-0004] Custom `Resource` + `@export`, `ResourceLoader.load`; ничего post-cutoff. [ADR-0006] `Control.mouse_filter`; ничего post-cutoff для этого потока.

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: GameFlow пишет в MatchLifecycle только `request_new_match()`, `request_quit_match()`, `request_resume()`; сигналы — типизированные, подключаются в `_compose()` (DI, без синглтон-поиска) *(from ADR-0003)*
- Forbidden: `SceneTree.paused`; анимация на raw `delta`/`Tween` поверх паузы (Settings из паузы и confirm — статичные); результаты — на `ui_dt` *(from ADR-0003)*
- Guardrail: presentation-узлы `process_priority` ≥ 0 *(from ADR-0003)*
- Required: настраиваемые значения — в `FlowConfig` (`assets/data/config/flow.tres`) с валидатором; невалидное поле = `fail_boot` *(from ADR-0004)*
- Forbidden: хардкод флоу-значений (времена, лимиты, URL); подсказки загрузки и UI-строки — не в конфиге (shell / `tr()`) *(from ADR-0004)*
- Guardrail: валидатор собирает все ошибки за один проход *(from ADR-0004)*
- Required: блокирующие экраны — полноэкранный `Control` с `MOUSE_FILTER_STOP`; неблокирующие оверлеи — `MOUSE_FILTER_IGNORE` *(from ADR-0006)*
- Forbidden: пропуск нажатия в кухню через блокирующий экран *(from ADR-0006)*
- Guardrail: вне `RUNNING` `flush(false)` тоже отбрасывает нажатия (defence in depth) *(from ADR-0006)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] Появление по порядку M1 (заголовок Shift over → счёт → рекорд → монеты/касса → чашки → [вызов] → [серия] → кнопки) на `ui_dt`; только при `match_ended(&"lost")`, при `quit` не показывается (TR-flow-012)
- [ ] Счёт накручивается от 0 до N за `FlowConfig.results_count_up_s` (0,8 с; 0 = без накрутки); тап во время накрутки сразу показывает финал; reduced motion — всё сразу (TR-flow-012, TR-flow-026)
- [ ] Не рекорд → `Best 4250 · 130 to beat` (разность верна; при равенстве не рекорд); рекорд → штамп `NEW RECORD!` (1,3→1,0, золото) + стингер; при Full строка `Till full · new day in Hh Mm` (TR-flow-012)
- [ ] Play Again / Share / Menu не реагируют первые `restart_input_grace_ms` после появления и срабатывают по release; порядок фокуса Play Again → Share → Menu; Escape игнорируется (TR-flow-012, TR-flow-010)
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Данные одним снимком на `match_ended`: `match_score`, `is_new_record`, `match_coins_added`, `match_cups`, `streak_grew_this_match`, состояние кассы — из Currency/Till/PlayerStats.
- Результаты остаются на `ui_dt` (не `sim_dt`, не raw delta) — ADR-0003 amendment.
- Share — disabled, пока карточка не готова (Story 012); при пустом `game_url` Share скрыта целиком (owner: game URL не выбран) — реализуемо с пустым конфигом.
- Строки вызова/серии — данные, которые подставляют Story 010 и player-stats; здесь рендер по готовому view-model, скрыты при пустых значениях.
- Стингер рекорда — эпик `audio-juice`; здесь вызов события.
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 012: рендер карточки и действие Share
- Story 010: логика вызова `?beat=`
- Story 011: плашка установки на итогах
- `hud`: «New best!» в партии (E20)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/results-overlay-evidence.md` + retained screenshot of each screen touched (9:20, 9:16, 1:1)
- Logic support: `tests/unit/game_flow/results_view_model_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001; внешние: `currency`, `till`, `player-stats`, `audio-juice`
- Unlocks: 010, 011, 012
