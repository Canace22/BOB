extends Node2D
## Asset review scene. Does not load the game, write saves, or replace PlayerArt.
const FRAMES: SpriteFrames = preload("res://assets/runtime/tide-picker-locomotion-v01/locomotion.tres")
var actors: Array[AnimatedSprite2D] = []
var stopped: bool = false
var playback_rate: float = 1.0

func _ready() -> void:
	var title := Label.new()
	title.text = "拾潮者 · IDLE / WALK / RUN    |    首版候选"
	title.position = Vector2(40, 24)
	title.add_theme_font_size_override("font_size", 30)
	add_child(title)
	var hint := Label.new()
	hint.text = "空格：暂停/播放   →：逐帧   1：正常速度   2：慢放    |    前后腿交替仍需精修；未替换主关卡"
	hint.position = Vector2(40, 76)
	add_child(hint)
	var names: Array[StringName] = [&"idle", &"walk", &"run"]
	for i: int in range(3):
		var label := Label.new()
		label.text = "%s   ·   %d FPS" % [str(names[i]).to_upper(), int(FRAMES.get_animation_speed(names[i]))]
		label.position = Vector2(80 + i * 410, 145)
		label.add_theme_font_size_override("font_size", 24)
		add_child(label)
		for miniature: bool in [false, true]:
			var sprite := AnimatedSprite2D.new()
			sprite.sprite_frames = FRAMES
			sprite.centered = false
			sprite.offset = Vector2(-256, -460)
			sprite.position = Vector2(230 + i * 410, 644 if miniature else 492)
			sprite.scale = Vector2.ONE * (94.0 / 365.0 if miniature else 0.8)
			add_child(sprite)
			sprite.play(names[i])
			actors.append(sprite)
	queue_redraw()
	if "--locomotion-capture" in OS.get_cmdline_user_args(): capture_review()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("172b35"))
	for i: int in range(3):
		draw_line(Vector2(50 + i * 410, 492), Vector2(410 + i * 410, 492), Color("627f83"))
		draw_line(Vector2(50 + i * 410, 644), Vector2(410 + i * 410, 644), Color("627f83"))

func set_stopped(value: bool) -> void:
	stopped = value
	for actor: AnimatedSprite2D in actors:
		if stopped: actor.pause()
		else: actor.play()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event is InputEventKey:
		if event.keycode == KEY_SPACE: set_stopped(not stopped)
		if event.keycode == KEY_RIGHT:
			set_stopped(true)
			for actor: AnimatedSprite2D in actors: actor.frame = (actor.frame + 1) % 8
		if event.keycode == KEY_1 or event.keycode == KEY_2:
			playback_rate = 1.0 if event.keycode == KEY_1 else 0.25
			for actor: AnimatedSprite2D in actors: actor.speed_scale = playback_rate

func capture_review() -> void:
	var folder: String = ProjectSettings.globalize_path("res://evidence/locomotion-v01")
	DirAccess.make_dir_recursive_absolute(folder)
	await get_tree().create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder.path_join("playback-a.png"))
	await get_tree().create_timer(0.42).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder.path_join("playback-b.png"))
	get_tree().quit()
