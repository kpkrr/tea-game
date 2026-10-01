# Story 001: ControlConfig и производные значения (скорость, радиусы, t_step)

> **Epic**: Player Control / Barista Movement
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-control-barista-movement.md`
**Requirement**: `TR-control-006`, `TR-control-008`, `TR-control-011`, `TR-control-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Data config & load-time validation
**ADR Decision Summary**: Конфиг - типизированные Resource (.tres) под корнем GameConfig, поля с sentinel-значениями, единый ConfigValidator собирает все ошибки во всех сборках, конфиг неизменяем после загрузки и инжектится через конструкторы, RNG - инъектируемый.
**ADR Version**: 2026-09-30
**Secondary ADRs**: ADR-0006 (Navigation & tap picking)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Custom Resource + @export - до-cutoff API. Проверено на 4.7.2: неверные типы в .tres молча приводятся ("abc" -> 0.0), поэтому обязателен CI-тест отгружаемых значений. duplicate_deep() (4.5) - только в фикстурах тестов; .tres-деревья копировать с DEEP_DUPLICATE_ALL.

**Control Manifest Rules (derived from governing ADRs — no manifest exists)**:
- Required (from ADR-0004): каждое тюнинг-значение из GDD/entities.yaml берётся из подресурса GameConfig; литералы в коде запрещены (кроме граничных тестов).
- Required (from ADR-0004): каждый @export имеет статический тип и sentinel-значение по умолчанию; новое поле поставляется вместе с правилом валидатора в том же изменении.
- Forbidden (from ADR-0004): load()/preload()/ResourceLoader для конфига внутри модулей; запись в объект конфига после загрузки.
- Required (from ADR-0006): agent_radius существует один раз в конфиге (work_gap - clearance_margin) и потребляется одним NavMeshBaker; валидатор требует кратность 0.05 и agent_radius < work_gap.

---

## Acceptance Criteria

*From GDD `design/gdd/player-control-barista-movement.md`, scoped to this story:*

- [ ] `effective_speed = base_walk_speed x speed_multiplier`: при множителях 1.0 / 1.15 / 1.3 / 1.5 получается 4.0 / 4.6 / 5.2 / 6.0 м/с (допуск 1e-6); в MVP-конфиге множитель 1.0 (AC 21).
- [ ] `agent_radius = work_gap 0.45 - clearance_margin 0.05 = 0.40` и `body_clearance` равны из одного источника, `agent_radius < work_gap`; фикстура с `agent_radius`, не кратным 0.05 (например 0.43), или >= `work_gap` даёт ошибку валидатора (AC 24, ADR-0006 §2).
- [ ] `tap_pick_radius = round(pick_radius_factor x min_tap_target / 2)` = 28 dp (48 dp, коэффициент 1.15), целое; значение задано в dp и не пересчитывается от масштаба экрана (AC 7-8).
- [ ] `t_step = 2.0` с хранится как авторитетное значение в `ControlConfig` (потребитель - только баланс-инструменты, не runtime); валидатор требует конечное значение > 0 (TR-control-012).

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/config/control_config.gd` (14 строк, sentinel `NAN`) и метод `speed()` из `barista_controller.gd`, `roundf(...)` из `tap_picker.gd::_init`.

- Поля `ControlConfig`: `base_walk_speed`, `speed_multiplier`, `work_gap`, `clearance_margin`, `agent_radius`, `pick_radius_factor`, `path_end_tolerance`, `guest_anchor_height`, плюс `t_step`; все `@export` типизированы, sentinel `NAN`.
- `agent_radius` в слайсе - отдельное поле; ADR-0004/0006 хотят ОДНО значение: либо вычислять в `ControlMath.agent_radius(cfg)`, либо хранить и валидировать равенство `work_gap - clearance_margin` (выбрать вычисляемый вариант, если не мешает .tres).
- `ControlMath` - статический класс без состояния (`effective_speed`, `agent_radius`, `tap_pick_radius(view_cfg, control_cfg)`), чтобы формулы тестировались без сцены.
- Правила валидатора добавляются в тот же PR (ADR-0004 Guidelines): `abs(r/0.05 - round(r/0.05)) < 1e-6` и `r < work_gap`.
- `tap_pick_radius` берёт `min_tap_target` из `ViewConfig`; конвертации dp -> px нет (ADR-0002: 1 unit = 1 dp).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002-003: использование радиуса при выборе тапа.
- Story 005: запекание NavMesh с этим радиусом.
- Story 007: использование скорости.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`.*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player_control/player_control_config_test.gd` - must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (`GameConfig`/`ConfigValidator` - эпик foundation-runtime; до его готовности - фикстуры)
- Unlocks: Story 002, 005, 007
