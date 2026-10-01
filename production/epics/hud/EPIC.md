# Epic: HUD & Feedback UI (in-match)

> **Layer**: Presentation
> **GDD**: design/gdd/hud-feedback-ui.md
> **Architecture Module**: HUD
> **Engine Risk**: HIGH
> **GDD Requirements Covered by ADRs**: 17 / 25 active
> **Status**: Ready
> **Stories**: 11 stories

## Overview

Всё, что игрок видит в партии: верхняя полоса со счётом и страйками, всплывающие числа, мировые оверлеи (касса, чайники, кольца терпения, жетоны заказов и чашек, контур цели), кнопка паузы, плашка «Till full!», виньетка последнего страйка. HUD ничего не хранит и читает состояние каждый кадр. Цвета шагов рецепта — Pillar 2 «цена видна в чашке».

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Viewport, camera fit & 2.5D presentation | Явный stretch, перспективная камера-диорама (дистанция от safe_aspect, кухня ≥ 95 %; было ortho), HUD-полосы, 3D-окружение + toon-спрайты, мировые оверлеи | HIGH |
| ADR-0003: Match simulation — clock, tick order, pause | GameClock + MatchDirector, фиксированный порядок тика, без SceneTree.paused, типизированные сигналы, DI через корень композиции | LOW |
| ADR-0006: Navigation & tap picking | NavMesh из данных + прямые запросы NavigationServer3D, выбор тапа без физики, ID (owner_id, index), запасной GridNavigator | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-hud-001 | Экранные полосы: счёт, 3 страйка, всплывающие числа, оверлей итогов; мир в полосы не заходит | ADR-0002 ✅ |
| TR-hud-002 | Мировые оверлеи: касса, чайники, кольцо и жетон гостя, жетоны чашки, метки станций, контур цели и кольцо на полу | ADR-0002 ✅ |
| TR-hud-003 | HUD ничего не хранит и не кэширует, значения читаются каждый кадр | ADR-0003 ✅ |
| TR-hud-004 | Состояния Inactive → Active → MatchEnd → Active | ADR-0003 ✅ |
| TR-hud-005 | Жетон и кольцо появляются уже в состоянии Approaching | GDD/UX — ADR не требуется |
| TR-hud-006 | Тапы по полосам не уходят в кухню; при открытом оверлее тапы получает только оверлей | ADR-0006 ✅ |
| TR-hud-007 | «Играть снова» принимает тапы после fade ~250 мс + grace 500 мс | ADR-0006, ADR-0003 ✅ |
| TR-hud-008 | Анимации HUD паузятся через игровое время | ADR-0003 ✅ |
| TR-hud-009 | `till_fill_ratio = amount / capacity` каждый кадр | ADR-0004 ✅ |
| TR-hud-010 | Open→Full — только акцент на кассе, без чисел в полосе | GDD/UX — ADR не требуется |
| TR-hud-011 | Испорченная чашка отличается силуэтом, не только цветом | GDD/UX — ADR не требуется |
| TR-hud-012 | При 9:20 постоянные элементы — счёт и страйки; страйки не скрываются | ADR-0002 ✅ |
| TR-hud-013 | Жетоны в Approaching рисуются с масштабом и прозрачностью 0,7; Waiting — поверх | ADR-0002 ✅ |
| TR-hud-014 | Два ухода в одном кадре — пульсы со сдвигом 100 мс | GDD/UX — ADR не требуется |
| TR-hud-015 | Всплывающие числа с полным значением сразу, дуга ~400 мс; overflow — отскок без числа | GDD/UX — ADR не требуется |
| TR-hud-016 | `is_new_record` читается готовым флагом из Currency | ADR-0003 ✅ |
| TR-hud-017 | Разделение snap и smooth для анимаций | GDD/UX — ADR не требуется |
| TR-hud-018 | Отдельный звук на каждое событие | GDD/UX — ADR не требуется |
| TR-hud-019 | Константы тюнинга HUD — данные | ADR-0004 ✅ |
| TR-hud-020 | Чужие константы только читаются | ADR-0004 ✅ |
| TR-hud-021 | Контур цели и кольцо на полу меняются в том же кадре, что и цель Player Control | ADR-0003 ✅ |
| TR-hud-022 | Опция reduced-motion для пульса колец (решается в `/ux-design`) | GDD/UX — ADR не требуется |
| TR-hud-023 | Кнопка паузы в HUD: пауза = hidden ИЛИ пауза игрока через единый GameClock (ADR-0003); только в Active; возврат вкладки не снимает паузу игрока; снятие только «Продолжить» (Escape/Enter на ПК); тапы по кухне на паузе игнорируются | ADR-0003, ADR-0006 ✅ |
| TR-flow-013 | Плашка «Till full!» (M2): 2 с, звон, вибрация, не останавливает партию и не ловит тапы (F9) | ADR-0003, ADR-0004, ADR-0006 ✅ |
| TR-flow-023 | Последний страйк: виньетка + сердцебиение при `guests_lost == max − 1`, замирают на паузе, reduced motion — без пульса (M12) | ADR-0003, ADR-0004, ADR-0006 ✅ |

