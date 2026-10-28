class_name RoomDoor
extends Interactable

@export var edge_id: String = ""
@export var target_room: String = ""
@export var target_entry: String = ""
@export var required_abilities: PackedStringArray = []
@export var required_flags: PackedStringArray = []
@export var boundary_flag: String = ""


func denied() -> String:
	if GameState.arena_active:
		return "战斗封场 · 先击败负壳蟹"
	for id in required_abilities:
		if not GameState.has_ability(id):
			return "需要" + WorldGraph.ABILITIES.get(id, "后续能力")
	for id in required_flags:
		if not GameState.has_flag(id):
			return "先击败负壳蟹" if id == "boss.r1_shell_crab" else "远侧壳闩未开 · 需从另一侧开启"
	return ""


func use() -> void:
	var reason := denied()
	if not reason.is_empty():
		EventBus.toast.emit(reason)
	elif not boundary_flag.is_empty():
		GameState.set_flag(boundary_flag)
		GameState.save_progress()
		EventBus.toast.emit("首关完成 · 后续区域尚未开放，可返回探索")
	elif not ResourceLoader.exists(WorldGraph.room_path(target_room)):
		EventBus.toast.emit("后续区域尚未开放")
	else:
		EventBus.room_change_requested.emit(target_room, target_entry)
