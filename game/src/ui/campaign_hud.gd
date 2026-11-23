class_name WhaleCampaignHUD
extends Control

var vitals: WhaleCampaignVitals
var objective_hud: WhaleCampaignObjectiveHUD
var counter_hud: WhaleCombatCounterHUD
var combo_hud: WhaleCombatComboHUD
var controller: WhaleCampaignUI
var map_button: Button
var pause_button: Button
var interaction_prompt: WhaleInteractionPrompt
var unlock_banner: WhaleUnlockBanner
var minimap: WhaleCampaignMinimap
var route_hud: WhaleCampaignRouteHUD

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	vitals=WhaleCampaignVitals.new()
	vitals.controller=controller
	add_child(vitals)
	minimap = WhaleCampaignMinimap.new()
	minimap.name = "Minimap"
	minimap.data = controller.data
	add_child(minimap)
	route_hud = WhaleCampaignRouteHUD.new()
	route_hud.controller = controller
	add_child(route_hud)
	map_button = WhaleUIStyle.button("", func() -> void: controller.open("map"))
	pause_button = WhaleUIStyle.button("Esc  暂停", func() -> void: controller.open("pause"))
	for button: Button in [map_button, pause_button]:
		button.custom_minimum_size = Vector2(22,22)
		button.add_theme_font_size_override("font_size", 12)
		var frame := WhaleUIStyle.box(Color(0.02,0.06,0.08,0.65),Color(WhaleUIStyle.AMBER,0.7))
		frame.set_corner_radius_all(4)
		frame.set_content_margin_all(3)
		button.add_theme_stylebox_override("normal",frame)
		add_child(button)
	resized.connect(_layout)
	objective_hud = WhaleCampaignObjectiveHUD.new()
	objective_hud.position=Vector2(26,124)
	add_child(objective_hud)
	objective_hud.configure_locations(controller.host.rooms)
	counter_hud=WhaleCombatCounterHUD.new()
	counter_hud.controller=controller
	add_child(counter_hud)
	combo_hud = WhaleCombatComboHUD.new()
	combo_hud.controller = controller
	add_child(combo_hud)
	interaction_prompt = WhaleInteractionPrompt.new()
	interaction_prompt.name = "InteractionPrompt"
	add_child(interaction_prompt)
	interaction_prompt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	unlock_banner = WhaleUnlockBanner.new()
	unlock_banner.name = "UnlockBanner"
	unlock_banner.controller = controller
	add_child(unlock_banner)
	unlock_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout()

func _process(_dt: float) -> void:
	minimap.visible = controller.page_id.is_empty()
	map_button.text = WhaleUIStyle.key("ui_region_map")
	for control: Control in [map_button, combo_hud]: control.visible = controller.page_id.is_empty()
	var objective: String=controller.host.dialogue.objective_hint()
	if is_instance_valid(controller.host.get("story")) and controller.host.story.running(): objective=CampaignStoryRoutes.objective(controller.host.story)
	if objective.is_empty(): objective=CampaignGuidance.hint(controller.host)
	objective_hud.present(objective,310.0)
	objective_hud.visible=objective_hud.visible and controller.page_id.is_empty() and is_instance_valid(controller.player) and controller.player.health>0
	_update_prompt()

