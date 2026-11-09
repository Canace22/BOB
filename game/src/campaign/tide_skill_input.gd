class_name TideSkillInput
extends RefCounted
var controller: TideSkillController
var attack_hold: float=0.0
var long_hold: float=0.0
var combo_left: float=0.0
var combo_next: bool=false
var attack_tracking: bool=false
var long_tracking: bool=false

func clear() -> void:
	if controller!=null and not controller.active and controller.visual_key in ["great_slash","cyclone","crystal_dash"]:
		controller.visual_key=""
		controller.elapsed=0.0
	attack_hold=0.0
	long_hold=0.0
	combo_left=0.0
	combo_next=false
	attack_tracking=false
	long_tracking=false

func read(dt: float) -> void:
	var p: TidePlayer=controller.actor
	if Input.is_action_just_pressed("tp_base_skills") and p.skill_practice_enabled():
		controller.use_upgrades=not controller.use_upgrades
		p.notification.emit("练习：升级潮术" if controller.use_upgrades else "练习：基础潮术")
	combo_left=maxf(0,combo_left-dt)
	if combo_left==0: combo_next=false
	if Input.is_action_just_pressed("tp_attack"):
		attack_tracking=true
		attack_hold=0.0
		var action: String="strike_01"
		if p.state in ["A1_dash","A5_slit"]: action="dash_slash"
		elif Input.is_action_pressed("tp_up"): action="upper"
		elif Input.is_action_pressed("tp_down") and not p.is_on_floor(): action="A3_anchor"
		elif combo_next: action="strike2"
		if not p.request_action(action):
			p.pending_action=action;p.pending_left=p.jump_buffer_time
		combo_next=not combo_next
		combo_left=0.65
	if Input.is_action_pressed("tp_attack") and attack_tracking:
		attack_hold+=dt
		if attack_hold>=0.25 and not controller.active and p.state_duration<=0 and p.skill_unlocked("dash"):
			controller.visual_key="cyclone" if Input.is_action_pressed("tp_down") else "great_slash"
			controller.elapsed=minf(attack_hold*0.2,0.14)
			controller.duration=0.5
	if attack_tracking and not Input.is_action_pressed("tp_attack"):
		if attack_tracking and attack_hold>=0.55:
			p.request_action("cyclone" if Input.is_action_pressed("tp_down") else "great_slash")
		attack_hold=0.0
		attack_tracking=false
		if not controller.active and controller.visual_key in ["great_slash","cyclone"]: controller.visual_key=""
	if Input.is_action_just_pressed("tp_orb"):
		var upgraded: bool=p.skill_unlocked("chapter") and controller.use_upgrades
		var action: String="shadow_orb" if upgraded else "A4_parry"
		if Input.is_action_pressed("tp_up"): action="abyss_scream" if upgraded else "up_spell"
		elif Input.is_action_pressed("tp_down") and not p.is_on_floor(): action="dark_dive" if upgraded else "dive"
		p.request_action(action)
	if Input.is_action_just_pressed("tp_dash"):
		p.request_action("shadow_dash" if p.skill_unlocked("chapter") and controller.use_upgrades else "A1_dash")
	if Input.is_action_just_pressed("tp_parry"): p.request_action("parry")
	if Input.is_action_just_pressed("tp_scan"): p.request_action("scan")
	if Input.is_action_just_pressed("tp_long_dash"):
		long_tracking=p.skill_unlocked("dash")
		if not long_tracking: p.notification.emit("蓄力长冲尚未解锁；击败负壳守卫后可用")
	if Input.is_action_pressed("tp_long_dash") and long_tracking and p.is_on_floor() and p.state_duration<=0:
		long_hold+=dt
		if long_hold>=0.15 and not controller.active:
			controller.visual_key="crystal_dash";controller.elapsed=minf(long_hold,0.6);controller.duration=0.6
	elif long_tracking and not Input.is_action_pressed("tp_long_dash"):
		if long_tracking and long_hold>=0.6: p.request_action("crystal_dash")
		long_hold=0.0
		long_tracking=false
		if not controller.active: controller.visual_key=""
	else:
		long_hold=0.0
	if long_hold==0.0 and not controller.active and controller.visual_key=="crystal_dash": controller.visual_key=""
	if Input.is_action_just_pressed("tp_interact"):
		var target: Node=p.interacted_target
		p.request_action("tram" if is_instance_valid(target) and target.has_method("use_transit_pass") else "interact")
