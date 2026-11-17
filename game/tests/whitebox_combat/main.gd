extends Node2D
## 独立、无存档白盒；几何体仅用于判定调试，不是正式美术。

var player: CombatWhiteboxPlayer
var enemy: CombatWhiteboxEnemy
var hud: Label
var event_hud: Label
var timeline: CombatWhiteboxTimeline
var events: Array[String] = []
var time: float = 0.0
var log_lines: PackedStringArray = []
var log_timer: float = 0.0
var title_set: bool = false
var extra_targets: Array[CombatWhiteboxEnemy] = []
var frame_stamp: int = 0
var frame_ms: float = 0.0
var peak_frame_ms: float = 0.0

func _ready() -> void:
	DisplayServer.window_set_title("BOB Combat Whitebox - Backstep")
	RenderingServer.set_default_clear_color(Color("151c29"))
	_make_floor(Rect2(0,540,1280,45))
	_make_floor(Rect2(-20,0,20,540))
	_make_floor(Rect2(1280,0,20,540))
	var actor: Node = preload("res://content/whalebelly/Player.tscn").instantiate()
	actor.set_script(preload("player.gd"))
	player = actor as CombatWhiteboxPlayer
	player.position = Vector2(550,540)
	add_child(player)
	enemy = CombatWhiteboxEnemy.new()
	enemy.player = player
	enemy.position = Vector2(650,540)
	add_child(enemy)
	enemy.resolved.connect(record)
	player.backstep_started.connect(func() -> void: record("BACKSTEP: cancel, no added i-frames"))
	player.animation_tag.connect(func(tag: String) -> void: record(tag))
	player.damaged.connect(func() -> void: record("DAMAGE: hp=%d" % player.health))
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(24,18)
	hud.add_theme_font_size_override("font_size",13)
	canvas.add_child(hud)
	event_hud = Label.new()
	event_hud.position = Vector2(24,608)
	event_hud.add_theme_font_size_override("font_size",15)
	canvas.add_child(event_hud)
	timeline = CombatWhiteboxTimeline.new()
	timeline.player = player
	timeline.enemy = enemy
	timeline.position = Vector2(24,220)
	timeline.size = Vector2(1232,190)
	canvas.add_child(timeline)
	record("READY: isolated whitebox; no campaign save")
	if OS.get_cmdline_user_args().has("--capture-animation"):
		add_child(preload("capture_animation.gd").new())
	if OS.get_cmdline_user_args().has("--profile-whitebox"):
		add_child(preload("profile.gd").new())
	if OS.get_cmdline_user_args().has("--record-skill-gifs"):
		add_child(preload("record_gifs.gd").new())

func _make_floor(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)

func record(message: String) -> void:
	var line: String = "%6.2f  %s" % [time,message]
	events.push_front(line)
	if events.size() > 4: events.pop_back()
	log_lines.append(line)
	print("[combat-whitebox] ",line)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	# 调试快捷键支持逻辑键；事件取证见原生验证日志。
	match event.keycode if event.keycode != 0 else event.physical_keycode:
		KEY_R: reset_arena()
		KEY_1:
			enemy.mode = 0
			record("MODE: low sweep")
		KEY_2:
			enemy.mode = 1
			record("MODE: long thrust")
		KEY_F:
			enemy.auto_attack = not enemy.auto_attack
			record("AUTO: %s" % enemy.auto_attack)
		KEY_H:
			enemy.armored = not enemy.armored
			record("ARMOR: %s" % enemy.armored)
		KEY_C:
			player.backstep_enabled = not player.backstep_enabled
			record("BACKSTEP ENABLED: %s" % player.backstep_enabled)
		KEY_F3:
			Engine.time_scale = 0.15 if Engine.time_scale == 1.0 else 1.0
			record("TIME SCALE: %.2f" % Engine.time_scale)
		KEY_F4:
			player.hit_feedback.toggle()
			record("HIT FEEDBACK: %s" % player.hit_feedback.enabled)
		KEY_F5:
			player.hit_feedback.toggle_audio()
			record("HIT AUDIO: %s" % player.hit_feedback.audio_enabled)
		KEY_F8:
			DirAccess.make_dir_recursive_absolute("res://build/qa/combat-whitebox")
			get_viewport().get_texture().get_image().save_png("res://build/qa/combat-whitebox/native.png")
		KEY_ENTER: enemy.begin_attack()
		KEY_Y: player.request_action("cyclone")
		KEY_F2:
			player.show_debug = not player.show_debug
			enemy.show_debug = player.show_debug
			for target: CombatWhiteboxEnemy in extra_targets: target.show_debug = player.show_debug
			record("HITBOXES: %s" % player.show_debug)
		KEY_8: toggle_group()
		KEY_9:
			enemy.health = 60
			record("PRACTICE: target HP 60")

