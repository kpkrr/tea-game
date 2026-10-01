# Story 007: World overlays: till fill, kettle status, cup tokens (ruined silhouette), station tags

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-002`, `TR-hud-010`, `TR-hud-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Explicit stretch, perspective diorama camera (distance fit from safe_aspect, kitchen >= 95% of screen; was ortho), HUD strips, 3D environment + toon sprites, world-space overlays projected from 3D positions.
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Post-cutoff 4.7 Control/transform/viewport changes; verify world->screen projection and stretch behaviour against docs/engine-reference/godot before use.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

Мировые оверлеи: заполнение кассы (по F1) у кассы, статус чайника (EMPTY/BREWING/READY), токены шагов чашки у чашки (Pillar 2), испорченная чашка — другой силуэт, не только цвет; статичные цветовые теги станций. Переход кассы Open→Full — только акцент на кассе, без чисел в полосе.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0002): each overlay is anchored to its object's projected bounding box, never inside the HUD strips
- Required (from ADR-0003): read Brewing/Till state per frame (no cache)
- Required: ruined state must not rely on colour alone (GDD/UX accessibility)

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] Касса, чайник, гость и чашка видны одновременно: заполнение — у кассы, статус — у чайника, токены — у чашки, все в bounding box своего объекта, ни один внутри полосы (AC 1–2)
- [ ] Три скриншота чайника EMPTY / BREWING / READY показывают различный визуал на самом чайнике (AC 18)
- [ ] `till_amount = 180/250` → индикатор 0.72; на `Open→Full` акцент меняется в том же кадре, числа в полосе не добавляются (AC 19, 20)
- [ ] Чашка 2 из 3 шагов — ровно 2 токена; `ruined = true` отличима от пустой чашки с первого взгляда по силуэту (AC 16, 17, 45)
- [ ] Цветовые теги станций есть, статичны в начале и посреди партии (AC 24)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — станционные оверлеи.
- Использовать `HudMath.till_fill_ratio` из Story 003.
- Силуэт испорченной чашки — решение с art-director; до арта — контрастная форма/крестик (placeholder).
- HUD skin art (icons, frames, fonts, tokens sprites) comes from epic `art-assets`; use placeholder `StyleBox`/flat shapes until it lands.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 008: контур цели и кольцо на полу
- Story 010: плашка Till full!
- HUD skin art (icons, frames, fonts, tokens sprites) comes from epic `art-assets`; use placeholder `StyleBox`/flat shapes until it lands.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/hud-world-overlays-till-kettles-cups-evidence.md` + retained screenshot/clip + lead sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002, 003
- Unlocks: 010
