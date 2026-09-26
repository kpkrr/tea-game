# Godot — Breaking Changes

Last verified: 2026-09-26

Changes between Godot versions, focused on post-LLM-cutoff changes (4.4+).

## 4.6 → 4.7 (Jun–Aug 2026 — POST-CUTOFF, HIGH RISK)

Source: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html

| Subsystem | Change | Details |
|-----------|--------|---------|
| Physics (Jolt) | `WorldBoundaryShape3D.plane.d` sign reversed | Existing WorldBoundaryShape3D planes using Jolt will behave inverted — check plane orientation after upgrading. |
| Physics (Jolt) | `SoftBody3D.mass` default `0` → `1 kg` | Existing soft bodies relying on the old default gain mass they didn't have before. |
| Physics (Jolt) | `SoftBody3D.linear_stiffness` application changed | Soft body behavior tuning may need re-calibration. |
| Physics (Jolt) | `Area3D` now reports overlaps with `SoftBody3D` | New overlap signals may fire where they didn't before. |
| Physics | `AudioStreamPlayer.area_mask` default `1` → `0` | Audio players no longer pick up area reverb/effects by default. |
| Input | Mouse/keyboard device IDs change to `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` | Code comparing raw device-ID integers must switch to the named constants. |
| Input | Gamepad input now respects window focus (disabled when unfocused) | A background window no longer receives gamepad events — check any always-on-gamepad assumptions. |
| Rendering | `LinearToSRGB` visual shader no longer clamps to `[0.0, 1.0]` | Shaders relying on the implicit clamp need an explicit `clamp()`. |
| Rendering | `CanvasItem` line drawing drops antialiasing feather | Lines render visibly thinner than in 4.6. |
| GUI | `Control` offset-transform now independent of layout | Enables slide/fade animations without affecting container layout — not breaking by itself, but changes how some anchored layouts resolve. |
| GUI | `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` renamed | Renamed to `UPDATE_WIDTH_UNIT` (GDScript source incompatible). |
| GUI | `RichTextLabel.add_image()`/`update_image()` signature changed | `width`/`height` now `float` (was `int`); `width_in_percent`/`height_in_percent` renamed to `width_unit`/`height_unit` and retyped to `RichTextLabel.ImageUnit`. Default changed `false` → `0`. |
| Audio | `AudioEffectSpectrumAnalyzer.tap_back_pos` removed | No replacement property named in the migration guide — remove any reference. |
| Core | `Object.is_class()` parameter type `String` → `StringName` | Source-compatible in GDScript; check any C# call sites. |
| Core | `OptimizedTranslation.generate()` return type `void` → `bool` | C# binary incompatible — recompile against 4.7. |
| Animation | `Animation.length` property metadata `float` → `double` | C# incompatible — recompile. |
| GDScript | Packed array element assignment no longer calls setter | Code relying on a setter firing on `packed_array[i] = x` must call the setter explicitly. |
| GDScript | Methods inheriting typed returns now require an explicit `return` statement | A method that previously fell through without returning may now be a compile error. |
| Editor | `EditorSceneFormatImporter` import-flag constants moved into `ImportFlags` enum | `IMPORT_ANIMATION`, `IMPORT_DISCARD_MESHES_AND_MATERIALS`, `IMPORT_FAIL_ON_MISSING_DEPENDENCIES`, `IMPORT_FORCE_DISABLE_MESH_COMPRESSION`, `IMPORT_GENERATE_TANGENT_ARRAYS`, `IMPORT_SCENE`, `IMPORT_USE_NAMED_SKIN_BINDS` — C# source incompatible. |
| Project defaults | Stretch mode/aspect | `disabled`/`keep` → `canvas_items`/`expand` — a fresh 4.7 project scales differently by default than a fresh 4.6 one did. Relevant here: this project is not yet scaffolded, so it will get the new defaults directly. |
| Project defaults | `LookAtModifier3D.relative` | `true` → `false` |
| Project defaults | `ProjectSettings.rendering/reflections/sky_reflections/roughness_layers` | `7` → `8` |
| Project defaults | `ResourceImporterDynamicFont.hinting` | `1` → `3` |

