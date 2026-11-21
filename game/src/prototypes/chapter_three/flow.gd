class_name ChapterThreeFlow
extends ChapterTwoFlow
## 主动开瓣是独立交互，不由战斗结算或跳过对白代替执行。
func restore() -> void:
	if host.facts.get("enemy_cleared",false):
		host.guard.finish()
		host.guard.visible = false
	host.set_blockade(bool(host.facts.get("repaired",false)))
	stage = "complete" if host.facts.get("completed",false) else ("repaired" if host.facts.get("repaired",false) else ("carry" if host.facts.get("salvage",false) else ("salvage" if host.facts.get("settled",false) else ("aftermath" if host.facts.get("valve_opened",false) else ("valve" if host.facts.get("enemy_cleared",false) else ("search" if host.facts.get("clue",false) else ("evidence" if host.facts.get("met",false) else "approach")))))))

func tick(dt: float) -> void:
	if host.player.health<=0: return
	if start_left>0:
		start_left-=dt
		if start_left<=0 and not host.facts.get("arrival",false): say("arrival")
		return
	var x: float = host.player.position.x
	if stage=="approach" and x>=520: say("meet")
	# 回水查看是可选观察，不能作为怪物对接近玩家的反应开关。
	elif stage in ["evidence","search"] and x>=1630:
		stage="shell_warning"
		warning_left=0.8
		host.record("ambush_warning")
	elif stage=="shell_warning":
		warning_left-=dt
		if warning_left<=0:
			stage="combat"
			host.guard.awake=true
	elif stage=="combat" and x<1000 and host.player.is_on_floor():
		host.guard.reset_encounter()
		stage="search"
	elif stage=="rescue":
		rescue_time+=dt
		if rescue_time>=8: finish_rescue()
	elif stage=="aftermath" and near(900,180): say("after")
	elif stage=="repaired" and x>=3400 and host.player.is_on_floor(): say("complete")

func say(id: String) -> void: open_dialogue(id,ChapterThreeDialogue.lines(id))

func defeated() -> void:
	if host.facts.get("enemy_cleared",false): return
	host.facts.enemy_cleared=true
	host.guard.awake=false
	host.guard.visible=false
	stage="valve"
	host.save_progress()
	host.record("mudback_retreated")

func near(x: float, radius: float = 115) -> bool:
	return absf(host.player.position.x-x)<radius and host.player.is_on_floor()

func interact() -> void:
	if stage=="complete":
		host.save_progress()
		get_tree().set_meta("chapter_run_launch",{"id":4,"suffix":host.qa_save_suffix,"save":host.save_enabled,"restore":true})
		get_tree().change_scene_to_file.call_deferred("res://content/prototypes/chapters/main.tscn")
	elif stage=="rescue": finish_rescue()
	elif stage in ["evidence","search"] and not host.facts.get("clue",false) and near(1010): say("basin")
	elif stage=="valve" and near(2140): say("valve")
	elif stage=="ready" and near(2140):
		# 先落盘再演出；退出后从居民已脱险的事故后节点继续，不重开水。
		host.facts.valve_opened=true
		host.save_progress()
		stage="rescue"
		rescue_time=0
		host.player.skill_controller.cancel()
		host.player.clear_combat_input()
		host.player.velocity=Vector2.ZERO
		host.player.controls_enabled=false
		host.record("valve_opened_by_player")
	elif stage=="salvage" and near(480):
		host.facts.salvage=true
		stage="carry"
		host.save_progress()
		host.record("shell_recovered")
	elif stage=="carry" and near(820): say("fixed")

func finish_rescue() -> void:
	if stage!="rescue": return
	stage="aftermath"
	host.record("flood_settled")
	# 玩家实际返程到高台再参与救援交流，不隔着半张地图声称抓住巢片。
	host.hold_world()
	host.release_world()

func close_dialogue() -> void:
	if not host.hud.dialogue.visible: return
	host.hud.dialogue.hide()
	match dialogue_id:
		"arrival": host.facts.arrival=true
		"meet":
			host.facts.met=true
			stage="evidence"
		"basin":
			host.facts.clue=true
			stage="search"
		"valve": stage="ready"
		"after":
			host.facts.settled=true
			stage="salvage"
		"fixed":
			host.facts.repaired=true
			host.set_blockade(true)
			stage="repaired"
		"complete":
			host.facts.completed=true
			stage="complete"
	host.save_progress()
	host.record("dialogue_finished",{"dialogue":dialogue_id})
	dialogue_id=""
	host.release_world()

func objective() -> String:
	match stage:
		"approach": return "到菌床旁，找补巢者"
		"evidence": return "沿浅槽向右，赶开大甲 · F查看回水（可选）"
		"search": return "沿浅槽向右，赶开阻路的大甲，查看排水口"
		"shell_warning": return "水中碎屑翻动 · 准备躲开大甲扑击"
		"combat": return "在废弃低坑迎战 · 避开住巢"
		"valve": return "大甲已退走 · 到右侧旧瓣按 F 查看"
		"ready": return "旧瓣裂缝正在排水 · F撬开旧瓣，尝试排走积水"
		"rescue": return "回水冲向菌床 · F跳过演出"
		"aftermath": return "沿左侧台阶回高台，安置住户"
		"salvage": return "左侧浅滩 F 捡回旧壳"
		"carry": return "回到住巢 F 固定巢片"
		"repaired": return "沿右侧台阶，前往脂库问看守"
	return "F继续第四章 · R回访 / F6重开"
