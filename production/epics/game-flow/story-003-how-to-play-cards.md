# Story 003: How to Play cards and `tutorial.seen`

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M (≈ half day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-003`, `TR-flow-002`, `TR-flow-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Три карточки обучения: автоматически перед первой сменой (Play при `tutorial.seen = false`), далее из меню. Тексты черновые (writer финализирует), хранятся как `tr()`-ключи; картинки — плейсхолдеры до `art-assets`.

**ADR Governing Implementation**: ADR-0005: Local persistence (SaveStore) (primary); also ADR-0003
**ADR Decision Summary**:
- **ADR-0005** (Local persistence (SaveStore)): JSON-блоб SaveStore с `schema_version`, scope(owner) на префикс, localStorage на web. Поправка 2026-10-01: аддитивные ключи `tutorial.seen`, `ui.install_hint_shown`, `challenge.target` (GameFlow), `haptics.vibration_on`, `stats.*`; `schema_version` остаётся 1.
- **ADR-0003** (Match simulation — clock, tick order, pause): GameClock + MatchDirector с фиксированным порядком тика, без `SceneTree.paused`, типизированные сигналы, DI через `_compose()`. Поправка 2026-10-01: состояние `IDLE`, `request_new_match/quit/resume`, `match_ended(reason)`, `ui_dt` для UI над паузой, wake lock из `_compose()`.
**ADR Version**: ADR-0005: 2026-09-30, ADR-0003: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0005] Web-путь: localStorage через хелпер оболочки `teaRushSave`; `SaveScope.declare_text` для строк. [ADR-0003] Стандартный `Node`/`Tween`; `Tween` допустим только вне партии (IDLE/меню); над паузой — статично (`ui_dt = 0`).

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: GameFlow владеет scope `tutorial`, `ui`, `challenge`; игровые данные читает только геттерами владельцев (Currency/Till/PlayerStats) *(from ADR-0005)*
- Forbidden: прямой доступ к чужим ключам SaveStore; `settings`/`haptics` scope у GameFlow (пишут AudioDirector/Haptics); повышение `schema_version` *(from ADR-0005)*
- Guardrail: запись — через общий flush шага 6 / page hide, отдельных flush-путей нет *(from ADR-0005)*
- Required: GameFlow пишет в MatchLifecycle только `request_new_match()`, `request_quit_match()`, `request_resume()`; сигналы — типизированные, подключаются в `_compose()` (DI, без синглтон-поиска) *(from ADR-0003)*
- Forbidden: `SceneTree.paused`; анимация на raw `delta`/`Tween` поверх паузы (Settings из паузы и confirm — статичные); результаты — на `ui_dt` *(from ADR-0003)*
- Guardrail: presentation-узлы `process_priority` ≥ 0 *(from ADR-0003)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] Play при `tutorial.seen = false` → How to Play (режим «из Play»); Start shift или Skip на любой карточке → `tutorial.seen = true` и `request_new_match()`; повторный Play сразу стартует партию (TR-flow-003, TR-flow-002)
- [ ] Back (←)/Escape из How to Play, открытого из Play, → Main Menu **без** `tutorial.seen`: следующий Play снова покажет обучение (AC 30 спека)
- [ ] Из меню How to Play открывается всегда; последняя кнопка — Done → Main Menu, `tutorial.seen` не сбрасывается; индикатор страниц `● ○ ○`, листание Next/свайп/←→, Skip (клавиша S); число карточек = `FlowConfig.how_to_play_cards` (проверка при старте) (TR-flow-003)
- [ ] Порядок фокуса: Next/Start shift/Done → Skip → Back; все подписи — `tr()`-ключи, лимит 90 символов на карточку, ≥ 14 dp (TR-flow-006)
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- `tutorial.seen` — scope `tutorial`, пишется GameFlow; чтение плохого ключа → `false` (валидация SaveStore).
- Карточки 1–3 — черновые тексты из спека (M-список); сдвиг 200 мс, reduced motion — мгновенно.
- `how_to_play_cards` сверяется с числом карточек в сцене на boot (`invariant`, ADR-0004 amendment).
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- `art-assets`: картинки/схемы карточек
- Story 001: fade-правила и back-навигация (используются здесь)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/how-to-play-cards-evidence.md` + retained screenshot of each screen touched (9:20, 9:16, 1:1)
- Logic support: `tests/unit/game_flow/how_to_play_flow_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001, 002
- Unlocks: None
