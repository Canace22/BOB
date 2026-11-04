extends SceneTree
## Current main-scene atlas contract; old fixed-84-frame run is no longer the display owner.
var host: Node2D
var checks: Array[Dictionary] = []
const OUT: String = "res://build/qa/action36/run"

func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
	for i: int in n: await physics_frame
func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"name":label,"pass":ok,"detail":detail})
	print("RUN_CHECK ", label, " ", ok, " ", detail)
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label + ".png"))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(45)
	var p: TidePlayer = host.player
	var visual: TideActionVisual = p.run_visual
	check("runtime_manifest_has_run", visual.manifest.has("run"))
	if not visual.manifest.has("run"):
		await host.graceful_quit(1)
		return
	var spec: Dictionary = visual.manifest.run
	var frames: Array[Texture2D] = visual.load_clip("run").body
	check("variable_frame_contract", frames.size() == int(spec.frame_count) and frames.size() > 2 and float(spec.fps)>0.0)
	check("run_is_loop", bool(spec.loop))
	var transparent: bool = true
	for frame: Texture2D in frames:
		var image: Image = frame.get_image()
		transparent = transparent and image.detect_alpha() != Image.ALPHA_NONE
	check("transparent_frames", transparent)
	check("idle_single_body", visual.current_key=="idle" and visual.sprite.visible and not p.body.visible)
	var start: Vector2 = p.position
	Input.action_press("tp_right")
	await tick(18)
	check("movement_selects_run", visual.current_key=="run" and visual.sprite.visible and not p.body.visible and p.position.x>start.x+30)
	check("gait_uses_travelled_distance", visual.phase>0.0)
	await capture("game-run-right")
	var held: Texture2D = visual.sprite.texture
	paused = true
	await create_timer(.3,true).timeout
	check("pause_holds_frame", visual.sprite.texture==held)
	paused = false
	await tick(10)
	check("resume_advances", visual.sprite.texture!=held)
	Input.action_release("tp_right")
	await tick(22)
	check("stop_restores_idle", p.animation_state=="idle" and visual.current_key=="idle" and visual.sprite.visible and not p.body.visible)
	Input.action_press("tp_left")
	await tick(12)
	check("left_facing_run", visual.current_key=="run" and p.get_node("Visual").scale.x<0)
	await capture("game-run-left")
	Input.action_release("tp_left")
	await tick(20)
	Input.action_press("tp_jump")
	await tick(3)
	Input.action_release("tp_jump")
	check("jump_replaces_run", visual.current_key=="jump" and visual.sprite.visible and not p.body.visible)
	await tick(110)
	Input.action_press("tp_right")
	await tick(10)
	Input.action_press("tp_attack")
	await tick(2)
	Input.action_release("tp_attack")
	check("attack_single_full_body", visual.current_key=="strike1" and visual.sprite.visible and not p.body.visible and not p.get_node("Visual/Legs").visible)
	Input.action_release("tp_right")
	await tick(30)
	host.reference_visible = true
	await tick(2)
	check("reference_mode_hides_animation", not visual.sprite.is_visible_in_tree())
	host.reference_visible = false
	await tick(3)
	var wall: StaticBody2D = StaticBody2D.new()
	var collision: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(20,200)
	collision.shape = box
	wall.add_child(collision)
	wall.position = p.position+Vector2(35,-60)
	host.add_child(wall)
	Input.action_press("tp_right")
	await tick(30)
	var blocked_at: Vector2 = p.position
	var blocked_phase: float = visual.phase
	await tick(18)
	check("wall_stops_gait", p.position.distance_to(blocked_at)<.1 and (visual.current_key!="run" or is_equal_approx(visual.phase,blocked_phase)))
	Input.action_release("tp_right")
	wall.queue_free()
	await tick(5)
	host.load_room(1)
	await tick(35)
	check("room_change_keeps_atlas_system", is_instance_valid(host.player.run_visual.sprite) and host.player.run_visual.manifest.has("run"))
	var failures: int = checks.filter(func(c: Dictionary) -> bool: return not c.pass).size()
	FileAccess.open(OUT.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	await host.graceful_quit(1 if failures else 0)
