class_name EnemyLabEel
extends EnemyLabEnemy
## 一条身体、一份生命与攻击实例；头尾位置由朝向派生，不交换身份。
var tail_dwell: float=0.0
var opening_left: float=0.0
var endpoint: String="head"
var nest: EnemyLabEelNestCycle
var center_hits: int=0
var center_repositions: int=0
const END_OFFSET: float=112.0

func _ready() -> void:
	super._ready()
	collision_mask=1
	nest=EnemyLabEelNestCycle.new()
	nest.enemy=self

func end_position(tail: bool=false) -> Vector2:
	return global_position+Vector2(facing*END_OFFSET*(-1.0 if tail else 1.0),-26.0)

func choose_move() -> String:
	if not forced_move.is_empty(): return forced_move
	if not pressure.queued.is_empty(): return pressure.queued
	if tail_dwell>=0.35 and attack_serial%3!=1: return "eel_tail"
	if attack_serial%3==0:
		return "eel_burrow" if (player.global_position.x-end_position().x)*facing<0.0 else "eel_brood"
	if attack_serial%3==1: return "eel_burrow"
	return "eel_bite"

func begin_attack(key: String="") -> bool:
	if not can_begin_attack(): return false
	var direction: float=facing
	var started: bool=super.begin_attack(key)
	# 通用入口面向玩家；长体不能因此把头尾瞬间对调。
	facing=direction
	if started:
		endpoint="tail" if move_key=="eel_tail" else "head"
		if nest.handles(): nest.begin()
		visual.present(self)
	return started

func set_state(next: String) -> void:
	var previous: String=state
	super.set_state(next)
	if next=="recover" and previous!="hurt": opening_left=float(spec.recover)
	if next=="idle":
		opening_left=0.0
		tail_dwell=0.0
		center_hits=0
	if is_instance_valid(visual): visual.present(self)

func control_window_open() -> bool:
	return outcome.is_empty() and opening_left>0.0 and state in ["recover","hurt"]

func phase_duration() -> float:
	if nest!=null and nest.handles(): return nest.duration()
	return super.phase_duration()

func can_receive_hit() -> bool:
	return super.can_receive_hit() and (nest==null or not nest.hidden())

func finish() -> void:
	super.finish()
	if nest!=null: nest.clear_eggs()

func take_hit(amount: int) -> void:
	var before: int=reactions.received
	super.take_hit(amount)
	if not auto_attack or not outcome.is_empty() or reactions.received==before: return
	if move_key=="eel_burrow" and state not in ["recover","hurt","idle"]: return
	var central: bool=absf(player.global_position.x-global_position.x)<80.0 and absf(player.global_position.y-global_position.y)<95.0
	center_hits=center_hits+1 if central else 0
	if center_hits<2: return
	# 中段不是永久安全区：保留两刀收益，然后以可读潜地换侧重新建立威胁。
	center_repositions+=1
	center_hits=0
	opening_left=0.0
	control_left=0.0
	velocity=Vector2.ZERO
	move_key="eel_burrow"
	pressure.cancel("center_reposition")
	spec=action_spec(move_key)
	endpoint="head"
	attack_serial+=1
	pressure.started(move_key)
	pulse=1
	followup_cancelled=true
	nest.begin()
	set_state("tell")
	changed.emit("中段受压 · 钻地换侧")

func _physics_process(dt: float) -> void:
	if feedback.frozen(dt): return
	pressure.tick(dt)
	velocity.y=minf(velocity.y+1750.0*dt,800.0)
	velocity.x=move_toward(velocity.x,0.0,1800.0*dt)
	if not outcome.is_empty(): timer+=dt
	elif state in ["hurt","recover"]:
		# 反击预算跨受击持续消耗；连打不重开整个收招，也不靠无敌脱身。
		opening_left=maxf(0.0,opening_left-dt)
		control_left=maxf(0.0,control_left-dt)
		timer+=dt
		if opening_left<=0.0: set_state("idle")
		elif state=="hurt" and control_left<=0.0: set_state("recover")
	elif player.health>0:
		if state=="idle": _idle_tick(dt)
		elif nest.handles():
			nest.tick(dt)
			if state=="active" and (move_key=="eel_burrow" or nest.stage=="bites"):
				velocity.x=facing*float(spec.get("speed",0.0))
		else:
			advance_action(dt)
			if state=="active" and move_key=="eel_bite": velocity.x=facing*float(spec.speed)
	# 两端都留在场内；只限制物理移动，不在换招时翻转整条身体。
	if position.x<155.0 and velocity.x<0.0: velocity.x=0.0
	if position.x>1125.0 and velocity.x>0.0: velocity.x=0.0
	move_and_slide()
	# 出土与玩家重叠时先保持可穿行，分离后再恢复身体阻挡，避免挤墙。
	if collision_layer==0 and outcome.is_empty() and not nest.hidden() and state!="emerge":
		var body := Rect2(player.global_position-Vector2(14,65),Vector2(28,65))
		if not hurt_rect().intersects(body): collision_layer=4
	visual.present(self)
	queue_redraw()

func _idle_tick(dt: float) -> void:
	timer+=dt
	var tail_near: bool=player.global_position.distance_to(end_position(true))<190.0
	tail_dwell=tail_dwell+dt if tail_near else 0.0
	if not auto_attack: return
	var tail: bool=tail_dwell>=0.35
	var goal: Vector2=end_position(tail)
	var distance: float=absf(player.global_position.x-goal.x)
	var reach: float=620.0 if choose_move() in ["eel_brood","eel_burrow"] else 170.0
	if timer>pressure.idle(0.60) and distance<reach and absf(player.position.y-position.y)<95.0:
		begin_attack()
	elif distance>135.0:
		velocity.x=signf(player.global_position.x-goal.x)*float(profile.speed)

func attack_rect() -> Rect2:
	if move_key=="eel_brood" and nest.stage=="spit": return Rect2(global_position,Vector2.ZERO)
	var side: float=-facing if move_key=="eel_tail" else facing
	var width: float=float(spec.get("width",110.0))
	var height: float=float(spec.get("height",65.0))
	return Rect2(global_position+Vector2(92.0 if side>0 else -92.0-width,-height),Vector2(width,height))

func hurt_rect() -> Rect2:
	var area: Rect2=super.hurt_rect()
	# 张颚蓄势时头部抬高，不能让看得见的颚部超出可打区域。
	if move_key=="eel_bite" and state=="tell":
		area.position.y=global_position.y-125.0
		area.size.y=125.0
	return area

func strike() -> void:
	if move_key=="eel_brood" and nest.stage=="spit": return
	var previous: int=parry_count
	super.strike()
	if parry_count>previous:
		if move_key=="eel_brood": followup_cancelled=true
		# 尾端格挡只打退尾端，不把另一侧的头部拖向玩家。
		velocity.x=0.0

func snapshot() -> Dictionary:
	var result: Dictionary=super.snapshot()
	result.endpoint=endpoint
	result.opening_left=opening_left
	result.nest_stage=nest.stage
	result.eggs=nest.live_eggs
	result.eggs_spawned=nest.eggs_spawned
	result.eggs_broken=nest.eggs_broken
	result.eggs_burst=nest.eggs_burst
	result.egg_hits=nest.egg_hits
	result.egg_blocks=nest.egg_blocks
	result.center_repositions=center_repositions
	if nest.handles(): result.locked=state not in ["idle","hurt","ended"] and (move_key=="eel_brood" or state!="tell")
	return result
