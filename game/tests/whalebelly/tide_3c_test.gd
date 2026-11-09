@warning_ignore_start("untyped_declaration")
extends SceneTree
var demo: Node2D
var p: TidePlayer
var checks: Array = []
func _initialize() -> void: call_deferred("run_tests")
func check(name:String,condition:bool,details:Variant=null) -> void:
	checks.append({"name":name,"pass":condition,"details":details})
	print("PASS " if condition else "FAIL ",name," ",details)
func frames(n:int) -> void:
	for i in range(n):await physics_frame
func tap(action:String,hold:int=1) -> void:
	Input.action_press(action);await frames(hold);Input.action_release(action);await frames(1)
func reset_at(pos:Vector2=Vector2(180,850)) -> void:
	for a in InputMap.get_actions():
		if str(a).begins_with("tp_"):Input.action_release(a)
	p.respawn();p.position=pos;p.invulnerable=0;p.state_duration=0;p.hitstop=0
	await frames(5)
func jump_peak(hold:int) -> float:
	await reset_at()
	var ground:float=p.position.y
	var peak:float=ground
	Input.action_press("tp_jump")
	for i in range(150):
		if i==hold:Input.action_release("tp_jump")
		await physics_frame
		peak=minf(peak,p.position.y)
	Input.action_release("tp_jump")
	return ground-peak
