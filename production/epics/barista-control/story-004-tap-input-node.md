# Story 004: TapInput: приём нажатий, последний press за кадр, сброс вне игры

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Navigation & tap picking
**ADR Decision Summary**: Пути - прямые запросы NavigationServer3D на приватной карте, NavMesh запекается на старте из KitchenConfig (без NavigationAgent3D); выбор тапа - чистая математика (близость pick-якоря, затем луч против AABB и плоскость пола) без физики; стабильные ID (owner_id, index).
**ADR Version**: 2026-09-30
**Secondary ADRs**: ADR-0003 (Match simulation - clock, tick order, pause)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Post-cutoff/версионно-зависимые API: NavigationServer3D.bake_from_source_geometry_data, NavigationMeshSourceGeometryData3D.add_projected_obstruction, map_set_use_async_iterations (проверены только на 4.7.2); map_force_update deprecated с 4.5, но работает - только на Booting, single-thread. Имя константы InputEvent.DEVICE_ID_EMULATION подтвердить в первой истории TapInput. Запрос пути до первой синхронизации карты печатает ERROR и возвращает пусто - всегда ждать poll_ready().

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0006): пути только через интерфейс Navigator; NavigationServer3D вызывается лишь из NavServerNavigator, NavMeshBaker и Pathing.
- Required (from ADR-0006): ввод входит только через ноду `TapInput._unhandled_input` -> `TapPicker.on_press()`; решение принимается только в `TapPicker.flush` на шаге 2 тика.
- Required (from ADR-0003): `flush(running)` вызывается из `MatchDirector._process`; при `dt == 0` (пауза, скрытая вкладка, конец матча) сохранённое нажатие отбрасывается; не более одного pending press (last wins).
- Required (from ADR-0006): неинтерактивные HUD `Control` - `MOUSE_FILTER_IGNORE`, блокирующие оверлеи - `MOUSE_FILTER_STOP` (ADR-0002 §6).

---

## Acceptance Criteria

*From GDD `design/gdd/player-control-barista-movement.md`, scoped to this story:*

- [ ] Тапом считается только press: release и drag игнорируются; за один кадр (press A, press пол, release, drag B) применяется только последнее нажатие - пол (AC 9).
- [ ] Один физический тап = одно событие: эмулированное мышью нажатие (`device == InputEvent.DEVICE_ID_EMULATION`) отфильтровано, `InputEventScreenTouch` с `pressed` принят; событие, поглощённое HUD `Control`, до `TapInput` не доходит.
- [ ] `flush(false)` (пауза игрока, скрытая вкладка, матч не RUNNING) сбрасывает сохранённое нажатие без `tapped`; после `resume()` первый тап разрешается нормально.

---

## Implementation Notes

В слайсе ввод обрабатывается внутри presentation/main-сцены (см. `prototypes/tea-rush-vertical-slice/src/feature/match_director.gd`, обработка тапа); вынести в отдельную ноду.

- `TapInput` (Node в сцене кухни) владеет `_unhandled_input`; `TapPicker` остаётся RefCounted (ADR-0006 §5).
- Принимаются: `InputEventScreenTouch.pressed` и `InputEventMouseButton` (left, pressed) с `device != InputEvent.DEVICE_ID_EMULATION`. Имя константы подтвердить по `docs/engine-reference/godot/modules/input.md` и 4.7.2 (4.7 менял device-ID) - это пункт верификации ADR-0006.
- `event.position` используется как dp напрямую (ADR-0002); `get_viewport().size` не читать.
- Тест через gdUnit4 scene runner (`simulate_*`/`Input.parse_input_event`); два касания в одном кадре - last wins.
- Никакой очереди: одно поле `_pending_press`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002-003: правила выбора цели.
- Story 009: отказ ввода после конца матча в контроллере.
- Hud epic: настройка mouse_filter у HUD-контролов.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/player_control/player_control_tap_input_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002, 003; foundation-runtime (MatchDirector тик, GameClock)
- Unlocks: Story 008, 009, 011
