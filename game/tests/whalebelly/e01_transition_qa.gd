extends SceneTree
var host: WhalebellyMain
var checks: Array[Dictionary]=[]
var route: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func step(n: int) -> void:
	for i: int in range(n):await physics_frame
func check(id: String,passed: bool,detail: Variant=null) -> void:
	checks.append({"id":id,"pass":passed,"detail":detail})
	print("PASS " if passed else "FAIL ",id," ",detail)
func walk(x: float) -> bool:
	var action: String="right" if host.connected_world.snapshot().world_x<x else "left"
	Input.action_press(action)
	for i: int in range(800):
		var state: Dictionary=host.connected_world.snapshot()
		if i%6==0:route.append(state)
		if absf(state.world_x-x)<15:host.release_controls();return true
		await physics_frame
	host.release_controls();return false
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host;await step(30)
	var world: XumenConnectedWorld=host.connected_world
	var e: XumenE01Transition=world.e01
	check("original_collision26",world.passages.supports==26,world.passages.supports)
	check("E01_old_tiled_floor_removed",not world.passages.get_node("Floor_E01").has_node("PaintedFloor"))
	check("neighbour_actor_prepared_once",world.contexts.has(1) and world.contexts[1].enemies.size()==1)
	var actor_id: int=world.contexts[1].enemies[0].actor.get_instance_id()
	check("asset_counts",e.parts.size()==4 and e.fronds.size()==3 and e.schools.size()==2 and e.emitters.size()==2,e.snapshot())
	var audio_id: int=world.ambience.get_instance_id()
	check("single_chapter_audio",world.ambience.playing and root.find_children("WaterAmbience","AudioStreamPlayer",true,false).is_empty())
	var same: int=host.player.get_instance_id()
	check("forward_real_input",await walk(2450))
	check("same_player_actor_and_no_dissolve",host.room_index==1 and host.player.get_instance_id()==same and world.contexts[1].enemies[0].actor.get_instance_id()==actor_id and not host.continuity.transition.active)
	check("reverse_real_input",await walk(1450))
	check("same_player_reverse",host.room_index==0 and host.player.get_instance_id()==same)
	var before: float=e.elapsed
	paused=true;await create_timer(.25,true).timeout
	check("pause_holds_clock",e.elapsed==before)
	paused=false;await step(12)
	check("resume_clock",e.elapsed>before)
	check("audio_identity_survives_round_trip",audio_id==world.ambience.get_instance_id() and world.ambience.playing)
	# Explicit boundary fixture: compare same instant, without physics/time advancement.
	host.player.position=Vector2(2170,631.847)-world.origin
	host.camera.position=host.player.position+Vector2(85,-175)
	host.camera.follow_anchor=host.player.position
	var camera_before: Vector2=host.camera.position+world.origin
	var velocity_before:=Vector2(155,-32)
	host.player.velocity=velocity_before
	host.player.world_effects._spawn_impact(host.player.global_position-Vector2(0,60),1,false)
	var fx: Dictionary=host.player.world_effects.particles[-1]
	var fx_world: Vector2=fx.node.global_position+world.origin
	var orb: WhalebellyTideOrb=load("res://src/campaign/tide_orb.gd").new()
	orb.caster=host.player;host.player.get_parent().add_child(orb)
	orb.global_position=host.player.global_position-Vector2(0,90)
	var orb_world: Vector2=orb.global_position+world.origin
	var clock_before: float=e.elapsed
	world.switching=true;world.load_room(1,[],true)
	check("camera_rebase_error_le1",(host.camera.position+world.origin-camera_before).length()<=1)
	check("speed_preserved",host.player.velocity==velocity_before)
	check("FX_world_position_and_age_preserved",fx.node.global_position+world.origin==fx_world and fx.time==0)
	check("orb_world_position_and_life_preserved",is_instance_valid(orb) and not orb.is_queued_for_deletion() and orb.global_position+world.origin==orb_world and orb.life==1.5)
	check("motion_phase_not_reset",e.elapsed==clock_before)
	check("orb_persistent_owner",orb.get_parent()==world.persistent_projectiles)
	# Deterministic two-cycle checks, isolated from unrelated room animation.
	e.update_at(3.25);var pose: int=e.fronds[0].frame
	e.update_at(11.25);check("flex_two_full_loops",e.fronds[0].frame==pose)
	e.update_at(0);e.update_at(180)
	check("bounded_recycling",e.emitters[0].bubbles.size()==5 and e.emitters[0].recycled>0,e.emitters[0].recycled)
	var first: Vector2=e.schools[0].sprites[0].position;e.update_at(182)
	check("fish_have_local_action_and_path",e.schools[0].sprites[0].position!=first and e.schools[0].sprites[0].hframes==8)
	e.update_at(host.clock)
	host.release_controls()
	check("chapter_audio_loop_configured",(world.ambience.stream as AudioStreamWAV).loop_mode==AudioStreamWAV.LOOP_FORWARD)
	# An ability fixture authorizes dash for this test only; never write it to formal progress.
	host.qa_full_abilities=true
	host.load_room(0,[1600,632]);await step(20)
	host.player.position=Vector2(2110,631.847)
	host.player.velocity=Vector2.ZERO
	await step(4)
	var jumping: bool=false
	Input.action_press("right");Input.action_press("jump");await step(7);Input.action_release("jump")
	Input.action_press("dash");await step(1);Input.action_release("dash")
	for i: int in range(110):
		if host.room_index==1 and host.player.velocity.y!=0:jumping=true
		await physics_frame
	host.release_controls()
	check("air_dash_crossing_fixture",host.room_index==1 and jumping,world.snapshot())

	var f:=FileAccess.open("res://build/qa/xumen-e01/qa.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"route":route,"scope":"Actual input forward/reverse; explicit isolated boundary FX fixture and deterministic loop checks separately labelled"},"\t"));f.close()
	var failures: int=checks.filter(func(c: Dictionary) -> bool:return not c.pass).size()
	print("E01_COMPLETE checks=",checks.size()," failed=",failures)
	await host.graceful_quit(1 if failures else 0)
