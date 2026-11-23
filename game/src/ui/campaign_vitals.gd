class_name WhaleCampaignVitals
extends Control
## 左上状态只读现有生命、蓄振、架势和反击，不创建额外资源。
var controller: WhaleCampaignUI

func has_shields() -> bool:
	return CampaignRelics.capacity(controller.host.collected)>0

func content_bottom() -> float:
	return 133.0 if has_shields() else 103.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_dt: float) -> void:
	visible = controller.page_id.is_empty()
	queue_redraw()

func meter(y: float, ratio: float, color: Color) -> void:
	var rect := Rect2(70,y,168,7)
	var frame := WhaleUIStyle.box(Color("10272d"),Color(WhaleUIStyle.BONE,0.65))
	frame.set_corner_radius_all(4)
	draw_style_box(frame,rect.grow(2))
	frame = WhaleUIStyle.box(color)
	frame.set_corner_radius_all(3)
	draw_style_box(frame,Rect2(rect.position,Vector2(rect.size.x*clampf(ratio,0,1),rect.size.y)))

func _draw() -> void:
	var p := controller.player as TideCombatPlayer
	if not is_instance_valid(p): return
	WhaleActionHUDStyle.panel(self,Rect2(-4,-4,320,content_bottom()),0.70)
	WhaleActionHUDStyle.text(self,Vector2(0,21),"生命",19)
	for i: int in p.max_health:
		WhaleActionHUDStyle.icon(self,"mask",Rect2(64+i*33,0,26,28),Color(0.94,0.98,1.18) if i<p.health else Color(0.38,0.43,0.44,0.55))
	var shields: int = CampaignRelics.capacity(controller.host.collected)
	var lower_offset: float = 30.0 if shields>0 else 0.0
	if shields>0:
		# 与生命使用相同的逐点排布；暗盾保留上限，亮盾表示剩余抵伤次数。
		WhaleActionHUDStyle.text(self,Vector2(0,51),"护盾",19,Color("8edbec"))
		for i: int in shields:
			var tint := Color("8edbec") if i<controller.host.relics.charges else Color(0.24,0.38,0.42,0.5)
			WhaleActionHUDStyle.icon(self,"guard",Rect2(64+i*33,30,26,28),tint)
	WhaleActionHUDStyle.icon(self,"soul",Rect2(-2,34+lower_offset,21,23))
	WhaleActionHUDStyle.text(self,Vector2(24,51+lower_offset),"蓄振",15)
	meter(42+lower_offset,float(p.soul)/p.max_soul,Color("61dfc1"))
	WhaleActionHUDStyle.text(self,Vector2(248,51+lower_offset),"%d / %d" % [p.soul,p.max_soul],14)
	var guard := p.skill_controller as TideCombatGuardSkills
	if guard != null:
		WhaleActionHUDStyle.icon(self,"guard",Rect2(-2,61+lower_offset,21,24))
		WhaleActionHUDStyle.text(self,Vector2(24,78+lower_offset),"架势",15,WhaleUIStyle.AMBER)
		meter(69+lower_offset,guard.guard_meter/guard.GUARD_MAX,Color("e4b25d") if guard.guard_lock<=0 else Color("ce7359"))
		WhaleActionHUDStyle.text(self,Vector2(248,78+lower_offset),"%d / %d" % [int(guard.guard_meter),int(guard.GUARD_MAX)],14,WhaleUIStyle.AMBER)
		if guard.guard_lock>0:
			WhaleActionHUDStyle.text(self,Vector2(70,101+lower_offset),"破防 · %.1fs" % guard.guard_lock,13,Color("ff967a"))
		elif guard.counter_left>0:
			WhaleActionHUDStyle.text(self,Vector2(70,101+lower_offset),"反击 +%d · %.1fs" % [guard.counter_bonus,guard.counter_left],13,WhaleUIStyle.AMBER)
