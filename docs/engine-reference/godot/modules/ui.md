# Godot UI — Quick Reference

Last verified: 2026-09-30 | Engine: Godot 4.7.2

Compiled 2026-09-30 from the `4.7.2-stable` `Control.xml` (diffed against
`4.6-stable`), the 4.6→4.7 migration guide, and a `--doctool` dump of the installed
4.7.2 editor. Unverified items are marked UNVERIFIED.

## 4.7 Changes (verified)

### Control offset-transform (new in 4.7, absent in 4.6)
Visual-only-by-default transform applied on top of layout, so containers/anchors
do not re-layout when it changes. Exact `Control` properties:

| Property | Type | Default |
|---|---|---|
| `offset_transform_enabled` | bool | `false` (all others ignored until true) |
| `offset_transform_position` | Vector2 | (0, 0) absolute |
| `offset_transform_position_ratio` | Vector2 | (0, 0) fraction of `size`; summed with position |
| `offset_transform_rotation` | float | 0.0 (radians) |
| `offset_transform_scale` | Vector2 | (1, 1) |
| `offset_transform_pivot` | Vector2 | (0, 0) absolute |
| `offset_transform_pivot_ratio` | Vector2 | (0.5, 0.5); summed with pivot |
| `offset_transform_visual_only` | bool | `true`: input still hits the original rect; `false`: input follows the visual position |

No `Tween` is needed; set the properties from any per-frame code.

### Other 4.7 Control changes
- New: `custom_maximum_size`, `propagate_maximum_size`, `get_maximum_size()`,
  `get_combined_maximum_size()`, `update_maximum_size()`, `translation_context`.
- `Control.accessibility_live` type moved to `AccessibilityServer.AccessibilityLiveMode`
  (C# incompatible).
- `RichTextLabel`: `UPDATE_WIDTH_IN_PERCENT` → `UPDATE_WIDTH_UNIT`; `add_image`/`update_image`
  `width`/`height` are `float`, `*_in_percent` → `*_unit` (`RichTextLabel.ImageUnit`).
- `TreeItem.select(column, set_as_cursor)` optional param added.

### mouse_filter (unchanged 4.6 → 4.7, verified in 4.7.2 XML)
- `Control.mouse_filter` default = `MOUSE_FILTER_STOP` (0). STOP consumes the event
  (marked handled, so it never reaches `_unhandled_input`); PASS = 1 bubbles up if
  unhandled; IGNORE = 2 does not receive and does not block.
- Per-class overrides (from `--doctool` dump of 4.7.2):
  `Label` = IGNORE, `NinePatchRect` = IGNORE, `Container` = PASS,
  `TextureRect` = PASS, `TextureProgressBar` = PASS, `PanelContainer` = STOP,
  `FoldableContainer`/`GraphNode`/`GraphFrame` = STOP. Plain `Control` = STOP,
  so a full-rect root `Control` swallows taps until set to IGNORE.
- `mouse_behavior_recursive` (INHERITED 0 / DISABLED 1 / ENABLED 2) can disable a
  whole subtree; check `get_mouse_filter_with_override()`.
- `mouse_force_pass_scroll_events` default `true` (scroll events pass up even from STOP).

### Dual focus (4.6, still current)
Mouse/touch focus is separate from keyboard/gamepad focus. Carried forward from
`breaking-changes.md` (4.5→4.6); not re-verified against 4.7 class docs. UNVERIFIED for
any 4.7 delta beyond the gamepad-window-focus change in `input.md`.

## Older Changes
- 4.5: `FoldableContainer`; recursive Control mouse/focus behavior (`*_behavior_recursive`); AccessKit screen reader; live translation preview.
- 4.4: `GraphEdit.connect_node(keep_alive)`; `RichTextLabel.push_meta(tooltip)`.

## Current API Patterns
```gdscript
# Popup slide/pop without disturbing container layout (4.7)
func pop(c: Control, t: float) -> void:
    c.offset_transform_enabled = true
    c.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
    c.offset_transform_scale = Vector2.ONE * lerpf(0.8, 1.0, t)
    c.offset_transform_position = Vector2(0.0, lerpf(24.0, 0.0, t))

# Non-interactive HUD: never let it eat taps
root.mouse_filter = Control.MOUSE_FILTER_IGNORE
```

## Common Mistakes
- Leaving a full-rect root `Control`/`PanelContainer` on `STOP` above a tap-driven world.
- Assuming a `Container` blocks input (it is PASS) but a `PanelContainer` does (STOP).
- Using `position`/`scale` for animations inside containers (re-laid-out); use `offset_transform_*`.
- Assuming offset-transform moves the hit rect (only with `offset_transform_visual_only = false`).
- Assuming `grab_focus()` affects mouse focus (keyboard/gamepad only since 4.6).
