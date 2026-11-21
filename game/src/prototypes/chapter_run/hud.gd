class_name ChapterRunHUD
extends Control
var host: ChapterRun
var dialogue: WhaleDialoguePanel
var objective: Label
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	theme=WhaleUIStyle.theme()
	objective=WhaleUIStyle.paragraph("")
	objective.position=Vector2(500,14)
	objective.size=Vector2(740,75)
	objective.add_theme_font_size_override("font_size",17)
	objective.add_theme_color_override("font_color",WhaleUIStyle.AMBER)
	add_child(objective)
	dialogue=WhaleDialoguePanel.new()
	add_child(dialogue)
	dialogue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue.advance_requested.connect(func() -> void: host.flow.advance())
	dialogue.skip_requested.connect(func() -> void: host.flow.close_dialogue())

func text(at: Vector2, value: String, font_size: int=17, color: Color=WhaleUIStyle.BONE) -> void:
	WhaleActionHUDStyle.text(self,at,value,font_size,color)

func _process(_dt: float) -> void:
	if not is_instance_valid(host.flow): return
	objective.visible=not dialogue.visible and not host.flow.finished
	objective.size.x=maxf(240,size.x-520)
	var value: String=str(host.flow.stage().get("objective",""))
	if objective.text!=value: objective.text=value

func _draw() -> void:
	if not is_instance_valid(host.flow): return
	text(Vector2(22,32),"第%d章 · %s" % [host.chapter_id,str(host.data.title)],22,WhaleUIStyle.AMBER)
	var defense:=host.player.skill_controller as TideCombatGuardSkills
	text(Vector2(22,60),"生命 %d / %d · 架势 %d" % [host.player.health,host.player.max_health,int(defense.guard_meter)],16)
	if host.flow.finished:
		text(Vector2(480,32),"F继续下一章 · R回访" if int(host.data.get("next",0))>0 else "全线白盒结束 · R回访 / F6重开本章",18,WhaleUIStyle.AMBER)
		return
	var s: Dictionary=host.flow.stage()
	if not dialogue.visible:
		text(Vector2(22,size.y-45),"WASD移动 · 空格跳跃 · J/I/K/L/Z与Q/E组合沿用 · F交互",15)
		text(Vector2(22,size.y-20),"R检查点 · F6本章重开 · F7/F8切章验收 · Esc暂停 | 场景与居民为白盒代理",13,WhaleUIStyle.MUTED)
		var target: Vector2=host.flow.target()
		var distance: float=host.player.position.distance_to(target)
		if distance>135:
			var direction: String="→" if target.x>host.player.position.x else "←"
			if absf(target.y-host.player.position.y)>75: direction+=" ↑" if target.y<host.player.position.y else " ↓"
			text(Vector2(size.x-230,105),direction+" 目标 "+str(int(distance)),19,WhaleUIStyle.AMBER)
	if host.encounter.warning>0: text(Vector2(440,130),"敌人正在逼近 · 准备应对",21,Color("ff9c79"))
	var enemy: EnemyLabEnemy=host.encounter.enemy
	if is_instance_valid(enemy) and enemy.outcome.is_empty():
		text(Vector2(470,85),str(enemy.profile.title)+" %d / %d" % [enemy.health,enemy.maximum],18)
		text(Vector2(470,110),str(enemy.spec.get("title","逼近")),15)
	if host.flow.observing:
		var captions: Array=s.get("captions",[])
		var ratio: float=host.flow.observation_time/maxf(0.1,host.flow.observation_duration)
		if not captions.is_empty(): text(Vector2(260,size.y-165),str(captions[mini(captions.size()-1,int(ratio*captions.size()))]),18,WhaleUIStyle.AMBER)
		text(Vector2(440,size.y-130),"F跳过本段观察",14)
	if host.resume_wait>0: text(Vector2(420,160),"松开游戏按键后继续",17,WhaleUIStyle.AMBER)
	if host.player.health<=0: text(Vector2(420,260),"倒下了 · R回本阶段检查点",24,WhaleUIStyle.AMBER)
	elif host.paused_by_user: text(Vector2(460,260),"已暂停 · Esc返回",24)
	if host.save_failed: text(Vector2(22,100),"保存失败 · 当前会话可继续",18,Color("ff9779"))