## Port Source (vertical slice)

Логика уже проверена в `prototypes/tea-rush-vertical-slice/`. Истории переносят её в `src/`, а не пишут заново:
- `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd`

## Stories

| # | Story | Type | Status | ADR | Estimate |
|---|-------|------|--------|-----|----------|
| 001 | [HudConfig data and read-only upstream accessors](story-001-hud-config-and-upstream-readers.md) | Logic | Ready | ADR-0004, ADR-0003 | S |
| 002 | [HUD shell, state machine and pause-aware animation clock](story-002-hud-shell-state-machine.md) | Integration | Ready | ADR-0003, ADR-0002 | M |
| 003 | [Top strip: score plate, strike icons, till counter and fill ratio](story-003-hud-top-strip-score-strikes-till.md) | UI | Ready | ADR-0002, ADR-0004, ADR-0007 | M |
| 004 | [Tap isolation: strips vs kitchen, modal overlays and restart grace](story-004-hud-tap-isolation-and-modal-input.md) | Integration | Ready | ADR-0006, ADR-0003 | M |
| 005 | [Guest order token and patience ring (Approaching, Waiting, layering)](story-005-hud-guest-order-token-patience-ring.md) | UI | Ready | ADR-0002, ADR-0003 | L |
| 006 | [Coin/score popups, overflow bounce and leaving pulse (snap vs smooth)](story-006-hud-popups-and-leaving-pulse.md) | Visual/Feel | Ready | ADR-0003, ADR-0002 | M |
| 007 | [World overlays: till fill, kettle status, cup tokens (ruined silhouette), station tags](story-007-hud-world-overlays-till-kettles-cups.md) | UI | Ready | ADR-0002, ADR-0003 | L |
| 008 | [Selected-target outline and destination ring](story-008-hud-target-outline-and-floor-ring.md) | UI | Ready | ADR-0002, ADR-0003 | S |
| 009 | [Pause button and Paused overlay (user pause via GameClock)](story-009-hud-pause-button-and-paused-overlay.md) | Integration | Ready | ADR-0003, ADR-0006 | M |
| 010 | [Till full! banner and last-strike vignette (with reduced motion)](story-010-hud-till-full-banner-last-strike-vignette.md) | Visual/Feel | Ready | ADR-0003, ADR-0004, ADR-0006 | M |
| 011 | [MatchEnd hand-off: freeze overlays, is_new_record flag, popup completion](story-011-hud-matchend-handoff.md) | Integration | Ready | ADR-0003 | S |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/hud-feedback-ui.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/story-readiness production/epics/hud/story-001-*.md`, then `/dev-story`.
