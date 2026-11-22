extends TestSuite
## 非零世界原点下直接实例化正式主角和完整敌人，检查房内路线、世界判定与退场清理。
class StoryTestHost extends WhalebellyMain:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

func fixture() -> Dictionary:
	var host:=StoryTestHost.new()
	host.room={"id":"story-test","size":[1600,1000],"doors":[],"enemies":[]}
	host.muted=true
	host.health=5
	host.player_soul=99
	host.integration_external_test=true
	add(host)
	host.setup_inputs()
	host.actor_frame=Node2D.new()
	host.actor_frame.position=Vector2(5000,-1700)
	host.add_child(host.actor_frame)
	var floor:=StaticBody2D.new()
	floor.collision_layer=1
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(1600,100)
	collision.shape=shape
	collision.position=Vector2(800,950)
	floor.add_child(collision)
	host.actor_frame.add_child(floor)
	host.streaming=CampaignRoomStream.new()
	host.streaming.enabled=false
	host.streaming.host=host
	# 该专项只推进敌人；正式玩家的_ready/共用命中/防御逻辑真实执行。
	var player: WhalebellyCampaignPlayer=load("res://content/whalebelly/CampaignPlayer.tscn").instantiate()
	player.host=host
	player.position=Vector2(600,900)
	host.player=player
	host.actor_frame.add_child(player)
	player.set_physics_process(false)
	player.controls_enabled=true
	var encounter:=CampaignStoryEncounter.new()
	host.add_child(encounter)
	encounter.setup(host)
	return {"host":host,"player":player,"encounter":encounter}

func config(profile: String) -> Dictionary:
	return {"profile":profile,"identity":profile,"room_id":"story-test","at":[850,900],"arena":[300,400,980,500],"auto_attack":false}

func test_formal_player_accepts_every_complete_executor_in_translated_room() -> void:
	var f:=fixture()
	var player: WhalebellyCampaignPlayer=f.player
	check(player.skill_controller is TideCombatGuardSkills and player.get_script()==preload("res://src/campaign/campaign_player.gd"),"formal common guard is used")
	for profile: Dictionary in EnemyLabCatalog.PROFILES:
		var enemy: EnemyLabEnemy=f.encounter.spawn(config(str(profile.id)))
		await physics_frames(10)
		check(enemy!=null and enemy.player==player,"full executor accepts actual formal player: "+str(profile.id))
		eq(enemy.get_parent().global_position,f.host.actor_frame.global_position,"encounter has no second room translation")
		check(enemy.position.x>=300 and enemy.position.x<=1280,"local location stays within actual arena")
		check(enemy.global_position.x>5000,"world actor position includes room origin")
		f.encounter.clear()
		await physics_frames(2)
	f.host.streaming.free()

func test_formal_normal_attack_hits_once_and_does_not_bypass_beam_guard() -> void:
	var f:=fixture()
	var player: WhalebellyCampaignPlayer=f.player
	var enemy: EnemyLabEnemy=f.encounter.spawn(config("forager"))
	await physics_frames(10)
	player.position=enemy.position-Vector2(75,0)
	player.facing=1.0
	player.hit_targets.clear()
	var hp: int=enemy.health
	player._melee(false)
	player._melee(false)
	eq(enemy.health,hp-1,"one formal swing hits chapter enemy only once")
	f.encounter.clear()
	await physics_frames(2)
	var guard: EnemyLabBeamGuard=f.encounter.spawn(config("beam_guard")) as EnemyLabBeamGuard
	await physics_frames(10)
	guard.move_key="beam_guard"
	guard.spec=guard.action_spec("beam_guard")
	guard.defense.begin()
	guard.set_state("guarding")
	player.position=guard.position+Vector2(75,0)
	player.facing=-1.0
	guard.facing=1.0
	player.hit_targets.clear()
	var guarded_hp: int=guard.health
	player._melee(false)
	eq(guard.health,guarded_hp,"formal normal attack obeys actual enemy guard")
	eq(guard.defense.blocks,1,"one actual guard interception")
	f.host.streaming.free()

func test_special_routes_and_sibling_hazards_use_correct_coordinate_space() -> void:
	var f:=fixture()
	var eel: EnemyLabEel=f.encounter.spawn(config("nest_eel")) as EnemyLabEel
	await physics_frames(10)
	check(eel.begin_attack("eel_burrow"),"actual burrow starts")
	eel.nest._advance_burrow()
	check(eel.nest.target_root>=eel.combat_space.x(155) and eel.nest.target_root<=eel.combat_space.x(1125),"burrow clamps room-local destination")
	eq(eel.nest.locked_x,f.player.position.x,"burrow reads local player coordinate")
	eel.nest._spit(0)
	var egg: EnemyLabNestEgg=eel.nest.eggs[0].get_ref() as EnemyLabNestEgg
	check(egg.global_position.x>5000,"egg launches in translated world")
	f.encounter.end_combat("kill")
	check(not egg.is_in_group("tide_hostile_projectiles"),"completion synchronously removes projectile damage group")
	f.encounter.clear(true)
	check(f.encounter.has_body("nest_eel"),"completed body retains unique identity")
	f.encounter.clear_room()
	check(not f.encounter.has_body("nest_eel"),"room exit clears every retired body")
	await physics_frames(2)
	var warden: EnemyLabWarden=f.encounter.spawn(config("pump_warden")) as EnemyLabWarden
	await physics_frames(10)
	check(warden.begin_attack("warden_waterstep"),"actual waterstep starts")
	check(warden.water.wash_goal.x>=warden.combat_space.x(350) and warden.water.wash_goal.x<=warden.combat_space.x(1030),"waterstep never clamps to lab world coordinates")
	check(absf(warden.water.wash_goal.y-900)<1.0,"waterstep lands on actual floor")
	f.encounter.clear_room()
	f.host.streaming.free()

func test_retreat_exits_without_erasing_other_finished_bodies() -> void:
	var f:=fixture()
	var defeated: EnemyLabEnemy=f.encounter.spawn(config("shell_guard"))
	await physics_frames(10)
	f.encounter.end_combat("surrender")
	f.encounter.clear(true)
	check(f.encounter.has_body("shell_guard"),"surrendered identity remains available")
	var retreating: EnemyLabEnemy=f.encounter.spawn(config("forager"))
	await physics_frames(10)
	f.encounter.end_combat("retreat")
	f.encounter.clear(true)
	check(not f.encounter.has_body("forager"),"retreat is not a corpse or stationary actor")
	check(f.encounter.has_body("shell_guard"),"retreat does not erase earlier surrendered body")
	check(not retreating.is_in_group("tide_targets") and retreating.collision_layer==0,"retreat transition has no attack/collision")
	await physics_frames(60)
	check(not is_instance_valid(retreating),"retreat presentation is reclaimed after fade")
	check(is_instance_valid(defeated),"other completed body survives retreat reclamation")
	f.encounter.clear_room()
	f.host.streaming.free()
