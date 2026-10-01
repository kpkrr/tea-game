# Story 003: Top strip: score plate, strike icons, till counter and fill ratio

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-001`, `TR-hud-009`, `TR-hud-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Explicit stretch, perspective diorama camera (distance fit from safe_aspect, kitchen >= 95% of screen; was ortho), HUD strips, 3D environment + toon sprites, world-space overlays projected from 3D positions.
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0004: Data config & load-time validation (Last Verified 2026-09-30)
- ADR-0007: Performance & load budgets (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Post-cutoff 4.7 Control/transform/viewport changes; verify world->screen projection and stretch behaviour against docs/engine-reference/godot before use.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

Постоянные элементы полосы: `match_score`, счётчик кассы, 3 иконки страйков (`guests_lost`), кнопки паузы/звука резервируются слотами. Формула F1: `till_fill_ratio = till_amount / till_capacity`, вычисляется каждый кадр. На 9:20 страйки и счёт не скрываются; при верхней полосе < 56 dp резервируется `hud_min_strip_dp`.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0002): HUD is always the top row; if the strip is < `hud_min_strip_dp` (56 dp) it is reserved and the kitchen stays inside its rect
- Required (from ADR-0004): `till_capacity` read from Till config, ratio computed per frame (no cache)
- Guardrail (from ADR-0007): HUD CPU within its per-system ms allocation; no per-frame allocations in `_process`

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] В Active в полосе ровно два постоянных числа (счёт, касса) и 3 иконки страйков, из них ровно `guests_lost` погашены; страйк не скрывается при 9:20 (AC 21, 46, 53)
- [ ] `till_fill_ratio`: 180/250 = 0.72; 250/250 = 1.0; 0/250 = 0.0; монотонно для всего домена [0, 250] (AC 35–38)
- [ ] При верхней полосе < 56 dp (640×640, 560×640) резервируется 56 dp, все 4 постоянных элемента влезают (AC 59)
- [ ] Retained-скриншоты на 360×800, 9:20 и 640×640

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — `_build_top_strip`/score/strikes.
- `till_fill_ratio` вынести в чистую статическую функцию (`HudMath`) для unit-теста — pure-логика без узлов.
- Анимация счётчика (snap vs smooth): счёт — snap по событию, кольца/плавные — сглаживаются (TR-hud-017 в Story 006).
- HUD skin art (icons, frames, fonts, tokens sprites) comes from epic `art-assets`; use placeholder `StyleBox`/flat shapes until it lands.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 007: заполнение кассы на мировом объекте
- Story 009/мute-кнопка: логика пауза/звук (кнопки — только слот здесь)
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
- UI: `production/qa/evidence/hud-top-strip-score-strikes-till-evidence.md` + retained screenshot/clip + lead sign-off
- Additionally (Logic part): `tests/unit/hud/till_fill_ratio_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002
- Unlocks: 007, 010
