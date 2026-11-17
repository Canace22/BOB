class_name CombatWhiteboxPlayer
extends TidePlayer
## 白盒专用适配：复用正式战斗内核，不改变主线解锁或存档。

signal backstep_started
var retreating: bool = false
var retreat_time: float = 0.0
var retreat_cooldown: float = 0.0
var retreat_facing: float = 1.0
var backstep_enabled: bool = true
var show_debug: bool = false
var action_visual: CombatWhiteboxActionVisual
var afterimage: CombatWhiteboxAfterimage
var profile_legacy_us: int = 0
var pad_input: CombatWhiteboxPadInput
var hit_feedback: CombatWhiteboxHitFeedback

func _ready() -> void:
	skill_controller = CombatWhiteboxSwordSkills.new()
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
	melee_startup = 0.05
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
	$Visual.show()
	action_visual = CombatWhiteboxActionVisual.new()
	action_visual.name = "RunVisualController"
	add_child(action_visual)
	action_visual.setup(self,94.0)
	afterimage = CombatWhiteboxAfterimage.new()
	add_child(afterimage)
	afterimage.setup(self)
	if not InputMap.has_action("wb_backstep"):
		InputMap.add_action("wb_backstep")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_Z
		InputMap.action_add_event("wb_backstep",event)
	# 远程桌面/输入注入可能保留逻辑键而改变扫描码；白盒两种事件都接受。
	for action: StringName in InputMap.get_actions():
		if not str(action).begins_with("tp_") and not str(action).begins_with("wb_"): continue
		for binding: InputEvent in InputMap.action_get_events(action):
			if binding is InputEventKey and binding.physical_keycode != 0:
				var logical := InputEventKey.new()
				logical.keycode = binding.physical_keycode
				if not InputMap.action_has_event(action,logical): InputMap.action_add_event(action,logical)
	pad_input = CombatWhiteboxPadInput.new()
	pad_input.setup(self)
	hit_feedback = CombatWhiteboxHitFeedback.new()
	add_child(hit_feedback)
	hit_feedback.setup(self)

func _exit_tree() -> void:
	if pad_input != null: pad_input.dispose()
	super._exit_tree()

func skill_unlocked(rule: String) -> bool:
	# 测试普通技法，禁用通关升级自动替换，Shift仍走基础冲刺。
	return rule != "chapter"

func _physics_process(dt: float) -> void:
	if not controls_enabled or health <= 0:
		pad_input.clear()
		skill_controller.input.clear()
		pending_action = ""
		jump_buffer = 0.0
		if not controls_enabled: return
	if health > 0: pad_input.tick(dt)
	(skill_controller as CombatWhiteboxSwordSkills).update_combo(dt)
	retreat_cooldown = maxf(0.0,retreat_cooldown-dt)
	if controls_enabled and (Input.is_action_just_pressed("wb_backstep") or pad_input.backstep_pressed()):
		try_backstep()
	if not retreating:
		super._physics_process(dt)
		queue_redraw()
		return
	# 后跳独占运动；不运行被取消技能的事件，也不继承跳跃的无敌。
	retreat_time += dt
	hitstop = maxf(0.0,hitstop-dt)
	if not pad_input.modified() and Input.is_action_just_pressed("tp_attack"): request_action("wb_backcut")
	if skill_controller.active:
		state_time += dt
		skill_controller.tick()
	facing = retreat_facing
	invulnerable = maxf(0.0,invulnerable-dt)
	damage_flash_left = maxf(0.0,damage_flash_left-dt)
	for key: String in cooldowns:
		cooldowns[key] = maxf(0.0,float(cooldowns[key])-dt)
	velocity.x = -retreat_facing*420.0
	velocity.y += gravity*dt
	move_and_slide()
	if retreat_time > 0.1 and is_on_floor():
		retreating = false
		retreat_cooldown = 0.12
		velocity = Vector2.ZERO
		state_duration = 0.0
		state = "idle"
	queue_redraw()