func toggle_group() -> void:
	if not extra_targets.is_empty():
		for target: CombatWhiteboxEnemy in extra_targets: target.queue_free()
		extra_targets.clear()
		record("GROUP: off")
		return
	for x: float in [735.0,815.0]:
		var target := CombatWhiteboxEnemy.new()
		target.player = player
		target.position = Vector2(x,540)
		target.show_debug = player.show_debug
		add_child(target)
		target.resolved.connect(record)
		extra_targets.append(target)
	record("GROUP: three targets")

func reset_arena() -> void:
	player.hit_feedback.clear()
	player.pad_input.clear()
	peak_frame_ms = 0.0
	player.afterimage.clear()
	player.retreating = false
	player.retreat_cooldown = 0.0
	player.skill_controller.cancel()
	player.skill_controller.input.clear()
	player.clear_projectiles()
	player.pending_action = ""
	player.pending_left = 0.0
	player.jump_buffer = 0.0
	player.recoil_left = 0.0
	player.state = "idle"
	player.state_duration = 0.0
	player.state_time = 0.0
	player.health = player.max_health
	player.soul = player.max_soul
	player.dead_signal_sent = false
	player.invulnerable = 0.0
	player.armor = 0.0
	player.hitstop = 0.0
	for key: String in player.cooldowns: player.cooldowns[key] = 0.0
	player.position = Vector2(550,540)
	player.velocity = Vector2.ZERO
	player.facing = 1.0
	enemy.health = 12
	enemy.state = "idle"
	enemy.elapsed = 0.0
	enemy.hit_sent = false
	enemy.facing = -1.0
	enemy.hit_count = 0
	enemy.attack_count = 0
	enemy.parry_count = 0
	enemy.position = Vector2(650,540)
	enemy.vertical_speed = 0.0
	enemy.air_lifts = 0
	for target: CombatWhiteboxEnemy in extra_targets:
		target.queue_free()
	extra_targets.clear()
	var skills := player.skill_controller as CombatWhiteboxSwordSkills
	skills.combo_hits = 0
	skills.combo_left = 0.0
	timeline.reset_history()
	record("RESET")

func _process(dt: float) -> void:
	var now: int = Time.get_ticks_usec()
	if frame_stamp > 0:
		frame_ms = float(now-frame_stamp)/1000.0
		peak_frame_ms = maxf(peak_frame_ms,frame_ms)
	frame_stamp = now
	# 引擎启动末段可能覆盖_ready中的标题，首帧再设置以区分同时打开的主线。
	if not title_set:
		DisplayServer.window_set_title("BOB Whitebox - Hit Feedback")
		title_set = true
	time += dt
	hud.text = "COMBAT WHITEBOX / no save | FPS %d | frame %.1fms | peak %.1fms (R resets)\n" % [Engine.get_frames_per_second(),frame_ms,peak_frame_ms]
	hud.text += "WASD move/aim | Space jump | J attack | K triple | I GUARD | L dash / moving launch | S+L BACKSTEP\n"
	hud.text += player.pad_input.page_hint()+"\n"
	hud.text += "F4 hit feedback %s | F5 sound %s | light 3f / multi 1f / heavy 4f\n" % [player.hit_feedback.enabled,player.hit_feedback.audio_enabled]
	hud.text += "R reset | 1/2 sweep/thrust | F auto | Enter attack | H armor | C A/B | F2 hitboxes | F3 slow | F8 capture\n"
	hud.text += "HP %d/5   soul %d   player %s   backstep %s\n" % [player.health,player.soul,"BACKSTEP" if player.retreating else player.state,player.backstep_enabled]
	hud.text += "Enemy HP %d   %s / %s   armor %s   auto %s\n" % [enemy.health,enemy.MODES[enemy.mode],enemy.state,enemy.armored,enemy.auto_attack]
	var skills := player.skill_controller as CombatWhiteboxSwordSkills
	hud.text += "Attacks %d   damage %d   guards %d   COMBO %d\n" % [enemy.attack_count,enemy.hit_count,enemy.parry_count,skills.combo_hits]
	for key: String in CombatWhiteboxSwordSkills.BINDINGS:
		hud.text += "%s [%s] %.1fs   " % [CombatWhiteboxSwordSkills.TITLES[key],CombatWhiteboxSwordSkills.BINDINGS[key],float(player.cooldowns.get(key,0.0))]
	event_hud.text = "\n".join(events)
	log_timer += dt
	if log_timer >= 1.0:
		log_timer = 0.0
		DirAccess.make_dir_recursive_absolute("res://build/qa/combat-whitebox")
		var file := FileAccess.open("res://build/qa/combat-whitebox/live.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"time":time,"hp":player.health,"x":player.position.x,"y":player.position.y,"facing":player.facing,"state":player.state,"backstep":player.retreating,"enemy":enemy.state,"damage":enemy.hit_count,"parries":enemy.parry_count,"events":log_lines}))

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _draw() -> void:
	draw_rect(Rect2(0,540,1280,45),Color("3c485a"))
	for x: int in range(0,1280,50):
		draw_line(Vector2(x,520),Vector2(x,555),Color("586176"),1.0)
