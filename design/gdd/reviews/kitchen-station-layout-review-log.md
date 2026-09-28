# Review Log: Kitchen & Station Layout

## Review — 2026-09-28 — Verdict: NEEDS REVISION → revised same session → APPROVED
Scope signal: XL
Specialists: none (lean mode)
Blocking items: 1 | Recommended: 2
Summary: Документ прочно закрывает геометрию, NavMesh и разделение
ответственности с соседними системами. Единственная находка — AC#6/#10
жёстко гейтили реализацию на порог (≥95% заполнения playfield) на всём
диапазоне 9:20–1:1, но механизм, которым камера это выполняет, нигде не
был описан, а «камера фиксированная» (Visual/Audio Requirements, Game
Feel) читалось как противоречащее самой возможности адаптивного заполнения.
Formulas отсутствовала, хотя `playfield_min_fill`/`min_tap_target` уже
пороги в реестре — тот же тест, что только что применили к
`platform-integration-telegram-mini-app.md`. Все пункты исправлены в той
же сессии; повторное полное ревью не запускалось.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Formulas / Acceptance Criteria: AC#6/#10 требовали ≥95%
  заполнения playfield на всём диапазоне соотношений сторон без описанного
  механизма; «камера фиксированная» не уточняла, адаптируется ли zoom.
  Исправлено: добавлена секция Formulas с контрактом
  `kitchen_fill_ratio >= playfield_min_fill`, явно разделены «камера не
  панорамируется» и «zoom обязан адаптироваться под playfield»; точная
  формула ortho-size/FOV оставлена уже запланированному ADR. AC#6/#10 и
  Visual Requirements обновлены со ссылкой на формулу.
- [RECOMMENDED] Tuning Knobs: отсутствовала, хотя `playfield_min_fill` и
  `min_tap_target` — пороги в реестре, как и в Platform Integration.
  Исправлено: добавлена секция (оба значения N/A-фиксированные).
- [RECOMMENDED] Edge Cases: «пропорции не совпадают» смешивала
  ответственность этой системы (≥95% margin) и Platform Integration
  (леттербокс вне 9:20–1:1). Исправлено: переписано на два явно
  разделённых пункта, симметрично правке в Platform Integration GDD.
Reviewed-Content-Hash: design/gdd/kitchen-station-layout.md a1e4693c9454e54791d3ffa00f76ced729a6050b
Reviewed-Content-Hash: design/registry/entities.yaml 33715a9fb473ab298274819b2fc85823ccf1dc75
