class_name ChapterRunEncounter
extends Node
## 每次遭遇独占容器；敌人、幻影、卵、水弹和场地门统一回收。
var host: ChapterRun
var enemy: EnemyLabEnemy
var container: Node2D
var gates: Array[StaticBody2D]=[]
var config: Dictionary={}
var started: bool=false
var warning: float=0
var time: float=0
var original_mask: int=1
var retired_body: EnemyLabEnemy
var retired_goal: Vector2
var moving_retired: bool=false

func _process(dt: float) -> void:
	if moving_retired and is_instance_valid(retired_body):
		retired_body.position=retired_body.position.move_toward(retired_goal,dt*210)
		if retired_body.position.distance_to(retired_goal)<1: moving_retired=false

func move_retired_to(value: Vector2) -> void:
	retired_goal=value
	moving_retired=true

func prepare(value: Dictionary) -> void:
	clear()
	config=value.duplicate(true)

func tick(dt: float, optional: bool=false) -> void:
	if config.is_empty(): return
	if not started:
		var trigger: Array=config.get("trigger",config.at)
		if host.player.position.distance_to(host.point(trigger))<=float(config.get("trigger_radius",140)):
			started=true
			warning=0.8
			host.record("encounter_warning",{"profile":config.profile,"optional":optional})
		return
	if warning>0:
		warning-=dt
		if warning<=0: spawn(optional)
		return
	time+=dt
	if optional and enemy is EnemyLabPredator and enemy.sheltered_player() and enemy.state not in ["idle","return","ended"]:
		enemy.set_state("return")
		for child: Node in container.get_children():
			if child!=enemy: child.queue_free()
		host.record("shelter_broke_chase")
	if is_instance_valid(enemy) and enemy.outcome.is_empty() and int(config.profile)<3:
		var lane: Array=config.get("lane",[0,float(host.data.get("width",3600))])
		enemy.position.x=clampf(enemy.position.x,float(lane[0])-host.offset.x,float(lane[1])-host.offset.x)

func spawn(optional: bool) -> void:
	container=Node2D.new()
	host.world.add_child(container)
	var profile: Dictionary=EnemyLabCatalog.profile(int(config.profile))
	profile.ending=str(config.get("ending",profile.ending))
	for key: String in ["hp","height","radius","speed","title"]:
		if config.has(key): profile[key]=config[key]
	profile=ChapterCombatPressure.apply(profile)
	match str(profile.id):
		"membrane_hunter": enemy=EnemyLabPredator.new()
		"nest_eel": enemy=EnemyLabEel.new()
		"pump_warden": enemy=EnemyLabWarden.new()
		"beam_guard": enemy=EnemyLabBeamGuard.new()
		"elder_guardian": enemy=ChapterRunElder.new()
		_: enemy=EnemyLabEnemy.new()
	enemy.profile=profile
	enemy.player=host.player
	enemy.position=host.point(config.at)
	enemy.show_ranges=false
	enemy.auto_attack=true
	original_mask=host.player.world_collision_mask
	container.add_child(enemy)
	if enemy is EnemyLabPredator:
		enemy.shelter_enabled=optional
		enemy.position=host.point(config.at)
		enemy.home=enemy.position
	if not optional and int(config.profile)>=3:
		# 特殊敌人复用原试验场空间；实体栏杆可见，避免越界追击及远处盲打。
		var left: float=minf(70,host.player.position.x-70)
		var right: float=maxf(1210,host.player.position.x+70)
		for x: float in [left,right]: gates.append(host.body(Rect2(x,80,20,440),container))
	host.record("enemy_spawned",{"class":enemy.get_class(),"profile":profile.id,"health":profile.hp})

func won() -> bool: return is_instance_valid(enemy) and not enemy.outcome.is_empty()

func end_combat() -> void:
	if is_instance_valid(enemy):
		if enemy.outcome.is_empty(): enemy.finish()
		enemy.auto_attack=false
		# 某些敌人的弹体是兄弟节点；只留已结束的身体供战后观察。
		for child: Node in container.get_children():
			if child!=enemy and not child is StaticBody2D: child.queue_free()
	for gate: StaticBody2D in gates:
		if is_instance_valid(gate): gate.queue_free()
	gates.clear()

func retire() -> void:
	if not is_instance_valid(container): return
	# 战后身体留在场内，死亡与非致死结果不会被阶段切换立即抹去。
	if is_instance_valid(enemy):
		enemy.visual.present(enemy)
		retired_body=enemy
	if is_instance_valid(enemy) and enemy.outcome=="retreat":
		var direction: float=signf(enemy.position.x-host.player.position.x)
		if is_zero_approx(direction): direction=1
		enemy.retreat_goal=clampf(enemy.position.x+direction*150,30-host.offset.x,float(host.data.get("width",3600))-30-host.offset.x)
	else:
		container.process_mode=Node.PROCESS_MODE_DISABLED
	host.player.world_collision_mask=original_mask
	enemy=null
	container=null
	config={}
	started=false
	gates.clear()

func clear() -> void:
	if is_instance_valid(container):
		# 先停物理并从目标组撤出，避免同帧遗留伤害或扫描到旧身体。
		for node: Node in container.get_children():
			if node is EnemyLabEnemy:
				node.auto_attack=false
				node.remove_from_group("tide_targets")
		container.process_mode=Node.PROCESS_MODE_DISABLED
		container.queue_free()
	if is_instance_valid(host) and is_instance_valid(host.player):
		host.player.world_collision_mask=original_mask
	enemy=null
	container=null
	gates.clear()
	started=false
	warning=0
	time=0
	config={}

func restore_completed_bodies() -> void:
	var active: Dictionary=config.duplicate(true)
	for stage: Dictionary in host.data.stages:
		if stage.kind!="battle" or not str(stage.id) in host.completed: continue
		var ending: String=str(host.flags.get(str(stage.id)+"_outcome",stage.enemy.get("ending","retreat")))
		if ending=="retreat": continue
		var saved: Dictionary=stage.enemy.duplicate(true)
		saved.ending=ending
		saved.at=host.flags.get(str(stage.id)+"_end_at",saved.at)
		prepare(saved)
		spawn(true)
		enemy.health=0
		enemy.finish()
		end_combat()
		retire()
		# 只恢复结束身体，不重演战斗；已完成的搬运代理保留其安置位置。
		for previous: Dictionary in host.data.stages:
			if previous.has("actor_at") and (str(previous.id) in host.completed or previous==host.flow.stage()):
				retired_body.position=host.point(previous.actor_at)
				moving_retired=false
	prepare(active)
