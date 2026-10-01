# Epics Index

Last Updated: 2026-10-01 (stories created: 161 total)
Engine: Godot 4.7.2 (GDScript, Compatibility renderer)
Source: design/gdd/systems-index.md (12 MVP-систем) + docs/architecture/architecture.md (Module Ownership) + docs/architecture/tr-registry.yaml

Код переносится из `prototypes/tea-rush-vertical-slice/` в `src/`; каждое EPIC.md перечисляет исходники для переноса.
Telegram-требования (TR-platform-002/003/004/014/015) отложены и в эпики не берутся.

| Epic | Layer | Module | GDD | Active TRs | Stories | Status |
|------|-------|--------|-----|-----------|---------|--------|
| [Foundation Runtime (Clock, Director, Config, Save)](foundation-runtime/EPIC.md) | Foundation | GameClock · MatchDirector · ConfigLoader · SaveStore · UtcClock · Rng | —  (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD) | 3 | 9 stories | Ready |
| [Platform Shell (Web)](platform-shell/EPIC.md) | Foundation | PlatformBridge + HTML-оболочка + web-экспорт | design/gdd/platform-integration-telegram-mini-app.md | 11 | 8 stories | Ready |
| [View Fit & Camera](view-fit/EPIC.md) | Foundation | ViewFit (+ view_fit_math) | design/gdd/kitchen-station-layout.md, design/gdd/hud-feedback-ui.md | 10 | 7 stories | Ready |
| [Kitchen & Station Layout](kitchen-layout/EPIC.md) | Foundation | KitchenLayout | design/gdd/kitchen-station-layout.md | 13 | 7 stories | Ready |
| [Order & Recipe System](recipe-book/EPIC.md) | Core | RecipeBook | design/gdd/order-recipe-system.md | 14 | 7 stories | Ready |
| [Player Control / Barista Movement](barista-control/EPIC.md) | Core | TapPicker · BaristaController · Pathing | design/gdd/player-control-barista-movement.md | 19 | 11 stories | Ready |
| [Brewing & Crafting](brewing/EPIC.md) | Feature | Brewing | design/gdd/brewing-crafting-mechanic.md | 12 | 8 stories | Ready |
| [Guest AI & Patience + Match Lifecycle](guest-sim/EPIC.md) | Feature | MatchLifecycle · GuestSim | design/gdd/guest-ai-patience.md | 23 | 11 stories | Ready |
| [Difficulty Curve & Session Pacing](difficulty-curve/EPIC.md) | Feature | DifficultyCurve | design/gdd/difficulty-curve-session-pacing.md | 11 | 6 stories | Ready |
| [Currency: Coins & Score](currency/EPIC.md) | Feature | Currency | design/gdd/currency-coins-score.md | 14 | 6 stories | Ready |
| [Till & Day Cycle](till/EPIC.md) | Feature | Till | design/gdd/till-day-cycle.md | 13 | 6 stories | Ready |
| [Player Stats](player-stats/EPIC.md) | Feature | PlayerStats | design/gdd/player-stats.md | 1 | 6 stories | Ready |
| [Visual Pipeline (Lighting, Toon Shader, Quality Tiers)](visual-pipeline/EPIC.md) | Presentation | KitchenView (рендер) · материалы · уровни качества | design/art/art-bible.md | 11 | 14 stories | Ready |
| [Art Assets (MVP content)](art-assets/EPIC.md) | Presentation | assets/art/* (контент для KitchenView, HUD, GameFlow) | design/art/art-bible.md | 0 | 13 stories | Ready |
| [HUD & Feedback UI (in-match)](hud/EPIC.md) | Presentation | HUD | design/gdd/hud-feedback-ui.md | 25 | 11 stories | Ready |
| [Game Flow (Menus & Out-of-Match Screens)](game-flow/EPIC.md) | Presentation | GameFlow | design/ux/game-flow.md | 20 | 13 stories | Ready |
| [Audio & Juice Feedback](audio-juice/EPIC.md) | Presentation | AudioDirector · Haptics | design/gdd/audio-juice-feedback.md | 16 | 18 stories | Ready |

## Порядок

1. **Sprint 1 — фундамент + визуальные спайки:** `foundation-runtime`, `platform-shell`, `view-fit`, `kitchen-layout`; параллельно spike S1–S5 из `visual-pipeline` (S5 — перспективная камера-диорама, 2026-10-01) и пилот `art-assets` (один персонаж + одна станция).
2. **Core + Feature:** `recipe-book`, `barista-control`, `brewing`, `guest-sim`, `difficulty-curve`, `currency`, `till`, `player-stats`.
3. **Presentation:** `hud`, `game-flow`, `audio-juice`, полное производство `art-assets`.
