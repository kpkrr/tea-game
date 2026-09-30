# ADR-0001: Web build & platform shell

## Status
Accepted

> Accepted 2026-09-30 by the owner. Open items (not blockers): WebGL2-unsupported fallback page and mid-match rotation not yet verified on device; `create_callback` on Android Chrome assumed equal to iPhone Safari. OQ 4 closed at acceptance: `prefers_reduced_motion()` / `reduced_motion_changed` added to the contract.

## Date
2026-09-30

## Last Verified
2026-10-01 (game-flow amendment: capability surface only — W1–W7 not yet run on device); 2026-09-30 (audio amendment revised the same day: Sample vs Stream behaviour checked against the Godot `4.7.2-stable` source tag)

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

**Export configuration: single-thread, host-agnostic.** Web export preset ships with **Thread Support: OFF**, and an export template with unused engine features disabled to reduce payload size. This requires no `Cross-Origin-Opener-Policy`/`Cross-Origin-Embedder-Policy` headers and therefore runs on any static HTTPS host — the actual hosting provider is not decided by this ADR and is deferred to `release-manager`/`devops-engineer`, with the hard requirements being **HTTPS** (the 4.7.2 web loader refuses to start outside a secure context — *"Secure Context — Check web server configuration (use HTTPS)"* — even in the single-thread build; observed on a phone over plain LAN HTTP during the spike, 2026-09-30; only `localhost` is exempt), `.wasm` served as `application/wasm`, and gzip/brotli compression. This is the conservative default under Architecture Principle 5 ("no threads, no heavy post-processing, without on-device measurement") and matches Godot's own documented recommendation for 2D-leaning games; it also sidesteps the unverified iOS SharedArrayBuffer risk noted in `modules/web.md` entirely, rather than depending on it working out. If the real-device spike later shows single-thread performance is genuinely insufficient, that is a new decision (see Consequences → Negative), not a retrofit of this one.

