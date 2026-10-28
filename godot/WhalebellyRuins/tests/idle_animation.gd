extends SceneTree
## Real main-scene input regression, with isolated QA state and no player-save writes.
class TestHost:
	extends "res://scripts/main.gd"
	func run_qa() -> void: pass

var game: Node2D
var results: Array = []
var output := "res://evidence/idle-v03"

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool, detail: Variant = null) -> void:
	results.append({"name":label,"pass":passed,"detail":detail})
	print("IDLE_CHECK ",label," ",passed," ",detail)

func tick(count: int) -> void:
	for i: int in range(count): await physics_frame
	await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game = load("res://scenes/main.tscn").instantiate()
	game.set_script(TestHost)
	game.qa = true
	root.add_child(game)
	await tick(40)
	var player: CharacterBody2D = game.player
	var idle: AnimatedSprite2D = player.idle_sprite
	var frames: SpriteFrames = idle.sprite_frames
	var duration := 0.0
	var atlas_ok := true
	for i: int in range(frames.get_frame_count(&"idle")):
		duration += frames.get_frame_duration(&"idle", i) / frames.get_animation_speed(&"idle")
		var texture: Texture2D = frames.get_frame_texture(&"idle",i)
		var image: Image = texture.get_image()
		var bounds: Rect2i = image.get_used_rect()
		atlas_ok = atlas_ok and image.get_size()==Vector2i(256,320) and bounds.position.x>0 and bounds.position.y>0 and bounds.end.x<256 and bounds.end.y<320
	check("transparent_full_body_atlas",atlas_ok,frames.get_frame_count(&"idle"))
	check("six_second_loop",is_equal_approx(duration,6.0) and frames.get_animation_loop(&"idle"),duration)
	check("grounded_idle_replaces_cutout",player.is_on_floor() and idle.visible and not player.art.visible and not player.sprite.visible)
	var root_before: Vector2 = player.position
	var frame_before: int = idle.frame
	await tick(30)
	check("idle_advances_without_root_motion",idle.frame!=frame_before and player.position.distance_to(root_before)<0.1)
	await capture("game-idle-a")
	await tick(115)
	await capture("game-idle-b")
	var held: int = idle.frame
	paused = true
	await create_timer(0.3,true).timeout
	check("tree_pause_holds_idle",idle.frame==held)
	paused = false
	await tick(16)
	check("resume_advances",idle.frame!=held)
	idle.frame = frames.get_frame_count(&"idle")-1
	await tick(10)
	check("loop_wraps",idle.frame<5,idle.frame)
	Input.action_press("right")
	await tick(14)
	check("idle_to_run",player.visual_state=="run" and player.sprite.visible and not idle.visible and not player.art.visible)
	await capture("game-run")
	Input.action_release("right")
	await tick(24)
	check("run_to_idle",player.visual_state=="idle" and idle.visible and idle.is_playing() and not player.sprite.visible)
	Input.action_press("left")
	await tick(10)
	Input.action_release("left")
	await tick(24)
	check("left_facing_idle",idle.visible and idle.scale.x<0)
	await capture("game-left-idle")
	Input.action_press("jump")
	await tick(3)
	Input.action_release("jump")
	check("jump_hides_idle",player.visual_state=="jump" and not idle.visible and player.sprite.visible)
	await tick(90)
	check("landing_restores_idle",player.is_on_floor() and idle.visible)
	Input.action_press("attack")
	await tick(2)
	Input.action_release("attack")
	check("attack_hides_idle",player.visual_state=="attack" and player.sprite.visible and not idle.visible)
	await tick(28)
	check("attack_recovers_idle",idle.visible and not player.sprite.visible)
	game.reference_visible = true
	await tick(2)
	check("reference_mode_keeps_authored_art",not idle.visible and player.art.visible)
	game.reference_visible = false
	await tick(3)
	check("reference_exit_restores_idle",idle.visible)
	# Shared idle scale/pivot also survive room replacement, without changing collision data.
	game.load_room(1)
	await tick(40)
	check("next_room_loads_idle",is_instance_valid(game.player.idle_sprite) and game.player.idle_sprite.sprite_frames==frames)
	var failed := 0
	for result: Dictionary in results:
		if not result["pass"]: failed += 1
	var report := {"engine":Engine.get_version_info().string,"renderer":DisplayServer.get_name(),"checks":results,"failed":failed,"user_save_written":false}
	var file := FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("IDLE_ANIMATION_QA ",results.size()," checks, ",failed," failed")
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failed==0 else 1)
