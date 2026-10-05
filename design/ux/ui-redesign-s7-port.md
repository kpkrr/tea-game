# UI redesign s7 — port spec (macket → game code)

**Status:** owner-approved on mockups (session 8, 2026-10-01). Next step: implement in the game.
**Target look (open these first):** `production/qa/evidence/ui-s7i-mockup-phone.jpg` (360×800),
`ui-s7i-mockup-desktop.jpg` (1280×800), `ui-s7i-top-zoom.jpg`, `ui-s7c-signs-zoom.jpg`, `ui-s7-held-cups.jpg`.
**Reference implementation (Pillow, exact numbers):** `prototypes/art-preview/tools/ui_mockup/ui/mock12.py`
(chain: mock12 → mock11 → mock10 → mock9 → mock8 → mock7 → mock6/5/4/3 → mock.py). When this spec and the
script disagree, the script is what the owner saw.
**Where to port first:** `prototypes/art-preview/` (it has the plate, perspective camera, `--clean-ui` frames).
Owner rules: mockup before game; Russian in chat, English UI text; no commits without the owner's command.

> Supersedes the old HUD parts of `design/ux/hud.md` (Nunito/Fredoka text, rings above heads, tickets
> under guests). Docs not yet updated — see "Docs still to update" at the end.

## Units
- `dp` = viewport px of the reference sizes (360×800 phone, 1280×800 desktop). Mockup frames were 2× (phone) —
  in `mock*.py` `dp(v)=v*sc`, `sc=2.0` phone, `2.5` desktop (desktop UI is 1.25× bigger than phone UI).
- All art is pixel art with an alpha threshold at 128 already applied. Use nearest filtering in Godot.
- Font for digits: `Jersey10.ttf` (OFL, placeholder pixel font).

## Assets — `prototypes/art-preview/art/ui_s7/` (provenance in `art-source/provenance.yaml`)
| File | What | Source sheet |
|---|---|---|
| `hud_bar.png` (1898×245) | top wooden bar, 3-slice: caps = 120 src px each side | s3 sheet B |
| `hud_score_plaque.png` (769×273) | score/coins plaque (star + coin icons drawn in) | s0 pilot v2 |
| `hud_heart_full.png`, `hud_heart_empty.png` | strikes (coral); empty = parchment fill | s0 pilot v2 |
| `hud_btn_pause.png`, `hud_btn_sound.png` | round buttons | s0 pilot v2 |
| `plaqueC.png` (512×820) + `ropeC.png` (96×813) | hanging order plaque, variant **C** (brass cap + knot + tassel); rope tiles vertically | s7 plaques |
| `plaqueA/B.png`, `ropeA/B.png` | rejected variants (keep for reference) | s7 plaques |
| `cup_<state>.png` ×9 | the mug: held cup + drink on order plaques | s7 cups |
| `signA_<step>.png` ×7 | station signs (square board on tall legs) | s7 signs |
| `gauge_empty/half/full.png` | kettle brewing pill | s3 sheet B |
| `bubble_warn.png`, `bubble_urgent.png` | "!" bubbles on order plaques | s3 sheet B |
| `Jersey10.ttf` | digits font | OFL |

Cup states: `empty, leaf_black, leaf_green, black_tea, green_tea, black_tea_lemon, green_tea_lemon, cold_tea, ruined`.
Steps → state: `[cup]`→empty; `+leaf_black`→leaf_black; `+water_100`→black_tea; `+lemon`→black_tea_lemon
(green: `leaf_green`/`water_80` likewise); `[cup, iced_tea]`→cold_tea; `ruined=true`→ruined.
Final drink of a recipe (order plaque): `cold_tea`, `black_tea`, `green_tea`, `black_tea_lemon`, `green_tea_lemon`.
Normalise all cups by `cup_empty` height (343 px) so contents/steam don't change the mug size.

## 1. Top HUD bar
- Bar art scaled so its visible height = **68 dp**: `s = 68dp / (245 × 0.86)`; the art's top ~14 % is
  pushed **off-screen** (flat top edge). Horizontal 3-slice: caps 120 src px × s, middle tiles.
