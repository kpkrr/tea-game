# Story 012: Share card render (1080×1350) and Share flow with fallbacks

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L (≈ 1 day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Карточка результата M8: рендер PNG заранее на `match_ended` (SubViewport → `Image.save_png_to_buffer` → `share_prepare`), нажатие Share только вызывает синхронный `share_prepared()`; фолбэки: скачать PNG + текст в буфер, только текст, без ошибок игроку.

**ADR Governing Implementation**: ADR-0001: Web build & platform shell (primary); also ADR-0004, ADR-0003
**ADR Decision Summary**:
- **ADR-0001** (Web build & platform shell): Все обращения к браузеру идут через PlatformBridge и JS-хелпер оболочки `window.teaRushPlatform` (try/catch, безопасные значения по умолчанию, вне web — no-op); `ready_reached` передаёт управление GameFlow, а не запускает партию. Поправка 2026-10-01 добавляет PWA, share, wake lock, orientation, launch param, open_external, vibrate.
- **ADR-0004** (Data config & load-time validation): Конфиг — типизированные `.tres`-ресурсы под корнем `GameConfig`, валидация `ConfigValidator` собирает все ошибки. Поправка 2026-10-01: новый `FlowConfig` (feedback_url, game_url, challenge_max, recent_shifts_max, install_hint_after_shifts, results_count_up_s, share_card_size, fade-времена, how_to_play_cards).
- **ADR-0003** (Match simulation — clock, tick order, pause): GameClock + MatchDirector с фиксированным порядком тика, без `SceneTree.paused`, типизированные сигналы, DI через `_compose()`. Поправка 2026-10-01: состояние `IDLE`, `request_new_match/quit/resume`, `match_ended(reason)`, `ui_dt` для UI над паузой, wake lock из `_compose()`.
**ADR Version**: ADR-0001: 2026-10-01, ADR-0004: 2026-09-30, ADR-0003: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0001] Web-экспорт single-thread; `JavaScriptBridge.create_callback` (объект держать в member), PWA-опции экспорта и `pwa_needs_update/pwa_update` — имена из знаний до 4.7, сверить с 4.7.2 (W2); user activation для share/open/install — проверка на устройстве (W1). [ADR-0004] Custom `Resource` + `@export`, `ResourceLoader.load`; ничего post-cutoff. [ADR-0003] Стандартный `Node`/`Tween`; `Tween` допустим только вне партии (IDLE/меню); над паузой — статично (`ui_dt = 0`).

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: всё браузерное — через PlatformBridge → `window.teaRushPlatform` (try/catch, safe default, вне web no-op); callback-объекты хранятся в member *(from ADR-0001)*
- Forbidden: `JavaScriptBridge` вне PlatformBridge; `NOTIFICATION_APPLICATION_*` на web; эмит сигналов из сырого JS-обработчика (только dirty-flag в `_process`) *(from ADR-0001)*
- Guardrail: Thread Support OFF; shell-хелпер определён до загрузчика движка *(from ADR-0001)*
- Required: настраиваемые значения — в `FlowConfig` (`assets/data/config/flow.tres`) с валидатором; невалидное поле = `fail_boot` *(from ADR-0004)*
- Forbidden: хардкод флоу-значений (времена, лимиты, URL); подсказки загрузки и UI-строки — не в конфиге (shell / `tr()`) *(from ADR-0004)*
- Guardrail: валидатор собирает все ошибки за один проход *(from ADR-0004)*
- Required: GameFlow пишет в MatchLifecycle только `request_new_match()`, `request_quit_match()`, `request_resume()`; сигналы — типизированные, подключаются в `_compose()` (DI, без синглтон-поиска) *(from ADR-0003)*
- Forbidden: `SceneTree.paused`; анимация на raw `delta`/`Tween` поверх паузы (Settings из паузы и confirm — статичные); результаты — на `ui_dt` *(from ADR-0003)*
- Guardrail: presentation-узлы `process_priority` ≥ 0 *(from ADR-0003)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] На `match_ended(&"lost")` рендерится карточка `FlowConfig.share_card_size` (1080×1350): логотип, `★ score`, `NEW RECORD!` при рекорде, `N cups served`, «Can you beat me?», адрес; ключевое — в центральном квадрате 1080×1080, поля 64 px; PNG передан в `share_prepare(png, text, url)` до первого нажатия (TR-flow-019)
- [ ] Share на итогах: `share_prepared()` вызывается синхронно из обработчика нажатия; при `can_share_files()` открывается системное меню с файлом; до готовности карточки кнопка disabled (P17), «тапа в пустоту» нет (TR-flow-019)
- [ ] Результаты `share_finished`: `&"downloaded"` → тост `Image saved, text copied`; `&"copied"` → `Text copied`; `&"cancelled"`/`&"failed"` → без ошибок (фолбэк как при отсутствии API); тост P20 ~2 с (TR-flow-019)
- [ ] Текст шаринга `I scored N in Tea Rush ☕ Can you beat me? <game_url>/?beat=N` ≤ 100 символов + URL; при пустом `FlowConfig.game_url` кнопка Share скрыта (дефолт до решения владельца); карточка проверена в превью ~250 px (TR-flow-019)
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Порядок: рендер на `match_ended`, не на нажатие — иначе теряется user activation (ADR-0001 amendment). `share_prepare` принимает base64 через `Marshalls`.
- Визуальное оформление — art-bible §7.6/§7.7 п. 9/§8.6 (Ink на Parchment, штамп −6°, ключевой текст ≥ 48 px); финальные ассеты — эпик `art-assets`, здесь сборка сцены карточки из плейсхолдеров.
- **Owner: game URL** (пусто → Share скрыта): реализуемо с пустым конфигом, не Blocked. Ссылка `?beat=` ведёт к Story 010.
- На iOS возможна потеря activation (W1) → запасной путь `set_activation_overlay` строится только если Story 013 зафиксирует провал.
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 007: кнопка Share на итогах (каркас)
- Story 008: JS `prepare/share` и фолбэки
- Story 013: проверка W1 на iOS/Android

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/game_flow/share_card_test.gd` OR playtest doc
- Evidence doc: `production/qa/evidence/share-card-evidence.md` (retained screenshot of each screen touched, 9:20 / 9:16 / 1:1)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 007, 008, 010
- Unlocks: 013