## 4.5 → 4.6 (Jan 2026 — POST-CUTOFF, HIGH RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Physics | Jolt is now the DEFAULT 3D physics engine | New projects use Jolt automatically. Existing projects keep their setting. Some HingeJoint3D properties (like `damp`) only work with GodotPhysics. |
| Rendering | Glow processes BEFORE tonemapping | Was after tonemapping. Scenes with glow will look different. Adjust intensity/blend in WorldEnvironment. |
| Rendering | D3D12 default on Windows | Was Vulkan. For better driver compatibility. |
| Rendering | AgX tonemapper new controls | White point and contrast parameters added. |
| Core | Quaternion initializes to identity | Was zero. Unlikely to affect most code but technically breaking. |
| UI | Dual-focus system | Mouse/touch focus now separate from keyboard/gamepad focus. Visual feedback differs by input method. |
| Animation | IK system fully restored | CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK via SkeletonModifier3D nodes. |
| Editor | New "Modern" theme default | Grayscale replaces blue-tint. Restore: Editor Settings → Interface → Theme → Style: Classic |
| Editor | "Select Mode" keybind changed | New "Select Mode" (v key) prevents accidental transforms. Old mode renamed "Transform Mode" (q key). |
| 2D | TileMapLayer scene tile rotation | Scene tiles can now be rotated like atlas tiles. |
| Localization | CSV plural form support | No longer requires Gettext for plurals. Context columns added. |
| C# | Automatic string extraction | Translation strings auto-extracted from C# code. |
| Plugins | New EditorDock class | Specialized container for plugin docks with layout control. |

## 4.4 → 4.5 (Late 2025 — POST-CUTOFF, HIGH RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| GDScript | Variadic arguments added | Functions can accept `...` arbitrary params — new language feature |
| GDScript | `@abstract` decorator | Abstract classes and methods now enforceable |
| GDScript | Script backtracing | Detailed call stacks available even in Release builds |
| Rendering | Stencil buffer support | New capability for advanced visual effects |
| Rendering | SMAA 1x antialiasing | New post-processing AA option |
| Rendering | Shader Baker | Pre-compiles shaders — reportedly 20x faster startup on some demos |
| Rendering | Bent normal maps, specular occlusion | New material features |
| Accessibility | Screen reader support | Control nodes work with accessibility tools via AccessKit |
| Editor | Live translation preview | Test GUI layouts in different languages in-editor |
| Physics | 3D interpolation rearchitected | Moved from RenderingServer to SceneTree. API unchanged but internals differ. |
| Animation | BoneConstraint3D | New: AimModifier3D, CopyTransformModifier3D, ConvertTransformModifier3D |
| Resources | `duplicate_deep()` added | New explicit method for deep duplication of nested resources |
| Navigation | Dedicated 2D navigation server | No longer a proxy to 3D navigation; smaller export for 2D games |
| UI | FoldableContainer node | New accordion-style container for collapsible UI sections |
| UI | Recursive Control behavior | Disable mouse/focus interactions across entire node hierarchies |
| Platform | visionOS export support | New platform target |
| Platform | SDL3 gamepad driver | Delegated gamepad handling to SDL library |
| Platform | Android 16KB page support | Required for Google Play targeting Android 15+ |

## 4.3 → 4.4 (Mid 2025 — NEAR CUTOFF, VERIFY)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Core | `FileAccess.store_*` return `bool` | Was `void`. Methods: `store_8`, `store_16`, `store_32`, `store_64`, `store_buffer`, `store_csv_line`, `store_double`, `store_float`, `store_half`, `store_line`, `store_pascal_string`, `store_real`, `store_string`, `store_var` |
| Core | `OS.execute_with_pipe` | Added optional `blocking` parameter |
| Core | `RegEx.compile/create_from_string` | Added optional `show_error` parameter |
| Rendering | `RenderingDevice.draw_list_begin` | Many parameters removed; `breadcrumb` parameter added |
| Rendering | Shader texture types | Parameter/return types changed from `Texture2D` to `Texture` |
| Particles | `.restart()` method | Added optional `keep_seed` parameter (CPU/GPU 2D/3D) |
| GUI | `RichTextLabel.push_meta` | Added optional `tooltip` parameter |
| GUI | `GraphEdit.connect_node` | Added optional `keep_alive` parameter |

## 4.2 → 4.3 (In Training Data — LOW RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Animation | `Skeleton3D.add_bone` returns `int32` | Was `void` |
| Animation | `bone_pose_updated` signal | Replaced by `skeleton_updated` |
| TileMap | `TileMapLayer` replaces `TileMap` | One node per layer instead of multi-layer single node |
| Navigation | `NavigationRegion2D` | Removed `avoidance_layers`, `constrain_avoidance` properties |
| Editor | `EditorSceneFormatImporterFBX` | Renamed to `EditorSceneFormatImporterFBX2GLTF` |
| Animation | AnimationMixer base class | AnimationPlayer and AnimationTree now extend AnimationMixer |
