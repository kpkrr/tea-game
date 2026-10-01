# Story 010: BaristaView: 4-направленная ходьба, маркер цели, чашка в руках

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & presentation
**ADR Decision Summary**: canvas_items/expand на базе 360x640 (1 unit = 1 dp), перспективная камера-диорама с фиксированным наклоном 52° (поправка 2026-10-01; было ортокамера), бариста и гости - AnimatedSprite3D (4 направления, боковое зеркалится), мировые оверлеи - Sprite3D/Label3D.
**ADR Version**: 2026-09-30
**Secondary ADRs**: ADR-0003 (Match simulation - clock, tick order, pause)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Домен Rendering/UI помечен HIGH (VERSION.md), но используемые AnimatedSprite3D/Sprite3D/Label3D - до-cutoff API. Проверить на устройстве: alpha-сортировка AnimatedSprite3D с ALPHA_CUT_OPAQUE_PREPASS на Compatibility/WebGL2. Toon-шейдер персонажей - эпик visual-pipeline.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0002): бариста - `AnimatedSprite3D`, 4 направления (боковое зеркалится), без бленда между направлениями; шейдер персонажей (toon) - эпик visual-pipeline.
- Required (from ADR-0003): анимация привязана к `clock.running_changed` и читает `clock.is_running()` в `_ready` (GameTimeSprite); `AnimationPlayer`/`Tween` не ведут игровое время.
- Forbidden (from ADR-0002): 3D-физика, реальные источники света и shadow maps; overlay-элементы - `Sprite3D`/`Label3D`.

---

## Acceptance Criteria

*From GDD `design/gdd/player-control-barista-movement.md`, scoped to this story:*

- [ ] Ходьба вверх / вниз / вбок выбирает анимацию по `facing` (4 направления, боковое - зеркалом), смена направления мгновенная, без бленда; в Idle/Holding - idle-поза; анимация ходьбы идёт только пока часы `running`, спрайт, созданный при остановленных часах, стартует на паузе.
- [ ] Маркер цели: на полу - в `points[-1]` (клэмпнутая точка), на станции/госте - иконка цели; при перенаправлении маркер переносится в тот же кадр; в Holding видна чашка в руках (с ингредиентами/без), при отказе - обратная связь от владельца, не от этого класса.
- [ ] Скриншоты в `production/qa/evidence/`: маркер на полу, маркер на станции, ходьба вверх/вниз/вбок, Holding с чашкой и без, перенаправление (AC 39).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/presentation/kitchen_view.gd` (`_build_barista`, `_update_barista`, `_on_target_changed`, ~строки 300-400) - слайс рисует процедурный пиксель-арт (`pixel_art.gd`); в продакшене спрайты - 2D toon по `design/art/art-bible.md`.

- `BaristaView` (Node3D): `AnimatedSprite3D` (unshaded до подключения toon-шейдера), blob-shadow quad, иконка чашки, `Sprite3D` маркера; читает состояние контроллера и `TapTarget`, логики не содержит (presentation: `process_priority >= 0`, читает свежее состояние после симуляции).
- Пока нет финальных кадров (`art-assets`), использовать плейсхолдерные `SpriteFrames` с теми же именами анимаций (`walk_down`, `walk_up`, `walk_side`, `idle_*`) - замена ассетов не должна менять код.
- Маркер: дебаунс не нужен, 1 кадр = отклик (TR-control-015 проверяется story 011).
- Проверить на устройстве alpha-сортировку `AnimatedSprite3D` (бариста за островом, гость перед столешницей) - пункт верификации ADR-0002; рекомендуется ревью godot-specialist (Risk HIGH по домену Rendering).
- Evidence-документ: снимки + краткий sign-off ответственного за визуал.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Art-assets epic: производство анимаций и кадров баристы (2D toon).
- Visual-pipeline epic: toon-шейдер, освещение, уровни качества.
- Story 011: измерение задержки отклика.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel: `production/qa/evidence/barista-view-animation-evidence.md` + скриншоты и sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 008 (состояние и `facing`); foundation-runtime (GameClock `running_changed`)
- Unlocks: Story 011
