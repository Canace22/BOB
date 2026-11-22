class_name EnemyLabElder
extends EnemyLabEnemy
## 老守护者的撑柄控距：稳定护甲、有限换握与非致死解除武装。
var mimic: EnemyLabElderMimic
var cycle: EnemyLabElderCycle
var stable: bool=true
var force_unstable: bool=false
var opening_left: float=0.0
var last_move: String=""
var repeats: int=0
var pressure_chain: int=0
var boosted_chase: float=0.0

func _ready() -> void:
	super._ready()
	collision_mask=1
	player.world_collision_mask|=4
	cycle=EnemyLabElderCycle.new()
	cycle.enemy=self
	mimic=EnemyLabElderMimic.new()
	mimic.enemy=self
	add_child(mimic)

func choose_move() -> String:
	if not forced_move.is_empty(): return forced_move
	if not pressure.queued.is_empty(): return pressure.queued
	if attack_serial==0: return "elder_sweep"
	if attack_serial==1: return "elder_thrust"
	if mimic.ready_to_cast() and last_move!="elder_mimic" and absf(player.position.x-position.x)<=mimic.reach(): return "elder_mimic"
	var gap: float=absf(player.position.x-position.x)
	var candidate: String="elder_thrust" if gap>230.0 else ("elder_vault" if gap<100.0 else "elder_grip")
	if candidate==last_move and repeats>=2: return "elder_grip" if candidate!="elder_grip" else "elder_vault"
	return candidate

func begin_attack(key: String="") -> bool:
	var requested: String=key if not key.is_empty() else choose_move()
	if requested=="elder_mimic":
		if not mimic.ready_to_cast(): return false
		if key.is_empty(): mimic.memory=mimic.repertoire.choose()
	if not super.begin_attack(requested): return false
	stable=absf(position.x-home.x)<=26.0 and not force_unstable
	force_unstable=false
	if move_key in ["elder_vault","elder_mimic"]: stable=false
	if not stable: spec.recover=float(spec.recover)+0.35
	repeats=repeats+1 if last_move==move_key else 1
	last_move=move_key
	if move_key=="elder_mimic": mimic.begin()
	return true

func armor_active() -> bool:
	return stable and state in ["idle","tell","active"]

func control_window_open() -> bool:
	return outcome.is_empty() and opening_left>0.0 and state in ["recover","hurt"]

func set_state(next: String) -> void:
	var previous: String=state
	super.set_state(next)
	if next=="recover" and previous!="hurt": opening_left=float(spec.recover)
	if next=="idle": opening_left=0.0

func phase_duration() -> float:
	if state in ["recover","hurt"]: return float(spec.get("recover",0.0))
	if state=="vault": return 0.72
	if state=="settle": return 0.45
	if state=="reground": return 0.50
	if move_key=="elder_grip" and pulse==2:
		if state=="tell": return float(spec.second)
		if state=="active": return 0.20
	return super.phase_duration()

func _physics_process(dt: float) -> void:
	if feedback.frozen(dt): return
	pressure.tick(dt)
	mimic.cooldown=maxf(0.0,mimic.cooldown-dt)
	boosted_chase=maxf(0.0,boosted_chase-dt)
	velocity.y=minf(velocity.y+1750.0*dt,800.0)
	velocity.x=0.0
	if not outcome.is_empty(): timer+=dt
	elif state in ["recover","hurt"]:
		opening_left=maxf(0.0,opening_left-dt)
		control_left=maxf(0.0,control_left-dt)
		timer=float(spec.recover)-opening_left
		if opening_left<=0.0:
			control_left=0.0
			if attack_serial%3==0 or player.health<=0:
				set_state("reground")
			else:
				set_state("idle")
				timer=0.13
			stable=false
		elif state=="hurt" and control_left<=0.0:
			set_state("recover")
			timer=float(spec.recover)-opening_left
	elif player.health>0:
		if state in ["vault","settle","reground"]: cycle.tick(dt)
		elif state=="idle": _idle_tick(dt)
		elif move_key=="elder_mimic": mimic.tick(dt)
		else:
			if state=="tell" and pulse==1 and timer<float(spec.lock):
				var axis: float=player.position.x-position.x
				if not is_zero_approx(axis): facing=signf(axis)
			advance_action(dt)
			if state=="active": velocity.x=facing*float(spec.speed)
	if mimic.evade_active(): collision_layer=0
	move_and_slide()
	if collision_layer==0 and outcome.is_empty() and not mimic.evade_active():
		var body := Rect2(player.position-Vector2(14,65),Vector2(28,65))
		if not hurt_rect().intersects(body): collision_layer=4
	visual.present(self)
	queue_redraw()

func _idle_tick(dt: float) -> void:
	timer+=dt
	if not auto_attack: return
	var gap: Vector2=player.position-position
	if not is_zero_approx(gap.x): facing=signf(gap.x)
	var reach: float=270.0 if choose_move()=="elder_thrust" else 210.0
	if choose_move()=="elder_mimic": reach=mimic.reach()
	if absf(gap.x)>1100.0: velocity.x=signf(home.x-position.x)*float(profile.speed)
	elif timer>pressure.idle(0.16) and absf(gap.x)<reach and absf(gap.y)<135.0: begin_attack()
	elif absf(gap.x)>120.0:
		velocity.x=facing*((230.0 if pressure.enabled() else 210.0) if boosted_chase<=0.0 else 270.0)
		if absf(position.x-home.x)>26.0: stable=false

