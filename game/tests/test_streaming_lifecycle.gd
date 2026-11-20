extends TestSuite

func world() -> WhalebellyMain:
	var host: WhalebellyMain = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.integration_external_test = true
	add(host)
	await physics_frames(5)
	for i: int in 300:
		if host.streaming.is_ready(1): break
		await tree.process_frame
	return host

func test_crossing_preserves_actor_controls_state_and_world_transform() -> void:
	var host: WhalebellyMain = await world()
	check(host.streaming.is_ready(1),"Adjacent scene must be ready")
	var actor: WhalebellyCampaignPlayer = host.player
	var controller: TideSkillController = actor.skill_controller
	var identity: int = actor.get_instance_id()
	actor.health=3
	actor.soul=55
	actor.velocity=Vector2(340,-150)
	actor.cooldowns.dash=0.47
	actor.grapple_target=Vector2(1500,400)
	var target_world: Vector2 = host.actor_frame.to_global(actor.grapple_target)
	var safe_world: Vector2 = host.actor_frame.to_global(actor.last_safe)
	var position: Vector2 = actor.global_position
	host.streaming._cross(1)
	eq(host.player.get_instance_id(),identity,"Ordinary crossing never recreates the actor")
	eq(actor.skill_controller,controller,"Controller survives without exit-tree disposal")
	eq(controller.actor,actor,"Controller remains bound to its actor")
	check(actor.global_position.distance_to(position)<0.001,"World position is continuous within floating point precision")
	eq(actor.velocity,Vector2(340,-150),"Velocity is not cleared")
	eq([actor.health,actor.soul],[3,55],"Vitals are not reset")
	eq(actor.cooldowns.dash,0.47,"Cooldown survives unchanged")
	check(host.actor_frame.to_global(actor.grapple_target).is_equal_approx(target_world),"Grapple target retains its world point")
	check(host.actor_frame.to_global(actor.last_safe).is_equal_approx(safe_world),"Safe point retains its world point")
	check(not actor.transition_locked and not host.continuity.transition.active,"No fade or input lock")
	check(host.visited.has("R1-02"),"Discovery happens on actual activation")
	host.streaming._cross(0)
	eq(host.player.get_instance_id(),identity,"Immediate return also preserves actor")

func test_conditions_and_loading_are_physical_gate_inputs() -> void:
	var host: WhalebellyMain = await world()
	host.qa_full_abilities=false
	var gates: CampaignStreamingGates = host.streaming.gates
	check(not gates.reason(3,4,{"ability":"boss"}).is_empty(),"Boss door stays restricted")
	host.defeated["R1-04:0"]=true
	check(not gates.reason(3,4,{"ability":"boss"}).contains("守关"),"Victory removes Boss restriction")
	check(gates.reason(7,11,{"requires":["pressure"]}).contains("潮压"),"Mark condition is retained")
	host.abilities.pressure=true
	check(not gates.reason(7,11,{"requires":["pressure"]}).contains("潮压"),"Grant removes mark restriction")
	check(not gates.reason(0,18,{}).is_empty(),"Unloaded target remains closed")
	host.streaming.failed[18]=ERR_FILE_NOT_FOUND
	check(gates.reason(0,18,{}).contains("失败"),"Failed request is explained")

func test_streamed_branch_does_not_show_legacy_door_on_bind_or_wake() -> void:
	var host: WhalebellyMain = await world()
	host.qa_full_abilities=false
	host.abilities.float=false
	var neighbor: CampaignDoorway = host.streaming.cached[1].scene.get_node("Doorways/Entrance3")
	check(not neighbor.visible,"Prepared branch doorway is hidden before its first active frame")
	host.streaming._cross(1)
	var entrance: CampaignDoorway = host.scenery.get_node("Doorways/Entrance3")
	host.player.position=Vector2(300,700)
	check(not entrance.visible,"Binding cannot flash the old frame at the bone stair")
	await physics_frames(12)
	check(not entrance.visible,"A missing ability cannot restore the duplicate frame")
	check(host.streaming.crossing_reason(5).contains("浮"),"The real branch gate still requires float")
	host.abilities.float=true
	for i: int in 300:
		if host.streaming.is_ready(5): break
		await tree.process_frame
	await physics_frames(2)
	check(not entrance.visible,"Unlocking float keeps the old frame hidden")
	eq(host.streaming.crossing_reason(5),"","The ready branch opens normally after float")
	host.streaming._cross(0)
	host.streaming._cross(1)
	check(not entrance.visible,"Returning from a sleeping room cannot flash the frame")
	# Isolated legacy-room previews still own their authored entrance art.
	host.streaming.enabled=false
	entrance.bind(host,entrance.data)
	check(entrance.visible,"Non-streaming entrance art remains available")

func test_remote_scenes_evict_and_explicit_reload_rebuilds_actor() -> void:
	var host: WhalebellyMain = await world()
	var old: int = host.player.get_instance_id()
	host.load_room(18)
	check(host.player.get_instance_id()!=old,"Explicit checkpoint reload rebuilds actor")
	eq(host.room_index,18,"Reload activates requested room")
	check(not host.streaming.cached.has(0),"Old remote scene window is cleared")
	check(host.actor_frame.position==host.streaming.origin(18),"Actor frame uses checkpoint room origin")

func test_prepared_neighbor_owns_frozen_enemies_without_changing_active_state() -> void:
	var host: WhalebellyMain = await world()
	var entry: Dictionary = host.streaming.cached[1]
	check(entry.initialized and not entry.enemies.is_empty(),"Neighbor actors and dynamic resources are prepared before crossing")
	var crab: CampaignCorpseCrab = entry.enemies[0].actor
	var before: float = crab.timer
	await physics_frames(12)
	eq(crab.timer,before,"Dormant AI remains frozen")
	eq(crab.collision_layer,0,"Dormant actor cannot block the active room")
	eq(host.room_index,0,"Preparation restores active room alias")
	check(host.enemies.is_empty(),"Preparation does not replace active enemy array")
	check(not host.visited.has("R1-02"),"Preloading is not exploration")

func test_respawn_rebuilds_checkpoint_room_and_releases_controls() -> void:
	var host: WhalebellyMain = await world()
	host.checkpoint={"room":1,"pos":[256,715]}
	host.abilities.float=true
	var identity: int = host.player.get_instance_id()
	await host.respawn()
	eq(host.room_index,1,"Death returns to saved room index")
	check(host.player.get_instance_id()!=identity,"Death uses explicit rebuild rather than seamless crossing")
	check(host.abilities.float,"Permanent ability survives death")
	eq(host.player.health,5,"Checkpoint restores health")
	check(not host.player.transition_locked and host.player.controls_enabled,"Respawn releases transition controls")
	check(host.actor_frame.position==host.streaming.origin(1),"Checkpoint local coordinates use the correct world frame")
