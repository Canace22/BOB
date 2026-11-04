extends SceneTree
var host: WhalebellyMain
var checks: Array[Dictionary]=[]
var player_id: int
func _initialize() -> void:call_deferred("run")
func step(count: int) -> void:
	for i: int in range(count):await physics_frame
func check(id: String,pass_value: bool,detail: Variant=null) -> void:
	checks.append({"id":id,"pass":pass_value,"detail":detail})
	print("PASS " if pass_value else "FAIL ",id," ",detail)
func walk_world(target: float, budget: int=1800) -> bool:
	var direction: String="right" if target>host.connected_world.snapshot().world_x else "left"
	Input.action_press(direction)
	for i: int in range(budget):
		var at: float=host.connected_world.snapshot().world_x
		if absf(at-target)<24:
			host.release_controls();return true
		if i%40==0:Input.action_press("attack")
		if i%40==2:Input.action_release("attack")
		if i%65==0 and host.player.is_on_wall():Input.action_press("jump")
		if i%65==30:Input.action_release("jump")
		await physics_frame
	host.release_controls();return false
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host
	await step(50)
	if "--reload-connected" in OS.get_cmdline_user_args():
		host.load_progress();host.load_room(host.room_index,host.checkpoint.pos);await step(30)
		check("independent_process_connected_save",host.room_index==0 and host.player.position.distance_to(host.point(host.checkpoint.pos))<5 and host.connected_world.chunks.size()==7,host.checkpoint)
		check("reload_control_binding",host.player.skill_controller.actor==host.player and host.player_ui.player==host.player)
		write_result("reload")
		await host.graceful_quit(0 if checks.all(func(c: Dictionary)->bool:return c.pass) else 1)
		return
	player_id=host.player.get_instance_id()
	check("seven_physical_chunks",host.connected_world.chunks.size()==7)
	check("six_physical_connections",host.connected_world.passages.supports>=6,host.connected_world.passages.supports)
	var endpoint: float=host.connected_world.layout.origins[1].x+280
	check("walk_actual_ground_01_to_02_no_interact",await walk_world(endpoint),host.connected_world.snapshot())
	check("same_player_and_motion_across_boundary",host.room_index==1 and host.player.get_instance_id()==player_id)
	check("no_snapshot_transition",not host.continuity.transition.active)
	check("return_02_to_01_no_interact",await walk_world(1430),host.connected_world.snapshot())
	check("same_player_return",host.room_index==0 and host.player.get_instance_id()==player_id)
	var before: Dictionary=host.connected_world.snapshot()
	paused=true;await create_timer(.15,true).timeout
	check("pause_holds_world",host.connected_world.snapshot().world_x==before.world_x)
	paused=false
	for edge: Dictionary in host.connected_world.layout.edges:
		if edge.ability in ["float","anchor","boss"]:check("locked_"+str(edge.id),not host.connected_world.passages.unlocked(edge))
	# Explicit room fixture for further connectors; walking is physical thereafter.
	host.load_room(1,[1450,715]);await step(25)
	check("walk_actual_ground_02_to_03",await walk_world(host.connected_world.layout.origins[2].x+270),host.connected_world.snapshot())
	check("arrived_03",host.room_index==2)
	check("walk_actual_ground_03_to_04",await walk_world(host.connected_world.layout.origins[3].x+300,1800),host.connected_world.snapshot())
	check("arrived_04",host.room_index==3)
	if host.room_index==3:
		host.health=5;host.player.health=5
		await CampaignCrabDriver.fight(host)
		host.release_controls()
		check("normal_boss_combat_in_connected_world",host.defeated.get("R1-04:0",false),host.health)
		if host.defeated.get("R1-04:0",false):
			check("walk_actual_ground_04_to_05",await walk_world(host.connected_world.layout.origins[4].x+210,1600),host.connected_world.snapshot())
			check("arrived_05",host.room_index==4)
	# Explicit ability fixtures; no claim that float/anchor are earned in this chapter.
	for edge: Dictionary in host.connected_world.layout.edges:
		if not edge.id in ["E33","E35"]:continue
		host.abilities[str(edge.ability)]=true
		host.health=5;host.player.health=5
		host.load_room(1,[edge.points[0].x-host.connected_world.layout.origins[1].x,edge.points[0].y-host.connected_world.layout.origins[1].y-1])
		await step(20)
		var begin: Vector2=edge.points[1]
		var end: Vector2=edge.points[-2]
		check("reach_shaft_"+str(edge.id),await walk_world(begin.x,300))
		var climbed: bool=await climb(end)
		check("climb_physical_platforms_"+str(edge.id),climbed,host.connected_world.snapshot())
		if climbed:
			check("enter_branch_"+str(edge.id),await walk_world(edge.points[-1].x+55,400),host.connected_world.snapshot())
			check("branch_context_"+str(edge.id),host.room_index==edge.to)
			check("return_to_shaft_"+str(edge.id),await walk_world(end.x,400))
			check("descend_return_"+str(edge.id),await descend(begin),host.connected_world.snapshot())
			check("walk_back_into_hub_"+str(edge.id),await walk_world(edge.points[0].x+(45 if edge.id=="E33" else -45),400),host.connected_world.snapshot())
			check("hub_context_after_return_"+str(edge.id),host.room_index==1)
	host.load_room(0,[110,610]);await step(30)
	Input.action_press("interact");await step(1);Input.action_release("interact");await step(45)
	check("physical_camp_connected_save",host.checkpoint.room==0 and host.checkpoint.pos.size()==2)
	var dying: int=host.player.get_instance_id()
	host.player.hurt(5,true)
	for frame: int in range(240):
		await physics_frame
		if host.player.get_instance_id()!=dying:break
	await step(30)
	check("death_respawn_connected",host.health==5 and host.room_index==0 and host.player.get_instance_id()!=dying,{"health":host.health,"state":host.player.state,"changed":host.player.get_instance_id()!=dying})
	check("respawn_skill_binding",host.player.skill_controller.actor==host.player and host.player_ui.player==host.player)
	var ghosts: Array[String]=[]
	for id: int in host.connected_world.chunks:
		var art: CanvasItem=host.connected_world.chunks[id].get_node_or_null("World/PlayerArt")
		if art!=null and art.visible:ghosts.append(str(host.rooms[id].id))
	check("reload_has_no_baked_player_duplicates",ghosts.is_empty(),ghosts)
	if DisplayServer.get_name()!="headless":
		await process_frame;await process_frame
		get_root().get_texture().get_image().save_png("res://build/qa/xumen-connected/connected-main.png")
	write_result("qa")
	var failed: int=checks.filter(func(c: Dictionary)->bool:return not c.pass).size()
	print("CONNECTED_COMPLETE checks=",checks.size()," failed=",failed)
	await host.graceful_quit(1 if failed else 0)

func write_result(name: String) -> void:
	var f:=FileAccess.open("res://build/qa/xumen-connected/"+name+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(checks,"\t"));f.close()

func climb(target: Vector2) -> bool:
	var held: int=0
	for i: int in range(1600):
		var world: Vector2=host.player.position+host.connected_world.origin
		if world.y<=target.y+20 and host.player.is_on_floor():host.release_controls();return true
		Input.action_release("left");Input.action_release("right")
		if absf(world.x-target.x)>15:Input.action_press("left" if world.x>target.x else "right")
		if held>0:
			held-=1
			if held==0:Input.action_release("jump")
		elif host.player.is_on_floor():Input.action_press("jump");held=26
		await physics_frame
	host.release_controls();return false

func descend(target: Vector2) -> bool:
	for i: int in range(1600):
		var world: Vector2=host.player.position+host.connected_world.origin
		if world.y>=target.y-22 and host.player.is_on_floor():host.release_controls();return true
		Input.action_release("left");Input.action_release("right")
		if absf(world.x-target.x)>15:Input.action_press("left" if world.x>target.x else "right")
		Input.action_press("down")
		if i%45==0:Input.action_press("jump")
		if i%45==2:Input.action_release("jump")
		await physics_frame
	host.release_controls();return false
