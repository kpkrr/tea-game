# Smoke Test: Critical Paths

**Purpose**: Run these checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core systems are implemented.

## Core Stability (always run)

1. Web build loads in a mobile browser: loading screen with progress, then the kitchen with no white flash (ADR-0001)
2. A browser without WebGL2 shows the static "update your browser" page and never loads the engine
3. The first match starts on its own after loading (`ready_reached` → `match_started`)

## Core Mechanic (update per sprint)

<!-- Add the primary mechanic for each sprint here as it is implemented -->
4. [Tap → barista walks → station action — fill in with the first Player Control story]
5. [Serve a drink → coins go into the till, score pops — fill in with the Currency/Till stories]

## Pause and resize

6. Hiding the tab mid-match freezes patience and kettles; returning resumes without a jump
7. Rotating or resizing mid-match changes only the framing, not match state

## Data Integrity

8. Best score and till amount survive a tab close and relaunch (once SaveStore is implemented)
9. An invalid config blocks boot with the "reload the page" screen (once ConfigLoader is implemented)

## Performance

10. No visible frame drops on the reference weak Android (30 fps floor, ADR-0007)
11. No memory growth over 5 consecutive matches (ADR-0007 §6)
