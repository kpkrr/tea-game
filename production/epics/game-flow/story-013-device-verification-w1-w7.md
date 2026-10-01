# Story 013: On-device verification of ADR-0001 checks W1–W7

> **Epic**: Game Flow (Menus & Out-of-Match Screens)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L (≈ 1 day)
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/ux/game-flow.md` (UX spec is the design source for this epic)
**Requirement**: `TR-flow-014`, `TR-flow-018`, `TR-flow-019`, `TR-flow-020`, `TR-flow-021`, `TR-flow-024`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

Нельзя проверить в редакторе: transient user activation и browser-API на Godot 4.7.2 web. Прогон W1–W7 на реальных iOS Safari и Android Chrome, фиксация результатов; при провале W1 — построить запасной HTML-оверлей активации (AQ-07).

**ADR Governing Implementation**: ADR-0001: Web build & platform shell (primary); also none
**ADR Decision Summary**:
- **ADR-0001** (Web build & platform shell): Все обращения к браузеру идут через PlatformBridge и JS-хелпер оболочки `window.teaRushPlatform` (try/catch, безопасные значения по умолчанию, вне web — no-op); `ready_reached` передаёт управление GameFlow, а не запускает партию. Поправка 2026-10-01 добавляет PWA, share, wake lock, orientation, launch param, open_external, vibrate.
**ADR Version**: ADR-0001: 2026-10-01

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: [ADR-0001] Web-экспорт single-thread; `JavaScriptBridge.create_callback` (объект держать в member), PWA-опции экспорта и `pwa_needs_update/pwa_update` — имена из знаний до 4.7, сверить с 4.7.2 (W2); user activation для share/open/install — проверка на устройстве (W1).

**Control Manifest Rules (this layer)** — *no control manifest exists; derived from the governing ADRs:*
- Required: всё браузерное — через PlatformBridge → `window.teaRushPlatform` (try/catch, safe default, вне web no-op); callback-объекты хранятся в member *(from ADR-0001)*
- Forbidden: `JavaScriptBridge` вне PlatformBridge; `NOTIFICATION_APPLICATION_*` на web; эмит сигналов из сырого JS-обработчика (только dirty-flag в `_process`) *(from ADR-0001)*
- Guardrail: Thread Support OFF; shell-хелпер определён до загрузчика движка *(from ADR-0001)*

---

## Acceptance Criteria

*From `design/ux/game-flow.md` (Acceptance Criteria, Moments M1–M14, States & Variants), scoped to this story:*

- [ ] W1: iOS Safari + Android Chrome — Share открывает системное меню с PNG из обработчика кнопки Godot; Send feedback открывает новую вкладку; на Android открывается Install prompt. Провал любого пункта → построен `set_activation_overlay` (HTML `<button>` над канвасом), перепроверено (TR-flow-019, TR-flow-021, TR-flow-018)
- [ ] W2/W3: PWA-ключи и `pwa_needs_update/pwa_update` существуют в 4.7.2; обновлённый деплой применяется при следующем запуске, не в матче; установленное PWA стартует офлайн и играет музыку (TR-flow-018)
- [ ] W4/W5: wake lock держится в 3-минутной партии на Android, отпускается на паузе/меню, берётся заново после возврата вкладки; поворот телефона в матче → `orientation_blocked_changed(true)` в течение кадра и пауза, обратно — пауза остаётся; окно ПК шире высоты — оверлея нет (TR-flow-020, TR-flow-014)
- [ ] W6/W7: `?beat=4250` читается один раз и убирается из адресной строки, перезагрузка не повторяет; `can_vibrate()` = false на iOS Safari, true на Android Chrome. Результаты всех W1–W7 (устройство, ОС/браузер, дата, pass/fail, скриншоты) — в evidence-документе (TR-flow-024)
- [ ] Весь player-facing текст — английский, через `tr()`-ключи (TR-flow-006)

---

## Implementation Notes

*Derived from the governing ADR amendments (2026-10-01) and Implementation Guidelines:*

- Собрать тестовый web-билд с заполненными `game_url`/`feedback_url` (временные тестовые значения, не коммитить в прод-конфиг).
- Результаты в `production/qa/evidence/device-verification-w1-w7-evidence.md` (таблица W1–W7: pass/fail/NOT RUN, причина); непрогнанный пункт явно помечается NOT RUN, не pass.
- Если W2 показывает отсутствие API — завести правку ADR-0001 (`/architecture-decision`), не молча менять поведение.
- Код — `src/game_flow/` (слайс-кода нет, пишется с нуля); публичные API с doc-комментариями; значения — из `FlowConfig`, не хардкод.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Stories 008–012: реализация самих возможностей
- ADR-0001 W-проверки вне game-flow (WebGL2-фолбэк, визибилити) — эпик `foundation-runtime`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: documented device playtest (evidence doc below)
- Evidence doc: `production/qa/evidence/device-verification-w1-w7-evidence.md` (retained screenshot of each screen touched, 9:20 / 9:16 / 1:1)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 006, 008, 009, 010, 011, 012; нужен доступ к iOS- и Android-устройству
- Unlocks: None
