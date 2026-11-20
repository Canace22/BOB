class_name EnemyLabElderMimic
extends Node2D
## 从真实释放事件记录技能快照，以敌人命中协议复现，不执行玩家输入或复制其控制器。
var repertoire: EnemyLabElderRepertoire
var enemy: EnemyLabElder
var memory: Dictionary={}
var copied: Dictionary={}
var source_key: String=""
var times: Array[float]=[]
var emitted: int=0
var last_release: float=-1.0
var cooldown: float=0.0
var casts: int=0
var interrupted: int=0
var orb_refs: Array[WeakRef]=[]
var view: EnemyLabElderEchoView
const NAMES: Dictionary={"strike_01":"普攻","A3_anchor":"下刺","A1_dash":"冲刺","A5_slit":"裂隙穿行","backstep":"后跳","recover":"凝息回复","orb":"潮弹","heavy":"蓄势重击","wb_rise":"上挑","wb_drive":"三段斩","wb_draw":"横扫重斩","wb_charge":"突进撞击","wb_flurry":"连刺","wb_backcut":"后跳回斩"}

func _ready() -> void:
	repertoire=EnemyLabElderRepertoire.new()
	repertoire.mimic=self
	view=EnemyLabElderEchoView.new()
	view.mimic=self
	add_child(view)
	enemy.player.skill_effect.connect(_observe)
	enemy.player.animation_tag.connect(repertoire.legacy)
	enemy.player.backstep_started.connect(repertoire.backstep)

func _observe(key: String, event: String, _origin: Vector2, _direction: float) -> void:
	if not enemy.outcome.is_empty() or enemy.player.health<=0: return
	var controller: TideCombatSkills=enemy.player.skill_controller as TideCombatSkills
	if not controller.active or controller.visual_key!=key: return
	var data: Dictionary=controller.data
	var dive: bool=str(data.get("motion",""))=="dive"
	if event!=("land" if dive else "release") or not controller.released: return
	if key=="tram": return
	_remember(key,data,clampi(controller.drive_step,1,3))

func _remember(key: String, data: Dictionary, steps: int) -> void:
	if not enemy.outcome.is_empty() or enemy.player.health<=0: return
	if enemy.position.distance_to(enemy.player.position)>700.0: return
	var ray := PhysicsRayQueryParameters2D.create(enemy.position+Vector2(0,-45),enemy.player.position+Vector2(0,-45),1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): return
	var adapted: Dictionary=repertoire.adapt(key,data)
	var observation: Dictionary={"key":key,"data":adapted,"steps":steps}
	repertoire.store(key,observation)
	if key not in ["strike_01","strike2"] or memory.is_empty(): memory=observation
	view.prepare(key)
	enemy.changed.emit("观招记下："+title(key))

func title(key: String) -> String:
	return str(NAMES.get(key,TideSkillCatalog.TITLES.get(key,key)))

func memory_title() -> String:
	var selected: Dictionary=memory if not memory.is_empty() else repertoire.choose()
	return title(str(selected.key)) if not selected.is_empty() else "尚未观招"

func status_title() -> String:
	if enemy.move_key=="elder_mimic" and enemy.state in ["tell","active"]: return title(source_key)+"（复现中）"
	return memory_title()

func reach() -> float:
	var selected: Dictionary=memory if not memory.is_empty() else repertoire.choose()
	var data: Dictionary=selected.get("data",{})
	if bool(data.get("projectile",false)): return 560.0
	if int(data.get("damage",0))<=0: return 600.0
	return clampf(float(data.get("reach",130.0))+float(data.get("speed",0.0))*float(data.get("release",0.0))+80.0,180.0,560.0)

func evade_active() -> bool:
	return enemy.state=="active" and enemy.move_key=="elder_mimic" and bool(copied.get("immune",false))

func ready_to_cast() -> bool:
	return not repertoire.choose().is_empty() and cooldown<=0.0 and enemy.outcome.is_empty()

func begin() -> void:
	cancel()
	if memory.is_empty() or (str(memory.key)=="recover" and (repertoire.heal_budget<=0 or enemy.health>=enemy.maximum)): memory=repertoire.choose()
	source_key=str(memory.key)
	copied=memory.data.duplicate(true)
	var steps: int=int(memory.steps)
	memory.clear()
	times.clear()
	if source_key=="wb_drive":
		for i: int in steps: times.append(float(copied.release)+float(copied.duration)*i)
	elif copied.has("pulses"):
		for at: Variant in copied.pulses: times.append(float(at))
	else: times.append(float(copied.get("release",0.1)))
	emitted=0
	last_release=-1.0
	cooldown=2.2
	enemy.spec.title="观招复现 · "+title(source_key)
	enemy.spec.tell=0.70
	enemy.spec.recover=0.75 if not str(copied.get("utility","")).is_empty() else 1.0
	enemy.spec.active=clampf(float(copied.get("duration",0.5))*(steps if source_key=="wb_drive" else 1),0.24,1.6)
	if str(copied.get("motion",""))=="dive": enemy.spec.active=1.10
	view.prepare(source_key)

