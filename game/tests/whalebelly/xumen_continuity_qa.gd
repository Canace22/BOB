extends SceneTree
## Real main-entry room/connection art verification; QA storage only.
const OUT := "res://build/qa/xumen-continuity/"
var host: WhalebellyMain
var checks: Array[Dictionary] = []
func _initialize() -> void: run.call_deferred()
func tick(frames: int) -> void:
	for i in frames: await physics_frame
func check(label: String, passed: bool, detail: Variant=null) -> void:
	checks.append({"id":label,"pass":passed,"detail":detail})
	print("CONTINUITY ",label," ",passed," ",detail)
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	host=(load("res://content/whalebelly/main.tscn") as PackedScene).instantiate()
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(25)
	if "--reload" in OS.get_cmdline_user_args():
		host.load_progress()
		host.load_room(host.room_index,host.checkpoint.pos)
		await tick(20)
		check("independent_checkpoint_reload",host.room_index==2 and host.player.is_on_floor())
		check("independent_scene_rebound",host.continuity.portals.size()==2 and host.continuity.depth!=null)
		await host.graceful_quit(0 if checks.all(func(c:Dictionary)->bool:return c.pass) else 1)
		return
	var counts: Array[int] = [1,4,2,2,1,1,1]
	var selected: Array[int] = [0,1,2,3,4,5,6]
	if "--sample" in OS.get_cmdline_user_args(): selected=[1,2]
	for index: int in selected:
		host.load_room(index)
		await tick(18)
		check(str(host.room.id)+"_portal_count",host.continuity.portals.size()==counts[index],host.continuity.state())
		check(str(host.room.id)+"_original_collision",host.scenery.has_node("World/Terrain/Surface0"))
		host.player.set_physics_process(false)
		host.set_process(false)
		host.camera.zoom=Vector2.ONE
		for portal: XumenContinuityPortal in host.continuity.portals:
			host.camera.position=Vector2(clampf(portal.base_position.x+750,640,float(host.room.size[0])-640),clampf(portal.portal_y-150,360,float(host.room.size[1])-360))
			host.camera.force_update_scroll()
			await shot(str(host.room.id)+"-"+portal.edge_id)
			var initial: float=portal.elapsed
			paused=true
			await create_timer(.15,true).timeout
			check(str(host.room.id)+portal.edge_id+"_pause",is_equal_approx(portal.elapsed,initial))
			paused=false
			await tick(8)
			check(str(host.room.id)+portal.edge_id+"_resume",portal.elapsed>initial)
			check(str(host.room.id)+portal.edge_id+"_separate_motion",portal.bubbles.bubbles.size()==4)
		host.set_process(true)
		host.player.set_physics_process(true)
		await tick(12)
	check("no_new_room_or_crosschapter_exit",host.rooms.size()==7 and int(host.rooms[4].doors[-1].to)==-1 and int(host.rooms[5].doors[-1].to)==-2)
	host.load_room(1)
	await tick(10)
	host.player.set_physics_process(false)
	host.player.position=Vector2(1600,713)
	host.enter_door(host.room.doors[1])
	await tick(20)
	check("E02_actual_door",host.room_index==2)
	check("E02_spawn_grounded",host.player.is_on_floor(),host.player.position)
	host.player_ui.open("map")
	await tick(3)
	await shot("anatomy-map")
	host.player_ui.close_all()
	await tick(4)
	host.load_room(1)
	host.player.position=Vector2(170,190)
	host.player.set_physics_process(false)
	host.qa_full_abilities=false
	host.practice=false
	host.abilities.float=false
	host.enter_door(host.room.doors[2])
	check("float_gate_remains_locked",host.room_index==1)
	host.abilities.anchor=false
	host.enter_door(host.room.doors[3])
	check("anchor_gate_remains_locked",host.room_index==1)
	# Explicit isolated checkpoint setup; gameplay-route save proof is separate.
	host.load_room(2)
	await tick(20)
	host.checkpoint={"room":2,"pos":[host.player.position.x,host.player.position.y]}
	host.save_progress(false)
	check("qa_checkpoint_saved",host.last_save_ok)
	var failed: Array=checks.filter(func(c:Dictionary)->bool:return not c.pass)
	FileAccess.open(OUT+"runtime.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed.size(),"note":"visual and pause QA with scenario placements; normal route verified separately"},"\t"))
	print("CONTINUITY_COMPLETE checks=",checks.size()," failed=",failed.size())
	await host.graceful_quit(0 if failed.is_empty() else 1)
