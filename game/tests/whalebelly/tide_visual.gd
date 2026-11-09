@warning_ignore_start("untyped_declaration")
extends SceneTree
var demo:Node2D
func _initialize() -> void:call_deferred("capture")
func wait_frames(n:int) -> void:
	for i in range(n):await physics_frame
func shot(name:String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/qa/whalebelly/evidence/tide-3c/"+name+".png")
func capture() -> void:
	demo=load("res://content/whalebelly/tide_demo.tscn").instantiate();demo.show_guide=false;root.add_child(demo);current_scene=demo
	await wait_frames(40);await shot("idle-16x9")
	Input.action_press("tp_right");await wait_frames(28);await shot("run");Input.action_release("tp_right")
	Input.action_press("tp_jump");await wait_frames(24);await shot("jump");Input.action_release("tp_jump")
	await wait_frames(110)
	demo.player.position=Vector2(459,850);demo.player.facing=1;await wait_frames(5);Input.action_press("tp_attack");await wait_frames(12);await shot("strike");Input.action_release("tp_attack")
	await wait_frames(30);Input.action_press("tp_heavy");await wait_frames(18);await shot("heavy");Input.action_release("tp_heavy")
	await wait_frames(30);root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800);await wait_frames(30);await shot("ui-16x10")
	demo.hud._show_guide();await wait_frames(3);await shot("guide-16x10")
	print("TIDE_VISUAL_CAPTURE_DONE");quit()
