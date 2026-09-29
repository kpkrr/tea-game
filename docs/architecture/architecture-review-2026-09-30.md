# Architecture Review Report

- Date: 2026-09-30
- Engine: Godot 4.7.2 (GDScript, Compatibility / WebGL2, single-thread web export)
- Mode: full · workflow `standard` · automation `autonomous`
- GDDs Reviewed: 10 MVP GDDs (+ game-concept, systems-index); требования взяты из `architecture.md` Appendix A (164 TR), сверены с изменениями GDD после его составления
- ADRs Reviewed: 7 (ADR-0001…0007, все **Proposed**)
- Engine specialist: godot-specialist — 2 блокирующих, 12 мелких замечаний; **все внесены в том же проходе** (см. «Исправлено в этом проходе»)

> Хэши ниже сняты **после** исправлений этого прохода. Следующий `/architecture-review`
> увидит UNCHANGED, если с тех пор ничего не менялось.

```
Reviewed-Content-Hash: docs/architecture/adr-0001-web-build-platform-shell.md 6e881ed39a23cc2b825523890d8f569a10365ed9
Reviewed-Content-Hash: docs/architecture/adr-0002-viewport-camera-fit-presentation.md 63719b78faf4ce190252b72443c113c4b9842602
Reviewed-Content-Hash: docs/architecture/adr-0003-match-simulation-clock-tick-events.md 7eb2dcdeb5f306794da546684d2d52639c453f75
Reviewed-Content-Hash: docs/architecture/adr-0004-data-config-load-validation.md 5695e820f406f0a00b3e2c5f18271b1f6d8b02c9
Reviewed-Content-Hash: docs/architecture/adr-0005-local-persistence-savestore.md e8bd79e8e0c4485d10c28f821991f83c443cd4b9
Reviewed-Content-Hash: docs/architecture/adr-0006-navigation-tap-picking.md 92797bc3a797b1ebf0f45fd5353079cd4a0e6575
Reviewed-Content-Hash: docs/architecture/adr-0007-performance-load-budgets.md 1ab31f8a8e64cc2184ddac8ef92288b03071e32a
Reviewed-Content-Hash: design/gdd/brewing-crafting-mechanic.md 406c6c636cb4111592f5b40d8c4a6b7d5e544dee
Reviewed-Content-Hash: design/gdd/currency-coins-score.md 69084ec81b41fba47c554e4068b747cf9211913a
Reviewed-Content-Hash: design/gdd/difficulty-curve-session-pacing.md d41e66387561122d9f84e3e910992cdc07abcb6a
Reviewed-Content-Hash: design/gdd/game-concept.md d60a410ab66b1f46eb1168562294639ba41219cd
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-09-29.md 924de66b6aa9f063b1c5afbf05727aac525f6845
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-09-29b.md fc6eac72191d2411503bc7ef8ffe24c764ca1500
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-09-29c.md 8f0eb6993fcb071fe3945e6c45266d92057e2dcd
Reviewed-Content-Hash: design/gdd/guest-ai-patience.md bcdb6d467101e672def5e57a0f31f9859a1f4c54
Reviewed-Content-Hash: design/gdd/hud-feedback-ui.md c24e0e04fca773fc93171bd07de891bd28e944a3
Reviewed-Content-Hash: design/gdd/kitchen-station-layout.md 0d6b37f39b4a8e2739388795992c305c911eba42
Reviewed-Content-Hash: design/gdd/order-recipe-system.md cc6a600a03eb358ff71ba3d9b322975ba3dfaaeb
Reviewed-Content-Hash: design/gdd/platform-integration-telegram-mini-app.md 6c9d9c65cfb9316942bb16f9793aa4cf2f9e6ee6
Reviewed-Content-Hash: design/gdd/player-control-barista-movement.md 6cccff08733c63d531bc7b349c98d3930aa34f0c
Reviewed-Content-Hash: design/gdd/systems-index.md 7a7f41eb09b0a900a23b49809fbb0873384c0722
Reviewed-Content-Hash: design/gdd/till-day-cycle.md a729df77e110f5286c2cd6af7545e689d1c11a09
```

---

## Traceability Summary

| Статус | Кол-во |
|---|---|
| ✅ Covered (Accepted ADR) | 0 |
| 🟡 Covered (Proposed ADR) | 145 |
| ⚠️ Partial | 11 |
| ➡️ Вне ADR — UX-спека | 3 |
| ❌ Gap | 0 |
| ⏸ Отложено (Telegram, решение 2026-09-30) | 5 |
| **Всего** | **164** (активных 159) |

Пробелов нет, но **ни одно покрытие не опирается на Accepted ADR**: все 145 — 🟡.
Путь выхода — `/architecture-decision accept ADR-NNNN` в порядке ниже, начиная со
spike ADR-0001.

