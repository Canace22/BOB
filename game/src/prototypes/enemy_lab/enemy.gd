class_name EnemyLabEnemy
extends CharacterBody2D
## 白盒敌人适配器：复用玩家命中协议与反馈，不接主线宿主或进度。
signal changed(message: String)
signal phase_started(phase: String)
var player: EnemyLabPlayer
var profile: Dictionary
var data: Dictionary = {"alive":true}
var spec: Dictionary = {}
var move_key: String = ""
var state: String = "idle"
var timer: float = 0.0
var facing: float = -1.0
var health: int = 0
var maximum: int = 0
var attack_serial: int = 0
var pulse: int = 1
var hit_sent: bool = false
var followup_cancelled: bool = false
var hit_count: int = 0
var parry_count: int = 0
var auto_attack: bool = true
var forced_move: String = ""
var outcome: String = ""
var retreat_goal: float = 0.0
var kill_comparison: bool = false
var show_ranges: bool = true
var show_art: bool = true
var control_left: float = 0.0
var air_lifts: int = 0
var home: Vector2
var last_result: String = "等待交战"
var visual: EnemyLabVisual
var feedback: TideEnemyFeedback
var reactions: EnemyLabReactions
var effects: EnemyLabAttackEffects

func _ready() -> void:
	maximum=int(profile.hp)
	health=maximum
	home=position
	collision_layer=4
	collision_mask=3
	z_index=3
	var body := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size=Vector2(float(profile.radius)*2.0,float(profile.height))
	body.shape=shape
	body.position.y=-float(profile.height)*0.5
	add_child(body)
	visual=EnemyLabVisual.new()
	visual.z_index=-1
	add_child(visual)
	feedback=TideEnemyFeedback.new()
	add_child(feedback)
	feedback.setup(visual)
	(visual.material as ShaderMaterial).shader=preload("res://src/prototypes/enemy_lab/enemy_warning.gdshader")
	reactions=EnemyLabReactions.new()
	reactions.enemy=self
	effects=EnemyLabAttackEffects.new()
	effects.enemy=self
	add_child(effects)
	add_to_group("tide_targets")

func set_state(next: String) -> void:
	state=next
	timer=0.0
	if next=="active": hit_sent=false
	if next in ["recover","hurt","ended"]: velocity.x=0.0
	if is_instance_valid(visual): visual.update_warning(self)
	phase_started.emit(next)

func begin_attack(key: String="") -> bool:
	if not can_begin_attack(): return false
	move_key=key if not key.is_empty() else choose_move()
	if not profile.moves.has(move_key): return false
	spec=EnemyLabCatalog.action(move_key)
	facing=signf(player.global_position.x-global_position.x) if not is_zero_approx(player.global_position.x-global_position.x) else facing
	attack_serial+=1
	pulse=1
	followup_cancelled=false
	set_state("tell")
	changed.emit(str(spec.title)+" 起手")
	return true

func can_begin_attack() -> bool:
	return state=="idle" and outcome.is_empty() and is_on_floor()

func choose_move() -> String:
	if not forced_move.is_empty(): return forced_move
	var gap: float=absf(player.global_position.x-global_position.x)
	match str(profile.id):
		"forager": return "rush" if gap>175.0 else ("double" if attack_serial%2==1 else "sweep")
		"mudback": return "ambush" if gap>200.0 else ("flip" if attack_serial%2==1 else "press")
		_: return "shell_push" if gap>160.0 else ("realign" if attack_serial%2==1 else "poke")

func phase_duration() -> float:
	if state=="tell" and pulse==2: return float(spec.get("second",0.30))
	return float(spec.get(state,0.0))

func advance_action(dt: float) -> void:
	var remaining: float=dt
	# 消费跨过的阶段和释放点；一帧跨完整攻击也不能漏判或重复命中。
	for limit: int in 12:
		if state not in ["tell","active","recover"] or remaining<=0.0: break
		var duration: float=phase_duration()
		var step: float=minf(remaining,maxf(0.0,duration-timer))
		timer+=step
		remaining-=step
		if state=="active" and timer>=minf(0.06,duration): strike()
		if timer+0.000001<duration: break
		match state:
			"tell": set_state("active")
			"active":
				if move_key=="double" and pulse==1:
					pulse=2
					set_state("tell")
				else: set_state("recover")
			"recover": set_state("idle")

func _physics_process(dt: float) -> void:
	if feedback.frozen(dt): return
	velocity.y=minf(velocity.y+1750.0*dt,800.0)
	velocity.x=move_toward(velocity.x,0.0,2000.0*dt)
	if not outcome.is_empty():
		timer+=dt
		if outcome=="retreat" and absf(position.x-retreat_goal)>4.0:
			velocity.x=signf(retreat_goal-position.x)*90.0
		move_and_slide()
		visual.present(self)
		queue_redraw()
		return
	if control_left>0.0 or state=="hurt":
		control_left=maxf(0.0,control_left-dt)
		if control_left<=0.0 and is_on_floor():
			air_lifts=0
			set_state("idle")
	elif player.health>0:
		if state=="idle":
			timer+=dt
			var gap: Vector2=player.global_position-global_position
			if absf(gap.x)>900.0:
				last_result="脱战返回"
				velocity.x=signf(home.x-position.x)*float(profile.speed)
			elif auto_attack and absf(gap.y)<110.0:
				var candidate: Dictionary=EnemyLabCatalog.action(choose_move())
				var reach: float=float(candidate.width)+float(profile.radius)*0.5+maxf(0.0,float(candidate.speed))*float(candidate.active)-10.0
				if timer>0.55 and absf(gap.x)<minf(330.0,reach): begin_attack()
				elif absf(gap.x)>float(profile.radius)+30.0:
					facing=signf(gap.x)
					velocity.x=facing*float(profile.speed)
		else:
			if state=="tell" and pulse==1 and timer<float(spec.get("lock",0.0)):
				var axis: float=player.global_position.x-global_position.x
				if not is_zero_approx(axis): facing=signf(axis)
			advance_action(dt)
			if state=="active": velocity.x=facing*float(spec.get("speed",0.0))
	move_and_slide()
	visual.present(self)
	queue_redraw()

