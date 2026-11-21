class_name WhaleCombatCounterHUD
extends Control
## 连击表现只读真实计数：空闲隐藏，命中触发一次放大，断连只淡出最后一个正数。
var controller: WhaleCampaignUI
var actor: TideCombatPlayer
var previous: int=0
var display_count: int=0
var hit_age: float=1.0
var fade_left: float=0.0
var combo_left: float=0.0
const HIT_TIME: float=0.42
const FADE_TIME: float=0.22

func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE

func clear() -> void:
	previous=0
	display_count=0
	hit_age=1.0
	fade_left=0.0
	visible=false

func _process(dt: float) -> void:
	var next_actor := controller.player as TideCombatPlayer
	if next_actor!=actor:
		actor=next_actor
		clear()
	if not is_instance_valid(actor) or actor.health<=0 or not controller.page_id.is_empty():
		clear()
		return
	position=Vector2(get_viewport_rect().size.x*0.81,get_viewport_rect().size.y*0.28)
	var combat := actor.skill_controller as TideCombatSkills
	var count: int=combat.combo_hits
	hit_age+=dt
	if count>0:
		if count!=previous:
			display_count=count
			hit_age=0.0
		fade_left=FADE_TIME
	else:
		fade_left=maxf(0.0,fade_left-dt)
	previous=count
	combo_left=combat.combo_left
	visible=display_count>0 and (count>0 or fade_left>0.0)
	queue_redraw()

func _draw() -> void:
	if display_count<=0: return
	var alpha: float = 1.0 if previous>0 else fade_left/FADE_TIME
	var kick: float = clampf(1.0-hit_age/HIT_TIME,0,1)
	var reduced: bool = controller.preferences.reduce_motion
	# 放大只属于HUD，不改变原战斗计数、时限与角色时钟。
	var zoom: float = 1.0 if reduced else 1.0+0.38*kick*kick
	var digits: String = str(display_count)
	var width: float = digits.length()*29+76
	WhaleActionHUDStyle.panel(self,Rect2(-8,-6,width+28,65),0.12*alpha)
	var origin := Vector2(width*0.5,24)
	draw_set_transform(origin*(1-zoom),0,Vector2.ONE*zoom)
	for i: int in digits.length():
		WhaleActionHUDStyle.icon(self,digits.substr(i,1),Rect2(i*29,-2,38,53),Color(1,1,1,alpha),true)
	var at: float = digits.length()*29+7
	WhaleActionHUDStyle.icon(self,"word",Rect2(at,7,76,25),Color(1,1,1,alpha),true)
	WhaleActionHUDStyle.icon(self,"underline",Rect2(at-6,31,88,14),Color(1,1,1,alpha),true)
	draw_set_transform(Vector2.ZERO)
