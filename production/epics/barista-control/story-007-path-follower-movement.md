# Story 007: PathFollower: движение по пути без разгона и проскока

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-017`, `TR-control-006`, `TR-control-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Navigation & tap picking
**ADR Decision Summary**: Пути - прямые запросы NavigationServer3D на приватной карте, NavMesh запекается на старте из KitchenConfig (без NavigationAgent3D); выбор тапа - чистая математика (близость pick-якоря, затем луч против AABB и плоскость пола) без физики; стабильные ID (owner_id, index).
**ADR Version**: 2026-09-30
**Secondary ADRs**: ADR-0003 (Match simulation - clock, tick order, pause)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Post-cutoff/версионно-зависимые API: NavigationServer3D.bake_from_source_geometry_data, NavigationMeshSourceGeometryData3D.add_projected_obstruction, map_set_use_async_iterations (проверены только на 4.7.2); map_force_update deprecated с 4.5, но работает - только на Booting, single-thread. Имя константы InputEvent.DEVICE_ID_EMULATION подтвердить в первой истории TapInput. Запрос пути до первой синхронизации карты печатает ERROR и возвращает пусто - всегда ждать poll_ready().

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0003): модули симуляции - RefCounted со step(dt), без _process/_physics_process и без чтения Time/OS/Engine.
- Required (from ADR-0006): `PathFollower` - pure, вызывается из `BaristaController.step`; за шаг проходит ВСЕ сегменты, которые покрывает `speed x dt`, и не пролетает последнюю точку.
- Required (from ADR-0003): dt приходит уже зажатым; модуль не читает время движка.

---

## Acceptance Criteria

*From GDD `design/gdd/player-control-barista-movement.md`, scoped to this story:*

- [ ] Первый шаг после принятия цели при прямой 2.0 м и dt = 1/60 смещает на 4.0/60 ~= 0.0667 м (допуск 1e-4): полная скорость без разгона и замедления; то же на следующих шагах (AC 22).
- [ ] Путь (0,0)->(0.4,0)->(0.4,0.4)->(0.4,1.4) при скорости 4.0 и dt = 0.25 (лаг, 1.0 м) приводит в (0.4, 0.6) +/- 0.001: пройдены две путевые точки, угол не срезан; шаг длиннее остатка пути останавливается на последней точке без проскока (AC 23).
- [ ] `facing` (XZ) обновляется по направлению последнего сегмента и доступен для выбора 4-направленной анимации.

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/core/barista_controller.gd::step` - внутренний цикл `while left > 0.0 and not _path.is_empty()` уже корректен (проверен слайсом); выделить его в pure-класс `PathFollower`.

- `PathFollower.advance(position, path, speed, dt) -> {position, path_remaining, facing}` или мутация своего состояния - выбрать вариант, удобный для тестов без сцены.
- `remove_at(0)` на `PackedVector3Array` - O(n), пути короткие; допустим индекс вместо удаления, если это упростит тест.
- Скорость - `ControlMath.effective_speed` (story 001), никаких литералов 4.0 в коде.
- Анимации/спрайт - story 010; здесь только геометрия.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: состояния и принятие целей.
- Story 010: отображение направления.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player_control/player_control_path_follower_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 008
