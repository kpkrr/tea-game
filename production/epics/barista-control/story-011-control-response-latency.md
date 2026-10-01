# Story 011: Интеграция: отклик на тап <= 3 кадра (маркер, старт, перенаправление, отказ)

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Performance & load budgets
**ADR Decision Summary**: Референсный слабый Android, цель 60 fps / пол 30 fps, бюджеты CPU по системам, потолки draw calls/памяти/размера; тап разрешается на шаге 2 и маркер рисуется в том же кадре (<= 33 мс на полу 30 fps, внутри TR-control-015).
**ADR Version**: 2026-09-30
**Secondary ADRs**: ADR-0003 (Match simulation - clock, tick order, pause)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Post-cutoff/версионно-зависимые API: NavigationServer3D.bake_from_source_geometry_data, NavigationMeshSourceGeometryData3D.add_projected_obstruction, map_set_use_async_iterations (проверены только на 4.7.2); map_force_update deprecated с 4.5, но работает - только на Booting, single-thread. Имя константы InputEvent.DEVICE_ID_EMULATION подтвердить в первой истории TapInput. Запрос пути до первой синхронизации карты печатает ERROR и возвращает пусто - всегда ждать poll_ready().

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0007): тап разрешается на шаге 2 тика и маркер рисуется в ТОМ ЖЕ кадре (<= 33 мс на полу 30 fps, внутри 50 мс).
- Required (from ADR-0003): порядок тика фиксирован (`flush` -> `barista.step` -> ...), presentation читает свежее состояние в том же кадре.
- Guardrail (from ADR-0007): латентность touch-to-engine в браузере измеряется отдельно на устройстве ADR-0001 и в эту историю не входит.

---

## Acceptance Criteria

*From GDD `design/gdd/player-control-barista-movement.md`, scoped to this story:*

- [ ] Headless-сцена с реальными TapInput, TapPicker, Pathing, BaristaController, BaristaView: `InputEventScreenTouch(pressed=true)` в кадре N по полу и (в отдельном прогоне) по станции -> не позже кадра N+3 есть маркер, старт движения (позиция изменилась) и состояние Walking (AC 36).
- [ ] Перенаправление во время Walking и отказ владельца (`FakeActionOwner` = REFUSE/невалидно) дают видимый отклик (новый маркер / сигнал отказа) не позже N+3, без потери позиции.
- [ ] Тап по HUD-полосе (вне `kitchen_rect`) не меняет цель баристы; HUD отражает цель/состояние в пределах 3 кадров (AC 40c, часть HUD - после эпика hud).

---

## Implementation Notes

Замыкающий тест эпика: склеивает stories 002-010 на реальном `NavigationServer3D` (headless, `map_force_update` в setup, `Pathing.dispose()` в teardown).

- Использовать gdUnit4 scene runner; кадры считать через `await runner.simulate_frames(n)`, а не по времени.
- Ручной замер на телефоне (видео 240 fps, медиана/p95, AC 37) - ADVISORY и входит в Web/Android spike ADR-0001/ADR-0007, не блокирует закрытие истории; результат вносится в `production/qa/evidence/` позже.
- Часть 40(a) AC (реальный Brewing: Holding у чайника без повторного тапа, действие ровно один раз) закрывается в brewing story 008; 40(b) (Guest AI) - в guest-sim epic.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Измерение touch-to-engine на устройстве (ADR-0001/0007 spike).
- Brewing story 008, guest-sim epic: интеграция с реальными владельцами.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/player_control/player_control_response_latency_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004, 005, 006, 008, 009, 010
- Unlocks: None (закрывает эпик)
