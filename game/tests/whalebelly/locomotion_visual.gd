extends SceneTree
var host: Node2D
var failures: int = 0
var output: String = "res://build/qa/action36/locomotion"
func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
	for i in n: await physics_frame
func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))
func visible_phase(p: TidePlayer) -> float:
	var visual: TideActionVisual = p.run_visual
	if not visual.active or visual.current_key != "jump": return -1.0
	var frames: Array[Texture2D] = visual.load_clip("jump").body
	return float(frames.find(visual.sprite.texture)) / maxf(1.0, frames.size())
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(45)
	var p: TidePlayer = host.player
	Input.action_press("tp_jump")
	await tick(4)
	check("rise_uses_takeoff_frames", visible_phase(p) >= 0.05 and visible_phase(p) <= 0.3 and p.velocity.y < 0)
	check("jump_original_color", p.run_visual.sprite.material.get_shader_parameter("flash") == 0.0)
	await shot("rise")
	var saw_fall: bool = false
	var saw_landing: bool = false
	for i in 110:
		await tick(1)
		if not saw_fall and p.velocity.y > 80:
			saw_fall = true
			check("fall_uses_descent_frames", visible_phase(p) >= 0.4 and visible_phase(p) <= 0.65)
			await shot("fall")
		if saw_fall and p.is_on_floor():
			saw_landing = p.run_visual.current_key == "jump" and visible_phase(p) >= 0.65
			await shot("landing")
			break
	Input.action_release("tp_jump")
	check("landing_recovery_visible", saw_landing)
	Input.action_press("tp_right")
	var start_x: float = p.position.x
	await tick(3)
	check("landing_does_not_lock_movement", p.position.x > start_x)
	Input.action_press("tp_attack")
	await tick(2)
	Input.action_release("tp_attack")
	check("attack_interrupts_landing", p.run_visual.current_key == "strike1" and p.run_visual.sprite.visible and not p.body.visible)
	Input.action_release("tp_right")
	await tick(45)
	check("returns_to_idle", p.run_visual.current_key == "idle")
	Input.action_press("tp_jump")
	await tick(3)
	Input.action_release("tp_jump")
	await tick(6)
	Input.action_press("tp_jump")
	await tick(2)
	Input.action_release("tp_jump")
	check("double_jump_keeps_skill_animation", p.run_visual.current_key == "double_jump")
	await tick(100)
	check("double_jump_lands_and_recovers", p.run_visual.current_key == "idle")
	print("LOCOMOTION_COMPLETE failed=", failures)
	await host.graceful_quit(1 if failures else 0)
