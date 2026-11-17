extends Node
## 定向执行同一组测试，避免全局runner预加载无关旧原型。

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var total_passed: int = 0
	var total_failed: int = 0
	for script: GDScript in [preload("res://tests/test_combat_whitebox.gd"),preload("res://tests/test_sword_whitebox.gd"),preload("res://tests/test_whitebox_timeline.gd"),preload("res://tests/test_whitebox_animation.gd"),preload("res://tests/test_whitebox_pad_input.gd"),preload("res://tests/test_whitebox_tap_input.gd"),preload("res://tests/test_whitebox_basic_motion.gd"),preload("res://tests/test_whitebox_hit_feedback.gd")]:
		var result: Vector2i = await _run_suite(script)
		total_passed += result.x
		total_failed += result.y
	print("WHITEBOX: %d passed, %d failed" % [total_passed,total_failed])
	get_tree().quit(0 if total_failed == 0 else 1)

func _run_suite(script: GDScript) -> Vector2i:
	var suite: TestSuite = script.new()
	suite.tree = get_tree()
	var passed: int = 0
	var failed: int = 0
	for method: Dictionary in suite.get_method_list():
		var key: String = str(method.name)
		if not key.begins_with("test_"): continue
		suite.failures.clear()
		await suite.before_each()
		await suite.call(key)
		await suite.after_each()
		if suite.failures.is_empty():
			passed += 1
			print("PASS ",key)
		else:
			failed += 1
			for message: String in suite.failures: printerr("FAIL ",key,": ",message)
	return Vector2i(passed,failed)
