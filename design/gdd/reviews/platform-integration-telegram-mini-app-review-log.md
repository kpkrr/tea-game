# Review Log: Platform Integration (Telegram Mini App)

## Review — 2026-09-28 — Verdict: NEEDS REVISION → revised same session → APPROVED
Scope signal: M
Specialists: none (lean mode)
Blocking items: 1 | Recommended: 2
Summary: Документ методологически сильный (формулы проверены на граничных
значениях, Edge Cases покрывают почти все практические сценарии, AC
тестируемы). Единственная находка — AC#8 и парный Edge Case приписывали
этой системе леттербокс на границе 9:20, который по факту производит
Kitchen & Station Layout AC#6 (кухня занимает «не менее 95%», а не 100%).
Все пункты исправлены в той же сессии; повторное полное ревью не
запускалось — пользователь принял правки без re-review.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Acceptance Criteria / Edge Cases: AC#8 и Edge Case «уже 9:20»
  ошибочно приписывали себе леттербокс на границе диапазона, который
  формула (Core Rules §5, ветка `else`) не производит — свободные полосы
  на самом деле дают ~5% margin из kitchen-station-layout.md AC#6. Исправлено:
  оба места переписаны с явной ссылкой на Kitchen AC#6, симметрично AC#9.
- [RECOMMENDED] Tuning Knobs: колонка «Диапазон» содержала прозу вместо
  диапазона/N-A. Исправлено на явное «N/A — фиксировано архитектурным
  решением».
- [RECOMMENDED] Formulas: `safe_aspect = safe_w / safe_h` не была защищена
  от `safe_h <= 0`. Исправлено: `safe_h` определён с `max(1, ...)`-guard.
Reviewed-Content-Hash: design/gdd/platform-integration-telegram-mini-app.md b6e3b5be6b71fb56089a95cbbce73eaa712da3f8
Reviewed-Content-Hash: design/registry/entities.yaml 33715a9fb473ab298274819b2fc85823ccf1dc75
