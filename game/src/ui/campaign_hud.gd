class_name WhaleCampaignHUD
extends Control

var controller: WhaleCampaignUI
var leaf: Texture2D
var echo: Texture2D
var map_button: Button
var pause_button: Button
var prompt_alpha: float = 0.0
var last_prompt: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	leaf = load("res://art/ui/leaf.svg") as Texture2D
	echo = load("res://art/ui/echo.svg") as Texture2D
	map_button = WhaleUIStyle.button("", func() -> void: controller.open("map"))
	pause_button = WhaleUIStyle.button("Esc  暂停", func() -> void: controller.open("pause"))
	for button: Button in [map_button, pause_button]:
		button.custom_minimum_size = Vector2(116, 40)
		button.add_theme_font_size_override("font_size", 16)
		add_child(button)
	resized.connect(_layout)
	_layout()

func _process(dt: float) -> void:
	var current: String = controller.data.prompt() if is_instance_valid(controller) and is_instance_valid(controller.host.player) else ""
	if current != last_prompt: prompt_alpha = 0.0
	last_prompt = current
	prompt_alpha = move_toward(prompt_alpha, 1.0, dt * 7.0)

func _layout() -> void:
	map_button.position = Vector2(size.x-282, size.y-61)
	pause_button.position = Vector2(size.x-151, size.y-61)

