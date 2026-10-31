@warning_ignore_start("untyped_declaration")
extends SceneTree

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	var packed: PackedScene = load("res://content/whalebelly/characters/locomotion_video_preview.tscn")
	assert(packed != null)
	var scene: Node2D = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var frames: SpriteFrames = scene.FRAMES
	var total := 0
	for state: StringName in [&"idle", &"walk", &"run"]:
		var count: int = frames.get_frame_count(state)
		assert(count >= 40, "Each loop must contain a substantial continuous sequence")
		assert(frames.get_animation_loop(state))
		for i: int in range(count):
			var texture: Texture2D = frames.get_frame_texture(state, i)
			assert(texture.get_size() == Vector2(512, 512))
			var image: Image = texture.get_image()
			assert(image.get_pixel(0, 0).a == 0.0)
			assert(image.get_pixel(511, 511).a == 0.0)
			total += 1
	var actor: AnimatedSprite2D = scene.actors[0]
	actor.play(&"walk")
	actor.frame = 0
	await create_timer(0.2).timeout
	assert(actor.frame >= 3, "Playback advances")
	scene.set_stopped(true)
	var held: int = actor.frame
	await create_timer(0.15).timeout
	assert(actor.frame == held, "Pause holds frame")
	actor.frame = frames.get_frame_count(&"walk") - 1
	scene.set_stopped(false)
	await create_timer(0.12).timeout
	assert(actor.frame < 12, "Wrap at sequence end")
	actor.play(&"run")
	await create_timer(0.12).timeout
	assert(actor.animation == &"run" and actor.frame > 0)
	print("VIDEO_LOCOMOTION_QA_PASS: %d frame regions, alpha corners, playback, pause, loop, state switch" % total)
	quit(0)
