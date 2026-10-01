# Story 008: Selected-target outline and destination ring

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-021`, `TR-hud-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Explicit stretch, perspective diorama camera (distance fit from safe_aspect, kitchen >= 95% of screen; was ortho), HUD strips, 3D environment + toon sprites, world-space overlays projected from 3D positions.
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Post-cutoff 4.7 Control/transform/viewport changes; verify world->screen projection and stretch behaviour against docs/engine-reference/godot before use.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

Контур выбранной цели (станция/гость) и кольцо на полу меняются в том же кадре, что и цель Player Control; предыдущая цель гасится.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0003): target read from Player Control per frame; same-frame update
- Required (from ADR-0002): outline/ring drawn in world space

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] Цель — станция или гость: вокруг неё контур; цель — пол: кольцо в точке назначения (AC 48, 49)
- [ ] Смена цели новым тапом скрывает контур/кольцо прежней и показывает новые в том же кадре (AC 50)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — target highlight.
- Точный вид — из `design/ux/hud.md` (qa-lead note 6); зафиксировать в evidence.
- HUD skin art (icons, frames, fonts, tokens sprites) comes from epic `art-assets`; use placeholder `StyleBox`/flat shapes until it lands.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Player Control: выбор цели
- Art: финальный шейдер контура

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/hud-target-outline-and-floor-ring-evidence.md` + retained screenshot/clip + lead sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002
- Unlocks: None
