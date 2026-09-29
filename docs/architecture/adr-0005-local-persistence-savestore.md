# ADR-0005: Local persistence (SaveStore)

## Status
Proposed

## Date
2026-09-30

## Last Verified
2026-09-30

## Decision Makers
Yan (product owner) · godot-specialist (engine validation 2026-09-30: no blocking issues; minor notes folded into Decision, Interfaces, Guidelines and Risks) · technical-director review skipped (review_mode `lean`) · decisions taken under `modes.automation: autonomous`, logged in `production/session-logs/decision-log.md`

## Summary
MVP has three pieces of state that must survive a browser restart — Currency's `best_score` and Till's `till_amount`/day state/`full_since_utc` — but on web `user://` is an IndexedDB-backed virtual FS whose sync Godot schedules from the main loop after a file closes — so a write made while the page is being hidden is not synced until the loop resumes, which may be never. This ADR defines one `SaveStore` (in-memory dictionary, owner-scoped keys, versioned JSON blob, validated read with per-key defaults) flushed at most once per tick and synchronously on page hide, with a pluggable backend: browser `localStorage` via a tiny HTML-shell helper on web, atomic `user://` file elsewhere, memory in tests.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (GDScript, single-thread web export) |
| **Domain** | Core / Platform-Web (persistence) |
| **Knowledge Risk** | HIGH for the web path (`VERSION.md`; `modules/web.md` flags `user://`→IDBFS sync timing as unresolved) — mitigated by not using `user://` on web. LOW for `JSON`, `FileAccess`, `DirAccess` |
| **References Consulted** | `docs/engine-reference/godot/modules/web.md` (§`user://` Persistence: IDBFS not synced per write, `OS.is_userfs_persistent()` false positives, private mode, `syncfs` reentrancy), `breaking-changes.md`, `deprecated-apis.md` (no persistence entries 4.4–4.7); ADR-0001 (HTML shell, `JavaScriptBridge`, visibility callback); headless 4.7.2 probe 2026-09-30 (JSON number types, parse failure, rename-over-existing) |
| **Post-Cutoff APIs Used** | None. `JavaScriptBridge.get_interface`, `JSON`, `FileAccess`, `DirAccess.rename_absolute` are pre-cutoff |
| **Verification Required** | (1) ✅ Verified on 4.7.2 headless: `JSON.stringify` → `parse` returns all numbers as `float` (950 → 950.0; 1790000000 round-trips exactly through `int()`); `JSON.parse_string("{broken")` returns `null` **and prints an engine ERROR** — use a `JSON` instance's `parse()`; `DirAccess.rename_absolute(tmp, target)` overwrites an existing target (macOS). (2) Spike device (ADR-0001): write `best_score`, then swipe the tab/app away (or close the tab) immediately, relaunch → value present. (Force-killing the browser process within ~1 s may legitimately lose the write — not a failure of this design.) (3) Private/incognito window on Chrome Android and desktop Safari: helper reports `available = false` or values vanish on window close — game still boots and plays. (4) "Clear site data" → next boot is a first launch (defaults, Till Open with 0). (5) `rename_absolute` overwrite on Windows/Linux desktop exports before any non-web ship. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (HTML shell hosts the `localStorage` helper; `JavaScriptBridge`; `visibility_changed`), ADR-0003 (end-of-tick flush slot in `MatchDirector._process`; composition root; page-hide routing through `MatchLifecycle`). Both Proposed; this ADR cannot be Accepted before them |
| **Enables** | Backend & Persistence (Vertical Slice) — `SaveStore` is its seam; ADR-0007 (boot read counted in TTI) |
| **Blocks** | SaveStore stories; Currency `best_score` persistence stories; Till persistence and cold-start reset stories |
| **Ordering Note** | Validation of loaded values follows ADR-0004's style (typed, per-field defaults, errors named) but save data is *player* data: failure falls back to defaults and never blocks boot, unlike config |

## Context

