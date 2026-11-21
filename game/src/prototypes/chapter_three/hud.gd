class_name ChapterThreeHUD
extends ChapterTwoHUD
func _draw() -> void:
	if not is_instance_valid(host.flow): return
	var p: ChapterTwoPlayer=host.player
	text(Vector2(24,32),"第三章 · 被冲走的家",22,WhaleUIStyle.AMBER)
	var defense:=p.skill_controller as TideCombatGuardSkills
	text(Vector2(24,60),"生命 %d / %d   架势 %d" % [p.health,p.max_health,int(defense.guard_meter)],17)
	text(Vector2(520,32),host.flow.objective(),18,WhaleUIStyle.AMBER)
	if not dialogue.visible:
		text(Vector2(24,size.y-45),"WASD移动 · 空格跳跃 · J普攻 I格挡 K三段 L冲刺 Z后跳 · F交互",15)
		text(Vector2(24,size.y-20),"R检查点 · F6本章重开 · Esc暂停 | 独立白盒：水路/住户/救援为几何演出代理",13,WhaleUIStyle.MUTED)
	if host.flow.stage=="combat":
		text(Vector2(500,85),"栖污大甲   %d / %d" % [host.guard.health,host.guard.maximum],20)
	if host.flow.stage=="rescue":
		var captions: Array[String]=["污絮随水排出，近处槽底露了出来。","住户：水回来了！往巢里冲了！","补巢者：抓住系带！别松！","老守护者：先把人拉上来！"]
		text(Vector2(270,size.y-170),captions[mini(3,int(host.flow.rescue_time/2))],20,WhaleUIStyle.AMBER)
	if host.resume_wait>0: text(Vector2(400,140),"松开游戏按键后继续",17)
	if p.health<=0: text(Vector2(400,270),"遭遇失败 · R回检查点",25,WhaleUIStyle.AMBER)
	elif host.paused_by_user: text(Vector2(450,270),"已暂停 · Esc返回",25)
	if host.save_failed: text(Vector2(24,100),"进度保存失败 · 当前会话可继续",18,Color("ff9779"))
