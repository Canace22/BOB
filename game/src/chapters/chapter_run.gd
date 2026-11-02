class_name ChapterRun
extends GameMain
## A separate, resumable chapter slice; never reads or writes the campaign save.

const START := "N01-A"
@export var progress_path: String = "user://chapters-v1.json"
var previous: Dictionary


func _enter_tree() -> void:
	previous = {"data": GameState.to_save_data(), "path": GameState.save_path,
		"autosave": GameState.autosave, "loaded": GameState.loaded,
		"current": GameState.current_room, "hp": GameState.hp,
		"energy": GameState.energy, "arena": GameState.arena_active}
	GameState.save_path = progress_path
	var data := SaveService.read(progress_path)
	if not str(data.checkpoint_room).begins_with("N0"):
		data = fresh_data()
	GameState.apply(data)
	GameState.autosave = true
	var actor := get_node("Player") as Player
	actor.tuning = actor.tuning.duplicate() as PlayerTuning
	actor.tuning.prototype_controls = true


static func fresh_data() -> Dictionary:
	return {"version": SaveService.VERSION, "checkpoint_room": START, "abilities": [], "flags": []}


func _exit_tree() -> void:
	GameState.autosave = false
	GameState.apply(previous.data)
	GameState.save_path = previous.path
	GameState.autosave = previous.autosave
	GameState.loaded = previous.loaded
	GameState.current_room = previous.current
	GameState.hp = previous.hp
	GameState.energy = previous.energy
	GameState.arena_active = previous.arena


func _respawn() -> void:
	await get_tree().create_timer(0.5, false).timeout
	GameState.restore()
	change_room(GameState.checkpoint_room, "camp")
	EventBus.toast.emit("回到菌灯旁 · 已找到的回声和通路仍在")
