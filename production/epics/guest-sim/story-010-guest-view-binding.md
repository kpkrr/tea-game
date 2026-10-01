# Story 010: GuestView: AnimatedSprite3D, 4 направления, якорь кольца терпения

> **Epic**: Guest AI & Patience + Match Lifecycle
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/guest-ai-patience.md`
**Requirement**: `TR-guest-023`, `TR-guest-024`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit, presentation
**Secondary ADRs**: ADR-0003: Match simulation — clock, tick order, pause (Version 2026-09-30)
**ADR Decision Summary**: Гости и бариста — AnimatedSprite3D (4 направления, бок зеркалится), unshaded; оверлеи (токен заказа, кольцо терпения) — Sprite3D/Label3D детьми сущности с фиксированным camera-facing.
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: MEDIUM (sprite/оверлеи в Compatibility renderer — проверка на устройстве)

Связка данных GuestSim с вью. Сами спрайты (4 архетипа гостей) — epic `art-assets`; рендер кольца/токенов — epic `hud`; здесь — нода гостя, направление анимации, пауза по `running_changed`, контракт данных кольца.

**Control Manifest Rules (from ADR; no manifest at this tier)**:
- Required: гость — `AnimatedSprite3D`, unshaded; оверлеи — дети сущности (from ADR-0002)
- Forbidden: оверлеи как `Control` с `unproject_position` на гостя (from ADR-0002)
- Required: sim-модули — `RefCounted` с `step(dt)`; без `_process`/`_physics_process`, без `Time`/`OS`/`Engine` времени (from ADR-0003)
- Forbidden: `get_tree().paused`, `_physics_process`, ссылки на autoload по имени, лямбды и `.bind()` в сигналах между RefCounted, `CONNECT_DEFERRED` (from ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/guest-ai-patience.md`, scoped to this story:*

- [ ] Гость = `AnimatedSprite3D` (unshaded), именованные анимации в 4 направлениях (бок зеркалится); направление выбирается по вектору движения; на паузе анимация стоит, возобновляется по `running_changed` (с плейсхолдер-ассетами).
- [ ] Вью отдаёт HUD `patience_level` (calm / warn / urgent по порогам 0.60 / 0.25) и `remaining_fraction`; кольцо-якорь — billboard-дочерняя нода, снимается мгновенно при Served/Leaving (без fade).
- [ ] Скриншот сцены с 4 гостями на уровнях calm / warn / urgent сохранён в `production/qa/evidence/` (AC 47).

---

## Implementation Notes

Новый код вью (в слайсе вью смешан с логикой). Подписка на `guest_spawned`/`guest_served`/`guest_left`; `GameTimeSprite` читает `clock.is_running()` в `_ready` и подписывается на `running_changed` (ADR-0003 §6). Уровень тревоги — `patience_level()` из GuestSim (порт из слайса, Formula 4). Ассеты подставлять плейсхолдерами до готовности art-assets.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- art-assets epic: финальные спрайты 4 архетипов
- hud epic: рендер кольца, токена заказа, цветов/пульса

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/Feel and UI evidence is not waived (see coding-standards).*

**Story Type**: Visual/Feel
**Required evidence**:
- `production/qa/evidence/guest-view-binding-evidence.md` + sign-off (retained screenshot)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 004, 005, 008
- Unlocks: См. таблицу зависимостей эпика
