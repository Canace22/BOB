class_name GamePause
extends CanvasLayer
## This node keeps processing during pause. World, hazards and action timers stop together.


func _ready() -> void:
	$Panel/Buttons/Resume.pressed.connect(close)
	$Panel/Buttons/Restart.pressed.connect(restart)
	$Panel/Buttons/Map.pressed.connect(open_map)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			close()
		else:
			show()
			$Panel/Buttons/Title.text = "已暂停"
			$Panel/Buttons/Resume.grab_focus()
			get_tree().paused = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map"):
		if visible:
			close()
		else:
			open_map()
		get_viewport().set_input_as_handled()


func close() -> void:
	hide()
	get_tree().paused = false


func restart() -> void:
	GameState.new_journey()
	close()
	EventBus.room_change_requested.emit(SaveService.START_ROOM, "camp")


func open_map() -> void:
	show()
	get_tree().paused = true
	var lines: PackedStringArray = ["须门 · 地图（已到访房间）", "R1-01 ↔ R1-02 ↔ R1-03 ↔ R1-04 ↔ R1-05", "R1-02 ↑ R1-06：需浮升    ↑ R1-07：需挂环", ""]
	for id: String in WorldGraph.ROOMS:
		if GameState.has_flag("map." + id):
			lines.append("%s %s %s%s" % ["▶" if GameState.current_room == id else "·", id, WorldGraph.ROOMS[id], "  营地" if GameState.checkpoint_room == id else ""])
	$Panel/Buttons/Title.text = "\n".join(lines)
	$Panel/Buttons/Resume.grab_focus()
