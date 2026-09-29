# Godot Web Export — Quick Reference

Last verified: 2026-09-30 | Engine: Godot 4.7.2

This module did not exist before this entry (post-cutoff HIGH-risk gap flagged
in `VERSION.md`). Content below is compiled from `docs.godotengine.org/en/4.7`,
official GitHub issue threads, and community reports via WebSearch on
2026-09-30 — not from training data. Where a claim could not be sourced from
the 4.7 docs specifically, that is stated explicitly rather than implied.

## What Changed Since ~4.6 (near/at LLM cutoff)

Web export as a subsystem is not called out in the 4.6→4.7 migration guide
(`breaking-changes.md`) beyond the general items already listed there (Input
device IDs, GUI offset-transform, stretch-mode defaults). No web-specific
breaking change is documented for 4.7 itself; the risk in this domain is
**absence of prior verification**, not a known regression.

## Rendering Constraint (verified, stable since 4.0)

- Godot 4.x web export **can only target WebGL 2.0**, via the **Compatibility**
  rendering method. Forward+ and Mobile rendering methods are not available on
  web. This project already pins `rendering: Compatibility` in `project.yaml`
  — consistent with the only option web export supports.
- Safari has historically had WebGL 2.0 compatibility issues; Chromium-based
  browsers and Firefox are the documented recommendation for desktop testing.

## Threads vs. Single-Thread (the central open question for ADR-0001)

Two export configurations exist, and the choice is **explicit, not a default
Godot picks for you**:

| Mode | Requirement | Trade-off |
|---|---|---|
| **Threaded** (Web export preset → Thread Support: on) | Page must be served with `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` HTTP response headers, over HTTPS (cross-origin isolation). Without these, the browser refuses `SharedArrayBuffer` and the game fails to load (commonly seen as a white/black screen or an explicit `SharedArrayBuffer is not defined` error). | Full engine performance; but the two response headers are a **hosting-level requirement** — not every static host lets you set them (GitHub Pages historically does not; itch.io needs "SharedArrayBuffer support" enabled per-project; a host you fully control, or Cloudflare Pages/Workers with custom headers, can). |
| **Single-threaded** (Thread Support: off at export time) | No special headers, runs on any static host over plain HTTPS. | Some performance cost; this is Godot's own documented recommendation for "maximum compatibility," explicitly called a "fine deal for most 2D games." |
| **Fallback for threaded without header control** | Web export preset → Progressive Web App → Enable. This installs a service worker that can apply the isolation headers itself, as a documented workaround when you cannot configure the origin server. | Adds PWA/service-worker complexity; not verified against this project's hosting choice — the interaction with the unresolved hosting decision (AQ-01 in `architecture.md`) is itself open. |

**iOS note found during research (not yet verified against 4.7 specifically):**
community reports describe Godot 4 web exports failing to run on iOS
Safari/Chrome due to upstream `SharedArrayBuffer` + WebGL2 interaction bugs on
that platform. This is a mobile-Safari-specific report, not confirmed against
4.7.2, and is exactly the kind of claim the real-device spike (ADR-0001) exists
to confirm or refute — do not treat it as settled without the spike.

## `user://` Persistence on Web (IndexedDB)

- On HTML5 export, `user://` is a virtual filesystem backed by **IndexedDB**,
  not a real disk. It is **not synced automatically on every write** the way a
  native `FileAccess` write is durable — the WASM runtime (Emscripten IDBFS)
  requires an explicit sync call to flush the in-memory FS to IndexedDB.
- The engine exposes `OS.is_userfs_persistent()` to check whether persistence
  is available at all, but the docs explicitly warn it **can produce false
  positives** — a passing check does not guarantee a write survived.
- Persistence requires the browser to allow IndexedDB/cookies for the origin.
  **Private/incognito browsing prevents persistence.** If the game runs inside
  an iframe (relevant only if a Telegram Mini App path is ever revisited),
  **third-party cookies must also be enabled**, which most mobile browsers
  restrict by default.
- Underlying Emscripten `IDBFS.syncfs()` has a known reentrancy hazard:
  overlapping sync calls can race on the same IndexedDB transaction, and in
  some reported cases the completion callback simply never fires. Two
  concurrent `flush()` calls from `SaveStore` is a real failure mode to design
  against, not a theoretical one.
- *Clarification (godot-specialist, 2026-09-30, from engine source, not docs)*: for
  `user://` Godot's web OS itself schedules one sync from the main-loop iteration after a
  file closes and skips starting a second while one runs, so the overlapping-`syncfs` race
  applies to raw Emscripten use, not Godot's `user://` path. The remaining hazard is that
  the sync waits for the next main-loop iteration — which does not happen while the tab
  is hidden. ADR-0005 therefore uses `localStorage` for saves on web.
- **Practical implication for ADR-0005 (SaveStore)**: `flush()` timing and
  whether it must be awaited/confirmed before treating a save as durable is
  unresolved from docs alone and needs the same on-device spike.

## Page Visibility / Background Behavior (verified, not project-specific)

