class_name EnemyLabWarden
extends EnemyLabEnemy
## 长柄封路与撤离目标；仅拥有敌人时序，伤害/架势使用共用协议。
signal reached_exit
const EXIT_X: float=1130.0
var passed: bool=false
var exit_enabled: bool=false
var opening_left: float=0.0
var flinch_left: float=0.0
var flinch_axis: float=0.0
var first_gap: float=0.0
var court: EnemyLabPumpCourt
var water: EnemyLabWardenWater

func _ready() -> void:
	super._ready()
	collision_mask=1
	water=EnemyLabWardenWater.new()
	water.enemy=self

func choose_move() -> String:
	if not forced_move.is_empty(): return forced_move
	if not pressure.queued.is_empty(): return pressure.queued
	var gap: float=absf(player.position.x-position.x)
	if pressure.enabled() and gap<240.0 and attack_serial%3==2: return "warden_double"
	if gap<95.0: return "warden_waterstep"
	return "warden_barrage" if gap>330.0 or attack_serial%2==0 else "warden_vortex"

func begin_attack(key: String="") -> bool:
	var accepted: bool=super.begin_attack(key)
	if accepted:
		if water.handles(): water.begin()
	return accepted

func release_pressure() -> void:
	if not outcome.is_empty(): return
	pressure.cancel("court_overload")
	if spec.is_empty(): spec=action_spec("warden_barrage")
	spec=spec.duplicate(true)
	spec.recover=1.35
	followup_cancelled=true
	if water!=null: water.cancel()
	control_left=0.0
	flinch_left=0.0
	set_state("recover")
	changed.emit("导压反冲 · 失衡窗口")

func control_window_open() -> bool:
	return outcome.is_empty() and opening_left>0.0 and state in ["recover","hurt"]

func set_state(next: String) -> void:
	var previous: String=state
	super.set_state(next)
	if next=="recover" and previous!="hurt": opening_left=float(spec.recover)
	if next=="idle":
		opening_left=0.0
		if water!=null: water.pressure_hits=0
	if is_instance_valid(visual): visual.present(self)

func phase_duration() -> float:
	if water!=null and water.handles(): return water.duration()
	if state=="tell" and pulse==2: return float(spec.second)
	return super.phase_duration()

func _physics_process(dt: float) -> void:
	# 安全线的结束优先于局部停顿与有效段，越线后不补发旧攻击。
	if exit_enabled and not passed and player.health>0 and player.position.x>=combat_space.exit_x:
		passed=true
		if outcome.is_empty(): finish()
		reached_exit.emit()
		changed.emit("安全线抵达 · 执卫停手")
	if feedback.frozen(dt): return
	pressure.tick(dt)
	velocity.y=minf(velocity.y+1750.0*dt,800.0)
	velocity.x=move_toward(velocity.x,0.0,2000.0*dt)
	if not outcome.is_empty(): timer+=dt
	elif state in ["recover","hurt"]:
		opening_left=maxf(0.0,opening_left-dt)
		control_left=maxf(0.0,control_left-dt)
		timer+=dt
		if opening_left<=0.0: set_state("idle")
		elif state=="hurt" and control_left<=0.0: set_state("recover")
	elif player.health>0:
		if state=="idle": _idle_tick(dt)
		elif water.handles():
			water.tick(dt)
			if state=="active" and move_key=="warden_waterstep": velocity.x=facing*float(spec.speed)
		else:
			if state=="tell" and pulse==1 and timer<float(spec.lock):
				var axis: float=player.global_position.x-global_position.x
				if not is_zero_approx(axis): facing=signf(axis)
			advance_action(dt)
			if state=="active": velocity.x=facing*float(spec.speed)
	if flinch_left>0.0 and state!="active":
		flinch_left=maxf(0.0,flinch_left-dt)
		velocity.x=flinch_axis*80.0
	if position.x<combat_space.x(320) and velocity.x<0: velocity.x=0.0
	if position.x>combat_space.x(1030) and velocity.x>0: velocity.x=0.0
	move_and_slide()
	if collision_layer==0 and outcome.is_empty() and state not in ["wash","reform"]:
		var body := Rect2(player.global_position-Vector2(14,65),Vector2(28,65))
		if not hurt_rect().intersects(body): collision_layer=4
	visual.present(self)
	queue_redraw()