func text(at: Vector2, value: String, font_size: int = 17, color: Color = WhaleUIStyle.BONE) -> void:
	draw_string_outline(WhaleUIStyle.FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0.01,0.03,0.04,0.95*color.a))
	draw_string(WhaleUIStyle.FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if not is_instance_valid(controller.player): return
	var p: TidePlayer = controller.player
	var prefs: WhaleUIPreferences = controller.preferences
	if prefs.contrast: draw_style_box(WhaleUIStyle.box(WhaleUIStyle.INK), Rect2(21,20,388,133))
	draw_arc(Vector2(65,72), 37, 0, TAU, 64, WhaleUIStyle.MUTED, 1.0, true)
	draw_texture_rect(echo, Rect2(39,42,52,57), false)
	for i: int in range(p.max_health):
		var rect := Rect2(120+i*39,35,30,42)
		draw_texture_rect(leaf, rect, false, Color(1,1,1,1) if i < p.health else Color(0.23,0.35,0.37,0.9))
	if prefs.numbers: text(Vector2(120+p.max_health*39+8,64), "%d / %d" % [p.health,p.max_health], 16)
	var count: int = ceili(float(p.max_soul)/maxi(1,p.skill_cost))
	for i: int in range(count):
		var rect := Rect2(120+i*57,87,49,9)
		draw_rect(rect, Color("20373c"))
		var amount: float = clampf(float(p.soul-i*p.skill_cost)/p.skill_cost,0,1)
		draw_rect(Rect2(rect.position,Vector2(rect.size.x*amount,rect.size.y)), WhaleUIStyle.TEAL)
		draw_rect(rect, WhaleUIStyle.MUTED,false,1)
	text(Vector2(120,121), "蓄振 %d/%d · 单次 %d" % [p.soul,p.max_soul,p.skill_cost], 15, WhaleUIStyle.MUTED)
	if controller.location_left > 0:
		var title: String = "须门遗港 · " + str(controller.host.room.name)
		var width: float = WhaleUIStyle.FONT.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x
		var title_color: Color = WhaleUIStyle.BONE
		title_color.a = clampf(controller.location_left,0,1)
		text(Vector2(size.x-36-width,57),title,23,title_color)
	if controller.host.practice: text(Vector2(size.x-270,87),"能力练习 · 不保存进度",16,WhaleUIStyle.AMBER)
	if controller.host.room_preview: text(Vector2(size.x-270,110),"房间预览 · 不记录发现",16,WhaleUIStyle.AMBER)
	if controller.notice_left>0: text(Vector2(35,157),controller.notice_text,17,WhaleUIStyle.AMBER)
	_draw_actions(p)
	map_button.text = WhaleUIStyle.key("ui_region_map") + "  地图"
	var prompt: String = controller.data.prompt()
	var prompt_key: String = "tp_interact"
	if not prompt.is_empty():
		var point: Vector2 = p.get_global_transform_with_canvas().origin
		var entrance: CampaignDoorway = controller.data.prompt_door()
		if entrance != null:
			point = entrance.get_global_transform_with_canvas() * entrance.prompt_offset
		else: point.y -= 130
		var show_key: bool = entrance == null or (entrance.restriction().is_empty() and not (entrance.kind == "exit" and controller.host.completed))
		var content: String = ("[" + WhaleUIStyle.key(prompt_key) + "]  " if show_key else "") + prompt
		var width: float = WhaleUIStyle.FONT.get_string_size(content,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
		text(Vector2(clampf(point.x-width*0.5,24,maxf(24,size.x-width-24)),clampf(point.y,150,size.y-100)), content, 17, Color(WhaleUIStyle.BONE, prompt_alpha))
	var boss: Dictionary = controller.data.boss()
	if not boss.is_empty():
		var width: float = minf(620,size.x*0.48)
		var x: float = (size.x-width)*0.5
		text(Vector2(size.x*0.5-58,size.y-132),"负壳守卫",23)
		draw_rect(Rect2(x,size.y-113,width,7),Color("15262c"))
		draw_rect(Rect2(x,size.y-113,width*clampf(float(boss.hp)/float(boss.max_hp),0,1),7),WhaleUIStyle.BONE)
		draw_rect(Rect2(x-3,size.y-116,width+6,13),WhaleUIStyle.MUTED,false,1)
		if prefs.numbers: text(Vector2(x+width+14,size.y-106),"%d/%d" % [maxi(0,int(boss.hp)),int(boss.max_hp)],15)
	if p.state == "recover":
		text(Vector2(35,189),"调息中 · 已消耗 %d" % p.skill_cost,16,WhaleUIStyle.AMBER)
		draw_line(Vector2(35,203),Vector2(35+220*clampf(p.state_time/maxf(p.state_duration,0.01),0,1),203),WhaleUIStyle.AMBER,3)
	elif p.skill_controller.input.attack_hold>=0.55 or p.skill_controller.input.long_hold>=0.6:
		text(Vector2(35,189),"蓄力完成 · 松开释放",16,WhaleUIStyle.AMBER)
	if p is WhalebellyCampaignPlayer and p.floating:
		text(Vector2(35,222),"浮膜余压 %.1f 秒" % p.float_left,16)

func _draw_actions(p: TidePlayer) -> void:
	var upgraded: bool = p.skill_unlocked("chapter") and p.skill_controller.use_upgrades
	var orb: String = "shadow_orb" if upgraded else "A4_parry"
	var dash: String = "shadow_dash" if upgraded else "A1_dash"
	var actions: Array[Array] = [
		["tp_dash",dash,"影潮" if upgraded else "贴流冲","dash",0],
		["tp_orb",orb,"深鸣" if upgraded else "叉鸣弹","orb",p.skill_cost],
		["tp_heavy","heavy","重鸣","heavy",p.skill_cost],
		["tp_heal","recover","调息","heal",p.skill_cost]]
	for i: int in range(actions.size()):
		var a: Array = actions[i]
		var locked: bool = not p.ability_available(str(a[1]))
		var cd: float = float(p.cooldowns.get(str(a[3]),0))
		var reason: String = "未解锁" if locked else ("%.1fs"%cd if cd>0 else ("蓄振不足" if p.soul<int(a[4]) else ""))
		if str(a[1])=="recover" and reason.is_empty():
			if p.health>=p.max_health: reason="生命已满"
			elif not p.is_on_floor(): reason="需落地"
		var x: float = 35+i*145
		text(Vector2(x,size.y-43), WhaleUIStyle.key(str(a[0]))+"  "+str(a[2]),17,WhaleUIStyle.MUTED if not reason.is_empty() else WhaleUIStyle.BONE)
		text(Vector2(x,size.y-21),reason if not reason.is_empty() else ("消耗 %d"%int(a[4]) if int(a[4])>0 else "可用"),13,WhaleUIStyle.AMBER if locked else WhaleUIStyle.MUTED)
