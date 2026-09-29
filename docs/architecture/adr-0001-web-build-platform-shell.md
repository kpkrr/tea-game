# ADR-0001: Web build & platform shell

## Status
Proposed

## Date
2026-09-30

## Last Verified
2026-09-30

## Decision Makers
Yan (product owner) · technical-director (architecture.md sign-off, 2026-09-30, APPROVED WITH CONDITIONS naming this ADR as the first gate) · godot-specialist (engine validation 2026-09-30: no blocking issues; 3 minor notes folded into Implementation Guidelines/Risks; claim that `class_name` may equal the autoload name rejected — Godot 4 parse error)

## Summary
Godot 4.7's web export needs an explicit thread/hosting strategy, an HTML shell that gates on WebGL2 and hides the load flash, and a `PlatformBridge` contract for safe-area and visibility that survives the browser's own main-loop pausing. This ADR picks single-thread, host-agnostic export plus a `JavaScriptBridge`-driven visibility path (Godot's built-in lifecycle notifications are confirmed broken on web), and leaves the export's real-device viability to a spike this ADR requires before it can be Accepted.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (GDScript, Compatibility renderer / WebGL2) |
| **Domain** | Platform / Web Export |
| **Knowledge Risk** | HIGH — post-cutoff (`docs/engine-reference/godot/VERSION.md`) |
| **References Consulted** | `docs/engine-reference/godot/modules/web.md` (authored 2026-09-30 for this ADR — no prior module existed), `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | `JavaScriptBridge.create_callback` for the visibility bridge (mechanism predates cutoff; the *reason* it's required — confirmed brokenness of `NOTIFICATION_APPLICATION_FOCUS_IN/OUT`/`_PAUSED`/`_RESUMED` on web, godotengine/godot#87014 — was verified this session via WebSearch, not training data); Web export preset's Thread Support toggle and Canvas Resize Policy (both stable APIs, but the compatibility rationale for leaving threads off is drawn from 4.7-era community reports, not confirmed 4.7.2-specific engine docs) |
| **Verification Required** | Real-device spike on a representative low-end Android phone (default mobile browser): cold download size, time-to-interactive, `JavaScriptBridge` visibility-callback reliability across backgrounding, touch-to-engine input latency baseline, `localStorage` save persistence across a real restart (ADR-0005). Also: confirm exact `JavaScriptBridge.create_callback` ↔ GDScript call pattern (community reports describe this as fiddly, not a solved recipe). iOS Safari/Chrome viability is **not** covered by the Android-only spike scope named in `architecture.md` — see Risks. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None — this is ADR-0001, the first ADR in the project |
| **Enables** | ADR-0002 (Viewport/camera fit consumes `safe_area_changed`), ADR-0003 (`visibility_changed`, `ready_reached`), ADR-0004 (`fail_boot`), ADR-0005 (SaveStore uses the shell's `teaRushSave` helper and the visibility callback), ADR-0006 (`mark_boot_complete` prerequisites), ADR-0007 (Perf budgets consume this ADR's spike measurements) |
| **Blocks** | All Foundation-layer stories (`PlatformBridge`, `ViewFit`, the init sequence in `architecture.md` §"Порядок инициализации") — the Technical Director's sign-off on `architecture.md` was APPROVED WITH CONDITIONS naming ADR-0001 through ADR-0005 as Accepted-before-coding gates |
| **Ordering Note** | Must not move to Accepted until the real-device spike (Verification Required, above) has actually been run and its results recorded in this file — a status flip without that spike would be exactly the deadlock `/architecture-decision accept` mode exists to prevent: a decision that looks settled while resting on unverified ground. ADR-0002 must pin stretch mode/aspect and define the window-px → viewport conversion for `safe_area_changed` |

## Context

### Problem Statement
Tea Rush ships as a single web build (Godot 4.7, WebGL2/Compatibility renderer), targeting phone and PC browsers, MVP scope fixed to plain standalone web only (Telegram Mini App deferred 2026-09-30). Nothing yet decides: how the engine is exported (threaded vs. single-thread, and what that implies for hosting), what the HTML wrapper around the engine does before and during load, or how the platform layer (`PlatformBridge`) turns raw browser signals (resize, orientation, tab visibility) into the two contracts every other Foundation module depends on: a safe-area rect and a single visibility signal. Godot's web target is the one domain in this project with no prior verification at all — no engine-reference module existed before this session, and `architecture.md`'s own Technical Director sign-off made resolving this domain, including a real-device spike, an explicit precondition for starting any code.

### Constraints
- Engine pinned at Godot 4.7.2, Compatibility renderer (WebGL2 is the only rendering path web export supports — not a choice this ADR makes, a constraint it inherits).
- Target device class: "слабом Android" (weak/low-end Android) in its default mobile browser is the named performance floor (`architecture.md` TD condition, Architecture Principle 5).
- Telegram Mini App is explicitly out of scope for MVP (2026-09-30 scope decision) — this ADR covers Standalone Web only; the `PlatformBridge` contract must not assume or require a Telegram context.
- No backend exists yet; all persistence is local — on web through `localStorage` via the shell helper, not `user://`/IndexedDB (ADR-0005 owns the detail; this ADR only hosts the helper).
- `docs/engine-reference/godot/` had zero web-domain coverage before this session — every claim in this ADR is either sourced from the new `modules/web.md` (itself dated 2026-09-30, WebSearch-derived) or explicitly marked unverified.

### Requirements
- Must produce one HTML5/WebGL2 build at one URL, working in both phone and PC browsers (TR-platform-001).
- Must gate engine load on a WebGL2 capability check — no WebGL2 means a static, non-Godot fallback page, and the engine must never attempt to load (TR-platform-011).
- Must show a loading screen with progress until the kitchen scene is ready, with no hard timeout (TR-platform-006), and must transition Loading→Ready without a white flash (TR-platform-018).
- Must recompute the safe area (the browser viewport, measured in window px) on resize/orientationchange, recomputed no more than once per frame (TR-platform-005, -010).
- Must expose exactly one visibility signal regardless of *how* the browser signals backgrounding (TR-platform-012).
- Must not reset match state on a mid-match resize (TR-platform-017).
- Must reach a `Ready` state that starts the first match (TR-platform-013, consumed by `MatchLifecycle` per `guest-ai-patience.md` Rule 13).

## Decision

**Export configuration: single-thread, host-agnostic.** Web export preset ships with **Thread Support: OFF**, and an export template with unused engine features disabled to reduce payload size. This requires no `Cross-Origin-Opener-Policy`/`Cross-Origin-Embedder-Policy` headers and therefore runs on any static HTTPS host — the actual hosting provider is not decided by this ADR and is deferred to `release-manager`/`devops-engineer`, with the only hard requirement being that it serves `.wasm` with the correct MIME type (`application/wasm`) and ideally gzip/brotli compression. This is the conservative default under Architecture Principle 5 ("no threads, no heavy post-processing, without on-device measurement") and matches Godot's own documented recommendation for 2D-leaning games; it also sidesteps the unverified iOS SharedArrayBuffer risk noted in `modules/web.md` entirely, rather than depending on it working out. If the real-device spike later shows single-thread performance is genuinely insufficient, that is a new decision (see Consequences → Negative), not a retrofit of this one.

**HTML shell.** A custom minimal wrapper (not Godot's full default export page) does, in order:
1. A plain-JS `canvas.getContext('webgl2')` capability check, *before* the engine's `.wasm`/loader script is even requested. Failure renders a static "please update your browser" page and the engine is never loaded (TR-platform-011) — this check lives entirely outside Godot, so it works even when the engine itself could never have started.
2. A loading screen with a progress bar driven by the standard web-export loading callback, kept visible with no hard timeout until `PlatformBridge.ready_reached` fires (TR-platform-006).
3. A CSS cross-fade from the loading screen to the game canvas — canvas stays at `opacity: 0` until the first frame is confirmed drawable, then fades in over the loading screen's fade-out — to avoid the white-flash failure mode Godot's canvas init can otherwise produce (TR-platform-018).

**`PlatformBridge` (Foundation autoload).** Owns the safe-area rect and `Loading`/`Ready`/`Failed` state (`Failed` added by ADR-0004: invalid config → `fail_boot(message)`, the shell shows a static "reload the page" screen and `ready_reached` is never emitted); the sole source of `safe_area_changed(rect)`, `visibility_changed(visible)`, `ready_reached`.
- *Safe area*: the **value** is always `DisplayServer.window_get_size()` — window px, i.e. CSS px × `devicePixelRatio` while `display/window/dpi/allow_hidpi` is on (it is) — never `innerWidth`/`innerHeight`, which are CSS px and would be off by the DPR in ADR-0002's conversion and ADR-0007's render scale. `get_viewport().size_changed` plus a JS `resize`/`orientationchange` listener are only **triggers**, coalesced through a per-frame dirty flag consumed once in `_process` — never emitted directly from the JS event handler — satisfying "no more than once per frame" (TR-platform-010) without a separate `requestAnimationFrame` timer, since Godot's own main loop is already synced to the browser's rAF cadence. This resolves AQ-05: "a frame" means one Godot `_process` tick.
- *Visibility*: **must not** use `NOTIFICATION_APPLICATION_FOCUS_IN/OUT` or `_PAUSED`/`_RESUMED` — confirmed non-functional on web export (godotengine/godot#87014), the one platform where Godot's normal cross-platform lifecycle notification is the wrong tool. Instead, the HTML shell registers a `document.visibilitychange` JS listener wired to a `JavaScriptBridge.create_callback` that calls back into GDScript, and `PlatformBridge` emits the single `visibility_changed(bool)` from that callback (TR-platform-012). The callback receives **one `Array`** of JS arguments (`func _on_js_visibility(args: Array)`), not typed parameters, and reads `document.visibilityState` itself. A page that *loads* in a background tab never fires `visibilitychange`, so `PlatformBridge` seeds its state from `document.visibilityState` at startup and exposes it via `is_visible()`; `_compose()` applies it to `MatchLifecycle` before the first match (ADR-0003). This also matters because the browser pauses `_process`/`_physics_process` entirely while backgrounded — a polling approach inside `_process` cannot work even in principle, independent of the notification bug.
- *Ready*: emitted once `ConfigLoader` validation and the kitchen scene (`KitchenLayout`) are loaded, `Pathing` reports its navigation map ready and the boot self-check passes (ADR-0006), and the first frame is drawable — drives both the HTML shell's fade transition and, per `architecture.md` §"Жизненный цикл матча", `MatchLifecycle.start()` (TR-platform-013).
- Mid-match resize never touches match state — `safe_area_changed` only reaches `ViewFit`/HUD layout, never `GameClock`/`MatchLifecycle` (TR-platform-017).

### Architecture Diagram

```
HTML shell (plain JS, no engine)
  ├─ WebGL2 check ──fail──► static "update your browser" page (engine never loads)
  │        └─pass──► load .wasm, show loading screen (progress, no timeout)
  ├─ document.visibilitychange ─JavaScriptBridge.create_callback─► PlatformBridge.visibility_changed(bool)
  └─ resize/orientationchange ─────────────────────────────────►  PlatformBridge (dirty flag)
                                                                        │ consumed once/_process
                                                                        ▼
PlatformBridge ──safe_area_changed(rect)──► ViewFit ──► (Kitchen, HUD layout)
       │
       ├──visibility_changed(visible)──► MatchLifecycle ──► GameClock.pause()/resume()
       └──ready_reached──► HTML shell (fade Loading→Ready) + MatchLifecycle.start()
```

### Key Interfaces

```gdscript
# platform_bridge.gd — registered as autoload "PlatformBridge"; no class_name (a class_name equal to the autoload name is a parse error in Godot 4)
extends Node
signal safe_area_changed(rect: Rect2)    # window px = DisplayServer.window_get_size() (CSS px × DPR with allow_hidpi on); ViewFit/ADR-0002 converts to viewport coords
signal visibility_changed(visible: bool) # single source of truth for both directions
signal ready_reached()                   # WebGL2 confirmed + ConfigLoader + KitchenLayout + Pathing ready (ADR-0006)

func get_safe_area() -> Rect2            # last known value, readable without waiting on a signal
func is_visible() -> bool                # seeded from document.visibilityState at startup, then tracked
func fail_boot(message: String) -> void  # Loading -> Failed (ADR-0004); called only by MatchDirector (from _compose() or its Booting-frame poll, ADR-0006)
func mark_boot_complete() -> void        # Loading -> Ready, emits ready_reached once; called only by MatchDirector after config valid + Pathing ready + verify() passed (ADR-0006) + RenderPrewarm done (ADR-0007)
```

### Implementation Guidelines
- Export with **Thread Support: OFF**; compile with unused features stripped from the export template.
- Set **Canvas Resize Policy: Adaptive** (`html/canvas_resize_policy=2`, the default; canvas follows the browser window). Not `Project` (1) — that sizes the canvas from project settings and would break the "safe area = browser viewport" contract; not `None` (0). *(Corrected 2026-09-30 during ADR-0002 authoring — earlier draft said `Project`, verified against the 4.7 `EditorExportPlatformWeb` class reference.)*
- Do not rely on the 4.7 stretch default (`canvas_items`/`expand`): stretch mode/aspect is pinned explicitly by ADR-0002 (TR-platform-007). `safe_area_changed` carries window pixels; conversion to stretched viewport coordinates is ADR-0002's job, never the consumer's guess.
- Run the WebGL2 probe on a throwaway canvas (not the engine's `<canvas>`), or release it via `WEBGL_lose_context` before the loader starts.
- Before finalising the shell, diff the hand-rolled probe against the capability checks in the generated 4.7 loader JS (`Engine`); the gate must be at least as strict as the engine's own requirements, otherwise a browser passes the gate and fails inside Godot init (defeats TR-platform-011).
- Implement `visibility_changed` only via `JavaScriptBridge.create_callback` + `document.visibilitychange`. Never via `NOTIFICATION_APPLICATION_*` on this platform.
- The shell must also forward `pagehide` to the same callback as `visible = false` (iOS Safari / bfcache may skip `visibilitychange`); duplicates are harmless because `PlatformBridge` emits only on state change (ADR-0005).
- The HTML shell must define the `window.teaRushSave` `localStorage` helper specified in ADR-0005.
- The `JavaScriptObject` returned by `create_callback` must be kept in a `PlatformBridge` member variable for the app's lifetime; a local is garbage-collected and the callback silently stops firing (noted by ADR-0003 engine validation, 2026-09-30).
- Coalesce resize/orientationchange into one `safe_area_changed` per `_process` tick via a dirty flag; never emit synchronously from the raw JS handler.
- The safe-area value must come from `DisplayServer.window_get_size()`; `innerWidth`/`innerHeight` may be used only as a trigger. Keep `allow_hidpi` on unless ADR-0002's fallback is taken (then window px = CSS px and ADR-0007's render scale must be re-derived).
- The `create_callback` handler takes a single `args: Array`.
- Run the WebGL2 check in plain JS in the HTML shell, strictly before requesting the engine's loader script.
- Do not treat `OS.is_userfs_persistent()` as authoritative (documented false-positive behavior) — `SaveStore` (ADR-0005) must design around that, not this module.
- Do not introduce `SharedArrayBuffer`-dependent code paths under an assumption threads might be toggled on later without a new/superseding ADR.

## Alternatives Considered

### Alternative 1: Threaded export + hosting selected for COOP/COEP support
- **Description**: Enable Thread Support in the export preset; require the hosting provider (or a CDN layer in front of it) to send `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.
- **Pros**: Full engine threading performance headroom, most relevant on the named weak-Android floor.
- **Cons**: Locks in a hosting constraint before any spike data exists to justify it; inherits the unverified iOS Safari/SharedArrayBuffer failure mode noted in `modules/web.md` with no mitigation; violates Architecture Principle 5 (no unmeasured risk).
- **Rejection Reason**: The performance this buys is not yet known to be needed, and the cost (hosting lock-in + an unverified platform risk) is paid immediately regardless.

### Alternative 2: Threaded export + PWA/service-worker header injection
- **Description**: Keep Thread Support on, but use the Web export's Progressive Web App option to install a service worker that applies COOP/COEP itself, avoiding a hosting-provider dependency.
- **Pros**: Recovers host-agnosticism while keeping thread performance.
- **Cons**: Adds a whole additional runtime layer (service worker lifecycle, caching, update flow) whose interaction with this exact engine version's threading requirement is itself undocumented from this session's research — compounds unverified risk rather than removing it.
- **Rejection Reason**: Trades one unverified risk (hosting headers) for a different, arguably larger one (service-worker/WASM interaction), for a performance gain that is still unmeasured.

### Alternative 3: Native app shell (Capacitor/Cordova WebView) instead of a plain browser page
- **Description**: Wrap the web build in a thin native app shell for distribution, rather than a plain URL.
- **Pros**: Could sidestep some mobile-browser inconsistencies (e.g. iOS Safari quirks) by controlling the WebView directly.
- **Cons**: Out of the fixed MVP scope — the 2026-09-30 scope decision fixed MVP to plain standalone web, and this reintroduces exactly the kind of platform-context branching the same decision removed by deferring Telegram.
- **Rejection Reason**: Scope, not technical merit — explicitly out of bounds for this ADR.

## Consequences

### Positive
- No hosting-provider constraint — any static HTTPS host works, keeping `devops-engineer`'s later choice unconstrained by this decision.
- Removes the iOS SharedArrayBuffer failure mode from the threading axis entirely (it may still exist for other reasons — see Risks).
- Matches Godot's own documented compatibility recommendation and this project's own Architecture Principle 5, rather than fighting either.
- The WebGL2 gate and Loading→Ready fade are implemented entirely in plain JS/CSS outside the engine, so they work even in the WebGL2-unsupported branch where nothing Godot-side ever runs.

### Negative
- Leaves engine-side performance headroom on the table that threads could unlock — acceptable now because it is unmeasured, not because it is assumed unnecessary; if the spike shows a real deficit, that becomes a new (or superseding) ADR, not a silent scope change here.
- The `JavaScriptBridge.create_callback` visibility wiring is confirmed *necessary* but not confirmed *easy* — community reports describe developers struggling with the exact call pattern; this ADR commits to the approach before that pattern is proven in this codebase.
- Export template "unused features disabled" is a documented technique without a documented number — the actual payload size this produces for Tea Rush is unknown until built and measured.

## Risks
- **iOS Safari/Chrome may not run the web export at all**, independent of the threading decision (community reports, unconfirmed for 4.7.2). The Android-only spike scope named in `architecture.md`/session state does **not** cover this. *Mitigation*: either extend the spike to include one iOS device before this ADR is Accepted, or explicitly accept iOS as an out-of-scope/known-risk platform for MVP — this ADR does not resolve that choice and flags it as open (see Open Question below) rather than deciding it unilaterally, since "browser ПК и телефона" in `game-concept.md` does not currently exclude iPhone.
- **`JavaScriptBridge` visibility callback reliability while the main loop is browser-paused is unconfirmed.** *Mitigation*: the real-device spike must explicitly test backgrounding→foregrounding, not just load performance.
- **`IDBFS.syncfs()` reentrancy race** — moot: ADR-0005 does not use `user://` on web.
- **Synchronous JS callbacks are a single-thread property.** ADR-0005's hide-time flush relies on the visibility callback running synchronously inside the browser event; threaded builds deliver callbacks asynchronously. *Mitigation*: any ADR that turns Thread Support on must revisit ADR-0005.
- **Two scaling systems compound** (browser canvas resize × Godot stretch mode, whose 4.7 default changed). *Mitigation*: this ADR fixes the unit of `safe_area_changed` (window px); ADR-0002 must pin stretch mode/aspect and own the conversion — flagged in Ordering Note.
- **WebGL2 probe interfering with the engine's context** or being narrower than the engine's own capability checks. *Mitigation*: Implementation Guidelines (throwaway canvas; diff against the generated loader).
- **Export template size is unmeasured.** *Mitigation*: forwarded to ADR-0007 (perf budgets) as the number this ADR's spike must produce.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| platform-integration-telegram-mini-app.md | TR-platform-001 — one HTML5/WebGL2 build, one URL | Single-thread, host-agnostic export; one static bundle, any HTTPS host |
| platform-integration-telegram-mini-app.md | TR-platform-005 — safe area from innerWidth/Height on resize/orientationchange (Standalone branch) | `PlatformBridge` safe-area pipeline: JS listener (trigger) → dirty flag → `DisplayServer.window_get_size()` (window px) → `safe_area_changed` |
| platform-integration-telegram-mini-app.md | TR-platform-006 — loading screen with progress, no hard timeout | HTML shell step 2 |
| platform-integration-telegram-mini-app.md | TR-platform-010 — safe-area recompute ≤ once/frame | Dirty-flag coalescing consumed once per `_process` tick |
| platform-integration-telegram-mini-app.md | TR-platform-011 — no WebGL2 → static fallback, engine never loads | Plain-JS capability check before the engine loader script is requested |
| platform-integration-telegram-mini-app.md | TR-platform-012 — one visibility signal | `JavaScriptBridge`-driven `document.visibilitychange` → single `visibility_changed(bool)` |
| platform-integration-telegram-mini-app.md | TR-platform-013 — `Ready` starts the first match | `ready_reached` → `MatchLifecycle.start()` |
| platform-integration-telegram-mini-app.md | TR-platform-017 — mid-match resize doesn't reset match state | `safe_area_changed` scoped to `ViewFit`/HUD only, never to `GameClock`/`MatchLifecycle` |
| platform-integration-telegram-mini-app.md | TR-platform-018 — Loading→Ready with no white flash | HTML shell CSS cross-fade, canvas hidden until first frame drawable |
| till-day-cycle.md | TR-till-012 — device clock manipulation, accepted MVP risk | This ADR provides no trusted external clock; noted here because the platform shell is where a future trusted-time source would need to be introduced, and none is in scope for MVP |

## Performance Implications
- **CPU**: Single-thread trades some headroom for host-agnosticism and lower unverified-risk surface; revisit only with spike evidence of a real deficit.
- **Memory**: WASM heap size depends on the export template's feature set; not yet measured.
- **Load Time**: No hard-coded budget yet — `architecture.md` AQ-01 defers the number to this ADR's spike; the Loading→Ready UX (progress bar, no timeout, no white flash) is designed to make whatever that number turns out to be tolerable rather than to hit a specific target.
- **Network**: One static bundle, no special hosting headers required; `.wasm` must be served with correct MIME type and ideally compressed.

## Migration Plan
Not applicable — greenfield project, no existing web build to migrate from.

## Validation Criteria
- Real-device spike executed on a representative low-end Android phone, default mobile browser: bundle size, cold time-to-interactive, `JavaScriptBridge` visibility-callback reliability across backgrounding, touch-to-engine latency baseline, `localStorage` save persistence across an actual restart — recorded in this file before `/architecture-decision accept ADR-0001` is run.
- WebGL2-unsupported path manually verified: static fallback renders, no engine load attempted.
- Loading→Ready transition verified with a retained screenshot (no white flash) per `coding-standards.md` run-and-observe requirement.
- Resize/orientationchange mid-match verified not to reset match state.
- iOS Safari/Chrome viability explicitly decided (tested or explicitly accepted as out of scope) before Accepted — see Risks.

## Related
- Will link to ADR-0002 (Viewport/camera fit), ADR-0005 (SaveStore), ADR-0007 (Perf budgets) once written — this ADR's `Enables` above records the planned relationship ahead of their existing.
- `docs/engine-reference/godot/modules/web.md` — engine reference authored alongside this ADR.
