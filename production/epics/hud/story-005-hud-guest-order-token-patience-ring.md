# Story 005: Guest order token and patience ring (Approaching, Waiting, layering)

> **Epic**: HUD & Feedback UI (in-match)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/hud-feedback-ui.md`
**Requirement**: `TR-hud-002`, `TR-hud-005`, `TR-hud-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Viewport, camera fit & 2.5D presentation
**ADR Decision Summary**: Explicit stretch, perspective diorama camera (distance fit from safe_aspect, kitchen >= 95% of screen; was ortho), HUD strips, 3D environment + toon sprites, world-space overlays projected from 3D positions.
**ADR Version**: 2026-09-30
**Secondary ADRs**:
- ADR-0003: Match simulation - clock, tick order, pause (Last Verified 2026-09-30)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Post-cutoff 4.7 Control/transform/viewport changes; verify world->screen projection and stretch behaviour against docs/engine-reference/godot before use.

**Port source**: `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state)

Мировой оверлей гостя: жетон заказа (цвета шагов рецепта + цена ≥ 12 dp со значком монеты) и кольцо терпения. Появляются уже в `Approaching` (масштаб и прозрачность 0,7), в `Waiting` — поверх остальных; исчезают на первом кадре после `Served`/`Leaving`.

**Control Manifest Rules (this layer)** *(derived from ADRs — no manifest)*:
- Required (from ADR-0002): overlays are world-projected, drawn above sprites, each guest independent (ID-keyed)
- Required (from ADR-0004): thresholds (`patience_warn_threshold`, approach alpha/scale) from HudConfig
- Forbidden (from ADR-0003): caching `remaining_fraction` between frames

---

## Acceptance Criteria

*From `design/gdd/hud-feedback-ui.md`, scoped to this story:*

- [ ] В кадре спавна (Approaching) жетон и кольцо видны у гостя с scale/alpha 0,7 (AC 8, Core Rule 4)
- [ ] Жетон для `black_tea_lemon` показывает точный маппинг цветов шагов рецепта + цену; на 360×800 при 4 гостях цена ≥ 12 dp со значком монеты (AC 9, 60)
- [ ] `remaining_fraction` 0.8 → заполнение 0.8, «спокойное»; 0.61→0.59 переключает цвет на кадре перехода; два гостя с одним рецептом имеют независимые жетоны (AC 11, 12, 44)
- [ ] На первом кадре после `Served`/`Leaving` жетон и кольцо не рендерятся; Waiting-гость A рисуется поверх Approaching-гостя B (AC 10, 13, 52)

---

## Implementation Notes

- Port from `prototypes/tea-rush-vertical-slice/src/presentation/hud.gd` (bring to standards: static typing, doc comments, DI, no cached state) — жетон/кольцо слайса.
- Цвета шагов рецепта — Pillar 2; маппинг данные из Order & Recipe (RecipeBook), не хардкод.
- Пул узлов по 4 слотам гостей, без аллокаций в `_process`.
- reduced-motion для пульса кольца — в Story 010.
- HUD skin art (icons, frames, fonts, tokens sprites) comes from epic `art-assets`; use placeholder `StyleBox`/flat shapes until it lands.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 006: пульс ухода и попапы
- Story 010: опция reduced-motion
- Story 007: жетоны чашки

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`; Visual/UI evidence is not waived (see coding-standards: a parse check is not a run).*

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/hud-guest-order-token-patience-ring-evidence.md` + retained screenshot/clip + lead sign-off
- Additionally (Logic part): `tests/unit/hud/patience_ring_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002
- Unlocks: 006, 010
