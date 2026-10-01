# Story 001: PlayerStats: ключи stats.*, загрузка и валидация recent

> **Epic**: Player Stats
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: `design/gdd/player-stats.md`
**Requirement**: `TR-flow-025`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Local persistence (SaveStore); ADR-0004: Data config & load-time validation
**ADR Decision Summary**: `SaveStore` — in-memory модель с owner-scope (`SaveScope`), один версионированный JSON-блоб, валидация каждого ключа с дефолтом, flush раз за тик (шаг 6) и при скрытии страницы; backend: `localStorage` (web) / `user://` (desktop) / `MemoryBackend` (тесты).
**ADR Version**: 2026-09-30

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Web-путь persistence — HIGH (`localStorage` через helper HTML-шелла, не `user://`). В юнит-тестах только `MemoryBackend`; `WebStorageBackend` покрыт on-device spike. JSON-числа возвращаются как float — читать через валидатор.

**Control Manifest Rules (this layer)**:
- Required: доступ к сохранению только через инъектированный `SaveScope`; каждый ключ объявлен (`declare_*`) с default и диапазоном до первого чтения (from ADR-0005)
- Required: владелец сам не вызывает `flush_if_dirty()`; flush — шаг 6 тика и скрытие страницы (from ADR-0005)
- Forbidden: запись `match_score` и внутриматчевого состояния в SaveStore; `user://` на web; владелец не создаёт backend (from ADR-0005)
- Required: каждое тюнинг-значение из GDD — `@export` поле `Resource` со статическим типом и sentinel-дефолтом; новое поле поставляется вместе с правилом валидатора (from ADR-0004)
- Required: конфиг инъектируется через конструктор; в юнит-тестах — фабрика `ConfigFactory.valid()` + оверрайды, не загрузка `.tres` (from ADR-0004)
- Forbidden: числовые литералы тюнинг-значений в коде, `load()`/`preload()` конфига внутри модуля, запись в конфиг (from ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/player-stats.md`, scoped to this story:*

- [ ] Класс `PlayerStats` (`RefCounted`, DI: `SaveScope`, `UtcClock`, `TillConfig`, `FlowConfig`) объявляет ключи `stats.shifts_played`, `cups_served`, `days_filled`, `streak`, `best_streak` (int ≥ 0), `streak_last_day` (int ≥ −1), `recent` (text, `max_length = 1024`) с default из GDD; первый запуск → нули, `recent = []`, `streak_last_day = −1`
- [ ] `stats.recent = "not json"` (а также `"[{]"`, >`recent_max` записей, отрицательный score, строковый score) → `recent = []`, остальные ключи сохраняются, одна запись в лог (AC 7)
- [ ] `FlowConfig.recent_shifts_max` (default 5, валидатор `1…20`) добавлен вместе с правилом `ConfigValidator`; PlayerStats — единственный писатель префикса `stats`

---

## Implementation Notes

Пишется с нуля (TDD): сначала тест на загрузку/валидацию, затем код. Зависит от `SaveScope.declare_text/read_text/write_text` (ADR-0005 поправка 2026-10-01) — если Foundation-эпик SaveStore ещё не содержит этих методов, сначала они. Внутренний формат `recent` — JSON-массив `{score, coins, new_record}`, числа проверять как конечные целые (JSON возвращает float). GDD Open Question 1 (отдельный модуль vs счётчики в Currency/Till) закрыт architecture.md: отдельный модуль `PlayerStats` (Feature/Meta).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002–005: сами правила обновления
- Story 006: интеграция

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player_stats/player_stats_load_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: SaveScope.declare_text (Foundation); FlowConfig (Config-фундамент)
- Unlocks: Story 002–005
