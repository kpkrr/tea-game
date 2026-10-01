# Story 005: HTML-оболочка: экран загрузки (логотип, прогресс, подсказка) и fade без белой вспышки

> **Epic**: Platform Shell (Web)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/platform-integration-telegram-mini-app.md`
**Requirement**: `TR-platform-006`, `TR-platform-018`, `TR-flow-016`, `TR-platform-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Web build & platform shell
**ADR Decision Summary**: Single-thread web-экспорт; HTML-оболочка гейтит WebGL2, показывает экран загрузки и скрывает белую вспышку; PlatformBridge отдаёт один visibility-сигнал через JavaScriptBridge.create_callback + Page Visibility API.
**ADR Version**: 2026-10-01 (Last Verified)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: JavaScriptBridge.create_callback (args: Array), Thread Support OFF, Canvas Resize Policy Adaptive; NOTIFICATION_APPLICATION_* на web сломаны (godot#87014); callback-объект хранить в member; HTTPS обязателен.

**Control Manifest Rules (this layer)**:
- Required (from ADR-0001): single-thread export (Thread Support OFF), Canvas Resize Policy Adaptive; один visibility-сигнал только через `JavaScriptBridge.create_callback` + `document.visibilitychange` (+ `pagehide`); JS-callback-объекты хранятся в member; callback принимает один `args: Array`
- Forbidden (from ADR-0001): `NOTIFICATION_APPLICATION_FOCUS_IN/OUT`/`_PAUSED`/`_RESUMED` на web; синхронный emit `safe_area_changed` из JS-handler; SharedArrayBuffer-пути; опора на `OS.is_userfs_persistent()`
- Guardrail (from ADR-0001/0007): cold ready на слабом устройстве — цели ADR-0007; boot-total ≤ 21.5 МБ, движок ≤ 10.5 МБ, `.pck` ≤ 11.0 МБ

---

## Acceptance Criteria

*From the TR-IDs / ADR guidelines above, scoped to this story:*

- [ ] Экран загрузки показывает логотип, прогресс-бар от стандартного web-export loading callback и одну случайную подсказку из inline-массива в `index.html` (English, по одной на загрузку); без жёсткого таймаута — экран остаётся до `ready_reached` (TR-platform-006, TR-flow-016)
- [ ] Canvas стартует с `opacity: 0`; по `ready_reached` CSS cross-fade показывает игру поверх затухающего loading-экрана — белая вспышка не наблюдается ни в Chrome, ни в Safari (TR-platform-018); цвет фона страницы = палитра арт-библии
- [ ] При `Failed` (`fail_boot`) оболочка показывает статичный экран «reload the page», loading-экран не зависает бесконечно под видом прогресса

---

## Implementation Notes

Расширяет `assets/web/shell.html` из story 004. Подсказки — массив в шаблоне (амендмент ADR-0001 2026-10-01: M5), не `GameConfig`. Связка с движком: `PlatformBridge.ready_reached` -> JS-вызов/флаг оболочки (через `JavaScriptBridge`, вызывается из `PlatformBridge`, не из gameplay). Evidence: retained screenshot каждого затронутого состояния экрана в `production/qa/evidence/`; записывать покадровую последовательность перехода (минимум 3 кадра: loading, середина fade, игра) для подтверждения отсутствия белого кадра. Sign-off: UX/art.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: WebGL2 gate
- Окончательные ассеты логотипа — art pipeline
- Пре-прогрев рендера до `ready_reached` — перф-эпик/MatchDirector Booting

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/shell-loading-screen-fade-evidence.md` с retained screenshot + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, 004
- Unlocks: Story 008