func _idle_tick(dt: float) -> void:
	timer+=dt
	if not auto_attack: return
	var gap: float=player.position.x-position.x
	if not is_zero_approx(gap): facing=signf(gap)
	var reach: float=700.0 if choose_move() in EnemyLabWardenWater.KEYS else 240.0
	if timer>pressure.idle(0.50) and absf(gap)<reach and absf(player.position.y-position.y)<120.0:
		begin_attack()
	else:
		# 守在玩家与出口之间；被绕过后正常追赶，不瞬移封死安全线。
		var goal: float=combat_space.clamp_x(player.position.x+170.0,500.0,1005.0)
		if absf(goal-position.x)>12.0: velocity.x=signf(goal-position.x)*float(profile.speed)

func advance_action(dt: float) -> void:
	timer+=dt
	if state=="active" and timer>=0.06: strike()
	if state not in ["tell","active"] or timer<phase_duration(): return
	if state=="tell": set_state("active")
	elif move_key=="warden_double" and pulse==1:
		var gap: Vector2=player.global_position-global_position
		first_gap=absf(gap.x)
		var reach: float=float(spec.width)+float(profile.radius)*0.5+30.0
		if absf(gap.x)>reach or gap.x*facing< -25.0 or absf(gap.y)>135.0:
			followup_cancelled=true
			set_state("recover")
			changed.emit("首刺落空 · 取消跟进")
		else:
			pulse=2
			set_state("tell")
	else: set_state("recover")

func guard_reaction(perfect: bool) -> void:
	if move_key=="warden_double" and pulse==1 and not perfect:
		last_result="挡住首刺 · 留意第二刺"
		velocity.x=0.0
		feedback.receive(0.04,-facing,5.0)
		return
	followup_cancelled=move_key=="warden_double" and pulse==1
	super.guard_reaction(perfect)
	if move_key=="warden_double" and pulse==1: followup_cancelled=true

func attack_rect() -> Rect2:
	if move_key=="warden_push":
		return Rect2(global_position-Vector2(65,100),Vector2(130,100))
	return super.attack_rect()

func take_hit(amount: int) -> void:
	var before: int=reactions.received
	super.take_hit(amount)
	if outcome.is_empty() and reactions.received>before:
		water.take_hit(amount)
		flinch_axis=signf(position.x-player.position.x)
		flinch_left=0.13

func finish() -> void:
	flinch_left=0.0
	if is_instance_valid(court): court.stop()
	if water!=null: water.cancel()
	# 这位角色固定存活，调试击杀对照也不能改写其结局。
	var comparison: bool=kill_comparison
	kill_comparison=false
	super.finish()
	kill_comparison=comparison

func snapshot() -> Dictionary:
	var result: Dictionary=super.snapshot()
	result.route_passed=passed
	result.opening_left=opening_left
	result.first_gap=first_gap
	result.water_shots=water.total_shots
	result.water_hits=water.hits
	result.water_blocks=water.blocks
	result.watersteps=water.escapes
	result.overloads=water.overloads
	return result

func can_receive_hit() -> bool:
	return super.can_receive_hit() and state!="wash"

func hurt_rect() -> Rect2:
	var area: Rect2=super.hurt_rect()
	if water!=null and water.weak_window():
		# 黄色压囊在躯干后方，必须同时覆盖其可见位置，而非只让躯干吃刀。
		var center: Vector2=global_position+Vector2(-facing*40.0,-48.0)
		area=area.merge(Rect2(center-Vector2(15,19),Vector2(30,38)))
	return area

func start_waterstep() -> void:
	if not outcome.is_empty(): return
	pressure.cancel("close_waterstep")
	water.cancel()
	var axis: float=player.global_position.x-global_position.x
	if not is_zero_approx(axis): facing=signf(axis)
	move_key="warden_waterstep"
	spec=action_spec(move_key)
	control_left=0.0
	opening_left=0.0
	flinch_left=0.0
	velocity=Vector2.ZERO
	attack_serial+=1
	pressure.started(move_key)
	pulse=1
	water.begin()
	set_state("tell")
	changed.emit("近身受压 · 水遁换位")
