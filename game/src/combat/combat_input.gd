class_name TideCombatInput
extends RefCounted
## 主线与白盒共用手柄式键盘布局；角色离场恢复原InputMap。

const BASE: Dictionary = {"tp_attack":[KEY_J],"tp_jump":[KEY_SPACE],"wb_face_k":[KEY_K],"wb_face_l":[KEY_L],"tp_dash":[KEY_L,KEY_SHIFT],"tp_parry":[KEY_I,KEY_B],"tp_heavy":[],"tp_interact":[KEY_F],"attack":[KEY_J],"interact":[KEY_F],"heal":[]}
const MODS: Dictionary = {"wb_lt":[KEY_Q],"wb_rt":[KEY_E]}
const FACES: Array[String] = ["tp_attack","wb_face_k","tp_parry","tp_dash"]
const LT: Array[String] = ["wb_rise","wb_drive","wb_draw","wb_charge"]
const RT: Array[String] = ["wb_flurry","cyclone","recover","A4_parry"]
const BOTH: Array[String] = ["scan","A5_slit","heavy","crystal_dash"]
const SELECT_WINDOW: float = 0.8
const CHORD_WINDOW: float = 0.06
const ACTION_BUFFER: float = 0.2
var waiting_face: int = -1
var face_age: float = 0.0
var ready_face: int = -1
var actor: TideCombatPlayer
var saved: Dictionary = {}
var suppress_modifiers: bool = false
var was_modified: bool = false
var focus_owned: bool = false
var long_owned: bool = false
var long_seconds: float = 0.0
var selected_page: int = 0
var select_left: float = 0.0
var chain_owned: bool = false

func tick(dt: float) -> void:
	# 在角色的命中停顿之前采样，避免停顿期间的点按丢失。
	ready_face = -1
	if waiting_face >= 0: face_age += dt
	if suppress_modifiers:
		if Input.is_action_pressed("wb_lt") or Input.is_action_pressed("wb_rt"): return
		suppress_modifiers = false
	select_left = maxf(0.0,select_left-dt)
	if select_left <= 0.0: selected_page = 0
	var pressed: int = (1 if Input.is_action_just_pressed("wb_lt") else 0) | (2 if Input.is_action_just_pressed("wb_rt") else 0)
	if pressed != 0:
		selected_page |= pressed
		select_left = SELECT_WINDOW
		actor.skill_controller.input.clear()
	if Input.is_action_just_pressed("ui_cancel"): consume_page()
	for i: int in FACES.size():
		if Input.is_action_just_pressed("wb_face_l" if i==3 else FACES[i]):
			waiting_face = i
			face_age = 0.0
			actor.pending_action = ""
			actor.pending_left = 0.0
	var c := actor.skill_controller as TideCombatSkills
	if c.drive_window <= 0.0 and actor.pending_action != "wb_drive": chain_owned = false

func consume_page() -> void:
	selected_page = 0
	select_left = 0.0

func effective_page() -> int:
	if suppress_modifiers: return 0
	# 点按后保留一次选招；旧按住组合也兼容，但不再要求左手持续占住Q/E。
	return selected_page | (1 if Input.is_action_pressed("wb_lt") else 0) | (2 if Input.is_action_pressed("wb_rt") else 0)

func setup(player: TideCombatPlayer) -> void:
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
	if modified() or not Input.is_action_pressed("tp_down"): return false
	# 在命中停顿前读取等待中的L，允许L→S；窗口过期后不重写已发出的位移。
	var chord: bool = waiting_face == 3 and face_age <= CHORD_WINDOW
	var shift: bool = Input.is_action_just_pressed("tp_dash") and not Input.is_action_just_pressed("wb_face_l")
	return chord or shift

func heal_held() -> bool:
	return focus_owned and Input.is_action_pressed("tp_parry")

