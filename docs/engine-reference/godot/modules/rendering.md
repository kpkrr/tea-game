# Godot Rendering — Quick Reference

Last verified: 2026-09-30 | Engine: Godot 4.7.2

Compiled 2026-09-30 from the `4.7.2-stable` tag class XML (`doc/classes/*.xml`),
`drivers/gles3/*` source, the 4.6→4.7 migration guide, and a `--doctool` dump from
the installed 4.7.2 editor. Anything not confirmed is marked UNVERIFIED. The
4.6-and-earlier history is kept at the bottom.

## 4.7 Changes (verified)

- **Stretch defaults**: new projects get `display/window/stretch/mode = canvas_items`
  and `stretch/aspect = expand` (was `disabled`/`keep`). The `ProjectSettings`
  class default is still `disabled`/`keep`; only *newly created* projects get the
  new values. A hand-written `project.godot` must set both explicitly.
  `canvas_items`: "3D is unaffected", 2D/Control render at target resolution.
- **`CanvasItem` line drawing drops the antialiasing feather** (GH-105122). Lines
  look thinner; widen `width` if you relied on the old look. Applies to
  `draw_line`/`draw_arc`-style calls.
- **`LinearToSRGB` visual shader no longer clamps** to [0,1] (Mobile/Forward+ only).
- `ProjectSettings.rendering/reflections/sky_reflections/roughness_layers` 7 → 8.
- `Viewport.SCALING_3D_MODE_NEAREST` exists in 4.7 (absent in 4.6 class XML).

## WebGL2 / Compatibility notes for a Sprite3D + Label3D scene

- **`Viewport.scaling_3d_scale`** works in Compatibility with `SCALING_3D_MODE_BILINEAR`
  (and NEAREST). FSR/FSR2/MetalFX fall back to bilinear (`ProjectSettings` note;
  `render_scene_buffers_gles3.cpp` L165-167). Scale `1.0` = off (no extra buffer).
  Any other value makes the GLES3 backend render into an internal 3D color+depth
  texture and blit it up (`use_internal_buffer`), so there is an extra buffer and
  blit; the fill-rate saving vs blit cost is UNVERIFIED on a device (spike).
  Node/Control 2D is not scaled by it.
- **Depth prepass on Compatibility**: `rendering/driver/depth_prepass/enable = true`
  but **`disable_for_vendors` defaults to `"PowerVR,Mali,Adreno,Apple"`**, so it is
  off on most phones. `ALPHA_CUT_OPAQUE_PREPASS` (= `TRANSPARENCY_ALPHA_DEPTH_PRE_PASS`)
  materials are always in the alpha (sorted, blended) pass; they only get the
  depth-prepass benefit when the prepass runs. Reading the source, with the prepass
  off they behave like ordinary blended sprites sorted back-to-front (inferred from
  `rasterizer_scene_gles3.cpp`; UNVERIFIED on a real Adreno/Mali device). Desktop
  browsers usually keep the prepass on, so desktop and phone can look different.
  Prepass thresholds: alpha < 0.99 discarded in depth pass, < 0.1 in shadow pass.
- **`render_priority`** (`Material`, `SpriteBase3D`, `Label3D`): orders **transparent**
  geometry only; it never reorders transparent vs opaque. `SpriteBase3D`/`Label3D`
  docs add: applies only when `alpha_cut == ALPHA_CUT_DISABLED` (the default).
  Higher = sorted in front.
- **`Label3D.outline_render_priority`**: default `-1` (`render_priority` default `0`),
  same transparent-only and `ALPHA_CUT_DISABLED`-only caveats. Keep outline below text.
- `SpriteBase3D`/`Label3D` defaults: `shaded=false`, `double_sided=true`,
  `no_depth_test=false`, `billboard=disabled`, `texture_filter=3` (linear mipmap
  anisotropic), `pixel_size` 0.01 (sprite) / 0.005 (label), Label3D `font_size` 32,
  `outline_size` 12. `no_depth_test` = "drawn in render order".
- `ALPHA_CUT_OPAQUE_PREPASS` values: DISABLED 0, DISCARD 1, OPAQUE_PREPASS 2, HASH 3.
  DISCARD gives hard edges (Label3D: can misbehave with antialiased fonts/outlines;
  MSDF fonts help).
- `display/window/dpi/allow_hidpi` default `true` (Web included).
- Web export is Compatibility/WebGL2 only (see `web.md`).

## Older Changes

### 4.6
- D3D12 default on Windows (was Vulkan); glow before tonemapping; AgX white point/contrast; SSR overhaul.
### 4.5
- Shader Baker; SMAA 1x; stencil buffer support; bent normal maps; specular occlusion.
### 4.4
- `RenderingDevice.draw_list_begin` params removed (`breadcrumb` added); shader `Texture2D` → `Texture`; particles `restart(keep_seed)`.
### 4.3
- `Compositor` + `CompositorEffect` for post-processing.

## Common Mistakes
- Assuming a fresh 4.7 project's stretch defaults match the ADR/project; set them explicitly.
- Expecting `render_priority` to affect alpha-cut/prepass sprites or transparent-vs-opaque order.
- Assuming the depth prepass runs on phones (Adreno/Mali/PowerVR/Apple disabled by default).
- Drawing rings with `draw_arc`/lines and expecting 4.6 thickness.
- Assuming `scaling_3d_scale < 1` is free in Compatibility (extra buffer + blit).