func try_backstep() -> bool:
	if not backstep_enabled or retreating or retreat_cooldown > 0.0:
		return false
	if not controls_enabled or health <= 0 or not is_on_floor():
		return false
	if state in ["hit","defeat","recover","interact"]:
		return false
	# 先冻结被打断动作的当前帧，再切换状态；不能截到后跳姿势。
	afterimage.capture_pose()
	pad_input.clear()
	# 保留已付资源、冷却和已发射弹体；清除排队输入及未释放的多段攻击。
	if state in ["A1_dash","A5_slit"]:
		invulnerable = 0.0
	skill_controller.cancel()
	skill_controller.input.clear()
	pending_action = ""
	pending_left = 0.0
	jump_buffer = 0.0
	recoil_left = 0.0
	armor = 0.0
	hitstop = 0.0
	retreat_facing = facing
	_enter("jump_land",0.5)
	event_done = true
	retreating = true
	retreat_time = 0.0
	velocity = Vector2(-facing*420.0,-260.0)
	backstep_started.emit()
	return true

func request_action(action: String) -> bool:
	if CombatWhiteboxSwordSkills.DEFINITIONS.has(action): return skill_controller.request(action)
	if retreating: return false
	if action in ["A1_dash","parry"] and _offense_active():
		# 防御取消只开放已完成攻击判定的后摇；先校验冷却，失败不得吞掉原动作。
		var cooldown_key: String = "dash" if action == "A1_dash" else "parry"
		if not controls_enabled or health <= 0 or float(cooldowns.get(cooldown_key,0.0)) > 0.0:
			return false
		if not _offense_released(): return false
		skill_controller.cancel()
		skill_controller.input.clear()
		pending_action = ""
		pending_left = 0.0
		jump_buffer = 0.0
		recoil_left = 0.0
		armor = 0.0
		state = "idle"
		state_duration = 0.0
		state_time = 0.0
	return super.request_action(action)

func _read_input() -> void:
	if pad_input.read(get_physics_process_delta_time()):
		# 跳跃不是技能页面键，预选Q/E时也不能吞掉空格的跳跃/小跳输入。
		if Input.is_action_just_pressed("tp_jump"): jump_buffer = jump_buffer_time
		if Input.is_action_just_released("tp_jump"): short_jump = true
		return
	super._read_input()

func _before_move(dt: float) -> void:
	super._before_move(dt)
	# 只约束地面普攻两段；同为strike_01代理的位移技不能被误锁。
	if not is_on_floor() or velocity.y < 0.0 or state_duration <= 0.0: return
	var basic: bool = skill_controller.visual_key == "strike2" if skill_controller.active else state == "strike_01"
	if basic: velocity.x = 0.0

func _focus_continues() -> bool:
	if pad_input.focus_owned:
		return focus_input and pad_input.heal_held() and soul >= skill_cost and health < max_health and is_on_floor() and cooldowns.heal <= 0.0
	return super._focus_continues()

func _offense_active() -> bool:
	if state_duration <= 0.0: return false
	if skill_controller.active:
		return skill_controller.data.has("damage")
	return state in ["strike_01","A3_anchor","heavy","A4_parry"]

func _offense_released() -> bool:
	if skill_controller.active:
		if not skill_controller.released: return false
		var pulses: Array = skill_controller.data.get("pulses",[])
		# 多段技能最后一段释放后才算后摇；不让冲刺/格挡顶替后跳的强制取消。
		if skill_controller.pulse_index < pulses.size(): return false
		if str(skill_controller.data.get("motion","")) == "dive":
			return skill_controller.landed
		return true
	var active_tail: float = 1.0/animation_fps if state in ["strike_01","A3_anchor"] else 0.0
	return event_done and state_time >= action_trigger_time()+active_tail

func take_damage(amount: int=1, source: Vector2=Vector2.ZERO, force: bool=false) -> bool:
	var accepted: bool = super.take_damage(amount,source,force)
	if accepted:
		retreating = false
		pad_input.clear()
	return accepted

func _cache_clip(source_id: String) -> void:
	var uncached: bool = not textures.has(source_id)
	var started: int = Time.get_ticks_usec()
	super._cache_clip(source_id)
	if uncached: profile_legacy_us += Time.get_ticks_usec()-started

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
