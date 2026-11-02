class_name ChapterPause
extends GamePause


func restart() -> void:
	GameState.apply(ChapterRun.fresh_data())
	GameState.save_progress()
	close()
	EventBus.room_change_requested.emit(ChapterRun.START, "camp")


func open_map() -> void:
	show()
	get_tree().paused = true
	var lines: PackedStringArray = ["两章试玩 · 已探索路线", "须庭入口 ↔ 须庭内侧 ↔ 折井上层 ↔ 封锁口", "", "高处可以找到两处可选回声。", "在菌灯旁按 E 休息，倒下后从最近营地出发。", ""]
	for id: String in WorldGraph.ROOMS:
		if id.begins_with("N0") and GameState.has_flag("map." + id):
			lines.append("%s %s%s" % ["▶" if id == GameState.current_room else "·", WorldGraph.ROOMS[id], " · 营地" if id == GameState.checkpoint_room else ""])
	$Panel/Buttons/Title.text = "\n".join(lines)
	$Panel/Buttons/Resume.grab_focus()