- **Phone** (content + caps don't fit): bar = full width, caps run off-screen
  (`x = −cap + 2dp`, `w = W + 2·cap − 4dp`).
- **Desktop** (fits): bar width = content + 3×14 dp gaps + 2×8 dp padding + 2 caps, centred; all items between the caps.
- Items left→right: score plaque (h **46 dp**), 3 hearts (h **22 dp**, 3 dp apart), pause, sound (h **40 dp**).
  Equal gaps between the 4 groups (space-between, 8 dp padding inside the caps / screen edges).
- Vertical: every item centred on the **visible** planks: `yc = (245·s·229/245 − off) / 2`
  (229/245 = last plank row above the bottom outline) → ≈ 9 dp from the screen top on phone.
- Score plaque text (Jersey 10): x = `plaque.x + 0.189·plaque.w + 4 dp` (icons end at 18.9 %);
  score **23 dp**, colour `#17705F`, centre y at 0.30 of plaque height; coins `250/250` **19 dp**, `#8A5E00`, at 0.72.

## 2. Hanging order plaques (variant C)
- 4 plaques = queue order left→right, each **74 × 56 dp**, **10 dp** apart, centred under the bar's visible inner width.
- Board = rows of `plaqueC.png` from y=361 (board top) down; uniform scale `s = 74dp / 512` horizontally;
  vertical 3-slice to 56 dp: keep top/bottom `cut = 87+12 = 99` src px, stretch the middle.
- Attachments (brass caps, knots, tassels): crop `plaqueC.png` rows `361−200 … 361+cut/2`, same scale, on top of the board.
  Rope centres in src px: x = **113** and **390**. Ropes: `ropeC.png` scaled by `s`, tiled from `bar_bottom − 6 dp`
  down to the attachment. Plaque top `Y = 68dp + 30dp − attachment_h + 4dp`.
- **Patience timer** in the thick dark channel of the rim. Channel insets (src px, outer→inner):
  L 44→80, R 46→82, T 53→87, B 49→84 (scale by `s`). Fills **clockwise from 12 o'clock**, remaining part
  coloured, the rest keeps the art's dark channel. Colour by patience: 1.0 `(108,194,74)` → 0.6 `(242,194,48)` →
  0.25 `(240,120,106)` → 0.0 `(216,50,60)` (linear between stops), then **muted 35 %** toward `(92,70,60)`.
- Inside the parchment: final-drink cup **22 dp** tall + price (Jersey 10, **18 dp**, Ink `#2B1D1A`), **5 dp** apart,
  centred. No coin icon.
- **Recipe stickers** on the bottom rim (one per step, cup first; order cup, leaf_black, leaf_green, iced_tea,
  water_100, water_80, lemon): 14×14 art px at 1 px = 1 dp, rounded, **no white border**, Ink outline,
  step colour (art bible §4; cream `#F5F1E8` → `(236,226,204)` so it reads), highlight top-left, darker inner
  edge bottom/right, peeled bottom-right corner (paper back `(214,204,184)`); tilted −10°, 7°, −5°, 11°, −8° (cycle),
  overlap −1 dp, every 2nd 1 dp lower; centre y = `plaque_bottom − 3 dp`; shadow `(20,12,8,90)` offset 1 dp.
- Warn (0.6 ≥ p > 0.25) / urgent (p ≤ 0.25): `bubble_warn/urgent.png` 18/20 dp at the plaque's top-right corner.
- Serving = tap the till; the oldest matching order closes (see session state, session 7 decisions).

## 3. Station signs
- `signA_<step>.png`; board = rows 0…319 (legs below). Board scaled to **36 dp wide and squashed to a square**
  (sheet came out ~4:5); legs stretched to the needed length.
- Back-row stations (cups, jars, kettles): board above the item, legs from `item_bottom − 4 dp` up to `item_top − 3 dp`;
  the item is drawn **over** the legs.
- Island stations (**iced_tea, lemon**): low — board bottom at `item_top + 35 % item_h`, legs 3 dp; drawn
  **after** the back-row items (so they never sit under the cups) and **before** their own item (jug/bowl covers the board bottom).
- Black tea sign shows twisted leaves (no coffee/scoop) — already in the art.

## 4. Kettle & held cup
- Brewing: `gauge_half`-style pill **26 dp** wide at 42 % of the kettle height (fill = brew progress; use
  empty/half/full art or clip `gauge_full`). **READY = the existing in-game steam**, no extra overlay.
- Held cup: `cup_<state>.png` **15 dp** tall at the barista's hand anchor (`x − 0.35·w`, `y − 0.75·h`).
  Owner may want it bigger (18–20 dp) — ask when showing.

## 5. Wide screens (desktop): kitchen shift
- If plaques would cover the kitchen, move **plate + camera** down — never a blurred/smeared fill.
  Prototype dev flag: `--shift-y=<vp px>` (`src/foundation/view_fit.gd::_shift_y`, adds to the plate transform
  origin; the off-axis camera follows). 1280×800 needs **89 px**. Make it automatic: shift = max(0, UI bottom +
  margin − kitchen top).
- **Do NOT touch the kitchen-focus blur** (`art/grade.gdshader`, `bg_blur`/`bg_sat`/`bg_bright`) — owner-approved,
  explicitly reconfirmed.

## Removed / replaced
Patience rings above heads, tickets above/below guests, round token icons, old Nunito/Fredoka HUD, s3 flat
icons and s4 self-made icons, s6 detailed sheet (too detailed), coin icon on orders, ready bubble on kettle.

## Docs still to update (not done)
`design/ux/hud.md` (layout above), `design/art/art-bible.md` §4/§7 (pixel UI, pixel font, muted coral timer,
coral hearts, stickers), GDDs: guests (queue on stairs, checkerboard), kitchen (station signs), serving
(tap the till, oldest matching order). Run `/propagate-design-change` after.

## Verify
Launch the art-preview scene at 360×800 and 1280×800, screenshot with `--bot --shot=… --shot-at=60`, compare side
by side with the `ui-s7i-*` mockups, keep the screenshots in `production/qa/evidence/` (UI evidence rule).
