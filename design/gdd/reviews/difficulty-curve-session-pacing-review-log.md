# Review Log — Difficulty Curve & Session Pacing

## Review — 2026-09-28 — Verdict: NEEDS REVISION → APPROVED (revised same session)
Scope signal: L
Specialists: none — lean mode
Blocking items: 1 | Recommended: 1
Summary: Core Rule 1 cited a game-concept.md quote ("рост с 0-й по 3-ю минуту") that does not exist in the document — game-concept twice names ~2 minutes as the target and explicitly leaves the exact curve as an open playtest question, not a fixed number. The same misattribution ran through Formulas 2–4's Source columns, Summary and Cross-References for all six baseline endpoints, and had already propagated into design/registry/entities.yaml. Separately, the "Проверка пропускной способности" balance-check formula (avg_time(p) = 7.75 + 1.5×p) did not match its own table (verified coefficient is 3.75, derived from order-recipe-system.md time_to_complete values) — the table itself was correct, only the written formula was wrong.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Core Rule 1 / Formulas 2-4 / Summary / Cross-References: ramp_duration=180s and the six baseline endpoints (8→18, 50→25, 0→40%) were misattributed to a game-concept.md quote that does not exist; game-concept names ~2 minutes and leaves the curve as an open question. Fixed: reattributed as an author decision, added Open Question #6, synced design/registry/entities.yaml notes.
- [RECOMMENDED] Formulas / Проверка пропускной способности: avg_time(p) formula stated coefficient 1.5, actual value used to produce the table is 3.75. Fixed: corrected coefficient, added derivation note.
- [ADVISORY] Player Fantasy and Tuning Knobs sections absent — advisory only at `standard` tier, not blocking. Not addressed this session.

Reviewed-Content-Hash: design/gdd/difficulty-curve-session-pacing.md 948df0cfbb40ffc0a51d4c4df29d31119ebe4306
Reviewed-Content-Hash: design/registry/entities.yaml 0944405233d1065f4a5c18219d04d1768d32316a
