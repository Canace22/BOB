class_name SaveService
extends RefCounted
## Persistent progress file: atomic write, .bak fallback, validation.
## Format and migration rules: docs/architecture.md#存档

const VERSION := 1
const DEFAULT_PATH := "user://save.json"
const START_ROOM := "R1-01"


static func default_data() -> Dictionary:
	return {"version": VERSION, "checkpoint_room": START_ROOM, "abilities": [], "flags": []}


static func write(data: Dictionary, path: String = DEFAULT_PATH) -> bool:
	if validate(data).is_empty():
		return false
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save %s: %s" % [tmp, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	# A corrupt primary must never replace the last valid backup.
	if not _parse(path).is_empty():
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			return false
	return DirAccess.rename_absolute(tmp, path) == OK


static func read(path: String = DEFAULT_PATH) -> Dictionary:
	for candidate: String in [path, path + ".bak"]:
		var data := _parse(candidate)
		if not data.is_empty():
			return data
	return default_data()


static func erase(path: String = DEFAULT_PATH) -> void:
	for candidate: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(candidate)


static func migrate(data: Dictionary) -> Dictionary:
	# Version 1 is current. Add `if version == 1: ...` steps here when the format changes.
	return data


static func validate(data: Dictionary) -> Dictionary:
	if data.get("version", 0) != VERSION:
		return {}
	var room: Variant = data.get("checkpoint_room")
	if not room is String or not WorldGraph.ROOMS.has(room):
		return {}
	var result := {"version": VERSION, "checkpoint_room": room}
	for key: String in ["abilities", "flags"]:
		var list: Variant = data.get(key)
		if not list is Array:
			return {}
		for item: Variant in list:
			if not item is String:
				return {}
		result[key] = (list as Array).duplicate()
	return result


static func _parse(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return {}
	return validate(migrate(json.data))