### Partial (11)
- TR-layout-002, -003, -004, -005, -006 — геометрия кухни, слоты, till-anchor, владение слотами: это данные `KitchenConfig` (ADR-0004) и строка владения в `architecture.md`; отдельное решение не нужно, но ни один ADR их не перечисляет. Действие: при `/create-stories` ссылаться на ADR-0004 + architecture.md.
- TR-recipe-012 — карта цветов шагов: `architecture.md` отдаёт её ADR-0002, но ни ADR-0002, ни ADR-0004 её не перечисляют. Действие: добавить строку в GDD Requirements ADR-0004 (`RecipeConfig`) при accept.
- TR-hud-005, -010, -011, -015, -017 — визуальные правила HUD, частично покрыты ADR-0002 §5–6 и ADR-0003 §6; остальное решает `/ux-design`.

### Вне ADR (3)
TR-hud-014 (пульсы со сдвигом 100 мс), TR-hud-018 (звук на событие — Audio, VS), TR-hud-022 (reduced-motion) → `/ux-design`.

Полная матрица: `docs/architecture/architecture-traceability.md`.

---

## Cross-ADR Conflicts

Known conflict-prone areas (`consistency-failures.md`): одна запись 2026-09-28 — плейсхолдер, отложенный в ещё не написанный документ. Здесь повторился тот же паттерн: ADR-0005 изменил хранилище, а ADR-0001 и architecture.md сохранили старый текст про IndexedDB.

### 🔴 Conflict 1: ADR-0001 vs ADR-0002 / ADR-0007 — единицы safe area *(исправлено)*
- Type: Integration contract
- ADR-0001 считал safe area из `innerWidth/innerHeight` (CSS px), но объявлял `safe_area_changed` в px окна.
- ADR-0002 переводит px окна в dp через `get_final_transform()`; ADR-0007 считает 3D pixel budget по device px.
- Impact: при `allow_hidpi` на телефоне с DPR 3 перевод ошибается в 3 раза, а render scale видит 360×800 вместо 1080×2400 и никогда не снижает разрешение.
- Resolution (применена): значение берётся только из `DisplayServer.window_get_size()`, JS служит лишь триггером. В ADR-0007 записано, что device px = px окна только при `allow_hidpi = true`.

### 🔴 Conflict 2: ADR-0003 vs ADR-0007 — `await` в `MatchDirector._process` *(исправлено)*
- Type: Pattern / Dependency
- ADR-0007 §7 «awaits `frame_post_draw` twice» внутри `Booting`, который гоняет `_process` (ADR-0003 §4).
- Impact: `await` превращает `_process` в корутину, а движок всё равно вызывает его следующим кадром. Пре-прогрев перезапускается или накладывается сам на себя, а флаг `_in_tick` врёт.
- Resolution (применена): Booting стал опрашиваемым подсостоянием `NAV_WAIT → PREWARM_WAIT → DONE`, кадры считает разовое подключение к `frame_post_draw`, а в `_process` запрещён `await`.

### 🟠 Conflict 3: ADR-0001 vs ADR-0005 — механизм хранения *(исправлено)*
Ограничения, проверка, риски и критерии ADR-0001, а также слой Platform в architecture.md говорили «`user://` → IndexedDB», а ADR-0005 выбрал `localStorage`. Текст выровнен; риск `syncfs` снят как неактуальный. Добавлен риск: синхронный flush при уходе в фон держится на single-thread (включение потоков требует пересмотра ADR-0005).

### 🟠 Conflict 4: ADR-0005 vs ADR-0003 — связь lifecycle → persistence *(исправлено)*
По ADR-0005 flush при скрытии вызывал `MatchLifecycle`. Теперь его делает обработчик видимости в `_compose()`: сначала `lifecycle.on_visibility_changed()`, затем `save_store.flush_if_dirty()`.

### 🟡 Conflict 5: ADR-0007 vs architecture.md (`UtcClock`) *(исправлено)*
Правило «только PerfProbe читает Time» запрещало продакшн-`UtcClock`. В него добавлено исключение для инъецированных адаптеров часов.

### ADR Dependency Order (`adr-dep-graph.sh`: 7 ADR, 12 рёбер, циклов нет, у всех есть секция зависимостей)
```
Foundation:          1. ADR-0001 Web build & platform shell
Depends on 0001:     2. ADR-0002 Viewport, camera fit & 2.5D
                     3. ADR-0003 Match simulation (clock, tick, events)
Depends on 0001+0003:4. ADR-0004 Data config & validation
                     5. ADR-0005 SaveStore
Depends on 0001–0003:6. ADR-0007 Performance & load budgets
Depends on 0002–0004:7. ADR-0006 Navigation & tap picking
```
⚠️ Каждый ADR зависит от Proposed-ADR. Корень всей цепочки — ADR-0001: он не станет Accepted, пока не пройден spike на реальном слабом Android и не решён вопрос iOS. ADR-0007 дополнительно требует подписи technical-director.

---

## GDD Revision Flags
Нет: все допущения GDD согласованы с проверенным поведением движка. GDD уже синхронизированы авторами ADR (pick-якоря, footprints вместо коллизий, допуск зазора −0,05 м). В этом проходе закрыты два устаревших Open Questions: Currency (бюджет мс → ADR-0007) и Platform OQ5 («кадр» → ADR-0001). В systems-index изменений нет.

