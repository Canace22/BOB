class_name EnemyLabBeamGuard
extends EnemyLabEnemy
## 诱追与受击反推；架势只响应真实伤害，破绽预算不会被连打刷新。
var defense: EnemyLabBeamDefense
var opening_left: float=0.0
var counters: int=0
var rear_breaks: int=0
var retreat_distance: float=0.0

func _ready() -> void:
	super._ready()
	collision_mask=1
	# 仅本轮封梁交战实体阻挡步行追穿；跳跃与原有穿越动作仍可换侧。
	player.world_collision_mask|=4
	defense=EnemyLabBeamDefense.new()
	defense.enemy=self
	add_child(defense)

func choose_move() -> String:
	if not forced_move.is_empty(): return forced_move
	return ["beam_guard","beam_press","beam_return","beam_brace"][attack_serial%4]

func begin_attack(key: String="") -> bool:
	if not super.begin_attack(key): return false
	retreat_distance=0.0
	if move_key=="beam_guard": defense.begin()
	if move_key=="beam_brace": set_state("brace")
	return true

func armor_active() -> bool:
	return state=="brace"

func control_window_open() -> bool:
	return outcome.is_empty() and opening_left>0.0 and state in ["recover","hurt"]

func set_state(next: String) -> void:
	var previous: String=state
	super.set_state(next)
	if next=="recover" and previous!="hurt": opening_left=float(spec.recover)
	if next=="idle": opening_left=0.0

func phase_duration() -> float:
	if state=="brace": return 0.80
	if state=="guarding": return 0.75
	if state=="guard_contact": return 0.22
	if state=="recover" or state=="hurt": return float(spec.get("recover",0.0))
	return super.phase_duration()

func take_hit(amount: int) -> void:
	if defense!=null and defense.intercept(amount): return
	var was_braced: bool=state=="brace"
	var front: bool=(player.global_position.x-global_position.x)*facing>=0.0
	var received: int=reactions.received
	super.take_hit(amount)
	# 死亡优先；同一多段技能后续命中不能重排或重置反推。
	if not outcome.is_empty() or reactions.received==received or not was_braced: return
	if front:
		followup_cancelled=false
		counters+=1
		spec=EnemyLabCatalog.action("beam_brace")
		set_state("tell")
		last_result="架叉受击 · 红光反推准备"
	else:
		rear_breaks+=1
		followup_cancelled=true
		_open(1.20,"绕背拆架 · 长破绽")
	changed.emit(last_result)

func _open(seconds: float, message: String) -> void:
	spec=spec.duplicate(true)
	spec.recover=seconds
	control_left=0.0
	set_state("recover")
	last_result=message

func guard_reaction(perfect: bool) -> void:
	_open(1.35 if perfect else 0.65,"完美格挡 · 刃架失衡" if perfect else "格挡停刃 · 短反击")
	feedback.receive(0.10 if perfect else 0.06,-facing,15.0 if perfect else 8.0)

func receive_feedback(seconds: float, direction: float, power: float) -> void:
	if defense!=null and defense.blocked_feedback:
		defense.blocked_feedback=false
		return
	super.receive_feedback(seconds,direction,power)

func attack_rect() -> Rect2:
	var width: float=float(spec.get("width",145.0))
	var height: float=float(spec.get("height",85.0))
	# 从身内起判，消除贴胸站桩盲区；身后的换侧空间仍然保留。
	return Rect2(global_position+Vector2(-28.0 if facing>0 else -width,-height),Vector2(width+28.0,height))

