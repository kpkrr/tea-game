# ADR-0004: Data config & load-time validation

## Status
Proposed

## Date
2026-09-30

## Last Verified
2026-09-30

## Decision Makers
Yan (product owner) · godot-specialist (engine validation 2026-09-30: no blocking issues; 4 minor notes folded into Decision, Guidelines and Risks — parser behaviour then confirmed by a headless 4.7.2 probe — Verification (1)) · technical-director review skipped (review_mode `lean`) · decisions taken under `modes.automation: autonomous`, logged in `production/session-logs/decision-log.md`

## Summary
Every GDD routes its tuning knobs through a "data file" with load-time validation (missing key, NaN/INF, out-of-range, cross-field invariants → load error, match does not start), but leaves the format, the validator, release-build behaviour and RNG injection to this ADR. Config is authored as typed custom `Resource` classes saved as `.tres` (one per system, under one `GameConfig` root), validated by a single pure `ConfigValidator` that collects every error by constant name in **all** builds; difficulty curves stay code formulas over config values, and all randomness comes from injected, per-purpose seeded `Rng` streams.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (GDScript, web export, single-thread) |
| **Domain** | Core (resources / data) |
| **Knowledge Risk** | LOW — custom `Resource` + `@export`, `ResourceLoader.load`, `RandomNumberGenerator` are pre-cutoff and have no 4.4–4.7 entries in `breaking-changes.md`; 4.5 added `Resource.duplicate_deep()` (used only in tests) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md` (4.5 `duplicate_deep()`), `deprecated-apis.md` (`duplicate()` for nested resources → `duplicate_deep()`), `current-best-practices.md` §Resources (4.5+), `modules/web.md` (single-thread: no background loading benefit); `design/registry/entities.yaml` (constants), GDD Tuning Knobs / Edge Cases of all 10 MVP GDDs |
| **Post-Cutoff APIs Used** | `Resource.duplicate_deep()` (4.5) — test fixtures only |
| **Verification Required** | (1) ✅ **Verified 2026-09-30 on installed 4.7.2 headless** (probe in session scratchpad): an omitted float field reads back as its `NAN` sentinel; `f = nan` loads as NaN; `Array[StringName]([&"cup", &"serve"])` round-trips; **wrong types are coerced silently with no error** — `"abc"` in a float field → `0.0`, `"x"` in an int field → `0`, int `7` in a float → `7.0`. Hence the mandatory shipped-values CI test (Risks). (2) In the exported web build all `assets/data/config/*.tres` are present and load (export preset "Export all resources" or explicit include; resources converted to binary are fine). (3) `ResourceLoader.load` of the config tree on the spike device adds < 50 ms to time-to-interactive. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (boot order, `ready_reached`; this ADR adds a boot-failure path to it) and ADR-0003 (composition root `MatchDirector._compose()` injects config and `Rng`; `max_step_delta` delivered from here). Both are Proposed; this ADR cannot be Accepted before them |
| **Enables** | ADR-0005 (SaveStore schema uses the same "typed + validated + defaults" rule), ADR-0006 (`agent_radius`, `tap_pick_radius`, slot IDs come from config), ADR-0007 (config load time counted in TTI; adds `ViewConfig.render_pixel_budget` (int) and `render_scale_min` (float) — validator: `0 < render_scale_min ≤ render_scale_3d ≤ 1`, budget > 0) |
| **Blocks** | ConfigLoader/ConfigValidator stories; every story that reads a tuning knob (all Feature and Core systems); DifficultyCurve and GuestSim spawn stories (RNG) |
| **Ordering Note** | ADR-0002/0003 placeholders ("one typed `Resource` owned by ViewFit / MatchDirector until ADR-0004 lands") become sub-resources of `GameConfig` under this ADR |

## Context

### Problem Statement
The ten MVP GDDs define ~40 tuning constants plus the five-recipe table and price invariants, and they agree on behaviour — "data file", load-time validation naming the constant, invalid config blocks match start, never crashes mid-match (Architecture Principle 4) — but not on mechanism. Open questions left to this ADR: file format and schema (Order & Recipe OQ "form of the load error"), what price invariants do in a release build (Order & Recipe OQ), Godot `Curve` vs formula for difficulty, and whether tier roll and recipe pick share an RNG stream (Guest AI OQ 9). Every system's first story reads config, so this must be fixed before coding.

### Constraints
- Web export, single-thread (ADR-0001): no background loading, no remote fetch in MVP.
- Unit tests must not do file I/O (coding standards) — validators and consumers must accept in-memory objects.
- Determinism: difficulty functions must return bit-identical results for the same input (TR-pacing-009); statistical tests use a recorded seed.
- Design source of truth for values is `design/registry/entities.yaml` + GDDs; the shipped data must match them.
- Only `MatchDirector._compose()` wires modules and touches autoloads (ADR-0003).

### Requirements
- Load error, naming the constant, for: missing key, NaN/INF/non-numeric, out-of-range, cross-field violations (TR-guest-017, TR-pacing-008, TR-recipe-004/005/006/007/008/013, TR-guest-002).
- Invalid config → match does not start (all GDDs; Principle 4).
- Recipes as data: `{recipe_id, steps, tier}`, exactly 5, price table lookup (TR-recipe-001/002/003/011).
- `station_types` equals placed stations (TR-layout-009); aspect and fill constants as data (TR-platform-016, TR-layout-015).
- Runtime second line of defence for difficulty outputs stays in Guest AI (TR-guest-018).
- Deterministic RNG through `FakeRng` in tests (TR-guest-020).
- Other systems' constants read-only to consumers such as HUD (TR-hud-019/020).

## Decision

**1. Format: typed custom `Resource` classes saved as `.tres`.** One `Resource` script per owning system (`ViewConfig`, `KitchenConfig`, `ControlConfig`, `RecipeConfig` + `RecipeDef`, `BrewingConfig`, `GuestConfig`, `DifficultyConfig`, `CurrencyConfig`, `TillConfig`, `HudConfig`), each field an `@export` with a static type. A root `GameConfig` references them. Files live in `assets/data/config/` (one `.tres` per system + `game_config.tres`); scripts in `src/foundation/config/`. The owning GDD's section is the source for each file; `design/registry/entities.yaml` values must match. **Missing-key detection:** every exported field defaults to a sentinel — `NAN` for floats, `-1` for ints meant to be ≥ 0, `&""` for `StringName`, empty for arrays — so a key absent from the `.tres` (or dropped by a failed type conversion) arrives as the sentinel and the validator reports it as "missing". The editor omits fields equal to the script default when saving, which is exactly what makes an unset field read back as the sentinel. Config has **no `bool` knobs** (no sentinel possible): a switch is an `int` 0/1 with −1 as sentinel. `RecipeDef`s are internal sub-resources of `recipes.tres`; the per-system files are linked from `game_config.tres` as `uid://` ExtResources.

**2. One validator, all errors, all builds.** `ConfigValidator.validate(cfg: GameConfig) -> Array[ConfigError]` is pure (no I/O, no autoloads) and runs every rule, collecting all failures instead of stopping at the first. Each `ConfigError` carries `path` (e.g. `difficulty.patience_max_end`), `rule` and a human message. Rules come straight from GDD Edge Cases/Tuning Knobs: finiteness, ranges, sentinels, direction of difficulty curves (`_end` never easier than `_start`), recipe grammar (first `cup`, exactly one trailing `serve`, steps ⊂ `station_types`, no duplicate sequences, ≥ 1 recipe per tier, price integer ≥ 1, price invariants in integers), exactly 5 recipes, `guest_slot_count` valid, `max_step_delta` > 0, `station_types` equals kitchen stations, navigation data (ADR-0006: `abs(control.agent_radius / 0.05 − round(…)) < 1e-6` and `< work_gap`; kitchen footprints pairwise non-overlapping and inside `floor_bounds`; interaction-point IDs unique, `[a-z0-9_]+`). Rules are per-system functions (`_validate_difficulty(cfg.difficulty, errors)` …) in the same class so cross-system checks (recipe steps vs kitchen `station_types`) have one home.

**3. Release behaviour: same as debug.** Price invariants and every other rule are checked in release too; validation is microseconds. The shipped config is also validated by a CI test, so a release failure means a broken build, and failing loudly beats serving wrong prices. On any error: `ConfigLoader` returns the errors, `MatchDirector._compose()` does **not** construct match modules and calls `PlatformBridge.fail_boot(message)`; the HTML shell replaces the loading screen with a static "Couldn't load the game — reload the page" screen. Debug builds additionally show the full error list on screen; all builds print each error once with `push_error`. `ready_reached` is never emitted in that case (ADR-0001 amendment: `Loading → Ready | Failed`).

**4. Immutable after load.** Config objects are loaded once at boot (init step 3), validated, then injected into modules through constructors as typed sub-resources (`GuestSim.new(cfg.guest, cfg.difficulty, …)`). No module may write to a config object or load config by path itself. A module reads other systems' constants only through the sub-resource injected into it (HUD gets `cfg.guest` for thresholds read-only).

**5. Difficulty curves are code, not `Curve` resources.** `DifficultyCurve` is a static-function class implementing the registry formulas (`progress = clamp(t / ramp_duration, 0, 1) ** curve_exponent`; linear lerp per curve) over `DifficultyConfig`. `Curve` would bake points, lose the exact-formula tests and bit-identical guarantee, and hide the design knobs behind handles.

**6. RNG: injected `Rng` interface, one stream per purpose.** `class_name Rng extends RefCounted` with `randf() -> float` (in [0, 1)) and `randi_range(from, to) -> int`. Production `SeededRng` wraps a `RandomNumberGenerator`; tests use `FakeRng` (scripted sequence) or `SeededRng` with a recorded seed. `MatchDirector` draws one `match_seed` at each `match_started` from a boot-seeded `RandomNumberGenerator` and derives named streams: `guest_tier`, `guest_recipe`, `cosmetic`. Each stream's seed is `splitmix64(match_seed ^ STREAM_CONST)` with a fixed per-stream constant — our own mix, not `hash()`, whose output is not guaranteed across engine versions. `RandomNumberGenerator` (PCG32) gives identical sequences on web and desktop for the same seed; only `seed` is set, never `state`. **Guest AI OQ 9 resolved: tier roll and recipe-within-tier pick use separate streams**, so tests can script one without affecting the other and adding a recipe to a tier never shifts the tier sequence. `match_seed` is logged in debug builds for reproduction. Global `randf()`/`randi()`/`randomize()` are banned in gameplay code.

**7. Runtime guard remains in consumers.** The validator makes invalid config unshippable; Guest AI Rule 12's spawn-time clamp/fallback of difficulty outputs (log once per match) stays in GuestSim as the second line of defence — not in the validator.

### Architecture Diagram

```
assets/data/config/
  game_config.tres ──► view.tres · kitchen.tres · control.tres · recipes.tres(RecipeDef×5)
                       brewing.tres · guest.tres · difficulty.tres · currency.tres · till.tres · hud.tres

Boot step 3:  ConfigLoader.load("res://assets/data/config/game_config.tres")
                 │ GameConfig (typed tree)
                 ▼
              ConfigValidator.validate(cfg) ─► Array[ConfigError]
                 │ empty                               │ non-empty
                 ▼                                     ▼
   MatchDirector._compose(cfg):                 PlatformBridge.fail_boot(msg)
     GuestSim.new(cfg.guest, cfg.difficulty,      → HTML shell error screen
                  rng_tier, rng_recipe, …)        → push_error ×N; debug overlay lists all
     Brewing.new(cfg.brewing, cfg.recipes) …      (ready_reached never emitted)
     HUD.bind(cfg.hud, cfg.guest /*read-only*/)
