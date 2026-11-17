class_name CombatWhiteboxPadInput
extends RefCounted
## 白盒手柄式键盘布局；临时覆盖冲突键位，退出场景恢复原InputMap。

const BASE: Dictionary = {"tp_attack":[KEY_J],"tp_jump":[KEY_SPACE],"wb_face_k":[KEY_K],"wb_face_l":[KEY_L],"tp_dash":[KEY_L,KEY_SHIFT],"tp_parry":[KEY_I,KEY_B],"tp_heavy":[],"tp_interact":[]}
const MODS: Dictionary = {"wb_lt":[KEY_Q],"wb_rt":[KEY_E]}
const FACES: Array[String] = ["tp_attack","wb_face_k","tp_parry","tp_dash"]
const LT: Array[String] = ["wb_rise","wb_drive","wb_draw","wb_charge"]
const RT: Array[String] = ["wb_flurry","cyclone","recover","A4_parry"]
const BOTH: Array[String] = ["scan","A5_slit","heavy","crystal_dash"]
const SELECT_WINDOW: float = 0.8
var actor: CombatWhiteboxPlayer
var saved: Dictionary = {}
var was_modified: bool = false
var focus_owned: bool = false
var long_owned: bool = false
var long_seconds: float = 0.0
var selected_page: int = 0
var select_left: float = 0.0
var chain_owned: bool = false

func tick(dt: float) -> void:
	select_left = maxf(0.0,select_left-dt)
	if select_left <= 0.0: selected_page = 0
	var pressed: int = (1 if Input.is_action_just_pressed("wb_lt") else 0) | (2 if Input.is_action_just_pressed("wb_rt") else 0)
	if pressed != 0:
		selected_page |= pressed
		select_left = SELECT_WINDOW
		actor.skill_controller.input.clear()
	if Input.is_action_just_pressed("ui_cancel"): consume_page()
	var c := actor.skill_controller as CombatWhiteboxSwordSkills
	if c.drive_window <= 0.0 and actor.pending_action != "wb_drive": chain_owned = false

func consume_page() -> void:
	selected_page = 0
	select_left = 0.0

func effective_page() -> int:
	# 点按后保留一次选招；旧按住组合也兼容，但不再要求左手持续占住Q/E。
	return selected_page | (1 if Input.is_action_pressed("wb_lt") else 0) | (2 if Input.is_action_pressed("wb_rt") else 0)

func setup(player: CombatWhiteboxPlayer) -> void:
	actor = player
	var bindings: Dictionary = BASE.merged(MODS)
	for action: String in bindings:
		saved[action] = InputMap.action_get_events(action) if InputMap.has_action(action) else null
		if not InputMap.has_action(action): InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for code: int in bindings[action]:
			for physical: bool in [true,false]:
				var key := InputEventKey.new()
				if physical: key.physical_keycode = code
				else: key.keycode = code
				InputMap.action_add_event(action,key)

func dispose() -> void:
	for action: String in saved:
		Input.action_release(action)
		if saved[action] == null: InputMap.erase_action(action)
		else:
			InputMap.action_erase_events(action)
			for event: InputEvent in saved[action]: InputMap.action_add_event(action,event)
	saved.clear()
	actor = null

func modified() -> bool:
	return effective_page() != 0

func backstep_pressed() -> bool:
	return not modified() and Input.is_action_pressed("tp_down") and Input.is_action_just_pressed("tp_dash")

func heal_held() -> bool:
	return focus_owned and Input.is_action_pressed("tp_parry")

func clear() -> void:
	consume_page()
	chain_owned = false
	long_owned = false
	long_seconds = 0.0
	actor.skill_controller.input.long_hold = 0.0
	if not actor.skill_controller.active and actor.skill_controller.visual_key == "crystal_dash": actor.skill_controller.visual_key = ""
	if focus_owned:
		actor.focus_input = false
		if actor.state == "recover" and actor.state_duration > 0.0: actor._cancel_focus()
	focus_owned = false

