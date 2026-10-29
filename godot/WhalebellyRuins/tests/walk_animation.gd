extends SceneTree
var host: Node2D
var checks: Array = []
const OUT := "res://evidence/walk-v03"
func _initialize() -> void: run.call_deferred()
func tick(n:int) -> void:
	for i in range(n): await physics_frame
func check(label:String,ok:bool,detail:Variant=null) -> void:
	checks.append({"name":label,"pass":ok,"detail":detail})
	print("WALK_CHECK ",label," ",ok," ",detail)
func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host=load("res://scenes/main.tscn").instantiate()
	host.qa=true;host.integration_external_test=true
	root.add_child(host);current_scene=host
	await tick(45)
	var p:CharacterBody2D=host.player
	var walk:Node=p.walk_visual
	var frames:SpriteFrames=walk.sprite.sprite_frames
	check("84_frames_at_12_fps",frames.get_frame_count(&"walk")==84 and frames.get_animation_speed(&"walk")==12)
	var duration:=0.0;var bounds_ok:=true
	for i in range(84):
		duration+=frames.get_frame_duration(&"walk",i)/12.0
		var image:Image=frames.get_frame_texture(&"walk",i).get_image()
		var bounds:Rect2i=image.get_used_rect()
		bounds_ok=bounds_ok and image.get_size()==Vector2i(256,320) and bounds.position.x>0 and bounds.position.y>0 and bounds.end.x<256 and bounds.end.y<320
	check("seven_second_loop",is_equal_approx(duration,7.0) and frames.get_animation_loop(&"walk"))
	check("transparent_canvas_padding",bounds_ok)
	check("idle_preserved",p.animation_state=="idle" and p.body.visible and not walk.sprite.visible)
	var start:Vector2=p.position
	Input.action_press("tp_right");await tick(18)
	check("movement_selects_walk",walk.sprite.visible and not p.body.visible and p.position.x>start.x+30)
	check("fixed_12fps",walk.sprite.frame in [2,3,4],walk.sprite.frame)
	await capture("game-walk-right")
	var held:int=walk.sprite.frame
	paused=true;await create_timer(.3,true).timeout
	check("pause_holds_frame",walk.sprite.frame==held)
	paused=false;await tick(10)
	check("resume_advances",walk.sprite.frame!=held)
	Input.action_release("tp_right");await tick(22)
	check("stop_restores_idle",p.animation_state=="idle" and p.body.visible and not walk.sprite.visible)
	Input.action_press("tp_left");await tick(12)
	check("left_facing_walk",walk.sprite.visible and p.get_node("Visual").scale.x<0)
	await capture("game-walk-left")
	Input.action_release("tp_left");await tick(20)
	Input.action_press("tp_jump");await tick(3);Input.action_release("tp_jump")
	check("jump_hides_walk",not walk.sprite.visible and p.body.visible)
	await tick(110)
	Input.action_press("tp_right");await tick(10)
	Input.action_press("tp_attack");await tick(2);Input.action_release("tp_attack")
	check("attack_keeps_original_layers",not walk.sprite.visible and p.body.visible and p.animation_state=="strike_01")
	Input.action_release("tp_right");await tick(30)
	host.reference_visible=true;await tick(2)
	check("reference_mode_hides_animation",not walk.sprite.is_visible_in_tree())
	host.reference_visible=false;await tick(3)
	# Solid wall in the same live main scene: movement input must not advance a walk in place.
	var wall:=StaticBody2D.new();var collision:=CollisionShape2D.new();var box:=RectangleShape2D.new()
	box.size=Vector2(20,200);collision.shape=box;wall.add_child(collision)
	wall.position=p.position+Vector2(35,-60);host.add_child(wall)
	Input.action_press("tp_right");await tick(30)
	var blocked_at:Vector2=p.position;held=walk.sprite.frame
	await tick(18)
	check("wall_stops_walk",p.position.distance_to(blocked_at)<.1 and walk.sprite.frame==held)
	Input.action_release("tp_right");wall.queue_free();await tick(5)
	# Wrap uses the same production clock and one 1/12-second interval.
	p.animation_state="run";walk.active=true;walk.elapsed=6.99
	walk.update(.02,1.0)
	check("loop_wraps",walk.sprite.frame==0)
	await tick(3)
	host.load_room(1);await tick(35)
	check("room_change_keeps_walk",is_instance_valid(host.player.walk_visual.sprite) and host.player.walk_visual.sprite.sprite_frames==frames)
	var failures:=checks.filter(func(c):return not c.pass).size()
	var file:=FileAccess.open(OUT.path_join("checks.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));file.close()
	host.graceful_quit(1 if failures else 0)
