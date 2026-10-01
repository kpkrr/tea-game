# Epic: Game Flow (Menus & Out-of-Match Screens)

> **Layer**: Presentation
> **GDD**: design/ux/game-flow.md
> **Architecture Module**: GameFlow
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 19 / 20 active
> **Status**: Ready
> **Stories**: 13 stories

## Overview

Экраны вне партии: главное меню со строкой статуса кассы и рекорда, How to Play (3 карточки перед первой сменой), Settings, Records, About, пауза с подтверждением выхода, итоги с накруткой счёта и «N to beat», оверлей «Rotate your phone», PWA-установка, карточка для шаринга, wake lock, вызов `?beat=N`. Весь текст — английский через `tr()`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Web build & platform shell | Single-thread web-экспорт, HTML-оболочка, проверка WebGL2, экран загрузки, Page Visibility, PWA/share/wake lock через хелпер оболочки | HIGH |
| ADR-0003: Match simulation — clock, tick order, pause | GameClock + MatchDirector, фиксированный порядок тика, без SceneTree.paused, типизированные сигналы, DI через корень композиции | LOW |
| ADR-0004: Data config & load-time validation | GameConfig + подресурсы .tres, ConfigValidator собирает все ошибки, RNG инъекцией | LOW |
| ADR-0005: Local persistence (SaveStore) | JSON-блоб с schema_version, scope(owner), localStorage на web / user:// на desktop, шов под бэкенд | HIGH |
| ADR-0006: Navigation & tap picking | NavMesh из данных + прямые запросы NavigationServer3D, выбор тапа без физики, ID (owner_id, index), запасной GridNavigator | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-flow-001 | Главное меню (Play / Records / Settings / How to Play) вместо стартового экрана E18; `ready_reached` → меню, без автостарта партии (F1) | ADR-0001, ADR-0003 ✅ |
| TR-flow-002 | Из меню до партии — 1 тап, если `tutorial.seen` | ADR-0003 ✅ |
| TR-flow-003 | How to Play: 3 карточки автоматически перед первой сменой, дальше из меню; `tutorial.seen` сохраняется (F4) | ADR-0005 ✅ |
| TR-flow-004 | Settings: Music / Sound effects / Vibration, применяются сразу, сохраняются; доступны из меню и из паузы; из паузы пауза не снимается (F2) | ADR-0001, ADR-0003, ADR-0005 ✅ |
| TR-flow-005 | Строки Vibration нет, если `navigator.vibrate` не поддерживается | ADR-0001 ✅ |
| TR-flow-006 | Весь текст игры — только английский, строки через `tr()`-ключи; выбора языка нет (F3) | GDD/UX — ADR не требуется |
| TR-flow-007 | Records: рекорд, до 5 последних смен, счётчики, серия; пустое состояние (F5) | ADR-0005 ✅ |
| TR-flow-008 | Пауза: Resume / Settings / Main Menu; Main Menu → подтверждение; выход = `match_ended(quit)`, очки засчитываются, итоги пропускаются | ADR-0003 ✅ |
| TR-flow-009 | Строка статуса в меню: Till A / C и Best; при Full — время до нового дня | ADR-0005 ✅ |
| TR-flow-010 | Кнопки меню срабатывают по release; Escape = назад; кнопка «назад» браузера не перехватывается | ADR-0006 ✅ |
| TR-flow-011 | Меню показывает «Progress can't be saved», если `SaveStore.persistent = false` | ADR-0005 ✅ |
| TR-flow-012 | Итоги (M1): порядок строк, накрутка счёта ≤ 0,8 с с пропуском по тапу, «N to beat», Play Again / Share / Menu с grace | ADR-0003, ADR-0004, ADR-0006 ✅ |
| TR-flow-014 | Тач-устройство в ландшафте → оверлей «Rotate your phone» + пользовательская пауза; обратный поворот паузу не снимает; на ПК оверлея нет (F6) | ADR-0001, ADR-0003 ✅ |
| TR-flow-017 | About: версия сборки, авторы, лицензии (включая Godot MIT) | ADR-0004 ✅ |
| TR-flow-018 | PWA: установка, строка Install app, одноразовая подсказка после 3-й смены, инструкция на iOS, скрыто в standalone; обновление — при следующем запуске | ADR-0001 ✅ |
| TR-flow-019 | Шаринг: PNG-карточка 1080×1350, рендер на `match_ended`, Web Share с файлом; фолбэк — скачать PNG + текст в буфер (F8) | ADR-0001, ADR-0004 ✅ |
| TR-flow-020 | Wake lock только во время идущей партии | ADR-0001, ADR-0003 ✅ |
| TR-flow-021 | Send feedback открывает `feedback_url` в новой вкладке; пустой конфиг — строки нет (M10) | ADR-0001, ADR-0004 ✅ |
| TR-flow-024 | Вызов `?beat=N`: валидация, сохранение, удаление параметра из адреса, строка в меню, итог на экране результатов, сброс при выполнении (M13) | ADR-0001, ADR-0005 ✅ |
| TR-flow-026 | Reduced motion: все переходы потока мгновенные | ADR-0001 ✅ |

## Port Source (vertical slice)

В срезе нет — пишется с нуля.

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [GameFlow router, navigation rules and `tr()` catalog](story-001-gameflow-router-navigation.md) | Integration | Ready | ADR-0003 | M |
| 002 | [Main Menu screen, status line and persistence warning](story-002-main-menu-status-line.md) | UI | Ready | ADR-0005 | M |
| 003 | [How to Play cards and `tutorial.seen`](story-003-how-to-play-cards.md) | UI | Ready | ADR-0005 | M |
| 004 | [Settings panel: Music / Sound effects / Vibration (menu and pause)](story-004-settings-panel.md) | UI | Ready | ADR-0005 | M |
| 005 | [Pause menu extension and End shift confirm](story-005-pause-menu-end-shift.md) | Integration | Ready | ADR-0003 | M |
| 006 | [Records screen, About panel and Send feedback row](story-006-records-about-feedback.md) | UI | Ready | ADR-0005 | M |
| 007 | [Results overlay: count-up, “to beat”, buttons with grace](story-007-results-overlay.md) | UI | Ready | ADR-0003 | L |
| 008 | [PlatformBridge game-flow capabilities and `teaRushPlatform` shell helper](story-008-platformbridge-flow-capabilities.md) | Integration | Ready | ADR-0001 | L |
| 009 | [Rotate-your-phone overlay and wake lock during a match](story-009-rotate-overlay-wake-lock.md) | Integration | Ready | ADR-0001 | S |
| 010 | [Friend challenge link `?beat=N`](story-010-friend-challenge-link.md) | Logic | Ready | ADR-0001 | M |
| 011 | [PWA install: export preset, Install app row and one-time hint](story-011-pwa-install-flow.md) | Integration | Ready | ADR-0001 | L |
| 012 | [Share card render (1080×1350) and Share flow with fallbacks](story-012-share-card.md) | Integration | Ready | ADR-0001 | L |
| 013 | [On-device verification of ADR-0001 checks W1–W7](story-013-device-verification-w1-w7.md) | Integration | Ready | ADR-0001 | L |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/ux/game-flow.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories game-flow` to break this epic into implementable stories.