### Problem Statement
Currency must keep `best_score` across restarts and never lower it; Till must keep `till_amount`, Open/Full and `full_since_utc` across restarts and check the UTC reset on cold start (TR-currency-006/009, TR-till-005/009/011). Currency OQ asks who owns the save file. On web, Godot's `user://` lives in an in-memory FS mirrored to IndexedDB by an asynchronous sync that Godot starts from its main-loop iteration after a file is closed (Godot itself guards against overlapping syncs). Writes are therefore not durable until a later frame's sync completes, and the browser stops the main loop when the tab is hidden — exactly when a mobile user swipes the game away. Persistence must be decided before Currency and Till are built.

### Constraints
- Web first, single-thread (ADR-0001); weak Android browsers; private mode and "clear site data" exist.
- Unit tests do no file I/O (coding standards): storage is injected.
- ADR-0003: only `MatchDirector` drives per-frame work; visibility reaches the game only through `PlatformBridge.visibility_changed`, delivered from a JS callback between frames.
- Till must not read score and Currency must not read till state (Pillar 4, architecture invariants).
- Data is tiny (< 200 bytes) and changes at most a few times per 10 s (each Served).

### Requirements
- `best_score` saved locally, never decreases; written only on `match_ended` when `is_new_record` (TR-currency-006/009).
- `till_amount`, day state, `full_since_utc` survive restart; `full_since_utc` saved on transition to Full (TR-till-005/009); first launch = Open, 0 (Till AC 28).
- Corrupt or missing save → defaults, never a crash (`architecture.md` §4).
- `match_score` is never persisted (TR-currency-006 note).
- One flat schema with `schema_version`; seam for Backend & Persistence.

## Decision

**1. `SaveStore` is an in-memory model with owner scopes.** `SaveStore` (`RefCounted`) holds a `Dictionary` of primitive values (`int`, `String`, `StringName` stored as `String`), loaded once at boot (init step 4). Owners never touch keys directly: `MatchDirector._compose()` hands each owner a `SaveScope` (`save_store.scope(&"currency")`) that prefixes keys (`currency.best_score`) and exposes typed `read_int/write_int`, `read_string/write_string`. A scope can only read and write its own prefix, which enforces single-writer ownership and Pillar 4 structurally. `write_*` only updates memory and marks the store dirty.

**2. Flush policy — owners never flush.** `MatchDirector._process` calls `save_store.flush_if_dirty()` once, after tick step 5 (a new ADR-0003 step 6), so all writes from one frame (e.g. Served → Till amount + Full transition, or `match_ended` → `best_score`) become one durable write. The `_compose()`-owned visibility handler (ADR-0003 §4) calls `lifecycle.on_visibility_changed(false)` and then `flush_if_dirty()` synchronously inside the JS visibility callback — `MatchLifecycle` itself has no `SaveStore` dependency — on web this is the last reliable moment before the browser may kill the page. There is no periodic or async flush.

**3. Blob format: one versioned JSON object.** `{"schema_version": 1, "currency.best_score": 950, "till.amount": 120, "till.day_state": "open", "till.full_since_utc": 0}`. Serialized with `JSON.stringify`, parsed with a `JSON` instance's `parse()` (no engine error spam). Because JSON numbers come back as `float`, reads go through a validator that accepts only finite, integral, in-range numbers and casts with `int()`. Each key is validated independently: an invalid or missing key falls back to its owner-declared default and is logged once; valid keys are kept. An unparseable blob or an older unmigratable `schema_version` yields all defaults; the original blob is copied once via `backend.write_backup()` (web key `tea_rush.save.corrupt`, file `save.json.corrupt`) before the next overwrite. A **newer** `schema_version` than this build knows (stale cached build) yields defaults for the session and sets `persistent = false` — the newer save is never overwritten. Future versions migrate forward through `_migrate_vN_to_vN1(data)` functions applied in order.

