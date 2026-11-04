class_name StoryProgress
extends RefCounted
## Isolated chapter state. Publish changes only after the atomic file replacement succeeds.

const VERSION := 1
const ROOM_ID := "story-c01-xuting"
const STAGES: Array[String] = [
	"c01.met_mender", "c01.foragers_retreated", "c01.route_known", "c01.completed"
]

var path: String = "user://story-c01/progress.json"
var flags: Dictionary:
	get: return _flags.duplicate()
var last_error: Error = OK
var last_message: String = ""
var recovered_from_backup: bool = false
var _flags: Dictionary = {}

func _init(save_path: String = "user://story-c01/progress.json") -> void:
	path = save_path

func has_flag(id: String) -> bool:
	return _flags.get(id, false) == true

func load_progress() -> bool:
	_flags.clear()
	recovered_from_backup = false
	_report(OK, "")
	var data: Dictionary = _read(path)
	if not data.is_empty():
		_flags = data.flags.duplicate()
		return true
	var backup: Dictionary = _read(path + ".bak")
	if not backup.is_empty():
		var error: Error = _write(backup.flags, false)
		if error != OK:
			_report(error, "备份可用，但恢复写入失败。请重试。")
			return false
		_flags = backup.flags.duplicate()
		recovered_from_backup = true
		_report(OK, "存档已从上一次完整备份恢复。")
		return true
	var exists: bool = FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")
	_report(ERR_FILE_CORRUPT if exists else ERR_FILE_NOT_FOUND,
		"章节存档损坏，无法继续；开始新旅途会保留原文件。" if exists else "尚无章节存档。")
	return false

func advance(id: String) -> Error:
	var index: int = STAGES.find(id)
	if index < 0: return _report(ERR_INVALID_PARAMETER, "未知章节事件。")
	if has_flag(id): return _report(OK, "")
	if index > 0 and not has_flag(STAGES[index - 1]):
		return _report(ERR_INVALID_DATA, "尚未完成前置事件。")
	var next: Dictionary = _flags.duplicate()
	next[id] = true
	var error: Error = _write(next)
	if error != OK: return _report(error, "进度保存失败，请重试当前交互。")
	_flags = next
	return _report(OK, "")

func reset_progress() -> Error:
	if FileAccess.file_exists(path):
		var copy_error: Error = DirAccess.copy_absolute(path, path + ".before-new")
		if copy_error != OK: return _report(copy_error, "无法备份原旅途，新旅途未开始。")
	var error: Error = _write({})
	if error != OK: return _report(error, "新旅途保存失败，原进度仍保留。")
	_flags.clear()
	recovered_from_backup = false
	return _report(OK, "")

func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path): return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null: return {}
	var parser := JSON.new()
	var source: String = file.get_as_text()
	file.close()
	if parser.parse(source) != OK: return {}
	var data: Variant = parser.data
	if not data is Dictionary: return {}
	var version: Variant = data.get("version")
	if not (version is int or version is float) or version != VERSION: return {}
	if data.get("room_id") != ROOM_ID: return {}
	var saved_flags: Variant = data.get("flags")
	if not saved_flags is Dictionary: return {}
	for key: Variant in saved_flags:
		if not key is String or not STAGES.has(key): return {}
		if not saved_flags[key] is bool or saved_flags[key] != true: return {}
	var gap: bool = false
	for id: String in STAGES:
		if not saved_flags.has(id): gap = true
		elif gap: return {}
	return data

func _write(next: Dictionary, retain_backup: bool = true) -> Error:
	var error: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK: return error
	var temporary: String = path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"version": VERSION, "room_id": ROOM_ID, "flags": next}, "\t"))
	file.flush()
	error = file.get_error()
	file.close()
	if error != OK: return error
	if retain_backup and FileAccess.file_exists(path):
		error = DirAccess.copy_absolute(path, path + ".bak")
		if error != OK: return error
	return DirAccess.rename_absolute(temporary, path)

func _report(error: Error, message: String) -> Error:
	last_error = error
	last_message = message
	return error
