class_name TestSuite
extends RefCounted
## Base class for tests/test_*.gd. Methods named test_* run in file order; they may await.

const TEST_SAVE := "user://test-save.json"

var tree: SceneTree
var failures: Array[String] = []
var _nodes: Array[Node] = []


func before_each() -> void:
	GameState.save_path = TEST_SAVE
	GameState.autosave = false
	SaveService.erase(TEST_SAVE)
	GameState.apply(SaveService.default_data())


func after_each() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	_nodes.clear()
	await tree.process_frame
	SaveService.erase(TEST_SAVE)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])


## Adds a node to the running tree and frees it after the test.
func add(node: Node) -> Node:
	tree.root.add_child(node)
	_nodes.append(node)
	return node


func physics_frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
