class_name EnemyLabPredator
extends EnemyLabEnemy
## 捕食者拥有飞行路线；伤害、格挡、受控和结束继续走试验场共用协议。
const PERCHES: Array[Vector2]=[Vector2(760,260),Vector2(1060,260)]
const PRESSURE_HITS: int=3
const PRESSURE_TIME: float=1.4
const ESCAPE_TELL: float=0.38
const EVADE_TIME: float=0.36
var water_shots: int=0
var water_hits: int=0
var water_blocks: int=0
var escape_aim: Vector2
var pressure_hits: int=0
var pressure_time: float=0.0
var escape_return: bool=false
var evade_direction: float=1.0
var shelter_enabled: bool=false
var target_point: Vector2
var flight_velocity: Vector2=Vector2.ZERO
var landing_pending: bool=false
var return_duration: float=1.5
var return_goal: Vector2

func _ready() -> void:
	super._ready()
	position=combat_space.perch(0 if position.x<combat_space.x(910) else 1)
	home=position
	collision_mask=1

func can_begin_attack() -> bool:
	return state=="idle" and outcome.is_empty() and not sheltered_player()

func choose_move() -> String:
	if not forced_move.is_empty(): return forced_move
	var gap: float=absf(player.global_position.x-global_position.x)
	if attack_serial%3==2 and gap<130.0: return "hunter_drop"
	return "hunter_glide" if attack_serial%3==1 else "hunter_pounce"

func begin_attack(key: String="") -> bool:
	if not super.begin_attack(key): return false
	_update_target()
	return true

func _update_target() -> void:
	if move_key=="hunter_glide":
		target_point=combat_space.perch(1 if position.x<combat_space.x(910) else 0)
	elif move_key=="hunter_drop": target_point=Vector2(position.x,combat_space.ground_at(self,position.x))
	else: target_point=Vector2(combat_space.clamp_x(player.position.x,340,1170),combat_space.ground_at(self,combat_space.clamp_x(player.position.x,340,1170)))
	if not is_zero_approx(target_point.x-position.x): facing=signf(target_point.x-position.x)

func set_state(next: String) -> void:
	super.set_state(next)
	if next in ["hurt","ended","escape_tell"]: landing_pending=false
	if next=="idle":
		pressure_hits=0
		pressure_time=0.0
		air_lifts=0
		escape_return=false
	elif next=="evade":
		velocity=Vector2(evade_direction*380.0,-420.0)
		_fire_water()
	if next=="active":
		flight_velocity=(target_point-position)/float(spec.active)
		landing_pending=move_key=="hunter_drop"
	elif next=="return":
		return_goal=combat_space.perch(0 if position.distance_to(combat_space.perch(0))<position.distance_to(combat_space.perch(1)) else 1)
		return_duration=position.distance_to(return_goal)/300.0
		if position.x<combat_space.x(300) and position.y>combat_space.floor_y-160:
			var outside := Vector2(combat_space.x(340),position.y)
			return_duration=(position.distance_to(outside)+outside.distance_to(return_goal))/300.0

	if is_instance_valid(visual): visual.present(self)

func phase_duration() -> float:
	if state=="escape_tell": return ESCAPE_TELL
	if state=="evade": return EVADE_TIME
	if state=="return": return maxf(0.01,return_duration)
	return super.phase_duration()

func sheltered_player() -> bool:
	return shelter_enabled and combat_space.shelter.has_point(player.position)