```

### Key Interfaces

```gdscript
class_name GameConfig extends Resource
@export var view: ViewConfig
@export var kitchen: KitchenConfig
@export var control: ControlConfig
@export var recipes: RecipeConfig
@export var brewing: BrewingConfig
@export var guest: GuestConfig          # includes max_step_delta (Guest AI Rule 11)
@export var difficulty: DifficultyConfig
@export var currency: CurrencyConfig
@export var till: TillConfig
@export var hud: HudConfig

class_name RecipeDef extends Resource
@export var recipe_id: StringName = &""
@export var steps: Array[StringName] = []
@export var tier: StringName = &""     # simple | medium | complex
@export var price: int = -1

class_name ConfigError extends RefCounted
var path: String      # "difficulty.patience_max_end"
var rule: StringName  # &"missing", &"not_finite", &"range", &"direction", &"invariant", …
var message: String

class_name ConfigValidator extends RefCounted
static func validate(cfg: GameConfig) -> Array[ConfigError]

class_name ConfigLoader extends RefCounted
static func load_config(path: String) -> GameConfig   # null + error if the file itself fails; never name a method `load` (shadows global)
# result + validate() are combined by MatchDirector._compose()

class_name Rng extends RefCounted
func randf() -> float                 # [0, 1)
func randi_range(from: int, to: int) -> int