func clear() -> void:
	waiting_face = -1
	ready_face = -1
	face_age = 0.0
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
	if Input.is_action_just_pressed("tp_dash") and not Input.is_action_just_pressed("wb_face_l"):
		_issue("A1_dash")
		return true
	if waiting_face >= 0:
		# A/D+L仍可能补成更高优先级的后跳，不能因正在移动就提前结算撞击。
		var direction: bool = (waiting_face==0 and (Input.is_action_pressed("tp_up") or Input.is_action_pressed("tp_down"))) or (waiting_face==1 and not is_zero_approx(actor.movement_axis()))
		if backstep_pressed():
			waiting_face = -1
			actor.try_backstep()
			return true
		if effective_page() == 0 and not direction and face_age < CHORD_WINDOW: return true
		ready_face = waiting_face
		waiting_face = -1
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
		if ready_face == 1:
			_issue("wb_drive")
			return true
		if backstep_pressed(): return true
		# S+L后跳优先；只有真实L面键触发移动撞击，Shift仍可单独作基础冲刺。
		if ready_face == 3 and not is_zero_approx(actor.movement_axis()):
			_issue("wb_charge")
			return true
		# 方向派生在按下J时采样；空中下刺和冲刺接斩继续交给原输入内核。
		if ready_face == 0 and actor.state not in ["A1_dash","A5_slit"]:
			var upper: bool = Input.is_action_pressed("tp_up")
			var sweep: bool = Input.is_action_pressed("tp_down") and actor.is_on_floor()
			if upper or sweep:
				actor.skill_controller.input.clear()
				_issue("wb_rise" if upper else "wb_draw")
				return true
		if ready_face == 0:
			var kernel: TideSkillInput = actor.skill_controller.input
			var action: String="strike2" if kernel.combo_next else "strike_01"
			if Input.is_action_pressed("tp_down") and not actor.is_on_floor(): action="A3_anchor"
			if actor.state in ["A1_dash","A5_slit"]: action="dash_slash"
			_issue(action)
			kernel.attack_tracking = true
			kernel.attack_hold = 0.0
			return true
		if ready_face == 2 or ready_face == 3:
			_issue("parry" if ready_face == 2 else "A1_dash")
			return true
		return backstep_pressed()
	var page: Array[String] = BOTH if selection == 3 else (LT if selection == 1 else RT)
	for i: int in FACES.size():
		# 扳机先按或与面键同帧按均生效；保持面键不因切页再出第二招。
		if ready_face != i: continue
		var action: String = resolve_action(page[i])
		consume_page()
		if action == "crystal_dash":
			long_owned = actor.is_on_floor()
			long_seconds = 0.0
			continue
		if action == "recover":
			focus_owned = true
			actor.focus_input = true
		_issue(action)
	return true

func _issue(action: String) -> void:
	var previous_facing: float = actor.facing
	var axis: float = actor.movement_axis()
	# 同帧方向与面键按下时，也按方向起手；失败不改掉当前动作的面向。
	if not is_zero_approx(axis): actor.facing = signf(axis)
	if actor.request_action(action):
		actor.pending_action = ""
		actor.pending_left = 0.0
		if action == "wb_drive": chain_owned = true
		return
	actor.facing = previous_facing
	# 复用角色的短输入缓存；冷却、资源和取消条件仍由request_action逐帧校验。
	if actor.state not in ["hit","defeat","recover","interact"] and action != "recover":
		actor.pending_action = action
		actor.pending_left = ACTION_BUFFER
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

func resolve_action(action: String) -> String:
	# 方向派生与通关升级由输入、HUD共用，避免提示基础技但实际发升级技。
	if action != "A4_parry": return action
	var upgraded: bool = actor.skill_unlocked("chapter") and actor.skill_controller.use_upgrades
	if Input.is_action_pressed("tp_up"): return "abyss_scream" if upgraded else "up_spell"
	if Input.is_action_pressed("tp_down") and not actor.is_on_floor(): return "dark_dive" if upgraded else "dive"
	return "shadow_orb" if upgraded else "A4_parry"
