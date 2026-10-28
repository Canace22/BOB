extends Node
## Headless runner scene (autoloads available): node tools/godot.mjs test [-- --filter=name]
## Quits with exit code 0 when every test passes.

const TEST_DIR := "res://tests/"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var filter := _filter()
	var passed := 0
	var failed := 0
	for path in _test_files():
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			printerr("FAIL cannot load test suite: ", path)
			failed += 1
			continue
		var suite: TestSuite = script.new()
		suite.tree = get_tree()
		for method in _test_methods(suite):
			if not filter.is_empty() and not (path + method).contains(filter):
				continue
			suite.failures.clear()
			await suite.before_each()
			await suite.call(method)
			await suite.after_each()
			if suite.failures.is_empty():
				passed += 1
				print("PASS %s::%s" % [path.get_file(), method])
			else:
				failed += 1
				for message: String in suite.failures:
					printerr("FAIL %s::%s  %s" % [path.get_file(), method, message])
	print("\n%d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


func _test_files() -> PackedStringArray:
	var files: PackedStringArray = []
	for file in DirAccess.get_files_at(TEST_DIR):
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_suite.gd":
			files.append(TEST_DIR + file)
	files.sort()
	return files


func _test_methods(suite: TestSuite) -> PackedStringArray:
	var names: PackedStringArray = []
	for method: Dictionary in suite.get_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_"):
			names.append(method_name)
	return names


func _filter() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			return arg.trim_prefix("--filter=")
	return ""