func _physics_process(dt: float) -> void:
	if feedback.frozen(dt): return
	velocity.y=minf(velocity.y+1750.0*dt,800.0)
	velocity.x=0.0
	if not outcome.is_empty(): timer+=dt
	elif state in ["recover","hurt"]:
		opening_left=maxf(0.0,opening_left-dt)
		control_left=maxf(0.0,control_left-dt)
		timer=float(spec.recover)-opening_left
		if opening_left<=0.0: set_state("idle")
		elif state=="hurt" and control_left<=0.0:
			set_state("recover")
			timer=float(spec.recover)-opening_left
	elif player.health>0:
		if state=="idle": _idle_tick(dt)
		elif defense.handles() and (move_key=="beam_guard" or state=="guard_contact"):
			defense.tick(dt)
		elif state=="brace":
			timer+=dt
			if timer>=0.80:
				followup_cancelled=true
				_open(0.35,"未受击 · 自然收架")
		else: _action_tick(dt)
	var previous: float=position.x
	move_and_slide()
	if state=="tell" and move_key=="beam_return": retreat_distance+=absf(position.x-previous)
	visual.present(self)
	queue_redraw()

func _idle_tick(dt: float) -> void:
	timer+=dt
	if not auto_attack: return
	var gap: Vector2=player.global_position-global_position
	if not is_zero_approx(gap.x): facing=signf(gap.x)
	if absf(gap.x)>900.0:
		velocity.x=signf(home.x-position.x)*float(profile.speed)
	elif timer>0.50 and absf(gap.x)<210.0 and absf(gap.y)<125.0: begin_attack()
	elif absf(gap.x)>120.0: velocity.x=facing*float(profile.speed)

func _action_tick(dt: float) -> void:
	if state=="tell":
		if timer<float(spec.lock):
			var axis: float=player.global_position.x-global_position.x
			if not is_zero_approx(axis): facing=signf(axis)
		if move_key=="beam_return" and retreat_distance<100.0:
			velocity.x=-facing*145.0
			if position.x<90.0 and velocity.x<0.0 or position.x>1190.0 and velocity.x>0.0: velocity.x=0.0
	elif state=="active": velocity.x=facing*float(spec.speed)
	timer+=dt
	if state=="active" and timer>=0.04: strike()
	if state not in ["tell","active"] or timer<phase_duration(): return
	if state=="tell": set_state("active")
	else:
		var miss: bool=not hit_sent
		_open(float(spec.recover),"扑空 · 刃落收招" if miss else "出手结束 · 收刃")

func pose() -> int:
	if defense!=null and defense.handles() and state!="idle": return defense.pose()
	if state=="brace": return 12
	if state in ["hurt","ended"]: return 15
	if state=="idle": return int(timer*7.0)%4 if absf(velocity.x)>5.0 else 0
	var row: int=profile.moves.find(move_key)+1
	var phase: int=0 if state=="tell" and timer<phase_duration()*0.5 else (1 if state=="tell" else (2 if state=="active" else 3))
	if move_key=="beam_brace" and state=="tell": phase=1
	return row*4+phase

func segments() -> Array[Dictionary]:
	if spec.is_empty(): return []
	if defense.handles(): return defense.segments()
	if state=="brace": return [{"phase":"brace","pulse":1,"start":0.0,"end":0.8}]
	if move_key=="beam_brace" and followup_cancelled:
		return [{"phase":"recover","pulse":1,"start":0.0,"end":float(spec.recover)}]
	var result: Array[Dictionary]=[]
	var cursor: float=0.0
	for phase: String in ["tell","active","recover"]:
		result.append({"phase":phase,"pulse":1,"start":cursor,"end":cursor+float(spec[phase])})
		cursor+=float(spec[phase])
	return result

func snapshot() -> Dictionary:
	var result: Dictionary=super.snapshot()
	result.opening_left=opening_left
	result.counters=counters
	result.rear_breaks=rear_breaks
	result.retreat_distance=retreat_distance
	result.defense_blocks=defense.blocks
	result.defense_breaks=defense.breaks
	result.ripostes=defense.ripostes
	result.defending=defense.guarding()
	result.shell=bool(result.shell) or defense.guarding()
	result.locked=state in ["brace","guarding","guard_contact"] or bool(result.locked)
	return result