**4. Backend by platform.** `SaveBackend` is a small interface (`read_blob`, `write_blob`, `write_backup`, `is_available`) chosen in `_compose()`:
- **Web: `WebStorageBackend`** — `localStorage` key `tea_rush.save`, reached through a helper the HTML shell defines (`window.teaRushSave = {available, read(), write(s)}`, each wrapped in JS `try/catch` returning `null`/`false`), obtained once via `JavaScriptBridge.get_interface("teaRushSave")`. `localStorage.setItem` is synchronous and does not depend on the main loop running after a hide; the browser commits it to disk shortly after (Chromium batches commits), so closing or swiping the tab away is safe, while force-killing the whole browser process within ~1 s can still lose the last write. `user://` is not used on web. `read()` may return `null`: the result is held in an untyped `Variant` and type-checked before use; the interface object is kept untyped (dynamic `JavaScriptObject` methods).
- **Desktop/editor: `FileBackend`** — `user://save.json`: write `save.json.tmp`, check `store_string()`'s `bool` result (4.4+), close, then `DirAccess.rename_absolute` over the target. Rename is atomic on POSIX but not on Windows (target removed, then moved), so `read_blob` falls back to `save.json.tmp` when `save.json` is missing.
- **Tests: `MemoryBackend`.**

**5. Unavailable storage degrades silently.** If the helper reports `available = false` (blocked storage, some private modes) or a write returns `false`, `SaveStore.persistent` becomes `false`, one warning is logged, and the game continues with an in-memory store for the session. No error screen and no MVP UI for it (a VS "progress won't be saved" hint may read `persistent`).

**6. Key ownership (MVP).**

| Key | Owner | Written | Default |
|---|---|---|---|
| `currency.best_score` | Currency | `match_ended` with `is_new_record` | 0 |
| `till.amount` | Till | every change (Served add, daily reset) | 0 |
| `till.day_state` | Till | Open↔Full transitions | `"open"` |
| `till.full_since_utc` | Till | on → Full; cleared on reset | 0 |

`match_score` and all in-match state are never saved. Settings (`settings.*`) are reserved for the UI owner when it exists.

### Architecture Diagram

```
Boot step 4: backend = WebStorageBackend | FileBackend | MemoryBackend
             SaveStore.load(backend) → parse → per-key validate → defaults for bad keys
             _compose(): Currency.new(save.scope(&"currency"), …); Till.new(save.scope(&"till"), utc_clock, …)

Frame:  MatchDirector._process
          0–5  (ADR-0003 tick) ── Currency/Till: scope.write_int(...)  → memory + dirty
          6    save_store.flush_if_dirty() ─► backend.write_blob(JSON) ─► localStorage.setItem (sync)
Hide:   JS visibilitychange ─► PlatformBridge ─► MatchDirector (_compose handler)
                                               ├─► lifecycle.on_visibility_changed(false) ─► clock.pause()
                                               └─► save_store.flush_if_dirty()   (same JS callback)
```

### Key Interfaces

```gdscript
class_name SaveStore extends RefCounted
const SCHEMA_VERSION := 1
var persistent: bool                                  # read-only (getter)
static func open(backend: SaveBackend) -> SaveStore   # never fails; defaults on any problem
func scope(owner: StringName) -> SaveScope
func flush_if_dirty() -> void                         # MatchDirector step 6 and page hide only

class_name SaveScope extends RefCounted
func declare_int(key: StringName, default: int, min_value: int, max_value: int) -> void
func declare_string(key: StringName, default: String, allowed: PackedStringArray) -> void
func read_int(key: StringName) -> int                 # validated value or declared default
func write_int(key: StringName, value: int) -> void   # memory only; marks dirty
func read_string(key: StringName) -> String
func write_string(key: StringName, value: String) -> void

class_name SaveBackend extends RefCounted             # WebStorageBackend | FileBackend | MemoryBackend
func read_blob() -> String                            # "" when nothing stored
func write_blob(blob: String) -> bool
func write_backup(blob: String) -> bool             # one-slot copy of an unreadable/unmigratable blob
func is_available() -> bool
```

