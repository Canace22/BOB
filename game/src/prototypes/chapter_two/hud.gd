class_name ChapterTwoHUD
extends Control
## 章节白盒界面：标明代理与独立存档，不伪装为正式主线已完成。
var host: ChapterTwoWhitebox
var dialogue: WhaleDialoguePanel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = WhaleUIStyle.theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	dialogue = WhaleDialoguePanel.new()
	add_child(dialogue)
	dialogue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue.advance_requested.connect(func() -> void: host.flow.advance())
	dialogue.skip_requested.connect(func() -> void: host.flow.close_dialogue())

func text(at: Vector2, value: String, font_size: int = 17, color: Color = WhaleUIStyle.BONE) -> void:
	WhaleActionHUDStyle.text(self,at,value,font_size,color)

func _draw() -> void:
	if not is_instance_valid(host.flow): return
	var p: ChapterTwoPlayer = host.player
	WhaleActionHUDStyle.panel(self,Rect2(14,12,330,96),0.65)
	text(Vector2(26,33),"第二章 · 守住路的人",20,WhaleUIStyle.AMBER)
	for i: int in p.max_health:
		WhaleActionHUDStyle.icon(self,"mask",Rect2(26+i*27,45,22,24),Color.WHITE if i<p.health else Color(0.35,0.4,0.4,0.4))
	var defense := p.skill_controller as TideCombatGuardSkills
	text(Vector2(26,94),"架势 %d / 100   蓄振 %d" % [int(defense.guard_meter),p.soul],14)
	WhaleActionHUDStyle.panel(self,Rect2(size.x-510,14,488,52),0.4)
	text(Vector2(size.x-495,39),host.flow.objective(),17,WhaleUIStyle.AMBER)
	if not dialogue.visible:
		text(Vector2(26,size.y-59),"WASD 移动 · 空格跳跃 · J普攻 I格挡 K三段 L冲刺 Z后跳 · Q/E选招",14)
		text(Vector2(26,size.y-35),"W+J上挑 / S+J横扫 / A/D+L撞击 · R检查点重试 · F6重开 · Esc暂停",13)
		text(Vector2(26,size.y-13),"独立白盒：几何场地 / 住巢代理 / 既有老守护者姿势演出；不写正式存档",12,WhaleUIStyle.MUTED)
	if host.flow.stage in ["shell_warning","combat"]:
		text(Vector2(size.x*0.5-74,88),"负壳守卫 · 解除封锁",18)
		draw_rect(Rect2(size.x*0.5-150,98,300,7),Color("20323b"))
		draw_rect(Rect2(size.x*0.5-150,98,300*float(host.guard.health)/host.guard.maximum,7),WhaleUIStyle.AMBER)
		text(Vector2(size.x*0.5-100,128),str(host.guard.spec.get("title","重壳警告")),15,WhaleUIStyle.BONE)
	if host.flow.stage=="rescue":
		var captions: Array[String] = ["住户：绳子！上头的绳子断了！","老守护者：抓住左边，别松手！","老守护者：一个一个来，我撑着。","住户：都上来了！下面没人了！"]
		text(Vector2(340,size.y-140),captions[mini(3,int(host.flow.rescue_time/2))],20,WhaleUIStyle.AMBER)
	if host.resume_wait>0: text(Vector2(380,160),"松开游戏按键后继续",18,WhaleUIStyle.AMBER)
	if host.save_failed: text(Vector2(26,140),"白盒进度保存失败 · 当前会话仍可继续",16,Color("ff9779"))
	if p.health<=0:
		WhaleActionHUDStyle.panel(self,Rect2(410,250,460,90))
		text(Vector2(440,290),"重壳挡住了去路 · 按R立即重试",23,WhaleUIStyle.AMBER)
	elif host.paused_by_user:
		WhaleActionHUDStyle.panel(self,Rect2(450,250,380,90))
		text(Vector2(480,290),"已暂停 · Esc返回 / R重试",22)
