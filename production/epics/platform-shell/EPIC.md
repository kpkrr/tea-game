# Epic: Platform Shell (Web)

> **Layer**: Foundation
> **GDD**: design/gdd/platform-integration-telegram-mini-app.md
> **Architecture Module**: PlatformBridge + HTML-оболочка + web-экспорт
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 11 / 11 active
> **Status**: Ready
> **Stories**: 8 stories

## Overview

Одна web-сборка по одному URL: HTML-оболочка с проверкой WebGL2 и экраном загрузки (логотип, прогресс, подсказка), единый сигнал видимости через Page Visibility API, safe area от видимого вьюпорта, переход Loading→Ready без белой вспышки, пресет экспорта и публикация. Telegram Mini App отложен — его требования помечены ⏸ и в истории не берутся. Сюда же входит spike на слабом Android из ADR-0001.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Web build & platform shell | Single-thread web-экспорт, HTML-оболочка, проверка WebGL2, экран загрузки, Page Visibility, PWA/share/wake lock через хелпер оболочки | HIGH |
| ADR-0007: Performance & load budgets | 60/30 fps, мс на систему, draw calls ≤ 180, .pck ≤ 11 МБ, загрузка ≤ 21,5 МБ, уровни качества Low/Mid/High, PerfProbe | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-platform-001 | Одна HTML5/WebGL2-сборка, один URL (браузер ПК и телефона) | ADR-0001 ✅ |
| TR-platform-002 | Детект контекста: `window.Telegram.WebApp` + успешный `ready()` → TMA, иначе Standalone | ⏸ отложено (Telegram) — не брать в истории |
| TR-platform-003 | SDK есть, но init упал или вышел по таймауту → тихо как Standalone, без UI ошибки | ⏸ отложено (Telegram) — не брать в истории |
| TR-platform-004 | Scope TG SDK: safe-area инсеты + опционально тема; без платежей | ⏸ отложено (Telegram) — не брать в истории |
| TR-platform-005 | Safe area = `innerWidth/Height` на resize/orientationchange | ADR-0001 ✅ |
| TR-platform-006 | Экран загрузки с прогрессом до готовности кухни, без жёсткого таймаута | ADR-0001 ✅ |
| TR-platform-011 | Нет WebGL2 → статичный экран «обновите браузер», движок не грузится | ADR-0001 ✅ |
| TR-platform-012 | Один visibility-сигнал (Page Visibility API) | ADR-0001 ✅ |
| TR-platform-013 | Состояние `Ready` запускает первый матч | ADR-0001 ✅ |
| TR-platform-014 | TG `initData`/user ID опциональны, их отсутствие ничего не блокирует | ⏸ отложено (Telegram) — не брать в истории |
| TR-platform-015 | Флаг контекста доступен для будущей монетизации | ⏸ отложено (Telegram) — не брать в истории |
| TR-platform-016 | `viewport_aspect_min`/`max` — данные из реестра | ADR-0004, ADR-0002 ✅ |
| TR-platform-017 | Resize посреди партии не сбрасывает состояние матча | ADR-0001, ADR-0002 ✅ |
| TR-platform-018 | Переход Loading→Ready без белой вспышки | ADR-0001 ✅ |
| TR-flow-015 | Адресная строка не обрабатывается; «кухня ≥ 95 %» — от видимого вьюпорта (F7) | ADR-0002 ✅ |
| TR-flow-016 | Экран загрузки: логотип, прогресс, одна случайная подсказка (в HTML-оболочке) | ADR-0001 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/foundation/platform_bridge.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [PlatformBridge: автозагрузка, BootState](story-001-platform-bridge-core.md) | Logic | Ready | ADR-0001 | M |
| 002 | [Visibility-сигнал и reduced motion](story-002-visibility-reduced-motion.md) | Integration | Ready | ADR-0001 | M |
| 003 | [Safe area, aspect из конфига, resize без сброса матча](story-003-safe-area-resize.md) | Integration | Ready | ADR-0001 | M |
| 004 | [HTML-оболочка: WebGL2-гейт и teaRushSave](story-004-shell-webgl2-gate.md) | UI | Ready | ADR-0001 | M |
| 005 | [Экран загрузки и fade без белой вспышки](story-005-shell-loading-screen-fade.md) | UI | Ready | ADR-0001 | M |
| 006 | [Export preset, PWA и CI size gate](story-006-web-export-preset-size-gate.md) | Config/Data | Ready | ADR-0001, ADR-0007 | M |
| 007 | [PerfProbe](story-007-perf-probe.md) | Logic | Ready | ADR-0007 | M |
| 008 | [Spike на слабом Android](story-008-weak-android-spike.md) | Integration | Ready | ADR-0001 | L |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/platform-integration-telegram-mini-app.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/story-readiness production/epics/platform-shell/story-001-platform-bridge-core.md`, затем `/dev-story`.