HTML shell helper (ADR-0001 shell, plain JS):
```js
window.teaRushSave = {
  available: (() => { try { localStorage.setItem('__t', '1'); localStorage.removeItem('__t'); return true } catch (e) { return false } })(),
  read()  { try { return localStorage.getItem('tea_rush.save') } catch (e) { return null } },
  write(s){ try { localStorage.setItem('tea_rush.save', s); return true } catch (e) { return false } },
};
```

### Implementation Guidelines
- Owners must access persistence only through their injected `SaveScope`; they must never construct a backend, call `FileAccess`/`localStorage` directly, or call `flush_if_dirty()`.
- Every key must be declared (`declare_int`/`declare_string`) with default and range before first read; undeclared reads are an error in debug.
- `flush_if_dirty()` must be called only from `MatchDirector` step 6 and from the page-hide path; never asynchronously, never from owners.
- On web, the game must never read or write `user://` for save data and must not rely on `OS.is_userfs_persistent()`.
- Blob parsing must use a `JSON` instance's `parse()` (not `JSON.parse_string`) and must treat every number as untrusted `float`: finite, integral, in declared range, then `int()`.
- A save failure (parse, validation, backend) must never block boot or a match; it falls back to defaults and logs once.
- `match_score` and in-match state must never be written to `SaveStore`.
- `FileBackend` must write to a temp file and replace the target with `DirAccess.rename_absolute`.
- Unit tests must use `MemoryBackend`; `WebStorageBackend` is covered by the on-device spike and a web smoke test.
- `WebStorageBackend` must store `read()` results in an untyped `Variant` and check the type before converting (`null` when nothing stored or storage blocked).
- Custom slim export templates must keep the `JavaScriptBridge` module (`javascript_eval=no` is fine — it only disables `eval`).
- A save with a newer `schema_version` than the build knows must never be overwritten.

## Alternatives Considered