**HTML shell.** A custom minimal wrapper (not Godot's full default export page) does, in order:
1. A plain-JS `canvas.getContext('webgl2')` capability check, *before* the engine's `.wasm`/loader script is even requested. Failure renders a static "please update your browser" page and the engine is never loaded (TR-platform-011) — this check lives entirely outside Godot, so it works even when the engine itself could never have started.
2. A loading screen with a progress bar driven by the standard web-export loading callback, kept visible with no hard timeout until `PlatformBridge.ready_reached` fires (TR-platform-006).
3. A CSS cross-fade from the loading screen to the game canvas — canvas stays at `opacity: 0` until the first frame is confirmed drawable, then fades in over the loading screen's fade-out — to avoid the white-flash failure mode Godot's canvas init can otherwise produce (TR-platform-018).

**`PlatformBridge` (Foundation autoload).** Owns the safe-area rect and `Loading`/`Ready`/`Failed` state (`Failed` added by ADR-0004: invalid config → `fail_boot(message)`, the shell shows a static "reload the page" screen and `ready_reached` is never emitted); the sole source of `safe_area_changed(rect)`, `visibility_changed(visible)`, `ready_reached`.
- *Safe area*: the **value** is always `DisplayServer.window_get_size()` — window px, i.e. CSS px × `devicePixelRatio` while `display/window/dpi/allow_hidpi` is on (it is) — never `innerWidth`/`innerHeight`, which are CSS px and would be off by the DPR in ADR-0002's conversion and ADR-0007's render scale. `get_viewport().size_changed` plus a JS `resize`/`orientationchange` listener are only **triggers**, coalesced through a per-frame dirty flag consumed once in `_process` — never emitted directly from the JS event handler — satisfying "no more than once per frame" (TR-platform-010) without a separate `requestAnimationFrame` timer, since Godot's own main loop is already synced to the browser's rAF cadence. This resolves AQ-05: "a frame" means one Godot `_process` tick.
- *Visibility*: **must not** use `NOTIFICATION_APPLICATION_FOCUS_IN/OUT` or `_PAUSED`/`_RESUMED` — confirmed non-functional on web export (godotengine/godot#87014), the one platform where Godot's normal cross-platform lifecycle notification is the wrong tool. Instead, the HTML shell registers a `document.visibilitychange` JS listener wired to a `JavaScriptBridge.create_callback` that calls back into GDScript, and `PlatformBridge` emits the single `visibility_changed(bool)` from that callback (TR-platform-012). The callback receives **one `Array`** of JS arguments (`func _on_js_visibility(args: Array)`), not typed parameters, and reads `document.visibilityState` itself. A page that *loads* in a background tab never fires `visibilitychange`, so `PlatformBridge` seeds its state from `document.visibilityState` at startup and exposes it via `is_visible()`; `_compose()` applies it to `MatchLifecycle` before the first match (ADR-0003). This also matters because the browser pauses `_process`/`_physics_process` entirely while backgrounded — a polling approach inside `_process` cannot work even in principle, independent of the notification bug.
- *Ready*: emitted once `ConfigLoader` validation and the kitchen scene (`KitchenLayout`) are loaded, `Pathing` reports its navigation map ready and the boot self-check passes (ADR-0006), and the first frame is drawable — drives both the HTML shell's fade transition and, per `architecture.md` §"Жизненный цикл матча", `MatchLifecycle.start()` (TR-platform-013).
- Mid-match resize never touches match state — `safe_area_changed` only reaches `ViewFit`/HUD layout, never `GameClock`/`MatchLifecycle` (TR-platform-017).

> **Amendment 2026-09-30 — audio output, mute and music (owner decisions during `/ux-design hud`; music source, playback mode and results-screen behaviour revised the same day).** MVP ships one looped music track and a HUD mute button.
> - **Track:** `assets/audio/music/music_jazz_main.ogg` (owner's file; Ogg Vorbis, stereo, 48 kHz, ≈ 102 kbps, 204.8 s, 2 608 161 B). Owner chose to raise the budget rather than trim or re-encode it.
> - **Bus layout** (`res://default_bus_layout.tres`, the `audio/buses/default_bus_layout` default): `Master` ← `Music`, `SFX`. Every `AudioStreamPlayer` sets `bus` to `Music` or `SFX` (never `Master`). Mute = `AudioServer.set_bus_mute(master_idx, muted)` in every state; bus indices are resolved once by name (`get_bus_index`). **One bus effect:** `AudioEffectLowPassFilter` at slot 0 of `Music`, disabled by default (`set_bus_effect_enabled`). `SFX` and `Master` carry no effects.
> - **Playback mode — mixed.** The web default `audio/general/default_playback_type.web` = **Sample** stays for all SFX (browser Web Audio plays the buffers; low latency, no main-thread mixing). **`MusicPlayer` alone sets `playback_type = PLAYBACK_TYPE_STREAM`.** Checked against the Godot `4.7.2-stable` source (`platform/web/audio_driver_web.cpp` `register_sample`, `platform/web/js/libs/library_godot_audio.js`, `ProjectSettings.xml`): in Sample mode (1) bus `AudioEffect`s are not applied, so the low-pass filter would do nothing; (2) the first `play()` decodes the **whole** Ogg synchronously on the main thread into a `Vector<AudioFrame>` plus a planar `PackedFloat32Array` (≈ 79 MB each at 48 kHz for this track, both in the wasm heap, which never shrinks), then JS copies it into a resident Web Audio `AudioBuffer` (≈ 79 MB). On the RD that means a multi-second stall and ≈ 160 MB of heap. In Stream mode `AudioStreamOggVorbis` keeps only its compressed `OggPacketSequence` (≈ 2.6 MB) and decodes on the fly in the engine mixer, so the filter works. Cost: the no-threads `AudioWorklet` asks the main thread for audio between frames, and a main-thread block longer than the ring buffer underruns (crackle). Mitigation: `audio/driver/output_latency.web` = **100** ms (default 50), which gives a ring buffer of 4096 frames ≈ 85 ms at 48 kHz. In 4.7.2 this value only sizes the stream ring buffer (`latencyHint` is not passed to the `AudioContext`), so Sample-mode SFX latency is unchanged. Music latency does not matter.
> - **Music is not in the `.pck`** (ADR-0007 amendment). The export preset excludes `assets/audio/music/*`, and the export/CI step copies `music_jazz_main.ogg` next to `index.html`. After `ready_reached`, `_compose()` calls `AudioDirector.start_music_fetch(url)` with an absolute URL from `PlatformBridge.asset_url("music_jazz_main.ogg")` (`new URL(name, document.baseURI).href` via `JavaScriptBridge`; `HTTPRequest` cannot take a relative URL). `AudioDirector` owns an `HTTPRequest` child (`use_threads = false`). On success it calls `AudioStreamOggVorbis.load_from_buffer(body)` (packet split only, no decode), sets `stream.loop = true` in code (import flags do not apply to a runtime-loaded stream) and drops the body. On failure: one retry after 5 s, then the session stays silent, with no error UI. Off-web (editor, tests, desktop) the same method `load()`s the `res://` path instead. The fetch starts only after `ready_reached`, so it never competes with the boot download.
> - **`AudioDirector`** (presentation `Node` in the kitchen scene, built by `_compose()` and injected with `GameClock`, `cfg.audio` and `save.scope(&"settings")`; it never references `PlatformBridge` by name): owns the bus mute, the low-pass filter, the `MusicPlayer` and `settings.muted` (ADR-0005 amendment). API: `set_muted(muted: bool)` (HUD mute button → bus mute + `write_bool`), `is_muted() -> bool` (HUD reads per frame), `on_paused_changed(paused: bool)` (connected to `MatchLifecycle.paused_changed`, ADR-0003 amendment), `on_match_started()`, `on_match_ended()`, `start_music_fetch(url: String)`.
> - **Music rules.** Music plays when all three hold: first gesture seen, stream loaded, not `hidden or user_paused`. It starts at position 0 the first time all three become true (so it simply begins when the download lands, if the player has already touched the screen).
>   - *Player pause / tab hidden* → `MusicPlayer.stream_paused = true`; on resume `false`, continuing from the same position. Because `paused_changed` is emitted synchronously inside the JS visibility callback, the music stops before the browser halts the main loop.
>   - *MatchEnd* (`match_ended`) → music keeps playing, muffled: the filter is enabled and `cutoff_hz` ramps log-linearly from 20 000 Hz (no audible filtering) to `cfg.audio.music_lowpass_cutoff_hz` over `cfg.audio.music_lowpass_ramp_s`. The ramp accumulates **`GameClock.ui_dt`** in `AudioDirector._process` (priority 0, after `MatchDirector`). `ui_dt` runs while the match is frozen and is 0 while hidden, so the ramp pauses with the page. No `Tween` (ADR-0003 §6).
>   - *"Играть снова"* (`match_started` after `Ended`) → filter disabled, cutoff reset, `MusicPlayer.play(0.0)`: the track restarts from the beginning (if unlocked and loaded; otherwise the start rule above applies later).
>   - *Mute* → Master bus only; playback, pause and filter state are unaffected (decoding continues while muted, which is accepted).
> - **Autoplay / unlock:** browsers keep the `AudioContext` suspended until a user gesture. Godot's web audio driver is expected to resume it on input (not confirmed for 4.7.2 by `docs/engine-reference/`; Verification A1). Fallback: the shell captures the engine's context by wrapping the `AudioContext` constructor before the loader runs and calls `resume()` from its own first `pointerdown`/`touchend`/`keydown` listener. `AudioDirector._input` watches for the first pressed touch / mouse button / key (never consumes it), records the gesture and stops listening. No script-driven looping. Mute state is applied at boot before any sound.
> - **Config (ADR-0004 amendment):** new `AudioConfig` sub-resource with `music_lowpass_cutoff_hz` (default 800) and `music_lowpass_ramp_s` (default 0.3), the same placeholders as the HUD UX spec.
> - **Verification (added):** (A1) iOS Safari: music starts on the first touch (not only on `touchend`/`click`), loops without a gap, and `stream_paused` pauses/resumes a Stream-mode player; (A2) hide the tab mid-match → music stops within the hide callback, and does not resume on return while user-paused; (A3) `set_bus_mute(Master)` silences Stream-mode music and Sample-mode SFX on web; (A4) iOS hardware silent switch behaviour recorded (Web Audio may be silenced by it; accepted, not overridden in MVP); (A5) Android Chrome same as A1–A3; (A6) the low-pass filter audibly muffles Stream-mode music on web at MatchEnd, and "Играть снова" restarts clean; (A7) no crackle on the RD during a 3-minute match with `output_latency.web` = 100 (if it crackles: raise to 200, then owner decision, see ADR-0007 amendment); (A8) the `HTTPRequest` fetch + `load_from_buffer` of the 2.6 MB file causes no frame > 100 ms on the RD, and the export `.pck` contains no `assets/audio/music/` entry.

> **Amendment 2026-10-01 — out-of-match flow and browser capabilities (`design/ux/game-flow.md`, owner decisions F1–F10 + author decisions M1–M14; authored autonomously, pending owner review).** The game gains a main menu, settings, How to Play, Records, PWA install, result sharing, a friend-challenge link, a rotate-your-phone overlay and a screen wake lock. Everything that touches the browser goes through `PlatformBridge` and the HTML shell, as before; no other module calls `JavaScriptBridge`.
> - **`ready_reached` no longer starts a match.** It hands over to `GameFlow` (new presentation module, `architecture.md`), which shows the main menu; the first match starts only on `request_new_match()` from Play / Start shift (ADR-0003 amendment 2026-10-01). The HUD start screen E18 is retired.
> - **Shell helper `window.teaRushPlatform`** (plain JS, defined before the loader runs, every method wrapped in `try/catch` and returning a safe default — same style as `teaRushSave`, ADR-0005). `PlatformBridge` reaches it once via `JavaScriptBridge.get_interface("teaRushPlatform")` and keeps the object untyped. Off-web every capability reports "unsupported" and every action is a no-op.
>
> | Capability | Shell side | `PlatformBridge` API |
> |---|---|---|
> | **PWA install** (M7) | Captures `beforeinstallprompt` **at page load, before the engine exists** (`preventDefault()`, keep the event); listens to `appinstalled`. `standalone` = `matchMedia('(display-mode: standalone)').matches \|\| navigator.standalone`. `isIOS` by UA/platform check (only to pick the hint text). | `can_prompt_install() -> bool`, `signal install_availability_changed(available: bool)`, `prompt_install()` (needs user activation, see below), `is_standalone() -> bool`, `is_ios() -> bool` |
> | **Share card** (M8) | `prepare(base64Png, text, url)` builds a `File` (`image/png`, `tea-rush.png`) **ahead of time**; `share()` calls `navigator.share({files, text, url})` when `navigator.canShare({files})`, else downloads the PNG via an `<a download>` Blob URL and writes the text with `navigator.clipboard.writeText`; else clipboard only. Reports the outcome through a `create_callback`. | `share_prepare(png: PackedByteArray, text: String, url: String)` (base64 via `Marshalls.raw_to_base64`), `share_prepared() -> void` call on press, `signal share_finished(result: StringName)` — `&"shared"`, `&"cancelled"`, `&"downloaded"`, `&"copied"`, `&"failed"`; `can_share_files() -> bool` |
> | **Wake lock** (M9) | `setWakeLock(on)`: keeps a "wanted" flag; while wanted and `document.visibilityState == 'visible'` holds a `navigator.wakeLock.request('screen')` sentinel, re-requests it on `visibilitychange` → visible (the browser releases it on hide). Unsupported → no-op. | `set_wake_lock(on: bool)` |
> | **Touch device / orientation** (M3) | `matchMedia('(pointer: coarse)')` seeded at boot + `change` listener (same pattern as reduced motion). | `is_coarse_pointer() -> bool`; `signal orientation_blocked_changed(blocked: bool)` — `blocked = is_coarse_pointer() and window width > window height`, computed from `DisplayServer.window_get_size()` in the **same per-frame dirty-flag pass as the safe area** (never from the raw JS handler); emitted on change only |
> | **Launch parameter** (M13) | Reads `location.search` once at boot; `clearParams()` = `history.replaceState(null, '', location.pathname + location.hash)`. | `get_launch_param(name: String) -> String` (`""` when absent), `clear_launch_params()`. Validation of the value (`?beat=` integer range) is `GameFlow`'s job, not the bridge's |
> | **External link** (M10) | `openUrl(url)` → `window.open(url, '_blank', 'noopener')`. | `open_external(url: String)` (needs user activation; off-web → `OS.shell_open`) |
> | **Vibration** (M2, M11, settings) | `canVibrate = typeof navigator.vibrate === 'function'` (false on iOS Safari); `vibrate(ms)`. | `can_vibrate() -> bool`, `vibrate(ms: int)` — called only by `Haptics` |
> | **Build version** (M6) | — | read from `ProjectSettings` `application/config/version`, not from the shell |
>
> - **User activation — the main risk of this amendment.** `navigator.share`, `window.open`, `beforeinstallprompt.prompt()` and `clipboard.writeText` require transient user activation. Godot's web platform queues DOM input and dispatches it inside its own main-loop iteration, so a GDScript button handler runs **after** the DOM event handler has returned. Chromium keeps transient activation for ≈ 5 s, so calls made from the handler in the next frame are expected to work there; Safari/WebKit's activation window is documented as shorter and less forgiving — **unverified for 4.7.2 on iOS (Verification W1)**. Therefore: (1) the share file is prepared on `match_ended`, never on press, so the press does only the synchronous `share()` call; (2) if W1 fails on iOS, the fallback is a transparent HTML `<button>` overlaid on the canvas at the rect of the Share / Install / Feedback button, positioned by `GameFlow` through `PlatformBridge.set_activation_overlay(id, rect_css_px, visible)`, whose own DOM `click` handler calls the shell action directly. The fallback is designed but only built if W1 fails.
> - **PWA build.** Use the Godot web export preset's **Progressive Web App** options (`progressive_web_app/enabled = true`, `display = standalone`, `orientation = portrait`, icons 144/180/512, background colour from the palette; `ensure_cross_origin_isolation_headers` stays **off** — the build is single-thread, see Decision). The Godot-generated service worker gives the offline cache. **Update rule:** a new deploy is picked up on the **next launch**, never mid-session: on boot `PlatformBridge` checks `JavaScriptBridge.pwa_needs_update()` and, if true, calls `JavaScriptBridge.pwa_update()` only while `GameFlow` is on the main menu before the first match (it reloads the page); the in-session `pwa_update_available` signal is logged and otherwise ignored. The names of these three members and the exact preset keys are taken from pre-4.7 knowledge — **verify against the 4.7.2 class reference before implementation (W2)**. The service worker must also cover the music file served next to `index.html` (ADR-0001 audio amendment) — check the generated SW's cache list (W3). Save data is not affected by a SW update (`localStorage`, ADR-0005 §3 newer-schema rule still guards stale caches).
> - **Loading tips (M5)** live in the HTML shell (a short inline array in `index.html`, English), because the shell shows them before the engine and `ConfigLoader` exist. They are not a `GameConfig` resource (ADR-0004 amendment 2026-10-01).
> - **Browser/Android back button** is not intercepted in MVP (no `popstate` handling).
> - **Validation (added):** (W1) iOS Safari + Android Chrome: Share opens the system sheet with the PNG from a Godot button handler; Feedback opens a new tab; Install prompt opens on Android — if any fails, build the activation overlay and retest; (W2) PWA export keys and `pwa_needs_update`/`pwa_update` exist in 4.7.2 and an updated deploy is applied on the next launch, not mid-match; (W3) installed PWA starts offline and plays music; (W4) wake lock held during a 3-minute match on Android, released on pause/menu, re-acquired after tab return; (W5) rotate a phone mid-match → `orientation_blocked_changed(true)` within one frame, match user-paused; rotate back → stays paused; PC window wider than tall → no overlay; (W6) `?beat=4250` is read once and removed from the address bar; reload does not re-apply it; (W7) `can_vibrate()` false on iOS Safari, true on Android Chrome.

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
signal reduced_motion_changed(enabled: bool) # OS/browser setting toggled while the page is open (rare; HUD re-reads)

func get_safe_area() -> Rect2            # last known value, readable without waiting on a signal
func is_visible() -> bool                # seeded from document.visibilityState at startup, then tracked
func prefers_reduced_motion() -> bool    # seeded from matchMedia('(prefers-reduced-motion: reduce)') at startup, then tracked; false off-web
func fail_boot(message: String) -> void  # Loading -> Failed (ADR-0004); called only by MatchDirector (from _compose() or its Booting-frame poll, ADR-0006)
func mark_boot_complete() -> void        # Loading -> Ready, emits ready_reached once; called only by MatchDirector after config valid + Pathing ready + verify() passed (ADR-0006) + RenderPrewarm done (ADR-0007)
func asset_url(file_name: String) -> String # amendment 2026-09-30: absolute URL of a file shipped next to index.html (post-boot music); "" off-web
# amendment 2026-10-01 (game-flow capabilities; all no-ops / "unsupported" off-web)
signal install_availability_changed(available: bool)
signal share_finished(result: StringName)          # &"shared" | &"cancelled" | &"downloaded" | &"copied" | &"failed"
signal orientation_blocked_changed(blocked: bool)  # coarse pointer and window wider than tall; same per-frame pass as safe area
func can_prompt_install() -> bool; func prompt_install() -> void; func is_standalone() -> bool; func is_ios() -> bool
func share_prepare(png: PackedByteArray, text: String, url: String) -> void   # on match_ended, never on press
func share_prepared() -> void                      # on Share press; synchronous shell call
func can_share_files() -> bool
func set_wake_lock(on: bool) -> void
func is_coarse_pointer() -> bool; func is_orientation_blocked() -> bool
func get_launch_param(name: String) -> String; func clear_launch_params() -> void
func open_external(url: String) -> void
func can_vibrate() -> bool; func vibrate(ms: int) -> void
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
- Reduced motion (accessibility-requirements.md OQ 4, TR-hud-022): `PlatformBridge` must seed `prefers_reduced_motion()` from `window.matchMedia('(prefers-reduced-motion: reduce)').matches` at startup and register a `change` listener on the same `MediaQueryList` through a second `create_callback` (kept in a member, like the visibility one); it emits `reduced_motion_changed` only on an actual change. Consumers (HUD, world overlays) must read this flag, never query the browser themselves. There is no in-game settings toggle in MVP. Off-web (editor, tests) the value is `false`.
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
| hud-feedback-ui.md (via accessibility-requirements.md OQ 4) | TR-hud-022 — reduced motion from the browser's `prefers-reduced-motion` | `prefers_reduced_motion()` + `reduced_motion_changed`, read in the shell via `matchMedia` |
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

## Spike Results (2026-09-30)

Source: `prototypes/web-spike/README.md` (session `0b7b7c05`, iPhone Safari, DPR 3). Android was **not** run — by owner decision the functional
results below are taken to hold on Android; device performance on a weak
Android is still unmeasured (ADR-0007).

- **HTTPS is mandatory:** the 4.7.2 loader refuses plain HTTP outside `localhost` ("Secure Context"), even single-thread.
- **iOS Safari runs the single-thread build** — the iOS risk is closed; iPhone stays in MVP scope.
- Cold ready 9.6 s over a phone hotspot (wasm 10.1 MB gzip downloaded in 4.4 s, ≈ 3.5 s local compile + init + scene); warm ready 1.2 s.
- `window_get_size()` = CSS px × DPR (1179×2085 for 393×695 × 3) — confirms the safe-area unit fix.
- Visibility: `visibilitychange` reached GDScript through `create_callback` (handler `args: Array`) **between frames**; the main loop stopped while hidden (1 frame in 16 s). `pagehide` did not fire on backgrounding (only on real unload), as expected.
- `localStorage` written inside the hide callback survived closing the tab (ADR-0005).
- Touch → engine ≤ 1 ms (Safari timer resolution).
- Not yet verified: WebGL2-unsupported fallback page; mid-match rotation on device; `create_callback` behaviour on Android Chrome (assumed equal).

## Related
- Will link to ADR-0002 (Viewport/camera fit), ADR-0005 (SaveStore), ADR-0007 (Perf budgets) once written — this ADR's `Enables` above records the planned relationship ahead of their existing.
- `docs/engine-reference/godot/modules/web.md` — engine reference authored alongside this ADR.
