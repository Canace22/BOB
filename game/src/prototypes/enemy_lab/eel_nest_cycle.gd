class_name EnemyLabEelNestCycle
extends RefCounted
## 鳗专属的潜地路线与布卵连段；生命/伤害/格挡仍由敌人共用入口负责。
var enemy: EnemyLabEel
var stage: String=""
var bites: int=0
var emitted: int=0
var live_eggs: int=0
var eggs_spawned: int=0
var eggs_broken: int=0
var eggs_burst: int=0
var egg_hits: int=0
var egg_blocks: int=0
var locked_x: float=0.0
var tunnel_duration: float=0.5
var tunnel_start: float=0.0
var target_root: float=0.0
var exit_facing: float=1.0
var eggs: Array[WeakRef]=[]

func handles() -> bool:
	return enemy.move_key in ["eel_burrow","eel_brood"]

func begin() -> void:
	stage="burrow" if enemy.move_key=="eel_burrow" else "spit"
	bites=0
	emitted=0
	locked_x=enemy.player.global_position.x

func duration() -> float:
	match enemy.state:
		"dive": return 0.32
		"tunnel": return tunnel_duration
		"emerge": return 0.65
		"link": return 0.55
		"coil": return 0.50 if bites==0 else 0.42
		"active": return 0.24 if stage=="bites" else float(enemy.spec.active)
	return float(enemy.spec.get(enemy.state,0.0))

func hidden() -> bool:
	return enemy.move_key=="eel_burrow" and enemy.state in ["dive","tunnel"]

func tick(dt: float) -> void:
	enemy.timer+=dt
	if enemy.state in ["link","coil"]:
		var root: float=clampf(locked_x-enemy.facing*180.0,155.0,1125.0)
		enemy.velocity.x=clampf((root-enemy.position.x)/dt,-200.0,200.0)
	if enemy.state=="tunnel":
		var fraction: float=clampf(enemy.timer/tunnel_duration,0.0,1.0)
		enemy.position.x=lerpf(tunnel_start,target_root,fraction)
	if enemy.move_key=="eel_brood" and enemy.state=="active" and stage=="spit":
		for shot: int in 3:
			if emitted==shot and enemy.timer>=0.04+float(shot)*0.22:
				_spit(shot)
				emitted+=1
	elif enemy.state=="active" and enemy.timer>=0.06:
		enemy.strike()
	# 格挡可能已从有效段转入收招，不能继续执行旧连段分支。
	if enemy.state=="recover" or enemy.timer<duration(): return
	if enemy.move_key=="eel_burrow": _advance_burrow()
	else: _advance_brood()

func _advance_burrow() -> void:
	match enemy.state:
		"tell":
			# 入地时锁定，后续不读取玩家坐标；可骗落点而非地下追踪。
			locked_x=enemy.player.global_position.x
			exit_facing=1.0 if enemy.position.x>locked_x else -1.0
			target_root=locked_x-exit_facing*180.0
			if target_root<155.0 or target_root>1125.0:
				exit_facing=-exit_facing
				target_root=locked_x-exit_facing*180.0
			target_root=clampf(target_root,155.0,1125.0)
			tunnel_start=enemy.position.x
			tunnel_duration=maxf(0.45,absf(target_root-tunnel_start)/720.0)
			enemy.collision_layer=0
			enemy.set_state("dive")
		"dive": enemy.set_state("tunnel")
		"tunnel":
			# 只有完全入地后调整朝向，露头时再给完整准备动作。
			enemy.facing=exit_facing
			enemy.set_state("emerge")
		"emerge": enemy.set_state("active")
		"active": enemy.set_state("recover")

func _advance_brood() -> void:
	match enemy.state:
		"tell": enemy.set_state("active")
		"active":
			if stage=="spit": enemy.set_state("link")
			elif bites==0:
				bites=1
				enemy.pulse=3
				enemy.set_state("coil")
			else: enemy.set_state("recover")
		"link":
			stage="bites"
			enemy.pulse=2
			enemy.set_state("coil")
		"coil": enemy.set_state("active")

func _spit(index: int) -> void:
	if live_eggs>=3: return
	for slot: int in range(eggs.size()-1,-1,-1):
		if not is_instance_valid(eggs[slot].get_ref()): eggs.remove_at(slot)
	var egg := EnemyLabNestEgg.new()
	egg.source=weakref(enemy)
	egg.player=enemy.player
	var mouth: Vector2=enemy.end_position()+Vector2(enemy.facing*12.0,-30.0)
	var destination := Vector2(clampf(locked_x+float(index-1)*85.0,50.0,1230.0),506.0)
	var flight: float=clampf(absf(destination.x-mouth.x)/340.0,0.50,0.85)
	egg.velocity=Vector2((destination.x-mouth.x)/flight,(destination.y-mouth.y-425.0*flight*flight)/flight)
	enemy.get_parent().add_child(egg)
	egg.global_position=mouth
	eggs.append(weakref(egg))
	live_eggs+=1
	eggs_spawned+=1

func clear_eggs() -> void:
	for ref: WeakRef in eggs:
		var egg: EnemyLabNestEgg=ref.get_ref() as EnemyLabNestEgg
		if is_instance_valid(egg): egg.consume()
	eggs.clear()
	live_eggs=0

func segments() -> Array[Dictionary]:
	var plan: Array[Array]=[]
	if enemy.move_key=="eel_burrow":
		plan=[["tell",0.75,1],["dive",0.32,1],["tunnel",tunnel_duration,1],["emerge",0.65,1],["active",0.28,1]]
	else:
		plan=[["tell",0.90,1],["active",0.65,1],["link",0.55,1],["coil",0.50,2],["active",0.24,2]]
		if not enemy.followup_cancelled or bites>0: plan.append_array([["coil",0.42,3],["active",0.24,3]])
	plan.append(["recover",float(enemy.spec.recover),enemy.pulse])
	var result: Array[Dictionary]=[]
	var cursor: float=0.0
	for part: Array in plan:
		result.append({"phase":part[0],"start":cursor,"end":cursor+float(part[1]),"pulse":part[2]})
		cursor+=float(part[1])
	return result

func pose() -> int:
	if not handles() or enemy.state in ["idle","hurt","ended"]: return -1
	if enemy.move_key=="eel_burrow":
		match enemy.state:
			"tell": return 0
			"dive": return 1 if enemy.timer<0.16 else 2
			"tunnel": return 3
			"emerge": return 4 if enemy.timer<0.32 else 5
			"active": return 6
			"recover": return 7
	else:
		match enemy.state:
			"tell": return 8 if enemy.timer<float(enemy.spec.tell)*0.55 else 9
			"link": return 11
			"coil": return 20 if enemy.timer<duration()*0.55 else 21
			"active": return 10 if stage=="spit" else 22
			"recover": return 23
	return -1
