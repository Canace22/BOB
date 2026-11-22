class_name EnemyLabWardenWater
extends RefCounted
## 招式归执卫自身：压囊蓄水、射弹/聚涡、水遁换位，不请求场景设施。
const KEYS: Array[String]=["warden_barrage","warden_vortex","warden_waterstep"]
var enemy: EnemyLabWarden
var shots: Array[WeakRef]=[]
var aim: Vector2
var emitted: int=0
var total_shots: int=0
var hits: int=0
var blocks: int=0
var escapes: int=0
var overloads: int=0
var pressure_hits: int=0
var rear_hits: int=0
var wash_start: Vector2
var wash_goal: Vector2

func handles() -> bool: return enemy.move_key in KEYS

func weak_window() -> bool:
	return handles() and enemy.outcome.is_empty() and enemy.state=="tell" and enemy.timer>float(enemy.spec.tell)*0.45

func begin() -> void:
	emitted=0
	rear_hits=0
	aim=enemy.player.global_position-Vector2(0,40)
	if enemy.move_key=="warden_waterstep":
		escapes+=1
		wash_start=enemy.position
		var direction: float=signf(enemy.position.x-enemy.player.position.x)
		if is_zero_approx(direction): direction=-enemy.facing
		var target: float=enemy.player.position.x+direction*180.0
		if target<enemy.combat_space.x(350.0) or target>enemy.combat_space.x(1030.0): target=enemy.player.position.x-direction*180.0
		var landing_x: float=enemy.combat_space.clamp_x(target,350,1030)
		wash_goal=Vector2(landing_x,enemy.combat_space.ground_at(enemy,landing_x))

func duration() -> float:
	if enemy.state=="wash": return 0.40
	if enemy.state=="reform": return 0.55
	return float(enemy.spec.get(enemy.state,0.0))

func tick(dt: float) -> void:
	enemy.timer+=dt
	if enemy.state=="wash":
		enemy.position=wash_start.lerp(wash_goal,clampf(enemy.timer/0.40,0.0,1.0))
	if enemy.state=="active":
		if enemy.move_key=="warden_barrage":
			for index: int in 3:
				if emitted==index and enemy.timer>=0.04+float(index)*0.22:
					_spawn("bullet",float(1-index)*0.14)
					emitted+=1
		elif enemy.move_key=="warden_vortex" and emitted==0:
			_spawn("vortex",0.0)
			emitted=1
		elif enemy.move_key=="warden_waterstep" and enemy.timer>=0.06: enemy.strike()
	if enemy.state=="recover" or enemy.timer<duration(): return
	match enemy.state:
		"tell":
			if enemy.move_key=="warden_waterstep":
				wash_start=enemy.position
				enemy.collision_layer=0
				enemy.set_state("wash")
			else: enemy.set_state("active")
		"wash":
			enemy.facing=signf(aim.x-enemy.global_position.x)
			if is_zero_approx(enemy.facing): enemy.facing=1.0
			enemy.set_state("reform")
		"reform": enemy.set_state("active")
		"active": enemy.set_state("recover")

func _spawn(kind: String, angle: float) -> void:
	for index: int in range(shots.size()-1,-1,-1):
		if not is_instance_valid(shots[index].get_ref()): shots.remove_at(index)
	var shot := EnemyLabWardenShot.new()
	shot.source=weakref(enemy)
	shot.player=enemy.player
	shot.kind=kind
	var origin: Vector2=enemy.global_position+Vector2(enemy.facing*100.0,-55.0)
	shot.velocity=(aim-origin).normalized().rotated(angle)*330.0
	if kind=="vortex":
		origin=enemy.global_position+Vector2(enemy.facing*75.0,-65.0)
		shot.velocity=Vector2(enemy.facing*180.0,0)
	enemy.get_parent().add_child(shot)
	shot.global_position=origin
	shots.append(weakref(shot))
	total_shots+=1

func take_hit(amount: int=1) -> void:
	if not enemy.outcome.is_empty(): return
	var delta: float=enemy.player.position.x-enemy.position.x
	if weak_window():
		if delta*enemy.facing< -25.0:
			rear_hits+=2 if amount>=3 else 1
			if rear_hits>=2:
				overload()
				return
	if not enemy.auto_attack: return
	if enemy.move_key=="warden_waterstep" and enemy.state not in ["recover","hurt","idle"]: return
	pressure_hits=pressure_hits+1 if absf(delta)<80.0 else 0
	if pressure_hits>=2:
		pressure_hits=0
		enemy.start_waterstep()

func overload() -> void:
	if not enemy.outcome.is_empty(): return
	enemy.pressure.cancel("yellow_weakpoint")
	overloads+=1
	cancel()
	enemy.control_left=0.0
	enemy.spec=enemy.spec.duplicate(true)
	enemy.spec.recover=1.45
	enemy.set_state("recover")
	enemy.changed.emit("压囊失压 · 可反击")

func cancel() -> void:
	for ref: WeakRef in shots:
		var shot: EnemyLabWardenShot=ref.get_ref() as EnemyLabWardenShot
		if is_instance_valid(shot): shot.consume()
	shots.clear()
	emitted=3

func pose() -> int:
	if not handles() or enemy.state in ["idle","hurt","ended"]: return -1
	if enemy.move_key=="warden_waterstep":
		return {"tell":8,"wash":9,"reform":10,"active":22,"recover":11}.get(enemy.state,11)
	var row: int=0 if enemy.move_key=="warden_barrage" else 1
	var phase: int=0 if enemy.state=="tell" and enemy.timer<duration()*0.55 else (1 if enemy.state=="tell" else (2 if enemy.state=="active" else 3))
	return row*4+phase

func segments() -> Array[Dictionary]:
	var plan: Array[Array]=[["tell",float(enemy.spec.tell)]]
	if enemy.move_key=="warden_waterstep": plan.append_array([["wash",0.4],["reform",0.55]])
	plan.append_array([["active",float(enemy.spec.active)],["recover",float(enemy.spec.recover)]])
	var result: Array[Dictionary]=[]
	var cursor: float=0.0
	for part: Array in plan:
		result.append({"phase":part[0],"pulse":1,"start":cursor,"end":cursor+float(part[1])})
		cursor+=float(part[1])
	return result
