extends Node
## Loads every script and scene under res:// so parse errors and broken references fail the check.

const SKIP_DIRS := ["res://.godot", "res://build", "res://addons"]


func _ready() -> void:
	var errors := 0
	for path in _collect("res://"):
		var resource := load(path)
		if resource == null:
			printerr("FAIL cannot load ", path)
			errors += 1
		elif resource is GDScript and not (resource as GDScript).can_instantiate():
			printerr("FAIL script does not compile ", path)
			errors += 1
	print("check_project: %d error(s)" % errors)
	get_tree().quit(1 if errors > 0 else 0)


func _collect(dir: String) -> PackedStringArray:
	var found: PackedStringArray = []
	for sub in DirAccess.get_directories_at(dir):
		var path := dir.path_join(sub)
		if not SKIP_DIRS.has(path):
			found.append_array(_collect(path))
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() in ["gd", "tscn", "tres", "gdshader"]:
			found.append(dir.path_join(file))
	return found
