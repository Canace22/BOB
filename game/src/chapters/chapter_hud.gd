class_name ChapterHud
extends GameHud


func refresh() -> void:
	$Top/Stats.text = "生命 %d / 4    蓄振 %d / 4    回声 %d / 2" % [GameState.hp, GameState.energy, int(GameState.has_flag("chapter.echo.1")) + int(GameState.has_flag("chapter.echo.2"))]
	$Top/Room.text = WorldGraph.ROOMS.get(GameState.current_room, "鲸落万物生 · 两章试玩")
	var goal: String = {"N01-A": "循着鲸歌向右探索 · 按住 Space 跳得更高", "N01-B": "清开两处食腐甲 · 去右侧听补巢者的回应", "N02-A": "沿折井前进 · 高台上有回声和壳闩", "N02-B": "在菌灯旁休息 · 前往封锁口"}.get(GameState.current_room, "")
	if GameState.has_flag("chapter.guard"):
		goal = "守卫已经退让 · 到右侧住巢按 E 查看后续"
	if GameState.has_flag("chapter.complete"):
		goal = "两章试玩完成 · 可返回找回声，Esc 可重新开始"
	$Top/Goal.text = goal
	$Controls.text = "A/D 移动 · Space 跳跃（长按更高）· J 连击 · K 重击 · F 调息回血 · E 交互 · Tab 地图 · Esc 暂停"


func _process(delta: float) -> void:
	remaining = maxf(0, remaining - delta)
	$Message.visible = remaining > 0
	var guards := get_tree().get_nodes_in_group("chapter_guard")
	$Boss.visible = GameState.arena_active and not guards.is_empty()
	if $Boss.visible:
		var guard := guards[0] as EnemyBase
		var hint: String = {"sweep": "低扫 · 起跳", "second": "再扫 · 再跳", "slam": "重壳下压 · 撤步"}.get(guard.kind, "")
		if guard.state == "recover":
			hint = "扣带松动 · 靠近反击"
		$Boss.text = "负壳守卫   %d / %d   %s" % [guard.health.current, guard.health.maximum, hint]
