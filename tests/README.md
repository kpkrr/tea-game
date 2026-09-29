# Test Infrastructure

**Engine**: Godot 4.7.2 (GDScript)
**Test Framework**: GdUnit4 v6.2.1 — committed in `addons/gdUnit4/`
**CI**: `.github/workflows/tests.yml` (gdUnit4-action v1.3.2, `version: installed`)
**Setup date**: 2026-09-30

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic) — one subfolder per system
  integration/    # Cross-system tests, SaveStore round-trips, config load, navigation bake
  smoke/          # Critical path list for the /smoke-check gate
  gdunit4_runner.gd  # headless entry point (project.yaml commands.test)
```

```
production/qa/
  evidence/       # Screenshot logs, perf evidence and manual sign-off records
```

> Manual evidence lives under `production/qa/evidence/`, not `tests/` — that is
> where `/smoke-check`, `/test-evidence-review` and `/qa-plan` read it.

## Running Tests

```bash
# all tests (what CI and /smoke-check run)
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/gdunit4_runner.gd

# one folder or suite — any gdUnit4 option after the script path
... --script tests/gdunit4_runner.gd -a res://tests/unit/view_fit
```

Exit code 0 = all passed; 100 = failures (verified 2026-09-30 with a deliberate
failing test). With no `-a` the runner adds `-a res://tests`; headless mode is
allowed because our suites do not depend on UI input events. HTML/XML reports go
to `reports/` (gitignored).

In the editor: enable the plugin (Project → Project Settings → Plugins → GdUnit4)
to get the GdUnit inspector panel. It is not required for the CLI.

Upgrading GdUnit4: replace `addons/gdUnit4/` with the new release and bump the
version note here; CI uses the committed copy, never `latest`.

## Test Naming

- **Files**: `[system]_[feature]_test.gd`
- **Functions**: `test_[scenario]_[expected]`
- **Example**: `game_clock_pause_test.gd` → `test_advance_while_hidden_returns_zero()`

## Project rules that shape tests (ADR-0003/0004/0005/0006)

- Logic lives in `RefCounted` classes with injected clock, `Rng`, config and
  storage — unit tests construct them directly, no `SceneTree`.
- Configs come from a `ConfigFactory` in memory, never from `.tres` on disk
  (one integration test loads the shipped `game_config.tres`).
- Randomness: `FakeRng` (scripted) or `SeededRng` with a recorded seed.
- Persistence: `MemoryBackend`. Navigation: `FakeNavigator`; real-server
  integration tests must call `Pathing.dispose()` in teardown.
- No timing assertions (determinism); on-device timings are evidence files.

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Manual walkthrough OR interaction test | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run on every push to `main` and every pull request. A failed suite
blocks merging.

`tests/unit/framework/framework_smoke_test.gd` only proves the toolchain; delete
it once the first real Logic test lands.
