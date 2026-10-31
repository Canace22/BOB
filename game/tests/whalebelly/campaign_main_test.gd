@warning_ignore_start("untyped_declaration")
extends SceneTree
var host:Node2D
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func step(n:int) -> void:
	for i in range(n):await physics_frame
func check(name:String,ok:bool,detail:Variant=null) -> void:
	checks.append({"name":name,"pass":ok,"detail":detail});print("PASS " if ok else "FAIL ",name," ",detail)
func tap(action:String,frames:int=1) -> void:
	Input.action_press(action);await step(frames);Input.action_release(action);await step(1)
func enter(index:int,pos:Array=[]) -> void:
	host.health=5;host.player_soul=99;host.load_room(index,pos);await step(30)
func shot(name:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/qa/whalebelly/tide-main-integration/"+name+".png")
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate();host.qa=true;host.qa_full_abilities=false;host.integration_external_test=true;root.add_child(host);current_scene=host
	await step(45)
	check("main_player_baseline",host.player.max_speed==265 and host.player.max_health==5 and host.player.collision_mask==5)
	check("one_camera",root.find_children("*","Camera2D",true,false).size()==1)
	check("persistent_ui",host.player_ui.player==host.player and host.player_ui.layer==100)
	check("initial_dash_locked",not host.player.request_action("A1_dash"))
	var start:Vector2=host.player.position
	await tap("tp_right",30);await step(12)
	check("main_walk_ground",host.player.position.x>start.x+75 and host.player.is_on_floor(),[start,host.player.position])
	await shot("main-start")
	await tap("tp_jump",18)
	check("main_jump",host.player.position.y<start.y-30)
	await step(100)
	for i in range(7):
		await enter(i)
		check("room_%d_spawn"%i,host.player.health==5 and host.player.position.y<=float(host.room.size[1]) and host.player.is_on_floor(),host.player.position)
		check("room_%d_original_layers"%i,host.scenery.has_node("World") and host.scenery.has_node("Far") and host.scenery.has_node("VisualMechanisms"))
		check("room_%d_ui_rebind"%i,host.player_ui.player==host.player)
		check("room_%d_bounds"%i,host.camera.limit_right==int(host.room.size[0]) and host.camera.limit_bottom==int(host.room.size[1]))
	await enter(1)
	var enemy:Dictionary=host.enemies[0]
	host.player.position=enemy.pos+Vector2(-85,0);host.player.facing=1;host.player.soul=0;host.player.invulnerable=5
	await step(5);await tap("tp_attack");await step(24)
	check("main_short_hit_soul",enemy.hp==2 and host.player.soul==11,[enemy.hp,host.player.soul])
	host.player.soul=99;await tap("tp_orb");await step(48)
	check("main_orb_kills",not enemy.alive and host.player.soul==66,[enemy.hp,host.player.soul])
	await step(10);await tap("tp_attack");await step(24)
	check("dead_enemy_no_soul",host.player.soul==66)
	await enter(1)
	enemy=host.enemies[0];host.player.position=enemy.pos+Vector2(-52,0);host.player.invulnerable=5
	await step(3);await tap("tp_heavy");await step(35)
	check("main_heavy_damage",enemy.hp==1,enemy.hp)
	host.player.invulnerable=0;host.player.state_duration=0;host.player.hitstop=0
	var hp:int=host.player.health
	await step(125)
	check("original_enemy_attack_hurts",host.player.health<hp,[hp,host.player.health])
	check("hud_health_sync",host.player_ui.health_value==host.player.health)
	await enter(3)
	var boss:Dictionary=host.enemies[0]
	host.player.invulnerable=100
	for n in range(10):
		host.player.position=boss.pos+Vector2(-105,0);host.player.facing=1;await tap("tp_attack");await step(30)
	check("boss_unlock_and_original_save",not boss.alive and host.abilities.dash and host.defeated.get(boss.key,false),boss.hp)
	check("earned_dash",host.player.request_action("A1_dash"));await step(30)
	await shot("main-boss")
	await enter(2)
	var reward:Vector2=host.point(host.room.reward)
	host.player.position=reward;host.player.velocity=Vector2.ZERO;await tap("tp_interact");await step(40)
	check("reward_callback",host.collected.get(str(host.room.id),false))
	await enter(0)
	host.player.position=host.point(host.room.get("camp",[93,550]));host.player.health=3;host.health=3
	await step(4);await tap("tp_interact");await step(40)
	check("camp_checkpoint",int(host.checkpoint.room)==0 and host.health==5)
	var nextdoor:Dictionary=host.room.doors[0]
	for door:Dictionary in host.room.doors:
		if int(door.to)==1:nextdoor=door
	host.player.position=host.point(nextdoor.pos);host.player.velocity=Vector2.ZERO
	Input.action_press("right");await tap("tp_interact");await step(40);Input.action_release("right")
	check("original_door_callback",host.room_index==1,{"room":host.room_index,"position":host.player.position,"state":host.player.state,"locked":host.player.transition_locked,"events":host.events.slice(maxi(0,host.events.size()-8))})
	host.checkpoint={"room":0,"pos":[120,host.ground_y(120,550)]}
	host.player.invulnerable=0;host.player.take_damage(5,Vector2.ZERO,true);await step(190)
	check("death_returns_checkpoint",host.room_index==0 and host.health==5 and host.player.soul==99,[host.room_index,host.health])
	check("respawn_ui_rebound",host.player_ui.player==host.player and not host.player_ui.death.visible)
	var before:Vector2=host.player.position;paused=true;await tap("tp_right",15);paused=false
	check("pause_stops_actor",host.player.position==before)
	await enter(2,[840,620]);await step(90)
	var mech:Node=host.scenery.get_node("VisualMechanisms")
	check("original_membrane_sag",mech.membrane_drop>15,mech.membrane_drop)
	Input.action_press("down");await tap("tp_jump");Input.action_release("down");await step(45)
	check("original_membrane_dive",host.events.any(func(e):return e.get("event","")=="membrane_dive"),host.player.position)
	await step(10)
	var rebound_y:float=host.player.position.y;var rebound_peak:float=rebound_y
	await tap("tp_jump")
	for frame in range(100):await physics_frame;rebound_peak=minf(rebound_peak,host.player.position.y)
	check("membrane_rebound_returns_upper",rebound_y-rebound_peak>180 and host.player.position.y<730,[rebound_y-rebound_peak,host.player.position])
	host.practice=true;host.player.position=Vector2(600,430);host.player.velocity=Vector2(0,50)
	await tap("float",12);check("original_float",host.player.float_left<1.5,host.player.float_left)
	await enter(1)
	host.practice=true
	if host.room.get("rings",[]).size()>0:
		var ring:Vector2=host.point(host.room.rings[0])+Vector2(0,55)
		host.player.position=ring+Vector2(-160,80);host.player.facing=1
		await tap("grapple");check("original_grapple",host.player.grapple_target!=Vector2.INF,host.player.grapple_target)
		host.player.invulnerable=0;host.player.take_damage(1)
		check("hurt_interrupts_grapple",host.player.grapple_target==Vector2.INF and host.player.state=="hit")
	host.practice=false
	await enter(4,[340,570])
	var safe:Vector2=host.player.last_safe
	host.player.position=Vector2(430,730);host.player.velocity=Vector2.ZERO
	await step(10)
	check("soft_bed_safe_return",host.player.health==4 and host.player.position.distance_to(safe)<5 and host.player.is_on_floor(),[safe,host.player.position])
	check("safe_point_not_over_pit",safe.x<357)
	await enter(0);await tap("tp_right",10);Input.action_press("tp_right");await tap("tp_attack");await step(8)
	check("moving_attack_layers",host.player.get_node("Visual/Legs").visible);await shot("main-moving-attack");Input.action_release("tp_right")
	await step(30);root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800);await step(5);await shot("main-ui-16x10")
	host.player_ui._show_guide();await step(2);await shot("main-guide");host.player_ui.guide.queue_free();host.player_ui.guide=null;host.player.controls_enabled=true
	host.checkpoint={"room":3,"pos":[90,610]};host.save_progress(false)
	var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://whalebelly/artmatch_qa_save.json"))
	check("save_v6_schema",saved.version==6 and saved.abilities.dash and saved.checkpoint.room==3)
	var failed:int=checks.filter(func(c):return not c.pass).size()
	var f:=FileAccess.open("res://build/qa/whalebelly/tide-main-integration/main-tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"));f.close()
	print("MAIN_INTEGRATION_COMPLETE checks=",checks.size()," failed=",failed)
	host.graceful_quit(1 if failed else 0)
