class_name EnemyLabSkills
extends TideCombatSkills
## 仅试验场的持续格挡样板，保留共用输入组合等待和攻击取消边界。
var guard_age: float=0.0
var guard_count: int=0
var perfect: bool=false
var counter_left: float=0.0
var counter_bonus: int=0
const GUARD_MAX: float=100.0
var guard_meter: float=GUARD_MAX
var guard_lock: float=0.0
var recovery_wait: float=0.0
var incoming_pressure: float=28.0
var incoming_unblockable: bool=false

func request(key: String) -> bool:
	if key=="parry" and (guard_lock>0.0 or guard_meter<25.0): return false
	if active and visual_key=="parry" and parried and DEFINITIONS.has(key):
		if not actor.controls_enabled or actor.health<=0 or actor.cooldowns.get(key,0.0)>0.0: return false
		cancel()
	var accepted: bool=super.request(key)
	if accepted and key=="parry":
		guard_age=0.0
		data.release=0.02
		data.parry_end=0.55
		duration=0.70
		data.duration=duration
		actor.state_duration=duration
		actor.cooldowns.parry=0.18
	return accepted

func tick() -> void:
	var dt: float=actor.get_physics_process_delta_time()
	if active and visual_key=="parry":
		guard_age+=dt
		# 时间轴停在持盾帧，迎击奖励仍用独立时钟，不能按住永久完美格挡。
		var held: bool=Input.is_action_pressed("tp_parry") and not Input.is_action_pressed("wb_lt") and not Input.is_action_pressed("wb_rt")
		if held and actor.state_time>=0.48: actor.state_time=0.48
		elif not held and guard_age>0.55: actor.state_time=maxf(actor.state_time,0.56)
	super.tick()

func guard_open() -> bool:
	return active and visual_key=="parry" and actor.state_time>=0.02 and actor.state_time<=0.55

func parry_damage(source: Vector2) -> bool:
	if not guard_open() or actor.health<=0: return false
	if source!=Vector2.ZERO and (source.x-actor.global_position.x)*locked_facing < -18.0: return false
	if incoming_unblockable: return false
	perfect=guard_age<=0.30
	if not perfect:
		guard_meter=maxf(0.0,guard_meter-incoming_pressure)
		recovery_wait=0.8
		if guard_meter<=0.0:
			break_guard()
			return false
	else:
		guard_meter=minf(GUARD_MAX,guard_meter+12.0)
	guard_count+=1
	parried=true
	counter_left=1.4
	counter_bonus=2 if perfect else 1
	actor.cooldowns.parry=0.0
	actor.soul=mini(actor.max_soul,actor.soul+(12 if perfect else 6))
	actor.stats_changed.emit(actor.health,actor.soul)
	actor.skill_effect.emit("parry","success",actor.global_position,locked_facing)
	(actor as EnemyLabPlayer).guard_success.emit(perfect)
	return true

func can_cancel(kind: String) -> bool:
	if active and visual_key=="parry" and parried: return true
	return super.can_cancel(kind)

func consume_counter() -> int:
	var bonus: int=counter_bonus if counter_left>0.0 else 0
	counter_bonus=0
	counter_left=0.0
	return bonus

func update_combo(dt: float) -> void:
	super.update_combo(dt)
	guard_lock=maxf(0.0,guard_lock-dt)
	recovery_wait=maxf(0.0,recovery_wait-dt)
	var defending: bool=active and visual_key=="parry"
	if defending and guard_age>0.30:
		guard_meter=maxf(0.0,guard_meter-18.0*dt)
		recovery_wait=0.8
		if guard_meter<=0.0: break_guard()
	elif not defending and not Input.is_action_pressed("tp_parry") and guard_lock<=0.0 and recovery_wait<=0.0:
		guard_meter=minf(GUARD_MAX,guard_meter+30.0*dt)
	# 反击奖励在待机时同样到期，不能依赖只在技能期间执行的tick。
	counter_left=maxf(0.0,counter_left-dt)
	if counter_left<=0.0: counter_bonus=0

func break_guard() -> void:
	guard_meter=0.0
	guard_lock=1.1
	recovery_wait=0.8
	counter_bonus=0
	counter_left=0.0
	cancel()
	actor.cooldowns.parry=guard_lock
	actor._enter("hit",0.65)
	(actor as EnemyLabPlayer).guard_broken.emit()