class_name DifficultyCurve extends RefCounted
static func progress(t: float, c: DifficultyConfig) -> float
static func guests_per_minute(t: float, c: DifficultyConfig) -> float
static func patience_max(t: float, c: DifficultyConfig) -> float
static func complex_order_share(t: float, c: DifficultyConfig) -> float

# PlatformBridge addition (ADR-0001 amendment)
func fail_boot(message: String) -> void   # Loading -> Failed; shell shows static error screen
```

### Implementation Guidelines
- Every tuning value named in a GDD Tuning Knobs table or in `entities.yaml` must come from a `GameConfig` sub-resource; literals for them in code are forbidden (tests may use them only for boundary cases).
- Every `@export` config field must have a static type and a sentinel default; a new field must ship with its validator rule in the same change.
- `ConfigValidator` must collect all errors, must name the dotted constant path, and must run in debug and release builds alike.
- Modules must receive config through constructor injection from `MatchDirector._compose()`; they must never call `load()`/`preload()`/`ResourceLoader` for config, and must never write to a config object.
- `Rng` must be injected; gameplay code must never call global `randf()`, `randi()`, `randi_range()`, `randomize()` or create its own `RandomNumberGenerator`.
- Tier roll and recipe pick must use separate streams (`guest_tier`, `guest_recipe`); new random decisions get a new named stream rather than sharing one.
- Difficulty curves must be computed by `DifficultyCurve` static functions, never by `Curve` resources.
- Unit tests must build configs with a factory (`ConfigFactory.valid()` + field overrides, or `duplicate_deep()` of it) — never by loading `.tres` from disk; one integration test loads and validates the shipped `game_config.tres`.
- Nested config copies must use `duplicate_deep()`, not `duplicate()` (4.5+). A tree loaded from disk must be copied with `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` — the default mode does not copy external sub-files; in-memory `ConfigFactory` objects may use the default.
- Tests that load `.tres` must use `ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)` so a mutated tree never poisons the shared cache; production loads once with the default cache and treats the result as immutable by convention.
- A sentinel default must never be changed to a real value: every `.tres` that omitted the field would silently adopt it.
- The ban on global `randf()`/`randi()`/`randomize()` in `src/` must be enforced by a CI grep, not only by review (the `Rng.randf()` method name also shadows the global, so warnings are not a reliable signal).

## Alternatives Considered

### Alternative 1: JSON files parsed at boot
- **Description**: `assets/data/config/*.json` → `JSON.parse_string` → Dictionary → validator + manual mapping to typed objects.
- **Pros**: Missing keys and wrong types are naturally visible; diff-friendly; editable without the editor; could be fetched remotely later.
- **Cons**: All JSON numbers are floats (int fields need extra checks); a hand-written mapping layer duplicates the schema; non-resource files are not exported to web unless added to the export include filter (silent-omission risk); no inspector editing; `StringName` arrays need conversion.
- **Rejection Reason**: More code and one more failure mode for the same validation; the missing-key advantage is recovered with sentinel defaults. Remote tuning is not an MVP goal.

### Alternative 2: Constants in GDScript (`const` in a config script)
- **Description**: A `Tuning.gd` with `const` values.
- **Pros**: Zero loading; compile-time checked.
- **Cons**: Violates "data, not literals" (coding standards, Principle 4); cannot build invalid fixtures for validator tests; every tweak is a code change.
- **Rejection Reason**: Contradicts project standards.

### Alternative 3: Godot `Curve` resources for difficulty
- **Description**: Author the three difficulty curves as `Curve` resources.
- **Pros**: Visual editing of arbitrary shapes.
- **Cons**: Baked sampling breaks exact-formula and bit-identical tests (TR-pacing-003/009); knobs (`ramp_duration`, `curve_exponent`, `_start`/`_end`) disappear into point handles; validator cannot check "never easier over time" cheaply.
- **Rejection Reason**: GDD defines formulas, not shapes.

### Alternative 4: Invariants only in debug (`assert`)
- **Description**: Price invariants as `assert()` stripped from release.
- **Pros**: Matches the GDD's minimum ("error in debug and tests").
- **Cons**: Two behaviours to reason about; a broken release would ship wrong economy silently.
- **Rejection Reason**: Validation cost is negligible; one behaviour everywhere.

### Alternative 5: One shared RNG stream for Guest AI
- **Description**: Tier roll and recipe pick consume the same `RandomNumberGenerator`.
- **Pros**: Simplest.
- **Cons**: Scripted tests must interleave values for both; adding a recipe or a new random call shifts every later roll, invalidating recorded-seed tests.
- **Rejection Reason**: Named streams cost one line each and keep tests stable.

## Consequences

### Positive
- Configs are typed and inspector-editable; the validator is pure and fully unit-testable with in-memory fixtures.
- One failure behaviour (blocked boot, named errors) in every build.
- RNG is reproducible per match from a logged seed; tests script each decision independently.

### Negative
- Sentinel defaults must be kept consistent; a forgotten sentinel turns "missing" into a silently valid default.
- `.tres` diffs are noisier than JSON; values are duplicated between `entities.yaml` and `.tres` until a sync check exists.
- A config error now blocks the whole game rather than degrading — accepted as intended by the GDDs.

## Risks
- **Registry ↔ `.tres` drift** (value tuned in `.tres` but not in `entities.yaml`/GDD) → a **mandatory** CI test (part of the first ConfigLoader story, not deferred) asserts every shipped config value against a checked-in expected table matching `entities.yaml`; generating that table with a `tools/` script is optional later.
- **Wrong-type values coerced silently by the `.tres` parser** (confirmed on 4.7.2: the loader only calls `set()`; `"abc"` → 0.0 for a float, `"x"` → 0 for an int — plausible numbers, not the sentinel, no load error) → the mandatory shipped-values CI test above is the real guard; `0` values that are out of range are also caught by range rules.
- **Recorded seeds invalidated by an engine upgrade** → mitigated by the own `splitmix64` derivation; PCG32 itself is stable.
- **Config missing from web export** → Verification (2); the export smoke test loads `game_config.tres` in the exported build.
- **`fail_boot` path never exercised** → an integration test injects an invalid config into `_compose()` and asserts no modules are built and `fail_boot` was called.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| order-recipe-system.md | TR-recipe-001…011, -013, -014: recipe data, grammar, price table, invariants in integers; OQ "release behaviour" and "form of load error" | `RecipeConfig`/`RecipeDef`; validator rules; same behaviour in release; `ConfigError{path, rule, message}` |
| difficulty-curve-session-pacing.md | TR-pacing-001, -002, -005, -008, -009, -011: formulas as data, load validation (NaN/INF/missing/direction), determinism | `DifficultyConfig` + `DifficultyCurve` static formulas; sentinel + finiteness + direction rules |
| guest-ai-patience.md | TR-guest-002, -003, -014, -017, -018, -020; OQ 9 (RNG streams) | `GuestConfig`; validator; runtime fallback stays in GuestSim; separate `guest_tier`/`guest_recipe` streams via injected `Rng` |
| kitchen-station-layout.md | TR-layout-001, -009, -015 | `KitchenConfig`; `station_types` == placed stations rule; fill/tap constants as data |
| player-control-barista-movement.md | TR-control-006, -012 | `ControlConfig` (`base_walk_speed`, `speed_multiplier` set, `t_step`) |
| brewing-crafting-mechanic.md | TR-brewing-003, -013 | `BrewingConfig` (`t_brew_base`, `speed_multiplier`) |
| currency-coins-score.md | TR-currency-003 | `CurrencyConfig.score_multiplier_base` |
| till-day-cycle.md | TR-till-001 (capacity), -006 | `TillConfig` (`till_capacity`, `daily_reset_time_utc`) |
| platform-integration-telegram-mini-app.md | TR-platform-016 | `ViewConfig.viewport_aspect_min/max` |
| hud-feedback-ui.md | TR-hud-009, -019, -020 | `HudConfig`; foreign sub-resources injected read-only |

## Performance Implications
- **CPU**: Validation once at boot, well under 1 ms; zero per-frame cost (values read from typed fields).
- **Memory**: A few KB of resources.
- **Load Time**: ~11 small `.tres` loads at boot (Verification 3: < 50 ms on the spike device).
- **Network**: Part of the `.pck`; no separate fetch.

## Migration Plan
No production code exists. Prototype `TUNING` constants in `prototypes/kitchen-core/kitchen_core.gd` are not migrated; production config is authored fresh from the GDDs and `entities.yaml`. ADR-0002/0003 interim "single typed Resource" notes are superseded by the sub-resources here. ADR-0001 gains the `Failed` boot state and `fail_boot()`.

## Validation Criteria
- gdUnit4 `ConfigValidator`: one test per GDD load-error AC (e.g. Difficulty AC 2–4, Order & Recipe AC 12 naming both invariants, Guest AI Rule 12 constants), each asserting the dotted path in the error.
- gdUnit4 `DifficultyCurve`: registry formula values at t = 0, 90, 180, 300; bit-identical repeat calls.
- gdUnit4 `SeededRng`: same seed → same sequence per stream; streams independent.
- Integration: shipped `game_config.tres` loads and validates with zero errors; invalid config → `fail_boot` called, no modules built.
- Web export smoke: config loads in the exported build.

## Related
- Depends on: ADR-0001 (boot order; amended with `Failed`), ADR-0003 (composition root, `max_step_delta` consumer)
- Enables: ADR-0005, ADR-0006, ADR-0007
- Design: all 10 MVP GDDs (Tuning Knobs, Edge Cases), `design/registry/entities.yaml`
- Architecture: `docs/architecture/architecture.md` Principle 4, init order step 3
