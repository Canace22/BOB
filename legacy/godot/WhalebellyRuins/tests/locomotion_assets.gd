extends SceneTree

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	var packed: PackedScene = load("res://scenes/characters/locomotion_preview.tscn")
	var scene: Node2D = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var frames: SpriteFrames = scene.FRAMES
	for state: StringName in [&"idle", &"walk", &"run"]:
		assert(frames.get_frame_count(state) == 8)
		assert(frames.get_animation_loop(state))
		for i: int in range(8):
			var texture: Texture2D = frames.get_frame_texture(state, i)
			assert(texture.get_size() == Vector2(512, 512))
			assert(texture.get_image().get_pixel(0, 0).a == 0.0)
	var actor: AnimatedSprite2D = scene.actors[0]
	actor.play(&"walk")
	actor.frame = 0
	await create_timer(0.35).timeout
	assert(actor.frame >= 2 and actor.frame <= 4, "Playback must advance real frames")
	scene.set_stopped(true)
	var held: int = actor.frame
	await create_timer(0.22).timeout
	assert(actor.frame == held, "Pause must hold pose")
	actor.frame = 7
	scene.set_stopped(false)
	await create_timer(0.16).timeout
	assert(actor.frame <= 1, "Loop must wrap from frame 7")
	actor.play(&"run")
	await create_timer(0.18).timeout
	assert(actor.animation == &"run" and actor.frame > 0, "State switch must play run")
	print("LOCOMOTION_QA_PASS: 24 textures, transparent corners, frame advance, pause, loop, state switch")
	quit(0)
