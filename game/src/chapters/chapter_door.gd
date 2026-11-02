class_name ChapterDoor
extends RoomDoor

@export var prerequisites: Array[String] = []


func denied() -> String:
	if GameState.arena_active:
		return "先让负壳守卫停止封路"
	if not GameState.meets(required_abilities, PackedStringArray(prerequisites)):
		return "先清开食腐甲，再去灯旁按 E 听补巢者的回应"
	return ""
