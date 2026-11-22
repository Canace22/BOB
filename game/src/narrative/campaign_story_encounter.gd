class_name CampaignStoryEncounter
extends Node
## 正式章节只拥有这场战斗的生命周期；所有技能、伤害与格挡复用共用执行器。
signal resolved(outcome: String)
var host: WhalebellyMain
var enemy: EnemyLabEnemy
var container: Node2D
var config: Dictionary={}
var room_id: String=""
var elapsed: float=0.0
var result: String=""
var original_player_mask: int=0
var retired: Array[Node2D]=[]
var retreat_tweens: Dictionary={}

func setup(value: WhalebellyMain) -> void:
	host=value
	process_mode=Node.PROCESS_MODE_PAUSABLE

func spawn(value: Dictionary) -> EnemyLabEnemy:
	clear(true)
	if not is_instance_valid(host) or not is_instance_valid(host.player): return null
	if not host.player is TideCombatPlayer: return null
	room_id=str(value.get("room_id",host.room.id))
	if room_id!=str(host.room.id): return null
	var profile: Dictionary=_profile(value.get("profile",0))
	if profile.is_empty(): return null
	config=value.duplicate(true)
	for key: String in ["ending","hp","height","radius","speed","title"]:
		if config.has(key): profile[key]=config[key]
	profile=ChapterCombatPressure.apply(profile)
	enemy=_create(str(profile.id))
	enemy.profile=profile
	enemy.player=host.player as TideCombatPlayer
	enemy.position=_point(config.get("at",host.player.position+Vector2(250,0)))
	enemy.show_ranges=false
	enemy.auto_attack=bool(config.get("auto_attack",true))
	var arena: Rect2=_arena(config.get("arena",Rect2(enemy.position-Vector2(640,420),Vector2(1280,420))))
	var options: Dictionary={"floor_y":float(config.get("floor_y",arena.end.y))}
	for key: String in ["exit_x","shelter","perches"]:
		if config.has(key): options[key]=config[key]
	if options.get("shelter") is Array:
		var shelter: Array=options.shelter
		if shelter.size()==2:
			var radius: float=float(config.get("shelter_radius",170))
			options.shelter=Rect2(_point(shelter)-Vector2.ONE*radius,Vector2.ONE*radius*2.0)
		else: options.shelter=_arena(shelter)
	enemy.combat_space.configure(arena,options)
	container=Node2D.new()
	container.name="ChapterEncounter"
	container.set_meta("story_identity",str(config.get("identity",config.get("actor_id",profile.id))))
	# 房内坐标与正式玩家共用actor_frame。容器不再叠加房间偏移，判定/弹体显式用世界坐标。
	host.actor_frame.add_child(container)
	original_player_mask=host.player.world_collision_mask
	container.add_child(enemy)
	enemy.z_index=host.player.z_index
	if enemy is EnemyLabPredator: enemy.shelter_enabled=bool(config.get("optional",false))
	if enemy is EnemyLabWarden: enemy.exit_enabled=config.has("exit_x")
	enemy.changed.connect(_changed)
	return enemy

func _physics_process(dt: float) -> void:
	if not is_instance_valid(container): return
	if not is_instance_valid(host.player) or str(host.room.id)!=room_id or host.player.health<=0 or host.quitting:
		clear()
		return
	tick(dt)

func tick(dt: float) -> void:
	if not is_instance_valid(enemy) or not result.is_empty(): return
	elapsed+=dt
	if not enemy.outcome.is_empty(): _settle(enemy.outcome)
	elif enemy.combat_space.configured:
		# 只约束该遭遇活动范围，不移动玩家、不生成看不见的关卡墙。
		var space: EnemyLabCombatSpace=enemy.combat_space
		var x: float=clampf(enemy.position.x,space.x(30),space.x(1250))
		if not is_equal_approx(x,enemy.position.x):
			enemy.position.x=x
			enemy.velocity.x=0.0

func won() -> bool:
	return not result.is_empty()

func _changed(_message: String) -> void:
	if is_instance_valid(enemy) and not enemy.outcome.is_empty(): _settle(enemy.outcome)

func end_combat(outcome_override: String="") -> void:
	if not is_instance_valid(enemy) or not result.is_empty(): return
	if not outcome_override.is_empty(): enemy.profile.ending=outcome_override
	if enemy.outcome.is_empty(): enemy.finish()
	_settle(enemy.outcome)