### Alternative 1: `user://` + `ConfigFile`/`FileAccess` on web (IDBFS)
- **Description**: Same file path on all platforms; rely on Godot's IDBFS mirroring.
- **Pros**: One code path; engine-native.
- **Cons**: Durability depends on an asynchronous sync that Godot starts from the main loop — after a tab hide the loop is halted, so a write made at hide time is not synced until the player returns (if ever); `is_userfs_persistent()` false positives make failure undetectable. (Overlapping-sync races described in `modules/web.md` apply to raw Emscripten `syncfs`; Godot's own `user://` path serialises its syncs.)
- **Rejection Reason**: Loses data in the most common mobile exit path (swipe away right after a match).

### Alternative 2: Owner-driven immediate flush on every write
- **Description**: `write()` persists immediately.
- **Pros**: Simplest mental model.
- **Cons**: Served → till add → Full transition writes 2–3 times per frame; owners take on I/O; harder to test ordering.
- **Rejection Reason**: One coalesced write per frame is equally durable with `localStorage` and cheaper.

### Alternative 3: Separate file/key per owner
- **Description**: `currency.save`, `till.save`.
- **Pros**: Physical isolation.
- **Cons**: Multiple writes per frame, partial-save states across files, two schema versions to migrate.
- **Rejection Reason**: Scopes give ownership isolation without multiplying storage.

### Alternative 4: Direct IndexedDB from JS
- **Description**: Shell helper writes to IndexedDB instead of `localStorage`.
- **Pros**: Larger quota; async-friendly.
- **Cons**: Asynchronous — same durability-on-hide problem; far more JS.
- **Rejection Reason**: Data is < 200 bytes; synchronous `localStorage` is the right tool.

## Consequences

### Positive
- Durable save at the moment of page hide on web, with no sync race.
- Ownership enforced by scopes; Pillar 4 cannot be broken by accident.
- Pure, file-free unit tests; corrupt data handled per key.
- Single seam (`SaveStore`/`SaveBackend`) for Backend & Persistence.

### Negative
- Two platform code paths (web `localStorage`, desktop file) — the web path is only testable in a browser.
- `localStorage` is per-origin: moving the game to another domain loses saves (accepted; no host change planned in MVP).
- Private mode loses progress silently in MVP (no UI hint).

## Risks
- **`localStorage` evicted by the browser** (storage pressure, Safari ITP 7-day cap on script-writable storage for sites without interaction) → players who return within 7 days are unaffected; Backend & Persistence (VS) is the real fix. Recorded as accepted MVP risk.
- **`visibilitychange` not fired on iOS Safari / bfcache navigations** → the shell also forwards `pagehide` as `visibility_changed(false)` (ADR-0001 amendment); ADR-0003 requires `visibility_changed` to be delivered synchronously (no `call_deferred`) so the hide flush runs inside the JS event.
- **JS helper missing** (shell edited, or game embedded without the shell) → `get_interface` returns `null` → treat as `available = false`; debug log names the cause.
- **Clock manipulation resets the till early** → accepted MVP risk (AQ-06, TR-till-012), unchanged by this ADR.
- **Page killed between a write and step 6 of the same frame** → impossible within one frame on single-thread web (the frame runs to completion); the only gap is a crash mid-frame, which loses at most that frame's changes.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| currency-coins-score.md | TR-currency-006, -009: `best_score` persisted locally, never decreases, written only when `is_new_record`; OQ "who owns the save file" | `currency.best_score` in Currency's `SaveScope`; SaveStore (Foundation) owns the file; Currency owns the key |
| till-day-cycle.md | TR-till-005, -009, -011: `full_since_utc` saved on Full; `till_amount` survives restart; missed midnights → one reset on cold start; AC 28 first launch = Open, 0 | `till.*` keys with defaults (0, `"open"`, 0); cold-start read at boot then Till's reset check |
| till-day-cycle.md | TR-till-012 (clock manipulation) | Unchanged accepted risk; noted |
| platform-integration-telegram-mini-app.md | Browser persistence with page hide (Platform Rule on backgrounding) | Synchronous flush in the visibility callback |

## Performance Implications
- **CPU**: One `JSON.stringify` + one `localStorage.setItem` (< 200 bytes) on frames with changes — at most a few per 10 s; well under 0.1 ms.
- **Memory**: Negligible.
- **Load Time**: One `getItem` + parse at boot (< 1 ms).
- **Network**: None.

## Migration Plan
No production code or saves exist. The prototype saves nothing. `architecture.md` §4 and the SaveStore API are updated to this ADR; ADR-0001's HTML shell gains the `teaRushSave` helper; ADR-0003's tick gains step 6 (flush) and the page-hide flush.

## Validation Criteria
- gdUnit4 (`MemoryBackend`): round-trip; missing key → default; `"950"`, `950.5`, `NaN`, negative, huge → default for that key only; unparseable blob → all defaults + backup; unknown `schema_version` → defaults; scope cannot read another owner's key; `flush_if_dirty` writes once per dirty frame and not at all when clean; failing backend → `persistent = false`, game continues.
- Integration: MatchDirector frame with Served → Till Full → one `write_blob` call containing both `till.amount` and `till.full_since_utc`; visibility hidden → flush before return.
- On-device: Verification (2)–(4).

## Related
- Depends on: ADR-0001 (shell helper, `JavaScriptBridge`, visibility), ADR-0003 (tick step 6, compose, page-hide path)
- Consistent with: ADR-0004 (validated typed reads; but save failure never blocks boot)
- Enables: Backend & Persistence (VS), ADR-0007
- Design: `currency-coins-score.md` (Core Rules 7–8, OQ), `till-day-cycle.md` (Rules 5–7, Edge Cases, AC 28/40)
- Architecture: `architecture.md` §4 Save/Load, AQ-03, AQ-06
