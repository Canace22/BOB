class_name WhaleUISaveAccess
extends RefCounted
## V6 validation shared by the title and campaign loader; optional fields stay compatible.
static func read(path: String, rooms: Array) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return {}
	var value: Variant = parser.data
	if not value is Dictionary or int(value.get("version", 0)) != 6: return {}
	var checkpoint: Variant = value.get("checkpoint")
	if not checkpoint is Dictionary: return {}
	var index: Variant = checkpoint.get("room")
	if not (index is int or index is float) or int(index) < 0 or int(index) >= rooms.size(): return {}
	var pos: Variant = checkpoint.get("pos")
	if not pos is Array or (pos.size() != 0 and pos.size() != 2): return {}
	for coordinate: Variant in pos:
		if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)): return {}
	for field: String in ["abilities", "collected", "defeated", "visited"]:
		if value.has(field) and not value[field] is Dictionary: return {}
	if value.has("narrative"):
		var story: Variant = value.narrative
		if not story is Dictionary: return {}
		if not story.get("seen",{}) is Dictionary or not story.get("objective",{}) is Dictionary: return {}
		for key: Variant in story.get("seen",{}):
			if not key is String or not story.seen[key] is bool: return {}
		for key: String in ["id","text","room"]:
			if not story.get("objective",{}).get(key,"") is String: return {}
	if value.has("chapter_story"):
		var chapter: Variant=value.chapter_story
		if not chapter is Dictionary or int(chapter.get("version",0))!=1: return {}
		if not chapter.get("completed",[]) is Array or not chapter.get("facts",{}) is Dictionary: return {}
		for id: Variant in chapter.get("completed",[]):
			if not id is String: return {}
	return value

static func write(path: String, payload: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var temp: String = path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK: return error
	if FileAccess.file_exists(path):
		error = DirAccess.copy_absolute(path, path + ".bak")
		if error != OK: return error
	return DirAccess.rename_absolute(temp, path)
