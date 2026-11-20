class_name EnemyLabReactions
extends RefCounted
## 敌人侧结算与控制；不把护壳的半点伤害取整丢失，不生成主线奖励。
var enemy: EnemyLabEnemy
var damage_remainder: float=0.0
var rewarded_serial: int=-1
var received: int=0
func sheltered() -> bool:
	return enemy.armor_active()
func controllable() -> bool:
	return enemy.control_window_open()
func heavy_window() -> bool:
	return bool(enemy.spec.get("interrupt",false)) and enemy.state=="tell" and enemy.timer>=float(enemy.spec.tell)-0.35
func take_hit(amount: int) -> void:
	if amount<=0 or not enemy.can_receive_hit(): return
	received+=1
	var front: bool=(enemy.player.global_position.x-enemy.global_position.x)*enemy.facing>=0.0
	var ratio: float=0.5 if sheltered() and front else 1.0
	var guard: EnemyLabSkills=enemy.player.skill_controller as EnemyLabSkills
	var bonus: int=guard.consume_counter()
	if bonus>0: ratio=1.0
	var exposed: bool=enemy.state=="recover"
	damage_remainder+=float(amount)*ratio+float(bonus)
	var damage: int=int(floor(damage_remainder))
	damage_remainder-=damage
	if str(enemy.profile.id)=="forager" and exposed and rewarded_serial!=enemy.attack_serial:
		rewarded_serial=enemy.attack_serial
		damage+=2
	enemy.health=maxi(0,enemy.health-damage)
	enemy.last_result=("护壳累计 %.1f" % damage_remainder) if ratio<1.0 else ("破绽反击" if exposed else "命中")
	if enemy.health<=0:
		enemy.finish()
		return
	var heavy: bool=enemy.player.skill_controller.visual_key in ["wb_draw","heavy","great_slash"]
	if controllable() or (heavy_window() and heavy):
		enemy.set_state("hurt")
		enemy.control_left=0.24
	enemy.changed.emit(enemy.last_result)
func launch(speed: float) -> void:
	if not controllable() or str(enemy.profile.id) not in ["forager","membrane_hunter"] or enemy.air_lifts>=3: return
	enemy.velocity.y=-speed/(1.0+float(enemy.air_lifts)*0.5)
	enemy.air_lifts+=1
	enemy.set_state("hurt")
	enemy.control_left=0.24
func control(seconds: float) -> void:
	if not controllable(): return
	enemy.set_state("hurt")
	enemy.control_left=maxf(enemy.control_left,seconds)
