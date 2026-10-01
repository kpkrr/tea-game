# Story 006: SaveStore + SaveScope: схема v1, аддитивные ключи, валидация значений

> **Epic**: Foundation Runtime (Clock, Director, Config, Save)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: — (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD)
**Requirement**: `TR-flow-027`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Local persistence (SaveStore)
**ADR Decision Summary**: Один JSON-блоб, плоские dotted-ключи, schema_version; SaveScope(owner) декларирует ключи с default/range; backend: localStorage через хелпер оболочки на web, user:// + атомарная замена на desktop.
**ADR Version**: 2026-09-30 (Last Verified)

**Engine**: Godot 4.7.2 | **Risk**: HIGH (web path)
**Engine Notes**: user:// на web не используется (IDBFS sync не гарантирован); JSON.parse_string печатает ERROR — использовать экземпляр JSON.parse(); числа из JSON — float, проверять finite/integral/range; rename_absolute на Win/Linux проверить перед не-web релизом.

**Control Manifest Rules (this layer)**:
- Required (from ADR-0005): доступ к сохранению только через инжектированный `SaveScope`; ключи декларируются (default + range) до первого чтения; `flush_if_dirty()` — только MatchDirector step 6 и page-hide
- Forbidden (from ADR-0005): `user://` на web; `JSON.parse_string`; прямой `FileAccess`/`localStorage` в owner-коде; запись `match_score`/состояния матча; перезапись сейва с более новой `schema_version`
- Guardrail (from ADR-0005): сбой сохранения никогда не блокирует boot или матч — откат к defaults, лог один раз

---

## Acceptance Criteria

*From the TR-IDs / ADR guidelines above, scoped to this story:*

- [ ] `open(backend)` никогда не падает: пустой/повреждённый JSON -> defaults + бэкап сырого блоба; `schema_version` неизвестная/старая -> defaults + бэкап; версия НОВЕЕ `SCHEMA_VERSION` (=1) -> `persistent=false`, сейв не перезаписывается
- [ ] Ключи — плоские dotted `owner.key`; `declare_int/string/bool` задают default и range; любое значение из блоба проходит валидацию (число = float, finite, integral, в диапазоне -> `int()`); плохое -> default + один warning
- [ ] Новые ключи аддитивны: блоб со старым набором ключей читается без потери данных, `schema_version` остаётся 1 (TR-flow-027); объявленный ключ `stats.recent` — строка с валидируемым JSON-содержимым (невалидный JSON -> default)
- [ ] `flush_if_dirty()` пишет блоб только при изменении; чтение/запись необъявленного ключа — assert в debug; `match_score` не сохраняется

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/save_store.gd` (131 строка) в `src/foundation/save_store.gd`. Парсинг через экземпляр `JSON.parse()`, не `parse_string`. Добавить: вид `json_string` (валидируется разбором JSON и проверкой формы) для `stats.recent`; список ключей из game-flow/currency/till/audio GDD регистрируют их owner'ы — здесь только механизм. Юнит-тесты на `MemoryBackend`. Статическая типизация везде, doc-комментарии (`##`) на публичном API, зависимости через конструктор (DI), без синглтонов.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: Web/File backends
- Объявление конкретных ключей — feature-эпики (Currency, Till, GameFlow, Audio)
- Вызов `flush_if_dirty()` — story 009

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save_store/save_store_schema_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 007, 009
