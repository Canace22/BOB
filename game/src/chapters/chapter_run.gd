class_name ChapterRun
extends GameMain
## A separate, resumable chapter slice; never reads or writes the campaign save.

const START := "N01-A"
signal battle_requested
@export var progress_path: String = "user://chapters-v1.json"
var previous: Dictionary
var battle_pending := false
var skills: TrainingSkills


func _enter_tree() -> void:
	previous = {"data": GameState.to_save_data(), "path": GameState.save_path,
		"autosave": GameState.autosave, "loaded": GameState.loaded,
		"current": GameState.current_room, "hp": GameState.hp, "max_hp": GameState.max_hp,
		"energy": GameState.energy, "arena": GameState.arena_active}
	GameState.save_path = progress_path
	var data := SaveService.read(progress_path)
	if not str(data.checkpoint_room).begins_with("N0"):
		data = fresh_data()
	# Old guard victories do not silently skip the newly connected mother fight.
	if not data.flags.has("chapter.mother_victory"):
		data.flags.erase("chapter.guard")
		data.flags.erase("chapter.complete")
	GameState.max_hp = 6
	GameState.apply(data)
	GameState.autosave = true
	var actor := get_node("Player") as Player
	actor.tuning = actor.tuning.duplicate() as PlayerTuning
	actor.tuning.prototype_controls = true
	actor.get_node("Health").maximum = 6


func _ready() -> void:
	super._ready()
	skills = TrainingSkills.new()
	player.add_child(skills)
	skills.reset()


func _change(path: String, entry: String) -> void:
	if skills != null:
		skills.clear_projectiles()
	super._change(path, entry)
	if room.room_id == "N02-B" and GameState.has_flag("chapter.mother_victory") and not GameState.has_flag("chapter.complete"):
		player.reset_at(Vector2(1920, 800))
	if room.room_id == "N02-B" and GameState.has_flag("chapter.mother_victory"):
		var mother := preload("res://src/enemies/crab_prototype/crab_prototype.tscn").instantiate() as CrabPrototype
		mother.position = Vector2(1200, 800)
		room.get_node("Gameplay").add_child(mother)
		mother.set_physics_process(false)
		mother.visual.set_physics_process(false)
		mother.state = "waiting"
		mother.hurtbox.immune = true
		mother.visual.present(mother)


func _unhandled_input(event: InputEvent) -> void:
	if not get_tree().paused and event.is_action_pressed("ranged"):
		skills.buffer_cast()


func _process(_delta: float) -> void:
	if battle_pending or changing or get_tree().paused or room == null:
		return
	if room.room_id == "N02-B" and player.position.x >= 440 and GameState.has_flag("chapter.challenge") and not GameState.has_flag("chapter.mother_victory"):
		battle_pending = true
		GameState.checkpoint_room = "N02-B"
		GameState.save_progress()
		battle_requested.emit()


static func fresh_data() -> Dictionary:
	return {"version": SaveService.VERSION, "checkpoint_room": START, "abilities": [], "flags": []}


func _exit_tree() -> void:
	GameState.autosave = false
	GameState.max_hp = previous.max_hp
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
	skills.reset()
	change_room(GameState.checkpoint_room, "camp")
	EventBus.toast.emit("回到菌灯旁 · 已找到的回声和通路仍在")
