class_name EnemyLabElderRepertoire
extends RefCounted
## 旧动作/辅助技能的语义适配；记录实际执行，不授予玩家权限或操作关卡。
var mimic: EnemyLabElderMimic
var learned: Dictionary={}
var heal_budget: int=4
var shields: int=0
var healing: int=0
var scans: int=0
var blocked_feedback: bool=false

func legacy(tag: String) -> void:
	var p: TideCombatPlayer=mimic.enemy.player
	if p.skill_controller.active: return
	if tag==p.state+":start" and p.state in ["A1_dash","A5_slit"]:
		remember(p.state,{"duration":p.state_duration,"release":0.0,"motion":"dash","speed":p.dash_speed,"immune":true,"utility":"move"})
	if not p.event_done or tag!=p.state+":release":
		if tag=="recover:end" and p.state=="recover": remember("recover",{"duration":0.65,"release":0.40,"utility":"heal"})
		return
	match p.state:
		"A4_parry": remember("orb",{"duration":p.state_duration,"release":p.action_trigger_time(),"damage":p.orb_damage,"projectile":true})
		"heavy": remember("heavy",{"duration":p.state_duration,"release":p.action_trigger_time(),"damage":p.heavy_damage,"reach":p.heavy_radius,"shape":"radial"})
		"strike_01": remember("strike_01",{"duration":p.state_duration,"release":p.action_trigger_time(),"damage":1,"reach":p.melee_reach,"shape":"front"})
		"A3_anchor": remember("A3_anchor",{"duration":0.55,"release":0.15,"damage":1,"reach":p.downward_reach,"shape":"radial","motion":"dive"})

func backstep() -> void:
	remember("backstep",{"duration":0.35,"release":0.0,"utility":"backstep"})

func remember(key: String, data: Dictionary, steps: int=1) -> void:
	mimic._remember(key,data,steps)

func store(key: String, observation: Dictionary) -> void:
	learned[key]=observation.duplicate(true)

func choose() -> Dictionary:
	var enemy: EnemyLabElder=mimic.enemy
	var gap: float=absf(enemy.position.x-enemy.player.position.x)
	var best: Dictionary={}
	var score: float=-10000.0
	for key: String in learned:
		var record: Dictionary=learned[key]
		var data: Dictionary=record.data
		if str(data.get("utility",""))=="heal" and (heal_budget<=0 or enemy.health>=enemy.maximum): continue
		var weight: float=0.0
		if bool(data.get("projectile",false)): weight=5.0 if gap>230 else 1.0
		elif str(data.get("motion","")) in ["dash","lunge","shoulder","combo_dash"]: weight=4.0 if gap>180 else 1.0
		elif int(data.get("damage",0))>0: weight=4.0 if gap<220 else 0.0
		elif key=="parry": weight=3.0 if gap<160 else 0.0
		elif key=="recover": weight=3.0 if gap>200 else 0.5
		else: weight=1.0
		if key==mimic.source_key: weight-=5.0
		if not mimic.memory.is_empty() and str(mimic.memory.key)==key: weight+=0.25
		if weight>score:
			score=weight
			best=record
	return best.duplicate(true)

func adapt(key: String, data: Dictionary) -> Dictionary:
	var result: Dictionary=data.duplicate(true)
	if key=="parry": result.utility="guard"
	if key=="scan": result.utility="scan"
	if not result.has("damage") and str(result.get("motion",""))=="dash": result.utility="move"
	return result

func pulse() -> bool:
	var enemy: EnemyLabElder=mimic.enemy
	match str(mimic.copied.get("utility","")):
		"heal":
			var amount: int=mini(2,mini(heal_budget,enemy.maximum-enemy.health))
			enemy.health+=amount
			heal_budget-=amount
			healing+=amount
		"scan":
			scans+=1
			enemy.boosted_chase=3.0
			enemy.force_unstable=false
			enemy.changed.emit("复现探潮 · 锁定下一轮追击方向")
		"move","guard","backstep": pass
		_: return false
	return true

func motion() -> void:
	var enemy: EnemyLabElder=mimic.enemy
	if str(mimic.copied.get("utility",""))=="backstep":
		enemy.velocity.x=-enemy.facing*320.0
		if enemy.timer<0.025 and enemy.is_on_floor(): enemy.velocity.y=-230.0

func block(amount: int) -> bool:
	blocked_feedback=false
	var enemy: EnemyLabElder=mimic.enemy
	if amount<=0 or enemy.move_key!="elder_mimic" or mimic.source_key!="parry" or enemy.state!="active": return false
	if enemy.timer<float(mimic.copied.get("release",0.02)) or enemy.timer>0.42: return false
	if amount>=3 or (enemy.player.position.x-enemy.position.x)*enemy.facing<0.0:
		mimic.cancel()
		enemy.spec.recover=1.10
		enemy.set_state("recover")
		enemy.changed.emit("复现格挡被破 · 长破绽")
		return false
	shields+=1
	blocked_feedback=true
	enemy.reactions.received+=1
	enemy.spec.recover=0.24
	enemy.set_state("recover")
	enemy.changed.emit("复现格挡成功 · 准备追击")
	return true
