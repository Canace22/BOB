@warning_ignore_start("untyped_declaration")
extends SceneTree
const OUT="res://build/qa/whalebelly/evidence/baleen_wan22/main-current/"
var host:Node2D
var checks:Array=[]
func _initialize()->void:run.call_deferred()
func tick(n:int)->void:
	for i in n:await physics_frame
func check(id:String,ok:bool)->void:checks.append({"id":id,"pass":ok})
func shot(name:String)->void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run()->void:
	DirAccess.make_dir_recursive_absolute(OUT)
	host=load("res://content/whalebelly/main.tscn").instantiate();host.qa=true;host.integration_external_test=true;root.add_child(host);current_scene=host
	await tick(45)
	var env=host.scenery.get_node("ReferenceEnvironment")
	check("main_uses_wan_atlas",env.get_node("BALEEN-CENTER").texture.resource_path.begins_with("res://art/whalebelly/baleen_wan22/"))
	check("main_single_player",not env.has_node("CHARACTER"))
	var start=host.player.position
	Input.action_press("tp_right");await tick(90);Input.action_release("tp_right");await tick(8)
	check("current_controller_walks",host.player.position.x>start.x+100)
	await shot("walk")
	var elapsed=env.elapsed;paused=true;await create_timer(.25,true).timeout
	check("pause_holds_environment",env.elapsed==elapsed);paused=false;await tick(12)
	check("resume_advances_environment",env.elapsed>elapsed)
	var y=host.player.position.y
	Input.action_press("tp_jump");await tick(12);Input.action_release("tp_jump")
	check("current_controller_jumps",host.player.position.y<y-20);await shot("jump");await tick(90)
	host.load_room(1);await tick(30);check("other_room_retains_art",not host.scenery.has_node("ReferenceEnvironment"))
	host.load_room(0);await tick(30)
	check("return_reloads_wan_environment",host.scenery.get_node("ReferenceEnvironment/BALEEN-LEFT").frame_count==36)
	await shot("return")
	var failed=checks.filter(func(c):return not c.pass)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed.size(),"scope":"current controller movement and environmental integration; room transition explicitly loaded, not door traversal"},"\t"))
	print("WAN_MAIN ",JSON.stringify(checks));host.release_controls();await host.graceful_quit(0 if failed.is_empty() else 1)