func advance_action(dt: float) -> void:
	timer+=dt
	if state=="active" and timer>=0.04: strike()
	if state not in ["tell","active"] or timer<phase_duration(): return
	if state=="tell":
		if move_key=="elder_vault": cycle.launch()
		else: set_state("active")
	elif move_key=="elder_grip" and pulse==1:
		var gap: Vector2=player.position-position
		if not hit_sent and (absf(gap.x)>240.0 or absf(gap.y)>150.0):
			followup_cancelled=true
			set_state("recover")
		else:
			pulse=2
			if not is_zero_approx(gap.x): facing=signf(gap.x)
			set_state("tell")
	else:
		var gap: float=absf(player.position.x-position.x)
		if auto_attack and hit_sent and gap<240.0 and pressure_chain<1:
			pressure_chain+=1
			spec.recover=0.32
		else: pressure_chain=0
		set_state("recover")

func guard_reaction(perfect: bool) -> void:
	pressure_chain=0
	if move_key=="elder_mimic": mimic.cancel()
	if move_key=="elder_grip" and pulse==1 and not (pressure.enabled() and perfect):
		last_result="挡住回拨 · 仍有换握反压"
		feedback.receive(0.05,-facing,6.0)
		return
	pressure.cancel("perfect_guard" if perfect else "guard")
	stable=false
	force_unstable=true
	if pressure.enabled(): followup_cancelled=true
	spec=spec.duplicate(true)
	spec.recover=1.55 if perfect else 0.65
	set_state("recover")
	feedback.receive(0.10 if perfect else 0.05,-facing,15.0 if perfect else 6.0)

func attack_rect() -> Rect2:
	if move_key=="elder_mimic": return mimic.area()
	var width: float=float(spec.get("width",150.0))
	if move_key=="elder_grip" and pulse==1: width=100.0
	return Rect2(global_position+Vector2(-30.0 if facing>0 else -width,-float(spec.get("height",85.0))),Vector2(width+30.0,float(spec.get("height",85.0))))

func take_hit(amount: int) -> void:
	if not can_receive_hit(): return
	if mimic.repertoire.block(amount): return
	var replant: bool=state=="reground"
	var received: int=reactions.received
	super.take_hit(amount)
	if outcome.is_empty() and reactions.received>received: mimic.take_hit(amount)
	if replant and outcome.is_empty() and reactions.received>received: cycle.pressure_replant()

func can_receive_hit() -> bool:
	return super.can_receive_hit() and not mimic.evade_active()

func receive_feedback(seconds: float, direction: float, power: float) -> void:
	if mimic.repertoire.blocked_feedback:
		mimic.repertoire.blocked_feedback=false
		return
	super.receive_feedback(seconds,direction,power)

func finish() -> void:
	# 终局对手失去拦闸能力但存活，调试选项不能改写叙事结局。
	if mimic!=null: mimic.cancel()
	var comparison: bool=kill_comparison
	kill_comparison=false
	super.finish()
	kill_comparison=comparison
	opening_left=0.0
	stable=false
	force_unstable=false

func pose() -> int:
	if not outcome.is_empty(): return 23
	var special: int=cycle.pose()
	if special>=0: return special
	if state=="hurt": return 7
	if move_key=="elder_mimic" and state!="idle": return mimic.pose()
	if state=="idle": return int(timer*5.0)%4 if absf(velocity.x)>5.0 else 22
	if move_key=="elder_grip" and state in ["tell","active"]:
		return 12+(0 if state=="tell" else 1)+(2 if pulse==2 else 0)
	if move_key=="elder_vault": return 16 if state=="tell" else 19
	var row: int=1 if move_key=="elder_sweep" else 2
	return row*4+(0 if state=="tell" and timer<phase_duration()*0.5 else (1 if state=="tell" else (2 if state=="active" else 3)))

func snapshot() -> Dictionary:
	var result: Dictionary=super.snapshot()
	result.elder_stable=stable
	result.learned_count=mimic.repertoire.learned.size()
	result.copied_healing=mimic.repertoire.healing
	result.copied_blocks=mimic.repertoire.shields
	result.learned=mimic.memory_title()
	result.mimic_casts=mimic.casts
	result.mimic_interrupts=mimic.interrupted
	result.opening_left=opening_left
	result.vaults=cycle.vaults
	result.replant_interrupts=cycle.replant_interrupts
	result.locked=state in ["vault","settle"] or bool(result.locked) or (move_key=="elder_grip" and pulse==2)
	return result

func segments() -> Array[Dictionary]:
	if spec.is_empty(): return []
	if move_key=="elder_mimic": return mimic.segments()
	var special: Array[Dictionary]=cycle.segments()
	if not special.is_empty(): return special
	var result: Array[Dictionary]=[]
	var cursor: float=0.0
	var parts: int=2 if move_key=="elder_grip" and not followup_cancelled else 1
	for part: int in parts:
		for phase: String in ["tell","active"]:
			var seconds: float=float(spec[phase])
			if part==1: seconds=float(spec.second) if phase=="tell" else 0.20
			result.append({"phase":phase,"pulse":part+1,"start":cursor,"end":cursor+seconds})
			cursor+=seconds
	result.append({"phase":"recover","pulse":parts,"start":cursor,"end":cursor+float(spec.recover)})
	return result
