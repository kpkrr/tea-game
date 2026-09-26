# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7.2 |
| **Installed at pin time** | 4.7.2.stable.official.ed1daf0bf — `/Applications/Godot.app` (not on PATH), verified 2026-09-26. Matches the pin. |
| **Release Date** | 4.7.0 ("Lights, Camera, Action!") ~June 2026; 4.7.2 (this pin, maintenance release) August 18, 2026 |
| **Project Pinned** | 2026-09-26 |
| **Last Docs Verified** | 2026-09-26 |
| **LLM Knowledge Cutoff** | January 2026 (this session's model) |

## Knowledge Gap Warning

The assistant's training data covers Godot up to roughly 4.6 (released January
2026, right at the model's cutoff). **Godot 4.7 was released after the cutoff
and is NOT reliably known to the model.** Always cross-reference this directory
— especially `breaking-changes.md` and `deprecated-apis.md` — before suggesting
any Godot 4.7 API call.

## Installed-Version Gap Warning

The warning above is one-directional — it covers the **model** knowing less than
this pin. The reverse gap is real: this reference can sit **ahead of the
installed editor**, and an agent citing it correctly then emits APIs that do not
compile locally. **Check `Installed at pin time` above before trusting a
version-qualified claim** — `NOT DETERMINED` means the gap is unknown, not absent.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | ~Mid 2025 | MEDIUM | Jolt physics option, FileAccess return types, shader texture type changes |
| 4.5 | ~Late 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | MEDIUM | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | Jun–Aug 2026 | HIGH | HDR output, AreaLight3D, DrawableTexture2D, Control offset-transform animations, gamepad-focus/device-ID input changes, several Jolt Physics behavior changes |

## Verified Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.7 release notes: https://godotengine.org/releases/4.7/
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
