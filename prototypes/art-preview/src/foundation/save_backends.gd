# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: can a new player feel "barista holding the rush hour" in ~3 min, and can we build the full GDD loop at representative quality?
# Date: 2026-09-30
extends RefCounted
## Storage backends for SaveStore: browser localStorage, desktop file, memory.


class WebStorageBackend extends RefCounted:
	var _js: JavaScriptObject

	func _init() -> void:
		_js = JavaScriptBridge.get_interface("teaRushSave")

	func available() -> bool:
		return _js != null and bool(_js.available)

	func read_blob() -> String:
		var v: Variant = _js.read()
		return "" if v == null else str(v)

	func write_blob(s: String) -> bool:
		return bool(_js.write(s))

	func write_backup(s: String) -> void:
		_js.backup(s)


class FileBackend extends RefCounted:
	const PATH := "user://tea_rush_save.json"

	func available() -> bool:
		return true

	func read_blob() -> String:
		for p: String in [PATH, PATH + ".tmp"]:
			if FileAccess.file_exists(p):
				return FileAccess.get_file_as_string(p)
		return ""

	func write_blob(s: String) -> bool:
		var f := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
		if f == null:
			return false
		f.store_string(s)
		f.close()
		return DirAccess.rename_absolute(PATH + ".tmp", PATH) == OK

	func write_backup(s: String) -> void:
		var f := FileAccess.open(PATH + ".corrupt", FileAccess.WRITE)
		if f:
			f.store_string(s)


class MemoryBackend extends RefCounted:
	var blob := ""
	var writes := 0
	var ok := true

	func available() -> bool:
		return ok

	func read_blob() -> String:
		return blob

	func write_blob(s: String) -> bool:
		blob = s
		writes += 1
		return ok

	func write_backup(_s: String) -> void:
		pass
