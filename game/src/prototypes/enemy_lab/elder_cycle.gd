class_name EnemyLabElderCycle
extends RefCounted
## 自身长柄撑跃与回稳路线，不依赖场景机关，也不承担伤害结算。
var enemy: EnemyLabElder
var flight_speed: float=0.0
var vaults: int=0
var replant_interrupts: int=0

func launch() -> void:
	var destination: float=enemy.combat_space.clamp_x(enemy.player.position.x+enemy.facing*135.0,110.0,1170.0)
	flight_speed=clampf((destination-enemy.position.x)/0.72,-430.0,430.0)
	enemy.stable=false
	enemy.velocity.y=-620.0
	enemy.set_state("vault")
	vaults+=1

func tick(dt: float) -> void:
	enemy.timer+=dt
	if enemy.state=="vault":
		enemy.velocity.x=flight_speed
		if enemy.timer>0.25 and enemy.is_on_floor():
			enemy.velocity.x=0.0
			var axis: float=enemy.player.position.x-enemy.position.x
			if not is_zero_approx(axis): enemy.facing=signf(axis)
			enemy.set_state("settle")
	elif enemy.state=="settle":
		if enemy.timer>=0.45: enemy.set_state("active")
	elif enemy.state=="reground":
		var gap: float=enemy.home.x-enemy.position.x
		if absf(gap)>14.0: enemy.velocity.x=signf(gap)*160.0
		if absf(gap)<=14.0 or enemy.timer>=0.50:
			enemy.stable=absf(gap)<=26.0
			enemy.set_state("idle")

func pressure_replant() -> void:
	replant_interrupts+=1
	enemy.force_unstable=true
	enemy.stable=false
	enemy.velocity.x=0.0
	enemy.set_state("idle")
	enemy.timer=0.55
	enemy.last_result="回稳被压制 · 下一招立足不稳"
	enemy.changed.emit(enemy.last_result)

func pose() -> int:
	if enemy.state=="vault": return 17 if enemy.timer<0.25 else 18
	if enemy.state=="settle": return 19
	if enemy.state=="reground":
		return 20 if enemy.timer<0.18 else (21 if absf(enemy.home.x-enemy.position.x)>14.0 else 22)
	return -1

func segments() -> Array[Dictionary]:
	if enemy.state=="reground": return [{"phase":"reground","pulse":1,"start":0.0,"end":0.50}]
	if enemy.move_key!="elder_vault": return []
	var result: Array[Dictionary]=[]
	var cursor: float=0.0
	for part: Array in [["tell",0.85],["vault",0.72],["settle",0.45],["active",0.18],["recover",float(enemy.spec.recover)]]:
		result.append({"phase":part[0],"pulse":1,"start":cursor,"end":cursor+float(part[1])})
		cursor+=float(part[1])
	return result