func _physics_process(dt: float) -> void:
	if feedback.frozen(dt): return
	pressure.tick(dt)
	# 受压时钟跨受击/浮空/回挂持续，命中不能把反击窗口无限重开。
	if pressure_hits>0 and not escape_return and outcome.is_empty() and state in ["hurt","recover","return"]:
		pressure_time+=dt
		if pressure_time>=PRESSURE_TIME and state in ["hurt","recover"]: _prepare_escape()
	if not outcome.is_empty():
		_fall(dt)
		timer+=dt
	elif state=="hurt" or control_left>0.0:
		control_left=maxf(0.0,control_left-dt)
		_fall(dt)
		if control_left<=0.0 and is_on_floor():
			air_lifts=0
			set_state("recover")
	elif state=="idle":
		velocity=Vector2.ZERO
		timer+=dt
		if auto_attack and player.health>0 and timer>pressure.idle(0.85) and not sheltered_player(): begin_attack()
	elif state=="tell":
		if timer<float(spec.lock):
			if sheltered_player(): set_state("return")
			else: _update_target()
		if state=="tell": advance_action(dt)
	elif state=="active":
		velocity=flight_velocity
		move_and_slide()
		advance_action(dt)
		if state=="active" and is_on_floor() and flight_velocity.y>0.0: set_state("recover")
	elif state=="recover":
		_fall(dt)
		# 暴露窗口从真实落地开始，不能在空中掉落时提前耗光。
		if is_on_floor():
			if landing_pending:
				landing_pending=false
				effects.ground_impact(global_position,float(spec.width))
			timer+=dt
			if timer>=float(spec.get("recover",0.95)): set_state("return")
	elif state=="escape_tell":
		_fall(dt)
		timer+=dt
		if timer>=ESCAPE_TELL: set_state("evade")
	elif state=="evade":
		timer+=dt
		velocity.y+=950.0*dt
		move_and_slide()
		if timer>=EVADE_TIME: set_state("return")
	elif state=="return": _return_tick(dt)
	visual.present(self)
	queue_redraw()

func _fall(dt: float) -> void:
	velocity.y=minf(800.0,velocity.y+1750.0*dt)
	velocity.x=move_toward(velocity.x,0.0,1000.0*dt)
	move_and_slide()

func _return_tick(dt: float) -> void:
	timer+=dt
	# 被打到遮蔽下方时先沿地面出去，不穿过顶盖回挂。
	var goal: Vector2=Vector2(combat_space.x(340),position.y) if position.x<combat_space.x(300) and position.y>combat_space.floor_y-160 else return_goal
	var delta: Vector2=goal-position
	if delta.length()<6.0 and goal==return_goal:
		position=return_goal
		velocity=Vector2.ZERO
		set_state("idle")
		return
	velocity=delta.normalized()*minf(300.0,delta.length()/dt)
	move_and_slide()

func attack_rect() -> Rect2:
	var width: float=float(spec.get("width",100.0))
	var height: float=float(spec.get("height",70.0))
	return Rect2(global_position-Vector2(width*0.5,height),Vector2(width,height))

func control_window_open() -> bool:
	return outcome.is_empty() and not escape_return and (state in ["recover","hurt"] or (state=="return" and timer<0.45))

func take_hit(amount: int) -> void:
	var before: int=reactions.received
	var vulnerable: bool=control_window_open()
	super.take_hit(amount)
	if not outcome.is_empty() or escape_return or reactions.received==before: return
	if vulnerable and state in ["recover","hurt","return"]:
		pressure_hits+=1
		if pressure_hits>=PRESSURE_HITS: _prepare_escape()

func _prepare_escape() -> void:
	if escape_return or not outcome.is_empty(): return
	escape_return=true
	control_left=0.0
	velocity=Vector2.ZERO
	evade_direction=signf(position.x-player.position.x)
	if is_zero_approx(evade_direction): evade_direction=-facing
	if position.x>combat_space.x(1130): evade_direction=-1.0
	elif position.x<combat_space.x(340): evade_direction=1.0
	facing=-evade_direction
	escape_aim=player.global_position-Vector2(0,35)
	set_state("escape_tell")
	changed.emit("收伞蓄势 · 喷水脱身")

func _fire_water() -> void:
	if not outcome.is_empty(): return
	var orb := EnemyLabWaterOrb.new()
	orb.source=weakref(self)
	orb.player=player
	var mouth: Vector2=global_position+Vector2(facing*28.0,-45.0)
	var direction: Vector2=(escape_aim-mouth).normalized()
	orb.velocity=direction*300.0 if not direction.is_zero_approx() else Vector2(-evade_direction*300.0,0)
	get_parent().add_child(orb)
	orb.global_position=mouth
	water_shots+=1

func snapshot() -> Dictionary:
	var result: Dictionary=super.snapshot()
	result.pressure_hits=pressure_hits
	result.pressure_time=pressure_time
	result.water_shots=water_shots
	result.water_hits=water_hits
	result.water_blocks=water_blocks
	return result
