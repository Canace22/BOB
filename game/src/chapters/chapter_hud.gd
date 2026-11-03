class_name ChapterHud
extends GameHud


func refresh() -> void:
	$Top/Stats.text = "生命 %d / 6    蓄振 %d / 4    回声 %d / 2" % [GameState.hp, GameState.energy, int(GameState.has_flag("chapter.echo.1")) + int(GameState.has_flag("chapter.echo.2"))]
	$Top/Room.text = WorldGraph.ROOMS.get(GameState.current_room, "鲸落万物生 · 两章试玩")
	var goal: String = {"N01-A": "越过滤缝 · 须根高处传来短鸣", "N01-B": "借高低路分开食腐甲 · 找到补巢者", "N02-A": "沿膜褶下行 · 放下短桥便于返回", "N02-B": "在菌灯旁休息 · 前往封锁口"}.get(GameState.current_room, "")
	if GameState.has_flag("chapter.guard"):
		goal = "守卫已经退让 · 到右侧住巢按 E 查看后续"
	if GameState.has_flag("chapter.complete"):
		goal = "两章试玩完成 · 可返回找回声，Esc 可重新开始"
	$Top/Goal.text = goal
	$Controls.text = "A/D 移动 · Space 跳跃 · J 连击 · K 重击 · U 蓄满松开发射 · F 回血 · E 交互 · Tab 地图 · Esc 暂停"


func _process(delta: float) -> void:
	remaining = maxf(0, remaining - delta)
	$Message.visible = remaining > 0
	var journey := get_parent() as ChapterRun
	if journey != null and journey.skills != null:
		var shield := "护盾就绪" if journey.player.hurtbox.guard > 0 else "护盾 %d / 6" % journey.skills.shield_charge
		$Top/Stats.text = "生命 %d / 6    蓄振 %d / 4    回声 %d / 2    %s" % [GameState.hp, GameState.energy, int(GameState.has_flag("chapter.echo.1")) + int(GameState.has_flag("chapter.echo.2")), shield]
	var guards := get_tree().get_nodes_in_group("chapter_guard")
	$Boss.visible = GameState.arena_active and not guards.is_empty()
	if $Boss.visible:
		$Top/Goal.text = "避开出招 · 反击松开的扣带"
		var guard := guards[0] as EnemyBase
		var hint: String = {"sweep": "抬钳 · 留心低扫", "slam": "重壳下压 · 离开正面"}.get(guard.kind, "")
		if guard.state == "recover":
			hint = "扣带松动 · 反击"
		elif guard.state in ["idle", "turn"]:
			hint = "正面壳缘坚硬 · 留意身后的扣带"
		$Boss.text = "负壳守卫   %d / %d\n%s" % [guard.health.current, guard.health.maximum, hint]