func run_tests() -> void:
	demo=load("res://content/whalebelly/tide_demo.tscn").instantiate();demo.show_guide=false;root.add_child(demo);current_scene=demo;p=demo.player
	await frames(10)
	check("spawn_grounded",p.is_on_floor())
	check("libraries_15x36_12fps",p.anim.get_animation_library("full").get_animation_list().size()==15 and p.anim.get_animation("full/run").track_get_key_count(0)==36 and is_equal_approx(p.anim.get_animation("full/run").step,1.0/12))
	check("animation_tree_active",p.tree.active and p.playback.is_playing())
	check("nearest_and_collision",p.body.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST and p.get_node("CollisionShape2D").shape.size==Vector2(24,32))
	check("five_ground_wall_rays",p.get_node("Foot0") is RayCast2D and p.get_node("WallRight") is RayCast2D)
	await reset_at();Input.action_press("tp_right");await frames(12)
	check("movement_speed",absf(p.velocity.x-180)<1,p.velocity.x)
	check("run_animation",p.state=="run" and p.body.texture!=null)
	Input.action_release("tp_right");await frames(12);check("friction_stops",absf(p.velocity.x)<.1)
	var high:float=await jump_peak(100);var low:float=await jump_peak(1)
	check("variable_jump_heights",high>450 and high<500 and low>290 and low<340,{"high":high,"short":low})
	await reset_at();await tap("tp_jump",5);await tap("tp_jump");check("double_jump",p.jump_count==2 and p.state=="strike_02" and p.velocity.y<0,p.velocity.y)
	await frames(8);var before:int=p.jump_count;await tap("tp_jump");check("no_third_jump",p.jump_count==before)
	await reset_at();p.position=Vector2(180,820);p.velocity=Vector2(0,380);p.coyote=0;p.jump_count=2;await frames(1);await tap("tp_jump");await frames(9);check("landing_input_buffer",p.velocity.y<0,{"vy":p.velocity.y,"buffer":p.jump_buffer})
	await reset_at();p.position.y-=5;await frames(2);p.coyote=.06;p.jump_count=2;await tap("tp_jump");check("coyote_jump",p.velocity.y<0 and p.jump_count==1)
	await reset_at();var x:float=p.position.x;await tap("tp_dash");await frames(10);check("dash_distance",p.position.x-x>125 and p.position.x-x<155,p.position.x-x)
	check("dash_cooldown",p.cooldowns.dash>0)
	await reset_at();p.invulnerable=0;await tap("tp_dash");check("dash_invulnerability",not p.take_damage(15,Vector2.ZERO) and p.health==100)
	await reset_at();await tap("tp_slit");check("slit_priority_and_invulnerability",p.state=="A5_slit" and not p.take_damage(15) and p.cooldowns.slit>1.9)
	await reset_at();p.position=Vector2(113,700);p.velocity=Vector2(0,200);Input.action_press("tp_left");await frames(10);check("wall_slide",p.velocity.y<=60.1 and p.velocity.y>0 and not p.is_on_floor() and p.get_node("WallLeft").is_colliding(),p.velocity)
	await tap("tp_jump");check("wall_jump",p.velocity.x>100 and p.velocity.y<0,p.velocity);Input.action_release("tp_left")
	await reset_at(Vector2(459,850));p.soul=0;var target:Node=demo.targets[0];target.health=100;await tap("tp_attack");await frames(5);check("no_early_damage",target.health==100)
	await frames(9);check("melee_one_hit_and_soul",target.health==90 and p.soul==11,{"target":target.health,"soul":p.soul})
	await frames(12);check("melee_recovery_end",p.state_duration==0)
	await reset_at();p.request_action("strike_01");check("no_early_dash_cancel",not p.request_action("A1_dash"));await frames(19);check("late_dash_cancel",p.request_action("A1_dash"))
	await reset_at(Vector2(420,850));target.health=100;await tap("tp_orb");await frames(30);check("orb_cost_damage",p.soul==66 and target.health==80,{"hp":target.health,"soul":p.soul})
	await reset_at(Vector2(450,850));target.health=100;await tap("tp_heavy");await frames(22);check("heavy_cost_damage",p.soul==66 and target.health==85,{"hp":target.health,"soul":p.soul})
	await reset_at();p.soul=0;check("insufficient_soul",not p.request_action("A4_parry") and p.soul==0)
	await reset_at();p.health=10;p.request_action("recover");await frames(95);check("heal_complete",p.health==100 and p.soul==66)
	await reset_at();p.health=50;p.request_action("recover");await frames(20);p.invulnerable=0;p.take_damage();await frames(100);check("heal_interrupt_no_refund",p.health==35 and p.soul==33,{"hp":p.health,"soul":p.soul})
	await reset_at();check("hurt_and_soul",p.take_damage() and p.health==85 and p.soul==66);check("hurt_invulnerability",not p.take_damage() and p.health==85)
	await reset_at(Vector2(490,790));p.jump_count=2;target.health=100;p.cooldowns.dash=.5;p.velocity.y=150;p.request_action("A3_anchor");await frames(22);check("pogo_refills_mobility",target.health==90 and p.velocity.y<0 and p.jump_count==0,{"hp":target.health,"vy":p.velocity.y,"jumps":p.jump_count})
	await reset_at(Vector2(320,850));await frames(5);await tap("tp_interact");await frames(35);check("interact_signal",demo.interact_count==1)
	await reset_at();p.take_damage(100,Vector2.ZERO,true);check("death_input_lock",p.state=="defeat" and not p.request_action("A1_dash"));await frames(185);check("death_signal_and_ui",p.dead_signal_sent and demo.hud.death.visible)
	p.respawn();await frames(2);check("respawn_resources",p.health==100 and p.soul==99 and p.cooldowns.dash==0 and p.position.distance_to(p.spawn_point)<2)
	check("ui_signal_sync",demo.hud.health_value==100 and demo.hud.soul_value==99)
	check("respawn_hides_death_ui",not demo.hud.death.visible)
	check("camera_bounds",demo.camera.limit_right==1200 and demo.camera.limit_bottom==1100)
	await reset_at()
	var key:=InputEventKey.new();key.physical_keycode=KEY_L;key.pressed=true;Input.parse_input_event(key);await frames(2)
	check("physical_key_mapping_dash",p.state=="A1_dash")
	key=InputEventKey.new();key.physical_keycode=KEY_L;key.pressed=false;Input.parse_input_event(key)
	await reset_at();p.request_action("strike_01");Input.action_press("tp_right");var moving_start:float=p.position.x;await frames(8);Input.action_release("tp_right");check("move_while_attacking",p.position.x>moving_start+8 and p.state=="strike_01")
	check("independent_lower_body_layer",p.get_node("Visual/Legs").visible and p.get_node("Visual/Legs").texture!=null and p.lower_frame>=6 and p.lower_frame<=29,p.lower_frame)
	check("loaded_all_action_textures",p.textures.size()==15 and p.effect_textures.size()==5,p.textures.size())
	check("action_display_matches_state",p.display_action==p.state)
	demo.hud.guide_path="user://whalebelly/tide_guide_automated_test.cfg";demo.hud._show_guide();check("guide_locks_controls",not p.controls_enabled)
	var enter:=InputEventKey.new();enter.physical_keycode=KEY_ENTER;enter.pressed=true;demo.hud._input(enter);await frames(12)
	var config:=ConfigFile.new();var status:=config.load(demo.hud.guide_path);check("guide_persists_read",status==OK and config.get_value("guide","read",false) and p.controls_enabled)
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/qa/whalebelly/evidence/tide-3c/runtime.png")
	var failures:int=checks.filter(func(c):return not c.pass).size()
	var out:String="res://build/qa/whalebelly/tide-main-integration/core-tests.json" if DirAccess.dir_exists_absolute("res://build/qa/whalebelly/tide-main-integration") else "res://build/qa/whalebelly/evidence/tide-3c/tests.json"
	var f:=FileAccess.open(out,FileAccess.WRITE)
	if f==null:push_error("Cannot write test evidence: "+str(FileAccess.get_open_error()));quit(2);return
	f.store_string(JSON.stringify({"checks":checks,"failed":failures},"\t"));f.close()
	print("TIDE_TESTS_COMPLETE ",checks.size()," checks; failures=",failures)
	quit(1 if failures else 0)
