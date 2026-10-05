# UI mockup scripts (session 7, throwaway)

Pillow mockups of the new UI over clean game frames. Run with the scratchpad venv (pillow, numpy, opencv-python-headless):

    python ui/mock3.py prototypes/art-preview/tools/ui_mockup     # -> production/qa/evidence/ui-topbar-{phone,desktop}.jpg

- `ui/mock.py` — cuts from the approved sheets (s0 HUD pilot v2, s1 world sheet), procedural ring/timer, station `sign()`.
- `ui/mock2lib.py` — queue on the stairs, hanging `sign_ticket()`, kettle gauge, ready bubble (dropped: READY = in-game steam).
- `ui/mock3.py` — final layout: wooden top bar + ropes + 4 hanging order signs, kitchen shift on wide screens, blurred top.
- Frames come from `--clean-ui --no-guests` (flags added to the prototype; see session state). Masks = GrabCut cutouts of station items (phone frame px; desktop mapped by scale 1.2975, offset (810.75, -444)).
- Jersey 10 (OFL) — placeholder pixel font for digits.

## Session 8 (2026-10-01) — final approved layout
- `ui/cut_s3.py`, `cut_msr.py`, `icons_s4.py`, `cut_s6.py`, `cut_s7.py` — sheet cutters (assets in `art/ui_s3`, `ui_s4`, `ui_s6`, `ui_s7`).
- `ui/mock4.py` … `ui/mock12.py` — iterations; each execs the previous one and overrides. **`mock12.py` = approved s7i look**
  (`production/qa/evidence/ui-s7i-*.jpg`). Port spec: `design/ux/ui-redesign-s7-port.md`.
- Desktop frame `ui/noguests-1280x800-shift89.png` was rendered by the game with `--shift-y=89 --day-at=42 --shot-at=60`.