func read(dt: float) -> bool:
	var selection: int = effective_page()
	var modifier: bool = selection != 0
	if focus_owned and not heal_held():
		actor.focus_input = false
		if actor.state == "recover" and actor.state_duration > 0.0: actor._cancel_focus()
		focus_owned = false
	# 切换技能页时取消旧蓄力，防止松开修饰键补发普攻重劈。
	if modifier != was_modified: actor.skill_controller.input.clear()
	was_modified = modifier
	_update_long(dt,Input.is_action_pressed("tp_dash"))
	if focus_owned or long_owned: return true
	if not modifier:
		# K专职三段，空格独立跳跃；方向由每次按K时的A/D决定。
		if Input.is_action_just_pressed("wb_face_k"):
			_issue("wb_drive")
			return true
		if backstep_pressed(): return true
		# S+L后跳优先；只有真实L面键触发移动撞击，Shift仍可单独作基础冲刺。
		if Input.is_action_just_pressed("wb_face_l") and not is_zero_approx(actor.movement_axis()):
			_issue("wb_charge")
			return true
		# 方向派生在按下J时采样；空中下刺和冲刺接斩继续交给原输入内核。
		if Input.is_action_just_pressed("tp_attack") and actor.state not in ["A1_dash","A5_slit"]:
			var upper: bool = Input.is_action_pressed("tp_up")
			var sweep: bool = Input.is_action_pressed("tp_down") and actor.is_on_floor()
			if upper or sweep:
				actor.skill_controller.input.clear()
				_issue("wb_rise" if upper else "wb_draw")
				return true
		return backstep_pressed()
	var page: Array[String] = BOTH if selection == 3 else (LT if selection == 1 else RT)
	for i: int in FACES.size():
		# 扳机先按或与面键同帧按均生效；保持面键不因切页再出第二招。
		if not Input.is_action_just_pressed(FACES[i]): continue
		var action: String = page[i]
		consume_page()
		if action == "crystal_dash":
			long_owned = actor.is_on_floor()
			long_seconds = 0.0
			continue
		if action == "recover":
			focus_owned = true
			actor.focus_input = true
		if action == "A4_parry":
			if Input.is_action_pressed("tp_up"): action = "up_spell"
			elif Input.is_action_pressed("tp_down") and not actor.is_on_floor(): action = "dive"
		_issue(action)
	return true

func _issue(action: String) -> void:
	var previous_facing: float = actor.facing
	var axis: float = actor.movement_axis()
	# 同帧方向与面键按下时，也按方向起手；失败不改掉当前动作的面向。
	if not is_zero_approx(axis): actor.facing = signf(axis)
	if actor.request_action(action):
		if action == "wb_drive": chain_owned = true
		return
	actor.facing = previous_facing
	# 复用角色的短输入缓存；冷却、资源和取消条件仍由request_action逐帧校验。
	if actor._offense_active() and action != "recover":
		actor.pending_action = action
		actor.pending_left = actor.jump_buffer_time
		if action == "wb_drive": chain_owned = true

func _update_long(dt: float, held: bool) -> void:
	if not long_owned: return
	if held:
		if actor.state in ["hit","defeat","recover","interact"] or not actor.is_on_floor():
			long_owned = false
			return
		if actor.state_duration <= 0.0:
			long_seconds += dt
			var c: TideSkillController = actor.skill_controller
			c.visual_key = "crystal_dash"
			c.elapsed = minf(long_seconds,0.6)
			c.duration = 0.6
			c.input.long_hold = long_seconds
	else:
		long_owned = false
		if long_seconds >= 0.6: actor.request_action("crystal_dash")
		if not actor.skill_controller.active: actor.skill_controller.visual_key = ""
		actor.skill_controller.input.long_hold = 0.0
		long_seconds = 0.0

func page_hint() -> String:
	var page: int = effective_page()
	var timer: String = " [%.1fs]" % select_left
	if page == 3: return "Q then E: J scan | K slit | I heavy | hold L long dash"+timer
	if page == 1: return "Q then: J rise | K triple (repeat K) | I wide sweep | L charge launch"+timer
	if page == 2: return "E then: J flurry | K cyclone | hold I heal | L orb (W up / air S dive)"+timer
	if chain_owned: return "TRIPLE: repeat K + A/D to turn | I guard / L dash / S+L backstep"
	return "Space jump | A/D+K triple | A/D+L launch | L dash | W+J rise | S+J sweep"