func _settle(outcome: String) -> void:
	if not result.is_empty() or not is_instance_valid(enemy): return
	result=outcome
	enemy.auto_attack=false
	enemy.velocity=Vector2.ZERO
	enemy.collision_layer=0
	enemy.remove_from_group("tide_targets")
	# 弹体是敌人的兄弟节点；先同步停伤害与退组，再排队释放，不能等下一物理帧。
	_stop_hazards()
	enemy.visual.present(enemy)
	container.process_mode=Node.PROCESS_MODE_DISABLED
	_restore_player_mask()
	resolved.emit(result)

func _stop_hazards() -> void:
	if not is_instance_valid(container): return
	for child: Node in container.get_children():
		if child==enemy: continue
		child.process_mode=Node.PROCESS_MODE_DISABLED
		for group: StringName in child.get_groups(): child.remove_from_group(group)
		if child.has_method("consume"): child.call("consume")
		else: child.queue_free()

func clear(keep_body: bool=false) -> void:
	if is_instance_valid(container):
		if is_instance_valid(enemy):
			enemy.auto_attack=false
			enemy.remove_from_group("tide_targets")
			enemy.collision_layer=0
		_stop_hazards()
		container.process_mode=Node.PROCESS_MODE_DISABLED
		if keep_body and is_instance_valid(enemy) and not enemy.outcome.is_empty():
			retired.append(container)
			if enemy.outcome=="retreat": _fade_retreat(container,enemy)
		else: container.queue_free()
	if not keep_body:
		for tween: Tween in retreat_tweens.values(): tween.kill()
		retreat_tweens.clear()
		for body: Node2D in retired:
			if is_instance_valid(body): body.queue_free()
		retired.clear()
	_restore_player_mask()
	enemy=null
	container=null
	config={}
	room_id=""
	elapsed=0.0
	result=""

func has_body(identity: String) -> bool:
	if is_instance_valid(container) and is_instance_valid(enemy) and enemy.outcome in ["kill","surrender"]:
		if str(container.get_meta("story_identity",""))==identity: return true
	for body: Node2D in retired:
		if is_instance_valid(body) and not bool(body.get_meta("story_retreat",false)) and str(body.get_meta("story_identity",""))==identity: return true
	return false

func body_for(identity: String) -> EnemyLabEnemy:
	for body: Node2D in retired:
		if not is_instance_valid(body) or bool(body.get_meta("story_retreat",false)) or str(body.get_meta("story_identity",""))!=identity: continue
		for child: Node in body.get_children():
			if child is EnemyLabEnemy: return child
	return null

func _fade_retreat(body: Node2D, actor: EnemyLabEnemy) -> void:
	body.set_meta("story_retreat",true)
	var axis: float=signf(actor.position.x-actor.player.position.x)
	if is_zero_approx(axis): axis=-actor.facing
	# 战斗已停止：这是退出画面的展示过渡，不登记为新的逐帧逃跑动作。
	var tween: Tween=create_tween()
	retreat_tweens[body.get_instance_id()]=tween
	tween.set_parallel(true)
	tween.tween_property(body,"position",body.position+Vector2(axis*80.0,0),0.45)
	tween.tween_property(body,"modulate:a",0.0,0.45)
	var body_id: int=body.get_instance_id()
	tween.finished.connect(func() -> void:
		retreat_tweens.erase(body_id)
		retired.erase(body)
		if is_instance_valid(body): body.queue_free())

func clear_room() -> void:
	clear(false)

func _restore_player_mask() -> void:
	if original_player_mask!=0 and is_instance_valid(host) and is_instance_valid(host.player):
		host.player.world_collision_mask=original_player_mask
	original_player_mask=0

func _exit_tree() -> void:
	clear()

static func _point(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(value[0],value[1])

static func _arena(value: Variant) -> Rect2:
	return value if value is Rect2 else Rect2(value[0],value[1],value[2],value[3])

static func _profile(value: Variant) -> Dictionary:
	if value is int or value is float: return EnemyLabCatalog.profile(int(value))
	for profile: Dictionary in EnemyLabCatalog.PROFILES:
		if str(profile.id)==str(value): return profile.duplicate(true)
	push_error("Unknown formal chapter enemy profile: "+str(value))
	return {}

static func _create(id: String) -> EnemyLabEnemy:
	match id:
		"membrane_hunter": return EnemyLabPredator.new()
		"nest_eel": return EnemyLabEel.new()
		"pump_warden": return EnemyLabWarden.new()
		"beam_guard": return EnemyLabBeamGuard.new()
		"elder_guardian": return ChapterRunElder.new()
	return EnemyLabEnemy.new()