func tick(dt: float) -> void:
	enemy.timer+=dt
	if enemy.state=="tell":
		if enemy.timer>=float(enemy.spec.tell):
			enemy.set_state("active")
			casts+=1
			if str(copied.get("motion",""))=="dive": enemy.velocity.y=-480.0
		return
	if enemy.state!="active": return
	_motion()
	if str(copied.get("motion",""))=="dive":
		if enemy.timer>0.25: enemy.velocity.y=700.0
		if enemy.timer>0.30 and enemy.is_on_floor() and emitted==0:
			_pulse()
			emitted=1
	else:
		while emitted<times.size() and enemy.timer>=times[emitted]:
			enemy.pulse=emitted+1
			_pulse()
			emitted+=1
			if enemy.state!="active": return
		# 冲刺类在自身有效段持续检查接触，不能只在起跑位置判一次。
		if str(copied.get("motion",""))=="dash" and int(copied.get("damage",0))>0: enemy.strike()
	if enemy.state=="active" and enemy.timer>=float(enemy.spec.active): enemy.set_state("recover")

func _motion() -> void:
	var motion: String=str(copied.get("motion",""))
	repertoire.motion()
	var release: float=float(copied.get("release",0.1))
	if motion in ["shoulder","lunge"] and enemy.timer<release:
		enemy.velocity.x=enemy.facing*float(copied.get("speed",0.0))
	elif motion=="combo_dash" and fmod(enemy.timer,float(copied.duration))<=0.12:
		enemy.velocity.x=enemy.facing*float(copied.speed)
	elif motion=="dash": enemy.velocity.x=enemy.facing*float(copied.get("speed",0.0))

func _pulse() -> void:
	last_release=enemy.timer
	enemy.hit_sent=false
	if repertoire.pulse(): return
	if bool(copied.get("projectile",false)):
		var orb := EnemyLabMimicOrb.new()
		orb.source=weakref(enemy)
		orb.player=enemy.player
		orb.velocity=Vector2(enemy.facing*enemy.player.orb_speed,0)
		enemy.get_parent().add_child(orb)
		orb.global_position=enemy.position+Vector2(enemy.facing*60.0,-52)
		orb_refs.append(weakref(orb))
	else:
		var before: int=enemy.hit_count
		enemy.strike()
		# 上挑/撞击只在真正造成伤害后施加原招式浮空，格挡或无敌不能被挑起。
		if enemy.hit_count>before and copied.has("launch"): enemy.player.velocity.y=-float(copied.launch)

func area() -> Rect2:
	var reach: float=float(copied.get("reach",125.0))
	var origin: Vector2=enemy.global_position
	match str(copied.get("shape","front")):
		"radial": return Rect2(origin-Vector2(reach,reach),Vector2.ONE*reach*2.0)
		"up": return Rect2(origin+Vector2(-70,-reach-50),Vector2(140,reach))
	return Rect2(origin+Vector2(0 if enemy.facing>0 else -reach,-110),Vector2(reach,110))

func take_hit(amount: int) -> void:
	if enemy.state!="tell" or enemy.move_key!="elder_mimic": return
	var rear: bool=(enemy.player.position.x-enemy.position.x)*enemy.facing<0.0
	if amount<3 and not rear: return
	interrupted+=1
	cancel()
	enemy.spec.recover=1.35
	enemy.control_left=0.0
	enemy.set_state("recover")
	enemy.last_result="复现被打断 · 长柄失衡"
	enemy.changed.emit(enemy.last_result)

func cancel() -> void:
	for ref: WeakRef in orb_refs:
		var orb: Node=ref.get_ref()
		if is_instance_valid(orb): orb.queue_free()
	orb_refs.clear()
	if is_instance_valid(view): view.clear()

func pose() -> int:
	if enemy.state=="tell": return 12 if enemy.timer<0.45 else 13
	if enemy.state!="active": return 7
	if source_key=="parry": return 12
	if source_key in ["recover","scan"]: return 22
	if str(copied.get("utility",""))=="backstep": return 17
	if str(copied.get("motion",""))=="dash": return 1
	if str(copied.get("motion",""))=="dive": return 18 if not enemy.is_on_floor() else 19
	if source_key=="wb_flurry": return 12+int(enemy.timer*12.0)%4
	if str(copied.get("shape",""))=="radial": return 4+int(enemy.timer*9.0)%4
	return 9 if bool(copied.get("projectile",false)) else (14 if str(copied.get("shape",""))=="up" or source_key=="wb_rise" else 10)

func segments() -> Array[Dictionary]:
	return [{"phase":"tell","pulse":1,"start":0.0,"end":float(enemy.spec.tell)},
	{"phase":"active","pulse":enemy.pulse,"start":float(enemy.spec.tell),"end":float(enemy.spec.tell)+float(enemy.spec.active),"marks":times},
	{"phase":"recover","pulse":enemy.pulse,"start":float(enemy.spec.tell)+float(enemy.spec.active),"end":float(enemy.spec.tell)+float(enemy.spec.active)+float(enemy.spec.recover)}]
