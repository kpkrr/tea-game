# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## One JSON blob with flat dotted keys (ADR-0005). Owners get a SaveScope that
## only touches their prefix; bad values fall back to the owner's default per key.
## Only MatchDirector (tick step 6) and the page-hide handler flush.

const SCHEMA_VERSION := 1

var persistent: bool:
	get: return _persistent

var _backend: RefCounted
var _values := {}
var _decl := {}  # full key -> {kind, default, min, max, allowed}
var _dirty := false
var _persistent := true
var _raw := {}


## Reads the blob once; never fails (bad data -> defaults, no storage -> in-memory).
func open(backend: RefCounted) -> void:
	_backend = backend
	if not backend.available():
		_persistent = false
		return
	var blob: String = backend.read_blob()
	if blob == "":
		return
	var json := JSON.new()
	if json.parse(blob) != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("save: corrupt blob, using defaults")
		backend.write_backup(blob)
		return
	var data: Dictionary = json.data
	var version: Variant = data.get("schema_version")
	if typeof(version) != TYPE_FLOAT or version != float(SCHEMA_VERSION):
		if typeof(version) == TYPE_FLOAT and version > SCHEMA_VERSION:
			_persistent = false  # never overwrite a newer save
		else:
			backend.write_backup(blob)
		return
	_raw = data


func scope(owner: StringName) -> SaveScope:
	return SaveScope.new(self, String(owner))


## Writes the blob if anything changed since the last flush.
func flush_if_dirty() -> void:
	if not _dirty:
		return
	_dirty = false
	if not _persistent:
		return
	var out := {"schema_version": SCHEMA_VERSION}
	out.merge(_values)
	if not _backend.write_blob(JSON.stringify(out)):
		_persistent = false


func _declare(key: String, spec: Dictionary) -> void:
	_decl[key] = spec
	_values[key] = _validated(key, _raw.get(key))


func _validated(key: String, v: Variant) -> Variant:
	var spec: Dictionary = _decl[key]
	match spec.kind:
		"int":
			if typeof(v) == TYPE_FLOAT and is_finite(v) and v == floorf(v) and v >= spec.min and v <= spec.max:
				return int(v)
		"string":
			if typeof(v) == TYPE_STRING and v in spec.allowed:
				return v
		"bool":
			if typeof(v) == TYPE_BOOL:
				return v
	if v != null:
		push_warning("save: bad value for %s, using default" % key)
	return spec.default


func _read(key: String) -> Variant:
	assert(key in _decl, "save key read before declare: " + key)
	return _values.get(key)


func _write(key: String, v: Variant) -> void:
	assert(key in _decl, "save key written before declare: " + key)
	if _values.get(key) != v:
		_values[key] = v
		_dirty = true


class SaveScope extends RefCounted:
	var _store: RefCounted
	var _prefix: String

	func _init(store: RefCounted, owner: String) -> void:
		_store = store
		_prefix = owner + "."

	func declare_int(key: String, default: int, min_v: int, max_v: int) -> void:
		_store._declare(_prefix + key, {"kind": "int", "default": default, "min": min_v, "max": max_v})

	func declare_string(key: String, default: String, allowed: PackedStringArray) -> void:
		_store._declare(_prefix + key, {"kind": "string", "default": default, "allowed": allowed})

	func declare_bool(key: String, default: bool) -> void:
		_store._declare(_prefix + key, {"kind": "bool", "default": default})

	func read_int(key: String) -> int:
		return _store._read(_prefix + key)

	func write_int(key: String, v: int) -> void:
		_store._write(_prefix + key, v)

	func read_string(key: String) -> String:
		return _store._read(_prefix + key)

	func write_string(key: String, v: String) -> void:
		_store._write(_prefix + key, v)

	func read_bool(key: String) -> bool:
		return _store._read(_prefix + key)

	func write_bool(key: String, v: bool) -> void:
		_store._write(_prefix + key, v)