- The browser **automatically pauses Godot's main loop when the tab is not
  the active tab** — `_process()` and `_physics_process()` stop firing on
  their own, independent of anything the project does. Running the game in
  its own window rather than a background tab avoids this browser-level pause.
- **`NOTIFICATION_APPLICATION_FOCUS_IN`/`_OUT` (and `_PAUSED`/`_RESUMED`) are
  confirmed NOT to fire reliably on web export** (tracked upstream as a known
  gap, e.g. godotengine/godot#87014). **Do not use Godot's built-in
  application-lifecycle notifications as the visibility source on web** — this
  is a web-specific limitation, unlike every other platform where those
  notifications are the correct primary path.
- **Architectural implication**: `PlatformBridge`'s `visibility_changed`
  signal must be built from a **JS-side `document.visibilitychange` listener
  wired through `JavaScriptBridge.create_callback`**, calling back into
  GDScript explicitly — this is the only path confirmed to work by community
  reports, though those reports describe developers "struggling" to call a
  GDScript function correctly from the JS callback, so the exact call pattern
  needs to be worked out and confirmed during implementation, not assumed
  correct from this summary. It cannot rely on a polling check inside
  `_process()` either, because `_process()` itself is already halted by the
  time visibility changes.

## `JavaScriptBridge`

Godot's docs reference a dedicated JS-interop page but this research pass did
not extract its full 4.7 API surface (callable registration, eval, download
handling). **Not sourced in enough detail to state API specifics here** — the
implementer should read `docs.godotengine.org/en/4.7/tutorials/scripting/cross_language_scripting.html`-adjacent
JavaScriptBridge docs directly during ADR-0001 implementation, not rely on
this summary for exact call signatures.

## Canvas / Viewport Resizing

- By default the canvas automatically matches the browser window size.
- **Canvas Resize Policy** export setting (`html/canvas_resize_policy`, per
  the 4.7 `EditorExportPlatformWeb` class reference): `0 None` — canvas is not
  resized; `1 Project` — canvas size comes from ProjectSettings (closer to a
  native window, does NOT follow the browser); `2 Adaptive` (default) — canvas
  resizes to fill as much of the page as possible. Relevant to how `PlatformBridge` reads
  `innerWidth`/`innerHeight` and to the debounce behavior TR-platform-010
  requires (no more than one safe-area recompute per frame).

## Export Template Size / Profile

Docs recommend compiling an **optimized export template with unused engine
features disabled** to reduce WebAssembly payload size significantly, but do
not give a concrete MB figure — actual payload size is project-specific and
was already flagged in `architecture.md` (AQ-01) as something only the spike
measures, not something a docs read can answer.

## Common Mistakes / Gotchas

- Assuming threaded export "just works" on any static host — it silently
  requires COOP/COEP headers that most simple hosts (GitHub Pages, plain S3)
  do not send by default.
- Assuming `OS.is_userfs_persistent() == true` guarantees a write survived a
  browser restart — it is documented to false-positive.
- Assuming `_process()`-based polling can observe tab backgrounding — the
  browser already halts the loop before that polling code would run again.
- Assuming iOS Safari behaves like desktop Safari for WebGL2/SharedArrayBuffer
  — community reports (not yet confirmed for 4.7.2) describe it as broken
  outright on some builds; this is exactly what the real-device spike must
  confirm before ADR-0001 can be Accepted.
- **Assuming `NOTIFICATION_APPLICATION_FOCUS_IN/OUT` or `_PAUSED/_RESUMED`
  detects tab backgrounding on web** — confirmed broken upstream
  (godotengine/godot#87014); this is the one platform where the standard
  cross-platform lifecycle notification is not the right tool.

## Sources

- [Exporting for the Web — Godot Engine (4.7) documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html)
- [Deploying Godot 4 HTML exports with cross-origin isolation · Rafael Epplée](https://www.rafa.ee/articles/deploying-godot-4-html-exports/)
- [Unable to run Godot without the use of threads and `SharedArrayBuffer` on the web platform · Issue #85938 · godotengine/godot](https://github.com/godotengine/godot/issues/85938)
- ["SharedArrayBuffer is not defined" error after a web build · Issue #93508 · godotengine/godot](https://github.com/godotengine/godot/issues/93508)
- [IndexedDB not working on HTML5 export — Godot Forum](https://forum.godotengine.org/t/indexeddb-not-working-on-html5-export/21179)
- [IDBFS not persistent? — emscripten-discuss](https://groups.google.com/g/emscripten-discuss/c/byDUVI7r-P4)
- [NOTIFICATION_APPLICATION_FOCUS_IN/OUT does not work in web exports · Issue #87014 · godotengine/godot](https://github.com/godotengine/godot/issues/87014)
- [\[Web\] Audio not muting on tab change / document.visibilitychange not detected — Godot Forum](https://forum.godotengine.org/t/web-audio-not-muting-on-tab-change-document-visibilitychange-not-detected-godot-4-3/124243)
