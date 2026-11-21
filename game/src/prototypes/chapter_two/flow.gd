class_name ChapterTwoFlow
extends Node
## 章节单向事实与当前演出分离；重试/读档不会复活已解除封锁的守卫。
var host: ChapterTwoWhitebox
var stage: String = "approach"
var warning_left: float = 0.0
var rescue_time: float = 0.0
var dialogue_id: String = ""
var dialogue_lines: Array[Array] = []
var line_index: int = 0
var start_left: float = 0.4
var retreats: int = 0
var departure_time: float = 0.0

func restore() -> void:
	if host.facts.get("guard_defeated",false):
		host.guard.awake = false
		host.guard.finish()
		host.set_blockade(true)
	stage = "complete" if host.facts.get("completed",false) else ("permitted" if host.facts.get("permit",false) else ("rescued" if host.facts.get("rescue_done",false) else ("defeated" if host.facts.get("guard_defeated",false) else ("warning" if host.facts.get("refusal",false) else "approach"))))
	if stage=="rescued": _permit_dialogue()

func tick(dt: float) -> void:
	if host.player.health<=0: return
	if start_left>0:
		start_left -= dt
		if start_left<=0 and not host.facts.get("arrival",false):
			open_dialogue("arrival",ChapterTwoDialogue.lines("arrival"))
		return
	if stage in ["permitted","complete"]: departure_time += dt
	var x: float = host.player.position.x
	if stage=="approach" and x>=1040 and host.player.is_on_floor():
		open_dialogue("refusal",ChapterTwoDialogue.lines("refusal"))
	elif stage=="warning" and x>=1220:
		stage = "shell_warning"
		warning_left = 0.85
		host.guard.set_state("idle")
		host.record("shell_warning")
	elif stage=="shell_warning":
		warning_left -= dt
		if warning_left<=0:
			stage = "combat"
			host.guard.awake = true
			host.guard.timer = 0
			host.record("combat_started")
	elif stage=="combat" and x<1010 and host.player.is_on_floor():
		host.guard.reset_encounter()
		stage = "warning"
		retreats += 1
		host.record("withdraw_to_safety")
	elif stage=="defeated" and x>=1750 and host.player.is_on_floor():
		if not host.facts.get("aftermath",false): open_dialogue("aftermath",ChapterTwoDialogue.lines("aftermath"))
		else: begin_rescue()
	elif stage=="rescue":
		rescue_time += dt
		if rescue_time>=8: finish_rescue()
	elif stage=="rescued":
		_permit_dialogue()
	elif stage=="permitted" and x>=2680 and host.player.is_on_floor():
		open_dialogue("complete",ChapterTwoDialogue.lines("complete"))

func defeated() -> void:
	if host.facts.get("guard_defeated",false): return
	host.facts.guard_defeated = true
	stage = "defeated"
	host.set_blockade(true)
	host.save_progress()
	host.record("guard_surrendered",{"alive":host.guard.data.alive,"ending":host.guard.outcome})

func begin_rescue() -> void:
	stage = "rescue"
	rescue_time = 0
	host.player.clear_combat_input()
	host.player.skill_controller.cancel()
	host.player.controls_enabled = false
	host.player.velocity = Vector2.ZERO
	host.record("rescue_started")

func finish_rescue() -> void:
	if stage!="rescue": return
	host.facts.rescue_done = true
	stage = "rescued"
	host.save_progress()
	host.record("rescue_completed")
	_permit_dialogue()

func _permit_dialogue() -> void:
	# 保留旧阶段ID以兼容白盒进度；剧情含义为疏散结束后重开通路。
	open_dialogue("permit",ChapterTwoDialogue.lines("permit"))

func interact() -> void:
	if stage=="complete" and host.player.position.x>=2600:
		# 只连接独立章节白盒，保留两章各自的进度命名空间。
		host.save_progress()
		get_tree().set_meta("chapter_two_launch",{"suffix":host.qa_save_suffix,"save":host.save_enabled,"restore":true})
		get_tree().change_scene_to_file.call_deferred("res://content/prototypes/chapter_three/main.tscn")
	elif stage=="rescue":
		host.record("rescue_skipped")
		finish_rescue()
	elif stage=="warning" and host.player.position.x>950:
		open_dialogue("repeat",ChapterTwoDialogue.lines("guard_repeat"))
	elif stage in ["permitted","complete"] and host.player.position.x>1900:
		open_dialogue("repeat",ChapterTwoDialogue.lines("elder_repeat"))

func open_dialogue(id: String, lines: Array[Array]) -> void:
	if host.hud.dialogue.visible: return
	dialogue_id = id
	dialogue_lines = lines
	line_index = 0
	host.hold_world()
	host.hud.dialogue.show()
	_show_line()
	host.record("dialogue_started",{"dialogue":id})

func advance() -> void:
	line_index += 1
	if line_index>=dialogue_lines.size(): close_dialogue()
	else: _show_line()

func _show_line() -> void:
	var line: Array = dialogue_lines[line_index]
	host.hud.dialogue.present(str(line[0]),str(line[1]))

func close_dialogue() -> void:
	if not host.hud.dialogue.visible: return
	host.hud.dialogue.hide()
	match dialogue_id:
		"arrival": host.facts.arrival = true
		"refusal":
			host.facts.refusal = true
			stage = "warning"
		"aftermath": host.facts.aftermath = true
		"permit":
			host.facts.permit = true
			stage = "permitted"
		"complete":
			host.facts.completed = true
			stage = "complete"
	host.save_progress()
	host.record("dialogue_finished",{"dialogue":dialogue_id})
	dialogue_id = ""
	host.release_world()

func objective() -> String:
	match stage:
		"approach": return "沿折井下降 · 询问负壳守卫"
		"warning": return "下层暂时封路 · F询问 / 寻找下行通路"
		"shell_warning": return "重壳落地警告 · 准备应对"
		"combat": return "解除封锁 · 引出重壳，再绕侧反击"
		"defeated": return "挡口已经空了 · 下层还有住户"
		"rescue": return "观察救援 · F可跳过并继续交流"
		"rescued": return "等住户离开断口，再说话"
		"permitted": return "跟着撤出的住户，前往胃室"
	return "F继续第三章 · R回访 / F6重开本章"