func _update_prompt() -> void:
	var p: TidePlayer = controller.player
	if not is_instance_valid(p) or p.health <= 0 or not p.controls_enabled or not controller.page_id.is_empty() or controller.host.continuity.travelling or controller.host.continuity.transition.active:
		interaction_prompt.present("", "", false)
		return
	var prompt: String = controller.data.prompt()
	if prompt=="在营地歇息": prompt="歇息"
	var prompt_key: String = "tp_interact"
	var entrance: CampaignDoorway = controller.data.prompt_door()
	if prompt.is_empty() and p is WhalebellyCampaignPlayer and controller.host.has_ability("anchor"):
		if p.grapple_target != Vector2.INF:
			prompt = "接下一环 · 空格跃离" if p.grapple_hanging else "松开锚环"
		elif p.ring_candidate() != Vector2.INF:
			prompt = "牵引前方圆环 · 到环停挂 · 空格跃离"
		prompt_key = "grapple"
	if prompt.is_empty():
		prompt = CampaignGuidance.float_prompt(controller.host)
		prompt_key = "float"
	var blocked: bool = entrance != null and (not entrance.restriction().is_empty() or (entrance.kind == "exit" and controller.host.completed and int(entrance.data.get("to", -1)) < 0))
	var detail: String = CampaignGuidance.requirement_hint(controller.host, entrance.data) if blocked else ""
	var gates := controller.host.streaming.gates as CampaignStreamingGates
	var barrier: Dictionary = gates.nearby_prompt() if is_instance_valid(gates) else {}
	if not barrier.is_empty():
		prompt = str(barrier.message)
		detail = str(barrier.detail)
		blocked = true
	interaction_prompt.reduce_motion = controller.preferences.reduce_motion
	interaction_prompt.high_contrast = controller.preferences.contrast
	interaction_prompt.present(prompt, "" if blocked else WhaleUIStyle.key(prompt_key), blocked, detail)

func _layout() -> void:
	minimap.position = Vector2(18,size.y-154)
	minimap.size = Vector2(132,132)
	objective_hud.position = Vector2(size.x-330,20)
	vitals.position = Vector2(30,22)
	map_button.text = WhaleUIStyle.key("ui_region_map")
	map_button.position = Vector2(148,size.y-42)
	map_button.tooltip_text = "地图"
	pause_button.hide()

func text(at: Vector2, value: String, font_size: int = 17, color: Color = WhaleUIStyle.BONE) -> void:
	draw_string_outline(WhaleUIStyle.FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0.01,0.03,0.04,0.95*color.a))
	draw_string(WhaleUIStyle.FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if not is_instance_valid(controller.player): return
	var p: TidePlayer = controller.player
	var prefs: WhaleUIPreferences = controller.preferences
	if controller.page_id == "conversation": return
	text(Vector2(30,size.y-169),str(controller.host.room.name),17,WhaleUIStyle.BONE)
	if controller.host.practice: text(Vector2(30,172),"能力练习 · 不保存进度",13,WhaleUIStyle.AMBER)
	# 临时消息读取状态区真实底边，避免获得护盾后与第三行挤在同一基线上。
	var notice_y: float=maxf(150.0,vitals.position.y+vitals.content_bottom()+25.0)
	if controller.notice_left>0: text(Vector2(30,notice_y),controller.notice_text,15,WhaleUIStyle.AMBER)
	var boss: Dictionary = controller.data.boss()
	if not boss.is_empty():
		var width: float = minf(430,size.x*0.34)
		var x: float = (size.x-width)*0.5
		var boss_name: String = str(boss.get("name","负壳守卫"))
		text(Vector2(size.x*0.5-WhaleUIStyle.FONT.get_string_size(boss_name,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x*0.5,39),boss_name,23)
		draw_rect(Rect2(x,55,width,7),Color("15262c"))
		draw_rect(Rect2(x,55,width*clampf(float(boss.hp)/float(boss.max_hp),0,1),7),WhaleUIStyle.BONE)
		draw_rect(Rect2(x-3,52,width+6,13),WhaleUIStyle.MUTED,false,1)
		if prefs.numbers: text(Vector2(x+width+14,66),"%d/%d" % [maxi(0,int(boss.hp)),int(boss.max_hp)],15)
	if p.state == "recover":
		text(Vector2(30,notice_y+23),"调息中 · 松开取消",14,WhaleUIStyle.AMBER)
	elif p.skill_controller.input.attack_hold>=0.55 or p.skill_controller.input.long_hold>=0.6:
		text(Vector2(30,notice_y+23),"蓄力完成 · 松开释放",14,WhaleUIStyle.AMBER)
	if p is WhalebellyCampaignPlayer and p.floating:
		text(Vector2(30,notice_y+45),"浮膜余压 %.1f 秒" % p.float_left,14)
