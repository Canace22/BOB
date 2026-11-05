extends "res://tests/whalebelly/connected_world_qa.gd"
## Existing physical route driver, per-edge rendered assets checked separately.
func run() -> void:
	var edge_id: String="E33"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--edge="):edge_id=arg.trim_prefix("--edge=")
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host;await step(45)
	var world: XumenConnectedWorld=host.connected_world
	var edge: Dictionary={}
	for candidate: Dictionary in world.layout.edges:
		if candidate.id==edge_id:edge=candidate
	check("all_26_original_bodies",world.passages.supports==26)
	check("branch_locked_without_ability",not world.passages.unlocked(edge))
	var art: XumenAuthoredShafts=world.shafts
	check("authored_distinct_plates",art.parts.has(edge_id) and art.parts[edge_id].size()==(13 if edge_id=="E33" else 14))
	var variants: Dictionary={}
	for node: Node in world.passages.get_children():
		if str(node.name).begins_with("Floor_"+edge_id):check(str(node.name)+"_no_old_ledge",node.get_child_count()==1)
	for item: Sprite2D in art.parts[edge_id].values():
		if "-step-" in item.name:variants[item.texture.resource_path]=true
	check("three_distinct_ledge_silhouettes",variants.size()==3)
	# Explicit ability and start fixture. No claim of earning later abilities.
	host.abilities[str(edge.ability)]=true
	host.load_room(1,[edge.points[0].x-world.layout.origins[1].x,edge.points[0].y-world.layout.origins[1].y-1]);await step(20)
	var id: int=host.player.get_instance_id()
	check("reach_lower_access",await walk_world(edge.points[1].x,300))
	check("climb_original_platforms",await climb(edge.points[-2]),world.snapshot())
	check("walk_into_upper_room",await walk_world(edge.points[-1].x+55,400))
	check("upper_room_same_player",host.room_index==edge.to and host.player.get_instance_id()==id)
	check("back_to_shaft",await walk_world(edge.points[-2].x,400))
	check("descend_original_platforms",await descend(edge.points[1]))
	check("back_to_hub",await walk_world(edge.points[0].x+(45 if edge_id=="E33" else -45),400))
	check("hub_same_player",host.room_index==1 and host.player.get_instance_id()==id)
	var time: float=art.elapsed
	paused=true;await create_timer(.2,true).timeout
	check("paused_motion",art.elapsed==time);paused=false;await step(12)
	check("resume_motion",art.elapsed>time)
	art.update_at(0);var at: Vector2=art.schools[0].sprites[0].position
	art.update_at(2);check("fish_body_and_route",art.schools[0].sprites[0].position!=at and art.schools[0].sprites[0].hframes==8)
	art.update_at(180);check("bounded_prewarmed_bubbles",art.emitters[0].bubbles.size()==6 and art.emitters[0].recycled>0)
	art.update_at(host.clock)
	check("no_crossfade",not host.continuity.transition.active)
	var f:=FileAccess.open("res://build/qa/xumen-transitions/"+edge_id+"-qa.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(checks,"\t"));f.close()
	var failed: int=checks.filter(func(c: Dictionary)->bool:return not c.pass).size()
	print("SHAFT_COMPLETE checks=",checks.size()," failed=",failed)
	await host.graceful_quit(1 if failed else 0)
