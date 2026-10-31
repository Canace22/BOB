@warning_ignore_start("untyped_declaration")
class_name WhalebellyIdlePreview
extends Node2D
## Isolated animation review at source scale and the actual gameplay footprint.
const FRAMES: SpriteFrames = preload("res://art/whalebelly/runtime/tide-picker-idle-v03/idle.tres")
var actors: Array[AnimatedSprite2D] = []
var stopped := false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("182e38"))
	var label := Label.new()
	label.text = "拾潮者 · 提灯守望 IDLE  |  6 秒循环 / 12 FPS / 70 帧\n空格暂停   →逐帧   A/D转向   1正常速度   2慢放\n完整原画 + 视频运动烘焙；下方小角色为关卡尺寸"
	label.position = Vector2(40,25)
	label.add_theme_font_size_override("font_size",23)
	add_child(label)
	for i: int in range(4):
		var actor := AnimatedSprite2D.new()
		actor.sprite_frames = FRAMES
		actor.centered = false
		actor.offset = Vector2(-128,-300)
		actor.position = Vector2(340 if i%2==0 else 940,510 if i<2 else 670)
		actor.scale = Vector2.ONE*(1.15 if i<2 else 94.0/261.0)
		add_child(actor)
		actor.play(&"idle")
		actors.append(actor)
	queue_redraw()
	if "--idle-capture" in OS.get_cmdline_user_args(): capture_loop()

func _draw() -> void:
	draw_rect(Rect2(650,160,580,540),Color("dfdfd5"))
	for y: float in [510.0,670.0]:
		draw_line(Vector2(60,y),Vector2(620,y),Color("60818a"))
		draw_line(Vector2(660,y),Vector2(1220,y),Color("667175"))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo(): return
	if event.keycode==KEY_SPACE:
		stopped = not stopped
		for actor: AnimatedSprite2D in actors:
			if stopped: actor.pause()
			else: actor.play()
	if event.keycode==KEY_RIGHT:
		stopped = true
		for actor: AnimatedSprite2D in actors:
			actor.pause()
			actor.frame = (actor.frame+1)%FRAMES.get_frame_count(&"idle")
	if event.keycode in [KEY_A,KEY_D]:
		for actor: AnimatedSprite2D in actors: actor.flip_h = event.keycode==KEY_A
	if event.keycode in [KEY_1,KEY_2]:
		for actor: AnimatedSprite2D in actors: actor.speed_scale = 1.0 if event.keycode==KEY_1 else 0.25

func capture_loop() -> void:
	var folder := "res://build/qa/whalebelly/evidence/idle-v03"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	await get_tree().create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder.path_join("preview.png"))
	await get_tree().create_timer(12.0).timeout
	get_tree().quit()
