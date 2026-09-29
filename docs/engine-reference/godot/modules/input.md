# Godot Input — Quick Reference

Last verified: 2026-09-30 | Engine: Godot 4.7.2

Compiled 2026-09-30 from `4.7.2-stable` `InputEvent.xml`/`ProjectSettings.xml`,
`4.6-stable` for diffing, the migration guide, and a `--doctool` dump of the
installed 4.7.2 editor. Unverified items are marked UNVERIFIED.

## 4.7 Changes (verified)

### InputEvent device IDs
`InputEvent.device` constants in 4.7.2:

| Constant | Value | Meaning |
|---|---|---|
| `InputEvent.DEVICE_ID_EMULATION` | **-1** | emulated mouse from touch, or emulated touch from mouse (**already present in 4.6**) |
| `InputEvent.DEVICE_ID_KEYBOARD` | **16** | keyboard (new in 4.7) |
| `InputEvent.DEVICE_ID_MOUSE` | **32** | physical mouse (new in 4.7) |

Mouse/keyboard used raw `0` before 4.7 (some joypads also use 0). Compare through the
constants, never integers. Migration guide: "check the input event by type or compare
`InputEvent.device` to the constants."

### Touch → mouse emulation
- `input_devices/pointing/emulate_mouse_from_touch` default `true`;
  `emulate_touch_from_mouse` default `false` (4.7.2 `ProjectSettings`).
- An emulated mouse event carries `device == DEVICE_ID_EMULATION`; filtering it is the
  supported way to tell it from a real mouse.
- Ordering (emulated `InputEventMouseButton` first, then `InputEventScreenTouch`,
  same frame and position): observed by headless probe on 4.7.2 and recorded in
  `navigation.md`; **not stated in the class docs**, so UNVERIFIED as a documented guarantee.

### Gamepad
- Gamepad input now respects window focus (disabled while the window is unfocused),
  per `breaking-changes.md` (4.6→4.7). UNVERIFIED against the migration page text:
  the fetched guide does not list this item; treat as unconfirmed.
- Dual focus (4.6): mouse/touch focus separate from keyboard/gamepad focus; see `ui.md`.

## Older Changes
- 4.6: dual-focus system; editor "Select Mode" key is `v`.
- 4.5: SDL3 gamepad driver; recursive Control disable.
- 4.3: `InputEventShortcut`.

## Current API Patterns
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        handle_tap(event.position)
    elif event is InputEventMouseButton and event.pressed \
            and event.button_index == MOUSE_BUTTON_LEFT \
            and event.device != InputEvent.DEVICE_ID_EMULATION:
        handle_tap(event.position)   # real mouse only; touch already handled
```

## Common Mistakes
- Comparing `event.device == 0` for mouse/keyboard (changed in 4.7).
- Handling both the emulated mouse press and the touch for one tap.
- Non-interactive `Control`s left on `MOUSE_FILTER_STOP` swallowing taps before `_unhandled_input`.
- Assuming `grab_focus()` affects mouse focus.