---

## Engine Compatibility Issues

- Engine Compatibility section: 7/7; версия везде 4.7.2; устаревших API нет.
- Post-cutoff API: `duplicate_deep` (ADR-0004, только тесты); `bake_from_source_geometry_data`, `add_projected_obstruction`, `map_set_use_async_iterations` (ADR-0006, проверено пробой 4.7.2); 4.7 `Control` offset-transform (ADR-0002 — **дописан**, ранее значился «None new»); `DEVICE_ID_EMULATION` (ADR-0006 — **дописан**).
- **Устаревшие справочники движка:** `modules/rendering.md`, `ui.md` и `input.md` датированы 4.6, а на них опираются ADR-0002 и ADR-0006. Рекомендуется обновить до 4.7 перед accept ADR-0002 и ADR-0006.
- Открыто: помечен ли `map_force_update` как deprecated в 4.7 (проба показывает, что он работает) — вписано в Verification ADR-0006.

### Engine Specialist Findings (все внесены)
| # | Sev | ADR | Находка → исправление |
|---|---|---|---|
| 1 | BLOCKING | 0003/0007 | `await` в `_process` → опрашиваемое подсостояние Booting |
| 2 | BLOCKING | 0001/0002/0007 | единицы safe area (CSS px против px окна) → `window_get_size()` |
| 3 | minor | 0006 | `TapPicker` (RefCounted) не получает `_unhandled_input` → узел `TapInput` |
| 4 | minor | 0002/0006 | HUD-`Control` по умолчанию `STOP` глотает тапы → `MOUSE_FILTER_IGNORE` |
| 5 | minor | 0001 | `create_callback` передаёт `Array` → `_on_js_visibility(args: Array)` |
| 6 | minor | 0001/0003 | вкладка, открытая в фоне, не шлёт `visibilitychange` → `is_visible()` из `visibilityState` |
| 7 | minor | 0003/0005 | flush вызывался из lifecycle → перенесён в обработчик `_compose()` |
| 8 | minor | 0001 | синхронный callback только в single-thread → отмечено как риск |
| 9 | minor | 0007 | `max_fps` на web может работать → риск переформулирован |
| 10 | minor | 0007 | WebAudio до жеста suspended → прогрев только decode, иначе на первом тапе |
| 11 | minor | 0007 | правило Time против `UtcClock` → исключение для адаптеров |
| 12 | minor | 0002 | `render_priority` работает только для прозрачных → оверлеи alpha-blend, outline ниже |
| 13 | minor | 0002 | `scaling_3d_scale` < 1 добавляет blit → замер на spike |
| 14 | minor | 0002 | offset-transform анимируется через `sim_dt`/`ui_dt`, не `Tween` |

Проверено специалистом и в порядке: JS-callback приходят между кадрами (assert `_in_tick` корректен); запись `localStorage` внутри callback безопасна; единицы viewport под `canvas_items` верны; фильтр `DEVICE_ID_EMULATION` верен; `map_force_update` только в Booting допустим; пре-прогрев через `frame_post_draw` работает.

---

## Architecture Document Coverage
- Все 10 MVP-систем из systems-index есть в слоях и Module Ownership; системы VS+ исключены намеренно (записано в документе). Осиротевших модулей нет.
- Исправлено: заголовок «ADRs Referenced» (не было 0006/0007); раздел ADR Audit («ADR пока нет, 0 из 164»); слой Platform (IndexedDB → localStorage); строки PlatformBridge (px окна, `is_visible`, `Failed`), Brewing (`GameClock.step_dt` → `step(dt)`), GuestSim («агент навигации» → `Navigator`); добавлен **Principle 6 «Без 3D-физики»** — на него ссылались ADR-0003, ADR-0006 и таблица рисков, но в списке его не было.
- Остаток: в Data Flow нет связи HUD → Audio (TR-hud-018); это нормально, пока Audio не выйдет из статуса VS.

---

## Verdict: **CONCERNS**

Пробелов и неразрешённых конфликтов нет. Оба блокирующих конфликта (единицы safe area, `await` в тике) найдены и исправлены в этом проходе. Вердикт CONCERNS, потому что **все 145 покрытых требований держатся на Proposed-ADR** и 11 покрыты частично. Путь к PASS — accept ADR по порядку выше.

### Required ADRs
Новых ADR не требуется. Нужно перевести существующие в Accepted:
1. ADR-0001: провести spike на слабом Android (размер, TTI, visibility, touch latency, `localStorage` после рестарта) и решить вопрос iOS.
2. ADR-0002 и ADR-0003: проверки из их Verification на том же устройстве; перед этим обновить `modules/rendering.md` и `ui.md` до 4.7.
3. ADR-0004, ADR-0005, ADR-0007 (+ подпись TD), затем ADR-0006 (перед ним обновить `modules/input.md`).
