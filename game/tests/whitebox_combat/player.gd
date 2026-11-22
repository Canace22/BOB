class_name CombatWhiteboxPlayer
extends TideCombatPlayer
## 白盒只覆盖试验参数与调试图形，战斗逻辑与主线共用。

func _ready() -> void:
	max_speed = 390.0
	acceleration = 9000.0
	friction = 12000.0
	gravity = 1750.0
	jump_height = 154.7
	short_jump_height = 40.0
	apex_hold = 0.0
	collision_size = Vector2(28,65)
	capsule_collision = true
	max_health = 5
	melee_damage = 1
	melee_reach = 125.0
	melee_height = 125.0
	melee_startup = 0.10
	melee_cancel_after = 0.0
	hurt_stun = 0.25
	hurt_invulnerability = 0.55
	hurt_soul_loss = 0
	heal_amount = 1
	preload_actions = false
	# 已由新图集显示角色，旧AnimationTree仅保留状态/事件，不再解码隐藏的36帧库。
	atlas_visual_enabled = true
	world_bounds = Rect2(-2000,-2000,4000,4000)
	super._ready()

func skill_unlocked(rule: String) -> bool:
	return rule != "chapter"

func _draw() -> void:
	if not show_debug: return
	var color := Color("59d7df")
	if retreating: color = Color("c89dff")
	elif state == "hit": color = Color("ff6474")
	elif skill_controller.visual_key == "parry": color = Color("ffe48c")
	draw_rect(Rect2(-14,-65,28,65),color)
	draw_line(Vector2(0,-48),Vector2(facing*32,-48),Color.WHITE,3.0)
	if state in ["strike_01","heavy"] and (not retreating or skill_controller.visual_key == "wb_backcut"):
		var reach: float = float(skill_controller.data.get("reach",melee_reach)) if skill_controller.active else melee_reach
		var key: String = skill_controller.visual_key
		if key == "wb_draw":
			draw_arc(Vector2(0,-40),reach,0,TAU,48,Color("ffd279"),5.0)
		elif key == "wb_flurry":
			for i: int in 5:
				var y: float = -90.0+i*17.0
				draw_line(Vector2(facing*15,y),Vector2(facing*reach,y+18.0),Color("ed96ff"),3.0)
		elif key == "wb_charge":
			draw_line(Vector2(0,-35),Vector2(facing*reach,-35),Color("ff966c"),12.0)
		else:
			draw_rect(Rect2(Vector2(0 if facing>0 else -reach,-90),Vector2(reach,85)),Color(0.3,0.9,1.0,0.2))

func create_skill_controller() -> TideCombatSkills:
	return CombatWhiteboxSwordSkills.new()

func create_action_visual() -> TideCombatVisual:
	return CombatWhiteboxActionVisual.new()

func create_afterimage() -> TideCombatAfterimage:
	return CombatWhiteboxAfterimage.new()

func create_pad_input() -> TideCombatInput:
	return CombatWhiteboxPadInput.new()

func create_hit_feedback() -> TideCombatFeedback:
	return CombatWhiteboxHitFeedback.new()
