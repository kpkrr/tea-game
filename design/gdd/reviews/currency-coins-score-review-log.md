# Review Log: Currency: Coins & Score

## Review — 2026-09-28 — Verdict: APPROVED
Scope signal: M
Specialists: none (lean mode)
Blocking items: 0 | Recommended: 3
Summary: Formulas are internally consistent and bounded at both extremes (no negative/zero/infinite outputs); the one non-obvious behavior — a perfectly-served medium recipe can outscore a complex recipe served at the edge, past remaining_fraction > 0.4 — is documented as intended with the threshold derived, not a bug. Bidirectional dependencies with Order & Recipe System and Guest AI & Patience were verified on disk, both already cite this GDD back with the exact same contract. All findings are documentation drift, not implementation blockers.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] Detailed Design (Core Rule 3): uses literal `× 10` instead of citing the named constant `score_multiplier_base` formalized later in Formulas — inconsistent with AC 34 ("no hardcoded values").
- [RECOMMENDED] Formulas (Formula 1 Variable table): `score_multiplier_base` row still says "кандидат в реестр" — stale, the constant is already registered in `design/registry/entities.yaml`.
- [RECOMMENDED] Acceptance Criteria (AC 6, AC 9): these are "prove a code path is absent" checks, closer to architecture-review/code-review than black-box QA — already self-flagged in the GDD; recommend tagging them distinctly from testable black-box ACs.

Reviewed-Content-Hash: design/gdd/currency-coins-score.md f19341378361d5a9f7abba9decfaad42f2f536b0
Reviewed-Content-Hash: design/registry/entities.yaml 2b9f0ee77ba6f29fd6f0aa5c02d3b568e3d19a32