func strike() -> void:
	if hit_sent or not outcome.is_empty(): return
	var player_rect := Rect2(player.global_position-Vector2(14,65),Vector2(28,65))
	if not attack_rect().intersects(player_rect): return
	var ray := PhysicsRayQueryParameters2D.create(global_position+Vector2(0,-30),player.global_position+Vector2(0,-30),1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): return
	hit_sent=true
	var guard: EnemyLabSkills=player.skill_controller as EnemyLabSkills
	var before: int=guard.guard_count
	# 本次攻击的防御属性只在伤害调用期间生效，不能污染后续伤害来源。
	guard.incoming_pressure=float(spec.get("guard_pressure",28.0))
	guard.incoming_unblockable=bool(spec.get("unblockable",false))
	var damaged: bool=player.take_damage(1,global_position)
	guard.incoming_pressure=28.0
	guard.incoming_unblockable=false
	if damaged:
		hit_count+=1
		last_result="命中玩家"
	elif guard.guard_count>before:
		parry_count+=1
		last_result="完美格挡 · 破绽反击" if guard.perfect else "格挡成功 · 可反击"
		guard_reaction(guard.perfect)
	else: last_result="无敌避开"
	changed.emit(last_result)

func guard_reaction(perfect: bool) -> void:
	followup_cancelled=move_key=="double" and pulse==1
	spec=spec.duplicate(true)
	spec.recover=maxf(float(spec.recover),1.1 if perfect else 0.65)
	set_state("recover")
	velocity.x=-facing*(180.0 if perfect else 80.0)
	feedback.receive(0.10 if perfect else 0.06,-facing,15.0 if perfect else 8.0)

func attack_rect() -> Rect2:
	var width: float=float(spec.get("width",100.0))
	var height: float=float(spec.get("height",70.0))
	var radius: float=float(profile.radius)*0.5
	return Rect2(global_position+Vector2(radius if facing>0 else -radius-width,-height),Vector2(width,height))
func hurt_rect() -> Rect2:
	return Rect2(global_position-Vector2(float(profile.radius),float(profile.height)),Vector2(float(profile.radius)*2.0,float(profile.height)))
func can_receive_hit() -> bool: return outcome.is_empty()
func armor_active() -> bool:
	return str(profile.id) in ["mudback","shell_guard"] and state in ["idle","tell","active"]
func control_window_open() -> bool: return outcome.is_empty() and not reactions.sheltered()
func take_hit(amount: int) -> void: reactions.take_hit(amount)
func launch(speed: float) -> void: reactions.launch(speed)
func knock_down(_strength: float=0.0) -> void: reactions.control(0.50)
func pin(seconds: float) -> void: reactions.control(minf(seconds,0.40))
func apply_knockback(force: float) -> void:
	if reactions.controllable(): velocity.x=clampf(force,-180.0,180.0)
func push_away(source_x: float) -> void:
	apply_knockback(180.0*signf(global_position.x-source_x))
func receive_feedback(seconds: float, direction: float, power: float) -> void:
	feedback.receive(seconds,direction,power)
func clear_feedback() -> void: feedback.clear()

func finish() -> void:
	outcome="kill" if kill_comparison else str(profile.ending)
	retreat_goal=clampf(position.x+150.0*signf(position.x-player.position.x),70.0,1210.0)
	data.alive=outcome!="kill"
	set_state("ended")
	velocity=Vector2.ZERO
	control_left=0.0
	hit_sent=true
	collision_layer=0
	collision_mask=1
	remove_from_group("tide_targets")
	changed.emit("结束："+outcome)

func snapshot() -> Dictionary:
	return {"enemy":profile.title,"move":spec.get("title","待机"),"key":move_key,"phase":state,"time":timer,"duration":phase_duration(),"serial":attack_serial,"pulse":pulse,"locked":state=="active" or (state=="tell" and timer>=float(spec.get("lock",0.0))),"controllable":reactions.controllable(),"heavy_window":reactions.heavy_window(),"health":health,"maximum":maximum,"shell":reactions.sheltered(),"side":"正面" if (player.global_position.x-global_position.x)*facing>=0.0 else "侧后","fraction":reactions.damage_remainder,"result":last_result,"ending":outcome,"hit":hit_sent,"received":reactions.received}

func _draw() -> void:
	if not show_ranges: return
	var body_rect: Rect2=hurt_rect()
	body_rect.position-=global_position
	draw_rect(body_rect,Color(0.3,0.9,1.0,0.10))
	draw_rect(body_rect,Color("75dce3"),false,1.0)
	if state in ["tell","active"]:
		var area: Rect2=attack_rect()
		area.position-=global_position
		draw_rect(area,Color(1.0,0.25,0.25,0.30 if state=="active" else 0.08))
		draw_rect(area,Color("ff886c"),false,1.0)
