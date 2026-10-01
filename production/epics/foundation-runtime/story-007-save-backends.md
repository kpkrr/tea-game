# Story 007: Save backends: Memory, File (атомарная замена), WebStorage (localStorage)

> **Epic**: Foundation Runtime (Clock, Director, Config, Save)
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A — no control manifest (standard tier)
> **Last Updated**: —

## Context

**GDD**: — (инфраструктура из ADR-0003/0004/0005; обслуживает все GDD)
**Requirement**: `TR-flow-027` (round-trip схемы v1 через реальные backend'ы)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Local persistence (SaveStore)
- Secondary: ADR-0001: Web build & platform shell (Last Verified 2026-10-01)
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

- [ ] `MemoryBackend` реализует контракт `available()/read_blob()/write_blob()/write_backup()` и используется во всех unit-тестах; `FileBackend` пишет во временный файл и заменяет цель через `DirAccess.rename_absolute` (round-trip-тест в `user://` тестовой папки)
- [ ] `WebStorageBackend` хранит результат `read()` в нетипизированном `Variant`, проверяет тип до конвертации (`null` = пусто/заблокировано), все вызовы к `window.teaRushSave` защищены; при `available=false` SaveStore работает в памяти и игра грузится
- [ ] Backend выбирается по платформе в composition root: `OS.has_feature("web")` -> WebStorage, иначе File; `user://` на web не используется
- [ ] Интеграционный тест: запись -> новый `SaveStore.open()` на том же backend возвращает те же значения (Memory и File)

---

## Implementation Notes

Port from `prototypes/tea-rush-vertical-slice/src/foundation/save_backends.gd` (3 класса). Разнести по файлам `src/foundation/save/`. JS-хелпер `window.teaRushSave` живёт в HTML-оболочке (platform-shell story 004), в срезе он инлайнится из `platform_bridge.gd` (`SAVE_JS`) — в продакшене инлайн убрать. WebStorage покрывается on-device spike (platform-shell story 008) и web smoke-тестом, а не unit-тестом. Проверка `rename_absolute` на Windows/Linux — до не-web релиза (ADR-0005).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- HTML-хелпер `teaRushSave` — platform-shell story 004
- Проверка сохранения на слабом Android — platform-shell story 008

---

## QA Test Cases

*N/A — no qa-lead specs at this tier (lean); implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save_store/save_backends_roundtrip_test.gd` — must exist and pass (или документированный playtest)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 006
- Unlocks: Story 009; platform-shell 008
