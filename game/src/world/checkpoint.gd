class_name Checkpoint
extends Interactable

@export var room_id: String = "R1-01"


func use() -> void:
	if GameState.arena_active:
		EventBus.toast.emit("战斗中无法休息")
		return
	GameState.rest_at(room_id)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.health.restore(GameState.hp)
	EventBus.sfx.emit("save")
	EventBus.toast.emit("营地已记录 · 生命与蓄振恢复")
