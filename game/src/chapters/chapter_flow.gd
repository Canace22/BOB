class_name ChapterFlow
extends Node
## One chapter save, two scene lifetimes. A scene exits before the next enters.

@export var progress_path := "user://chapters-v1.json"
var current: Node
var switching := false


func _ready() -> void:
	_show_journey()


func _clear_scene() -> void:
	if is_instance_valid(current):
		# Drop the JS handle before freeing its Godot callback owner.
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.render_game_to_text = undefined; window.bob_snapshot = undefined;")
		remove_child(current)
		current.free()
	get_tree().paused = false


func _show_journey() -> void:
	_clear_scene()
	var journey := preload("res://src/chapters/chapter_run.tscn").instantiate() as ChapterRun
	journey.progress_path = progress_path
	journey.battle_requested.connect(_request_battle)
	current = journey
	add_child(journey)
	switching = false


func _request_battle() -> void:
	if switching:
		return
	switching = true
	_show_battle.call_deferred()


func _show_battle() -> void:
	_clear_scene()
	var battle := preload("res://src/prototype/crab_arena.tscn").instantiate()
	battle.set_script(preload("res://src/chapters/chapter_mother_battle.gd"))
	battle.get_node("UI").set_script(preload("res://src/chapters/chapter_battle_ui.gd"))
	battle.progress_path = progress_path
	battle.journey_requested.connect(_return_to_journey)
	current = battle
	add_child(battle)


func _return_to_journey() -> void:
	_show_journey.call_deferred()
