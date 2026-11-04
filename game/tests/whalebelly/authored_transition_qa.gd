extends SceneTree
var host: WhalebellyMain
var checks: Array[Dictionary]=[]
var edge: String="E02"
func _initialize() -> void:call_deferred("run")
func step(n: int) -> void:
	for i: int in range(n):await physics_frame
func check(id: String,passed: bool,detail: Variant=null) -> void:
	checks.append({"id":id,"pass":passed,"detail":detail})
	print("PASS " if passed else "FAIL ",id," ",detail)
func walk(target: float) -> bool:
	Input.action_press("right" if host.connected_world.snapshot().world_x<target else "left")
	for i: int in range(750):
		if absf(host.connected_world.snapshot().world_x-target)<18:
			host.release_controls();return true
		await physics_frame
	host.release_controls();return false
func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--edge="):edge=arg.trim_prefix("--edge=")
	var source: int=2 if edge=="E03" else 1
	var shift: float=2184 if edge=="E03" else 0
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host;await step(35)
	var world: XumenConnectedWorld=host.connected_world
	var art: XumenAuthoredTransitions=world.authored
	check("unchanged_26_collision_instances",world.passages.supports==26)
	check(edge+"_old_floor_removed",not world.passages.get_node("Floor_"+edge).has_node("PaintedFloor"))
	check(edge+"_all_plates_loaded",art.parts[edge].size()==3 and art.parts[edge].ground.texture!=null)
	# Explicit starting fixture; crossing itself uses the existing input and physics.
	host.load_room(source,[1450,600 if source==2 else 715]);await step(20)
	var id: int=host.player.get_instance_id()
	check(edge+"_forward_actual_input",await walk(4610+shift),world.snapshot())
	check(edge+"_arrive_same_player",host.room_index==source+1 and host.player.get_instance_id()==id)
	check(edge+"_reverse_actual_input",await walk(3610+shift),world.snapshot())
	check(edge+"_return_same_player",host.room_index==source and host.player.get_instance_id()==id)
	check("no_dissolve",not host.continuity.transition.active)
	var before: float=art.elapsed
	paused=true;await create_timer(.2,true).timeout
	check("shared_clock_paused",art.elapsed==before)
	paused=false;await step(12);check("shared_clock_resumed",art.elapsed>before)
	art.update_at(0);var fish_at: Vector2=art.schools[0].sprites[0].position
	art.update_at(2);check("fish_body_and_route",art.schools[0].sprites[0].position!=fish_at and art.schools[0].sprites[0].hframes==8)
	art.update_at(180);check("bubbles_bounded_recycled",art.emitters[0].bubbles.size()==4 and art.emitters[0].recycled>0)
	art.update_at(host.clock)
	check("boss_gate_preserved",not world.passages.unlocked(world.layout.edges[3]))
	# Leave the QA save at an actual camp for the following independent process.
	host.load_room(0,[110,610]);await step(25)
	host.release_controls();Input.action_press("interact");await step(1)
	Input.action_release("interact");await step(65)
	check("camp_written_for_independent_reload",host.last_save_ok and host.checkpoint.room==0 and host.checkpoint.pos.size()==2)
	var failed: int=checks.filter(func(c: Dictionary)->bool:return not c.pass).size()
	var file:=FileAccess.open("res://build/qa/xumen-transitions/"+edge+"-qa.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(checks,"\t"));file.close()
	print("AUTHORED_COMPLETE checks=",checks.size()," failed=",failed)
	await host.graceful_quit(1 if failed else 0)
