# Sprint 1 — 2026-10-02 to 2026-10-15

## Sprint Goal
Доказать новый визуал на реальном web-рендере — спайки S1–S5 пройдены (S5 — перспективная камера-диорама, решение владельца 2026-10-01), toon-шейдер готов, пилот арта (бариста + одна станция) стоит в движке — и заложить в `src/` минимальный фундамент (часы, конфиги, данные кухни), на который встанет порт среза в Sprint 2.

## Capacity
- Total days: 10 (2 недели, соло-владелец + агенты)
- Buffer (20%): 2 дня
- Available: 8 дней
- Must Have: 8.0 дн. · Should Have: 4.5 дн. · Nice to Have: 4.25 дн.
- Оценки: S = 0,25 дн., M = 0,5 дн., L = 1 дн. (из story-файлов)

Milestone: не определён (`production/milestones/` нет) — план строится по бэклогу эпиков. Risk register нет — риски ниже оценены по содержимому спринта.

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| VP-001 | [Spike S1: тени + прокси + стоимость toon-шейдера](../epics/visual-pipeline/story-001-spike-s1-shadow-toon-cost.md) | technical-artist | 1.0 (L) | — | см. story |
| VP-002 | [Spike S2: vertex AO / LightmapGI на WebGL2, порядок опаков и спрайтов](../epics/visual-pipeline/story-002-spike-s2-lightmap-vertex-ao-sort-order.md) | technical-artist | 0.5 (M) | — | см. story |
| VP-003 | [Spike S3: мерцание спрайтов 192×256 без мипов](../epics/visual-pipeline/story-003-spike-s3-unmipped-sprite-shimmer.md) | technical-artist | 0.25 (S) | — | см. story |
| VP-004 | [Spike S4: оверлеи вне тумана и грейдинга](../epics/visual-pipeline/story-004-spike-s4-overlays-outside-fog-grading.md) | technical-artist | 0.5 (M) | — | см. story |
| VP-013 | [Spike S5: перспективная камера-диорама — fit, stretch, оверлеи, стоимость декораций/VFX, tilt-shift](../epics/visual-pipeline/story-013-spike-s5-perspective-diorama-camera.md) | technical-artist | 0.5 (M) | — (параллельно VP-001) | см. story — добавлено 2026-10-01 по решению владельца (камера-диорама); блокирует пилот: арт рисуется под 52° |
| VP-005 | [Toon-шейдер спрайтов](../epics/visual-pipeline/story-005-toon-sprite-shader.md) | godot-shader-specialist | 0.5 (M) | VP-001, VP-003 | см. story |
| AA-001 | [Стайл-фрейм чайной-диорамы (ref-01) + спеки + Master Style Reference](../epics/art-assets/story-001-asset-specs-msr-provenance.md) | art-director + владелец (утверждение) | 1.0 (L) | — | см. story |
| AA-002 | [Импорт-пайплайн: папки, пресеты, скрипт валидации](../epics/art-assets/story-002-import-pipeline-validation.md) | tools-programmer | 0.5 (M) | — | см. story |
| AA-003 | [ПИЛОТ: бариста + одна станция через весь пайплайн](../epics/art-assets/story-003-pilot-barista-and-station.md) | art-director + technical-artist | 1.0 (L) | AA-001, AA-002, VP-005, VP-013 | см. story |
| FR-001 | [GameClock: время, пауза, clamp](../epics/foundation-runtime/story-001-game-clock.md) | godot-gdscript-specialist | 0.25 (S) | — | см. story |
| FR-002 | [GameConfig + ConfigLoader](../epics/foundation-runtime/story-002-game-config-loader.md) | godot-gdscript-specialist | 0.5 (M) | — | см. story |
| FR-003 | [ConfigValidator](../epics/foundation-runtime/story-003-config-validator.md) | godot-gdscript-specialist | 0.5 (M) | FR-002 | см. story |
| KL-001 | [KitchenConfig: схема](../epics/kitchen-layout/story-001-kitchen-config-schema.md) | gameplay-programmer | 0.5 (M) | FR-002 | см. story |
| KL-002 | [Данные кухни: станции, остров, слоты, мусорка](../epics/kitchen-layout/story-002-kitchen-stations-slots-data.md) | gameplay-programmer | 0.5 (M) | KL-001 | см. story |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| VP-006 | [Материал окружения с запечённым vertex color](../epics/visual-pipeline/story-006-baked-vertex-color-environment-material.md) | technical-artist | 0.5 (M) | VP-002 | см. story |
| VP-007 | [DirectionalLight3D + прокси-капсулы теней](../epics/visual-pipeline/story-007-directional-light-shadow-proxies.md) | technical-artist | 0.5 (M) | VP-001, VP-005 | см. story |
| KL-003 | [Данные: касса, spawn, очередь, выход](../epics/kitchen-layout/story-003-till-and-guest-points-data.md) | gameplay-programmer | 0.25 (S) | KL-001, KL-002 | см. story |
| KL-004 | [KitchenLayout: геометрия, ID, pick-якоря](../epics/kitchen-layout/story-004-kitchen-layout-derived-geometry.md) | gameplay-programmer | 1.0 (L) | KL-001..003 | см. story |
| FR-005 | [Rng + UtcClock](../epics/foundation-runtime/story-005-rng-utc-clock.md) | godot-gdscript-specialist | 0.25 (S) | — | см. story |
| FR-006 | [SaveStore + SaveScope v1](../epics/foundation-runtime/story-006-save-store-core.md) | godot-gdscript-specialist | 0.5 (M) | — | см. story |
| VF-001 | [ViewConfig + явный stretch](../epics/view-fit/story-001-view-config-and-stretch.md) | godot-specialist | 0.25 (S) | FR-003 | см. story |
| VF-002 | [ViewFitMath: clamp + letterbox](../epics/view-fit/story-002-playfield-clamp-and-letterbox.md) | godot-specialist | 0.25 (S) | — | см. story |
| VF-003 | [ViewFitMath.solve_camera: перспективная камера](../epics/view-fit/story-003-kitchen-scale-and-camera-offsets.md) | godot-specialist | 1.0 (L) | VF-002 | см. story (оценка M → L 2026-10-01) |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| FR-004 | [CI-проверка game_config.tres](../epics/foundation-runtime/story-004-shipped-config-validation.md) | godot-gdscript-specialist | 0.25 (S) | FR-002, FR-003 | см. story |
| FR-007 | [Save backends: Memory/File/WebStorage](../epics/foundation-runtime/story-007-save-backends.md) | godot-gdscript-specialist | 0.5 (M) | FR-006 | см. story |
| VF-004 | [Резерв HUD-полосы Mode A/C](../epics/view-fit/story-004-hud-strip-reserve-mode-c.md) | godot-specialist | 0.5 (M) | VF-001, VF-003 | см. story |
| VF-005 | [Нода ViewFit → камера](../epics/view-fit/story-005-view-fit-node-camera-apply.md) | godot-specialist | 0.5 (M) | VF-001..004, PS-001 | см. story |
| PS-001 | [PlatformBridge core](../epics/platform-shell/story-001-platform-bridge-core.md) | godot-specialist | 0.5 (M) | — | см. story |
| PS-007 | [PerfProbe (нужен спайкам для замеров)](../epics/platform-shell/story-007-perf-probe.md) | performance-analyst | 0.5 (M) | — | см. story |
| AJ-001 | [Audio spike S1: stems в AudioStreamSynchronized на web](../epics/audio-juice/story-001-spike-s1-synchronized-stems-web.md) | audio-director | 1.0 (L) | — | см. story |
| AJ-003 | [Audio spike S3: Sample, mute, полифония, QOA](../epics/audio-juice/story-003-spike-s3-sample-latency-bus-mute-polyphony.md) | audio-director | 0.5 (M) | — | см. story |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|-------------|
| — | Первый спринт | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Спайки S1/S2 провалятся на WebGL2 (тени/LightmapGI слишком дорогие) | Medium | High | Уровни качества: Low без реальных теней уже заложен (TR-art-006); фолбэк — только blob-тени + vertex AO. Решение фиксируется в evidence до AA-003 |
| Нет слабого Android под рукой для замеров | Medium | Medium | Story допускает «NOT MEASURED + причина»; iPhone проверен 2026-09-30; замер переносится в platform-shell 008 |
| AI-генерация не держит стиль между кадрами/ракурсами | High | High | AA-001 фиксирует Master Style Reference и промпты; пилот AA-003 на одном персонаже до массового производства |
| Кросс-эпиковые зависимости (KitchenConfig ждёт ConfigLoader) | Low | Medium | FR-002 первым в очереди программирования; валидаторы с фолбэком на чистую функцию |
| Нет QA-плана | — | Low | Критерии приёмки и тест-пути уже в каждой story; `/qa-plan sprint` до закрытия спринта |

## Dependencies on External Factors
- Владелец: доступ к слабому Android-телефону для спайков (желательно)
- Владелец: инструмент AI-генерации изображений и одобрение стиля пилота
- Открыто, но не блокирует Sprint 1: `till_capacity` (замеры владельца), `medium_share_of_remaining`, домен + `feedback_url`

> ⚠️ **No QA Plan**: This sprint was started without a QA plan. Run `/qa-plan sprint`
> before the last story is implemented. The Production → Polish gate requires a QA
> sign-off report, which requires a QA plan.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-1.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
