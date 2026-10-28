extends Node2D

@export var player_scene:PackedScene = preload("res://scenes/CampaignPlayer.tscn")
@export var camera_lookahead:float=120.0 # New default; Inspector adjustable.
@export var camera_shake_pixels:float=6.0 # New default; Inspector adjustable.
@export var camera_dash_zoom:float=1.05 # New default; Inspector adjustable.
const PlayerUI = preload("res://scenes/PlayerUI.tscn")
const EnemyProxy = preload("res://scripts/campaign_enemy_proxy.gd")
const CampaignCamera = preload("res://scripts/campaign_camera.gd")
var player_soul:int=99
var camera_feedback:float=0
var player_ui:CanvasLayer
var interaction_hint:Label
var integration_external_test:bool=false
var rooms: Array = []
var room: Dictionary = {}
var room_index: int = 0
var scenery: Node2D
var player: CharacterBody2D
var camera: Camera2D
var ui: CanvasLayer
var info: Label
var status: Label
var reference: Sprite2D
var reference_visible: bool = false
var layer_solo: int = -1
var zoomed: bool = false
var reference_follow: bool = true
var camera_room_id: String = ""
var outlines: bool = false
var health: int = 5
var flash: float = 0.0
var clock: float = 0.0
var checkpoint: Dictionary = {"room": 0, "pos": []}
var collected: Dictionary = {}
var defeated: Dictionary = {}
var abilities: Dictionary = {"dash": false, "float": false, "anchor": false}
var enemies: Array = []
var message: String = ""
var message_time: float = 0.0
var capture_path: String = ""
var capture_room: int = 0
var capture_count: int = 0
var capture_quit: bool = false
var capture_layers: bool = false
var qa: bool = false
var qa_flow: bool = false
var qa_reload: bool = false
var qa_throat: bool = false
var qa_controls: bool = false
var practice_restore: Dictionary = {}
var practice: bool = false
var muted: bool = false
var completed: bool = false
var events: Array = []
var event_sequence: int = 0
var qa_actors: bool = false
var qa_normal: bool = false
var qa_normal_reload: bool = false
var qa_deep: bool = false
var qa_elements: bool = false
var qa_reference_level: bool = false
var quitting: bool = false
var qa_revisit: bool = false
var qa_reward_reload: bool = false
var qa_room7_reload: bool = false
var qa_full_abilities: bool = true
var sound_bank: Dictionary = {}
var sound_variants: Dictionary = {}
var sound_cursor: Dictionary = {}
var sound_last_time: Dictionary = {}
var qa_output: String = "user://artmatch_flow.json"
var font: Font
var overlay: Node2D

func _ready() -> void:
	get_viewport().snap_2d_transforms_to_pixel=true
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	for sound: String in ["jump","dash","strike","hit","hurt","slam","collect","save","sweep","heavy","heal"]:
		var sound_path: String = "res://assets/runtime/audio/"+sound+".wav"
		if ResourceLoader.exists(sound_path):
			var stream: AudioStream = load(sound_path)
			if stream != null:
				sound_bank[sound] = stream
				var variants: Array[AudioStream] = [stream]
				for variant: int in range(2,4):
					var variant_path: String = "res://assets/runtime/audio/"+sound+"_"+str(variant)+".wav"
					if ResourceLoader.exists(variant_path): variants.append(load(variant_path) as AudioStream)
				sound_variants[sound] = variants
	var contents: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rooms.json"))
	rooms = contents if contents is Array else contents.get("rooms", [])
	if rooms.is_empty():
		push_error("No room data")
		get_tree().quit(1)
		return
	setup_inputs()
	overlay = Node2D.new()
	overlay.z_index = 80
	add_child(overlay)
	overlay.draw.connect(draw_overlay)
	font = ThemeDB.fallback_font
	camera = Camera2D.new()
	camera.set_script(CampaignCamera)
	camera.host=self
	camera.lookahead=camera_lookahead
	camera.shake_pixels=camera_shake_pixels
	camera.dash_zoom=camera_dash_zoom
	add_child(camera)
	ui = CanvasLayer.new()
	add_child(ui)
	info = Label.new()
	info.position = Vector2(18, 10)
	info.add_theme_font_size_override("font_size", 17)
	info.add_theme_color_override("font_outline_color", Color(0,0,0,0.95))
	info.add_theme_constant_override("outline_size", 5)
	ui.add_child(info)
	status = Label.new()
	status.position = Vector2(18, 630)
	status.add_theme_font_size_override("font_size", 15)
	status.add_theme_constant_override("outline_size", 4)
	status.add_theme_color_override("font_outline_color", Color.BLACK)
	ui.add_child(status)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for arg: String in args:
		if arg.begins_with("--capture="): capture_path = arg.trim_prefix("--capture=")
		if arg.begins_with("--room="): capture_room = clampi(int(arg.trim_prefix("--room=")) - 1, 0, rooms.size() - 1)
		if arg == "--capture-quit": capture_quit = true
		if arg == "--capture-layers": capture_layers = true
		if arg.begins_with("--solo="): layer_solo = clampi(int(arg.trim_prefix("--solo=")), 0, 3)
		if arg == "--outlines": outlines = true
		if arg == "--reference": reference_visible = true
		if arg == "--zoom": zoomed = true
		if arg.begins_with("--evidence="): qa_output = arg.trim_prefix("--evidence=").path_join("flow.json")
		if arg == "--qa": qa = true
		if arg == "--qa-reference-level":
			qa = true
			qa_reference_level = true
			qa_full_abilities = false
		if arg in ["--qa-load", "--qa-reload"]:
			qa = true
			qa_reload = true
		if arg == "--qa-elements":
			qa = true
			qa_elements = true
			qa_full_abilities = false
		if arg == "--qa-deep":
			qa = true
			qa_deep = true
			qa_full_abilities = false
		if arg == "--qa-normal-reload":
			qa = true
			qa_normal_reload = true
			qa_full_abilities = false
		if arg == "--qa-revisit":
			qa = true
			qa_revisit = true
			qa_full_abilities = false
		if arg == "--qa-reward7-reload":
			qa = true
			qa_reward_reload = true
			qa_room7_reload = true
		if arg == "--qa-reward-reload":
			qa = true
			qa_reward_reload = true
			qa_full_abilities = false
		if arg == "--qa-normal":
			qa = true
			qa_normal = true
			qa_full_abilities = false
		if arg == "--qa-actors":
			qa = true
			qa_actors = true
		if arg == "--qa-controls":
			qa = true
			qa_controls = true
		if arg == "--qa-throat":
			qa = true
			qa_throat = true
		if arg == "--qa-flow":
			qa = true
			qa_flow = true
		if arg.begins_with("--qa-output="): qa_output = arg.trim_prefix("--qa-output=")
	if capture_path.is_empty() and not qa: load_progress()
	else: room_index = capture_room
	load_room(room_index)
	if not checkpoint.pos.is_empty() and int(checkpoint.room) == room_index and capture_path.is_empty():
		player.position = restored_room_position(point(checkpoint.pos))
	if not capture_path.is_empty():
		ui.visible = false
		player.set_physics_process(false)
	if qa_reference_level:
		var fixture: Node = load("res://tests/qa_reference_level.gd").new()
		fixture.host = self
		add_child(fixture)
		fixture.run.call_deferred()
	elif qa_elements:
		var fixture: Node = load("res://tests/qa_elements.gd").new()
		fixture.host = self
		add_child(fixture)
		fixture.run.call_deferred()
	elif qa_deep: run_deep_qa.call_deferred()
	elif qa_normal_reload: run_normal_reload_qa.call_deferred()
	elif qa_revisit: run_revisit_qa.call_deferred()
	elif qa_reward_reload: run_reward_reload_qa.call_deferred()
	elif qa_normal: run_normal_qa.call_deferred()
	elif qa_actors: run_actor_qa.call_deferred()
	elif qa_controls: run_controls_qa.call_deferred()
	elif qa_throat: run_throat_qa.call_deferred()
	elif qa_flow: run_flow_qa.call_deferred()
	elif qa_reload: run_reload_qa.call_deferred()
	elif qa and not integration_external_test: run_qa.call_deferred()

func point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func setup_inputs() -> void:
	var map: Dictionary = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "dash": [KEY_SHIFT], "attack": [KEY_Q], "float": [KEY_W], "grapple": [KEY_G], "interact": [KEY_E], "down": [KEY_S,KEY_DOWN]}
	for action: String in map:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for code: int in map[action]:
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)

func load_room(index: int, target_spawn: Array = []) -> void:
	# The authored starting room is visible in main.tscn and shares the same
	# PackedScene as runtime. Reuse it once; saved later rooms discard it.
	var authored_room: Node2D = get_node_or_null("LevelMap") if not is_instance_valid(scenery) else null
	var next_room: Dictionary = rooms[index]
	var packed: PackedScene = load("res://scenes/r1/"+str(next_room.id)+".tscn")
	if packed == null:
		push_error("Room resource unavailable: "+str(next_room.id))
		if qa: get_tree().quit(2)
		return
	if is_instance_valid(scenery):
		var old_ambience: Node = scenery.get_node_or_null("EnvironmentMotion")
		if old_ambience != null and old_ambience.has_method("release_ambience"): old_ambience.release_ambience()
		remove_child(scenery)
		scenery.queue_free()
	if is_instance_valid(reference):
		remove_child(reference)
		reference.queue_free()
	room_index = index
	room = rooms[index]
	if authored_room != null and index == 0:
		scenery = authored_room
	else:
		if authored_room != null:
			remove_child(authored_room)
			authored_room.queue_free()
		scenery = packed.instantiate()
		add_child(scenery)
	scenery.process_mode = Node.PROCESS_MODE_PAUSABLE
	var reference_environment: Node2D = scenery.get_node_or_null("ReferenceEnvironment")
	if reference_environment != null: reference_environment.level_host = self
	var default_spawn: Array = room.spawn if not capture_path.is_empty() else room.get("play_spawn", room.spawn)
	var spawn: Vector2 = restored_room_position(point(default_spawn if target_spawn.is_empty() else target_spawn))
	player = player_scene.instantiate()
	player.host = self
	player.name = "Player"
	player.position = spawn
	player.z_index = 20 if reference_environment != null else 3
	var cutout: Node2D = scenery.get_node_or_null("World/PlayerArt")
	if cutout != null:
		var pivot: Node2D = Node2D.new()
		pivot.name = "ReferenceArtPivot"
		player.add_child(pivot)
		cutout.reparent(pivot, false)
		cutout.position -= point(room.spawn)
		if reference_environment != null: cutout.z_index = 0
		player.art = pivot
	scenery.get_node("World").add_child(player)
	enemies.clear()
	for i: int in range(room.get("enemies", []).size()):
		var source: Dictionary = room.enemies[i]
		var origin: Vector2 = point(source.pos)
		var visual: Node2D = scenery.get_node_or_null("World/EnemyArt" + str(i))
		var key: String = str(room.id) + ":" + str(i)
		var boss: bool = source.get("boss", false)
		var alive: bool = not (boss and defeated.get(key, false))
		if visual != null: visual.visible = alive
		enemies.append({"pos": origin, "origin": origin, "visual": visual, "visual_origin": visual.position if visual != null else Vector2.ZERO, "boss": boss, "hp": 10 if boss else 3, "state": "idle", "timer": 0.0, "alive": alive, "facing": -1.0, "key": key, "hurt": 0.0, "hit_sent": false})
	for enemy:Dictionary in enemies:
		var proxy=EnemyProxy.new();proxy.host=self;proxy.data=enemy
		scenery.get_node("World").add_child(proxy)
	bind_player_ui()
	reference = Sprite2D.new()
	reference.centered = false
	var path: String = room.get("reference", "res://assets/reference/r1/" + str(room.id) + ".png")
	if ResourceLoader.exists(path): reference.texture = load(path)
	if reference_environment != null: reference.scale = reference_environment.scale
	reference.z_index = 100
	reference.visible = reference_visible
	add_child(reference)
	var reward_art: Node2D = scenery.get_node_or_null("World/RewardArt")
	if reward_art != null: reward_art.visible = not collected.get(str(room.id), false)
	record_event("room_enter", {"room": str(room.id), "spawn": [spawn.x,spawn.y]})
	if ResourceLoader.exists("res://scripts/environment.gd"):
		var environment: Node2D = load("res://scripts/environment.gd").new()
		environment.name = "EnvironmentMotion"
		environment.host = self
		scenery.add_child(environment)
	var mechanisms: Node2D = load("res://scripts/mechanisms.gd").new()
	mechanisms.host = self
	scenery.add_child(mechanisms)
	update_layers()
	update_camera()

func restored_room_position(value: Vector2) -> Vector2:
	# R1-01's new road retains the old world width. Existing checkpoints and
	# incoming door coordinates project to the new ground without save rewrites.
	if room.get("layered_environment", false):
		value.x = clampf(value.x,18.0,float(room.size[0])-18.0)
		value.y = ground_y(value.x,value.y)
	return value

func reference_camera_active() -> bool:
	return room.get("layered_environment",false) and reference_follow and capture_path.is_empty() and layer_solo < 0

func bind_player_ui() -> void:
	if not is_instance_valid(player_ui):
		player_ui=PlayerUI.instantiate()
		player_ui.player=player
		player_ui.campaign_mode=true
		player_ui.edge_margin=18
		player_ui.header_text=""
		player_ui.guide_path="user://tide_campaign_guide.cfg"
		player_ui.guide_enabled=not qa and capture_path.is_empty()
		player_ui.process_mode=Node.PROCESS_MODE_PAUSABLE
		add_child(player_ui)
	else:player_ui.bind_player(player)
	player_ui.visible=capture_path.is_empty()
	status.hide()
	interaction_hint=Label.new();interaction_hint.name="InteractionHint"
	interaction_hint.text="按 E 交互";interaction_hint.position=Vector2(-48,-125)
	interaction_hint.add_theme_font_size_override("font_size",17)
	interaction_hint.add_theme_constant_override("outline_size",4)
	interaction_hint.hide();player.add_child(interaction_hint)

func update_camera() -> void:
	camera.update_follow(get_process_delta_time())
	camera_room_id=str(room.id)

func _process(dt: float) -> void:
	if quitting: return
	if get_tree().paused:
		status.show()
		status.text = "暂停 · Esc 继续 · M 静音"
		return
	status.hide()
	if is_instance_valid(interaction_hint):interaction_hint.visible=player.interaction_nearby() and player.health>0 and not reference_visible
	clock += dt
	flash = maxf(0.0, flash - dt)
	message_time = maxf(0.0, message_time - dt)
	if room.is_empty(): return
	update_camera()
	update_parallax()
	if not reference_visible and layer_solo < 0 and capture_path.is_empty() and player.controls_enabled: update_enemies(dt)
	info.text = "%s  %s     生命 %s" % [str(room.id), str(room.name), "●".repeat(maxi(health, 0))]
	var mode: String = "原图对照" if reference_visible else (["远景", "中景", "可玩层", "前景"][layer_solo] if layer_solo >= 0 else "原图分层重建")
	status.text = "A/D 移动 · 空格 跳跃 · Shift 冲刺 · Q 攻击 · W 浮游 · G 锚环 · E 交互 / A或D+E 过门 · 舌膜 S+空格下潜\nTab 镜头 · F2 原图 · F3 碰撞 · F4 分层 · 1—7 房间预览 · F5 存档 · F6 读取 · F9 练习 · Esc 暂停 · M 静音   | " + mode
	if message_time > 0.0: status.text += "\n" + message
	if practice: info.text += "  [练习：全部能力，仅会话]"
	if not capture_path.is_empty():
		capture_count += 1
		if capture_count == 30: capture.call_deferred()
	overlay.queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if quitting: return
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode == KEY_ESCAPE:
		get_tree().paused = not get_tree().paused
		record_event("pause", {"paused":get_tree().paused})
		return
	if event.physical_keycode == KEY_M:
		muted = not muted
		AudioServer.set_bus_mute(0, muted)
		record_event("mute", {"muted":muted})
		notify("音效已静音" if muted else "音效已开启")
		return
	if get_tree().paused: return
	match event.physical_keycode:
		KEY_TAB:
			if room.get("layered_environment",false):
				reference_follow=not reference_follow
				zoomed=false
			else: zoomed=not zoomed
		KEY_F2:
			reference_visible = not reference_visible
			reference.visible = reference_visible
		KEY_F3: outlines = not outlines
		KEY_F4:
			layer_solo += 1
			if layer_solo > 3: layer_solo = -1
			update_layers()
		KEY_F9:
			if not practice:
				practice_restore = {"abilities":abilities.duplicate(true),"collected":collected.duplicate(true),"defeated":defeated.duplicate(true),"checkpoint":checkpoint.duplicate(true),"completed":completed}
				practice = true
			else:
				practice = false
				abilities = practice_restore.abilities
				collected = practice_restore.collected
				defeated = practice_restore.defeated
				checkpoint = practice_restore.checkpoint
				completed = practice_restore.completed
				load_room(room_index, [player.position.x,player.position.y])
			notify("练习模式：浮游、锚环、冲刺可用；不写入能力进度" if practice else "已恢复正式能力进度")
			record_event("practice", {"enabled":practice})
		KEY_F5: manual_save()
		KEY_F6:
			load_progress()
			load_room(room_index, checkpoint.get("pos", []))
		KEY_R: respawn()
		_:
			if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_7:
				load_room(event.physical_keycode - KEY_1)
				notify("房间预览跳转，不改变已记录的检查点")

func update_layers() -> void:
	var names: Array[String] = ["Far", "Middle", "World", "Foreground"]
	for i: int in range(names.size()):
		var node: Node2D = scenery.get_node_or_null(names[i])
		if node != null: node.visible = layer_solo < 0 or i == layer_solo
	var environment: Node = scenery.get_node_or_null("ReferenceEnvironment")
	if environment != null: environment.set_level_layer(layer_solo)

func ground_y(x: float, near_y: float) -> float:
	var best: float = near_y
	var distance: float = 150.0
	for surface: Array in room.surfaces:
		for i: int in range(surface.size() - 1):
			var a: Vector2 = point(surface[i])
			var b: Vector2 = point(surface[i + 1])
			if x >= minf(a.x, b.x) and x <= maxf(a.x, b.x) and absf(a.x - b.x) > 0.001:
				var y: float = lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
				if absf(y - near_y) < distance:
					best = y
					distance = absf(y - near_y)
	return best

func update_enemies(dt: float) -> void:
	for enemy: Dictionary in enemies:
		if not enemy.alive: continue
		enemy.timer = float(enemy.timer) + dt
		enemy.hurt = maxf(0.0, float(enemy.hurt) - dt)
		var pos: Vector2 = enemy.pos
		var delta: Vector2 = player.position - pos
		var range_limit: float = 220.0 if enemy.boss else 110.0
		if enemy.state == "idle":
			if absf(delta.x) < range_limit and absf(delta.y) < 130:
				enemy.state = "tell"
				enemy.timer = 0.0
				enemy.facing = signf(delta.x)
			elif absf(delta.x) < 500 and absf(delta.y) < 150:
				pos.x += signf(delta.x) * (24 if enemy.boss else 45) * dt
				pos.y = ground_y(pos.x, pos.y)
		elif enemy.state == "tell" and float(enemy.timer) > (0.95 if enemy.boss else 0.7):
			enemy.state = "active"
			enemy.hit_sent = false
			enemy.timer = 0.0
			record_event("enemy_attack_active", {"id":enemy.key})
		elif enemy.state == "active":
			if not enemy.hit_sent and float(enemy.timer)>0.10 and absf(delta.x) < range_limit and absf(delta.y) < 115:
				enemy.hit_sent = true
				player.hurt(1)
			if float(enemy.timer) > 0.2:
				enemy.state = "recover"
				enemy.timer = 0.0
		elif enemy.state == "recover" and float(enemy.timer) > 1.1:
			enemy.state = "idle"
			enemy.timer = 0.0
		enemy.pos = pos
		var visual: Node2D = enemy.visual
		if is_instance_valid(visual):
			visual.position = enemy.visual_origin + pos - Vector2(enemy.origin)
			visual.modulate = Color(1.7, 1.4, 1.3) if float(enemy.hurt) > 0 else (Color(1.15, 0.75, 0.6) if enemy.state == "tell" else Color.WHITE)
			var pivot: Node2D = visual.get_node_or_null("Pivot")
			if pivot != null:
				var breath: float = sin(clock*3.0+float(enemy.origin.x)*0.01)*0.018
				pivot.scale = Vector2(1.0+breath,1.0-breath)
				pivot.rotation = sin(float(enemy.timer)*18.0)*0.03 if enemy.state == "tell" else 0.0
			var claw: Node2D = visual.find_child("BossClaw",true,false) as Node2D
			if claw != null:
				var goal: float = -0.22 if enemy.state == "tell" else (0.32 if enemy.state == "active" else 0.0)
				claw.rotation = move_toward(claw.rotation,goal,dt*4.0)

func attack(origin: Vector2, facing: float) -> void:
	sfx("strike")
	record_event("attack", {"room":room_index})
	for enemy: Dictionary in enemies:
		if not enemy.alive: continue
		var delta: Vector2 = Vector2(enemy.pos) - origin
		if absf(delta.x) < (180 if enemy.boss else 125) and absf(delta.y) < 125 and delta.x * facing > -25:
			damage_enemy(enemy,1)

func damage_enemy(enemy:Dictionary,amount:int) -> void:
	if not enemy.alive:return
	enemy.hp = int(enemy.hp) - amount
	sfx("hit")
	record_event("enemy_hit", {"id":enemy.key,"hp":enemy.hp})
	enemy.hurt = 0.18
	if int(enemy.hp) <= 0:
		enemy.alive = false
		sfx("slam")
		record_event("enemy_defeated", {"id":enemy.key})
		if is_instance_valid(enemy.visual): enemy.visual.visible = false
		if enemy.boss:
			defeated[enemy.key] = true
			abilities.dash = true
			record_event("ability_unlocked", {"id":"dash"})
			notify("负壳守卫已击败：获得冲刺，通路解除封锁")
			save_progress(false)

func interact() -> void:
	var reward: Array = room.get("reward", [])
	if reward.size() == 2 and player.position.distance_to(point(reward)) < 100 and not collected.get(str(room.id), false):
		collected[str(room.id)] = true
		sfx("collect")
		record_event("reward", {"room":str(room.id)})
		var reward_art: Node2D = scenery.get_node_or_null("World/RewardArt")
		if reward_art != null: reward_art.visible = false
		health = 5
		notify("收集本房记忆 / 补给，已保存")
		save_progress(false)
		return
	if not Input.is_action_pressed("left") and not Input.is_action_pressed("right") and try_camp(): return
	for door: Dictionary in room.get("doors", []):
		if player.position.distance_to(point(door.pos)) > 125: continue
		enter_door(door)
		return
	notify("E 使用灯台 / 拾取；靠近门按 A/D + E 穿行")

func enter_door(door:Dictionary) -> void:
	var destination: int = int(door.to)
	if destination < 0:
		if destination == -1 and room_index == 4:
			completed = true
			record_event("level_complete", {"room":str(room.id)})
			sfx("collect")
			save_progress(false)
			notify("首关完成 · 已抵达食道出口；后续章节尚未制作，可沿原路继续探索")
			return
		notify(door.get("message", "后续区域未包含在首关中；此处保留出口关系"))
		return
	var needed: String = door.get("ability", "")
	if not needed.is_empty() and needed != "boss" and not has_ability(needed):
		notify("需要能力 " + needed)
		return
	if room_index == 3 and destination == 4:
		for enemy: Dictionary in enemies:
			if enemy.boss and enemy.alive:
				notify("先击败负壳守卫")
				return
	sfx("save")
	record_event("door", {"from":room_index,"to":destination})
	load_room(destination, door.get("spawn", []))
	notify("已穿过相邻解剖区域通道")
	return

func try_camp() -> bool:
	var default_camps: Dictionary = {0:[93,550],3:[80,610],4:[110,503]}
	var camp: Array = room.get("camp",default_camps.get(room_index,[]))
	if camp.size() == 2 and player.position.distance_to(point(camp)) < 180:
		checkpoint = {"room": room_index, "pos": [player.position.x, player.position.y]}
		sfx("save")
		record_event("physical_camp_save", {"room":room_index,"camp":camp,"player":checkpoint.pos})
		record_event("checkpoint", checkpoint)
		health = 5
		save_progress(false)
		notify("存档点已记录，生命恢复")
		return true
	return false

func notify(text: String) -> void:
	message = text
	message_time = 4.0
	if is_instance_valid(player_ui):player_ui.show_notice(text)

func save_progress(show_message: bool = true) -> void:
	if practice and not qa:
		notify("练习状态不写入正式存档")
		return
	var payload: Dictionary = {"version": 6, "checkpoint": checkpoint, "collected": collected, "defeated": defeated, "abilities": abilities, "completed":completed}
	var file: FileAccess = FileAccess.open("user://artmatch_qa_save.json" if qa else "user://artmatch_save.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(payload, "\t"))
	persist_events()
	if show_message: notify("已保存检查点与永久进度（F6 读取）")

func load_progress() -> void:
	var save_path: String = "user://artmatch_qa_save.json" if qa else "user://artmatch_save.json"
	if not FileAccess.file_exists(save_path): return
	var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not payload is Dictionary: return
	checkpoint = payload.get("checkpoint", checkpoint)
	room_index = clampi(int(checkpoint.room), 0, rooms.size() - 1)
	completed = payload.get("completed",false)
	collected = payload.get("collected", {})
	defeated = payload.get("defeated", {})
	if int(payload.get("version",0)) >= 6: abilities = payload.get("abilities", abilities)
	notify("已读取保存进度")

func respawn() -> void:
	sfx("slam")
	record_event("player_death", {"room":room_index})
	health = 5
	player_soul=99
	load_room(clampi(int(checkpoint.room), 0, rooms.size() - 1), checkpoint.get("pos", []))
	player.invulnerable = 1.5
	notify("已返回检查点")

func draw_overlay() -> void:
	if room.is_empty() or reference_visible: return
	if outlines:
		for surface: Array in room.surfaces:
			var points: PackedVector2Array = PackedVector2Array()
			for p: Array in surface: points.append(point(p))
			overlay.draw_polyline(points, Color(0.3,1,0.7), 3.0, true)
		for door: Dictionary in room.get("doors", []):
			overlay.draw_circle(point(door.pos) - Vector2(0,40), 35, Color(1,0.8,0.2,0.4))
		for p: Array in room.get("rings", []): overlay.draw_circle(point(p), 20, Color(0.3,0.9,1), false, 2)
	for enemy: Dictionary in enemies:
		if enemy.alive and enemy.state in ["tell", "active"]:
			var radius: float = 170.0 if enemy.boss else 85.0
			var color: Color = Color(1,0.45,0.15,0.75) if enemy.state == "tell" else Color(0.8,0.95,1,0.9)
			overlay.draw_arc(Vector2(enemy.pos) - Vector2(0,30), radius, 3.3, 6.1, 20, color, 4.0, true)

func capture() -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
	var result: Error = image.save_png(capture_path)
	print("CAPTURE ", capture_path, " result=", result)
	if capture_quit: await graceful_quit(0 if result == OK else 1)

func run_qa() -> void:
	var report: Dictionary = {"engine": Engine.get_version_info().string, "rooms": [], "note": "Spawn/collision and scene import smoke tests; not a complete traversal proof."}
	for i: int in range(rooms.size()):
		load_room(i)
		player.qa_mode = true
		for frame: int in range(70): await get_tree().physics_frame
		var row: Dictionary = {"id": room.id, "spawn_grounded": player.is_on_floor(), "position": [player.position.x, player.position.y], "layer_count": 0}
		for layer: String in ["Far", "Middle", "World", "Foreground"]:
			if scenery.has_node(layer): row.layer_count += 1
		report.rooms.append(row)
	var file: FileAccess = FileAccess.open("user://artmatch_qa.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	await graceful_quit()

func update_parallax() -> void:
	var shift: Vector2 = Vector2.ZERO
	if zoomed and not reference_visible and capture_path.is_empty() and layer_solo < 0:
		var center: Vector2 = point(room.size) * 0.5
		shift = (camera.position - center) * 0.009
		shift.x = clampf(shift.x, -6.0, 6.0)
		shift.y = clampf(shift.y, -4.0, 4.0)
	var environment: Node = scenery.get_node_or_null("ReferenceEnvironment")
	if environment != null:
		var offset := Vector2.ZERO
		if (zoomed or reference_camera_active()) and not reference_visible and layer_solo<0 and capture_path.is_empty():
			offset=(camera.position-point(room.size)*0.5)/(1671.0/1280.0)
		environment.level_camera_offset=Vector2(clampf(offset.x,-128.0,128.0),clampf(offset.y,-18.0,18.0))
		return
	scenery.get_node("Far").position = shift
	scenery.get_node("Middle").position = shift * 0.38
	scenery.get_node("Foreground").position = -shift * 0.6

func release_controls() -> void:
	for action: String in ["left", "right", "jump", "float", "grapple", "attack", "dash", "interact", "down"]: Input.action_release(action)

	for action in InputMap.get_actions():
		if str(action).begins_with("tp_"):Input.action_release(action)

func wait_physics(count: int) -> void:
	for frame: int in range(count): await get_tree().physics_frame

func input_tap(action: String) -> void:
	Input.action_press(action)
	await wait_physics(2)
	Input.action_release(action)
	await wait_physics(2)

func drive_to(target: Vector2, budget: int = 750) -> Dictionary:
	var initial_room: int = room_index
	var start: Vector2 = player.position
	var closest: float = start.distance_to(target)
	var frames: int = 0
	for frame: int in range(budget):
		frames = frame
		if room_index != initial_room: break
		var delta: Vector2 = target - player.position
		Input.action_release("jump")
		closest = minf(closest, delta.length())
		if absf(delta.x) < 40 and absf(delta.y) < 38: break
		Input.action_release("left")
		Input.action_release("right")
		if absf(delta.x) > 20: Input.action_press("right" if delta.x > 0 else "left")
		if frame % 55 == 0 and (delta.y < -45 or not player.is_on_floor() or absf(player.velocity.x) < 30): Input.action_press("jump")
		if frame % 55 == 3: Input.action_release("jump")
		if delta.y < -40 and not player.is_on_floor(): Input.action_press("float")
		else: Input.action_release("float")
		if frame % 26 == 0: Input.action_press("attack")
		if frame % 26 == 3: Input.action_release("attack")
		# Leap before a known horizontal gap, using the actual controller.
		if player.is_on_floor():
			for surface: Array in room.surfaces:
				var edge: Vector2 = point(surface[-1] if delta.x > 0 else surface[0])
				if absf(player.position.x - edge.x) < 75 and absf(player.position.y - edge.y) < 50 and absf(delta.x) > 95:
					Input.action_press("jump")
		if frame % 70 == 1 and delta.y < -90 and delta.x > 50: Input.action_press("grapple")
		if frame % 70 == 4: Input.action_release("grapple")
		await get_tree().physics_frame
	release_controls()
	var end: Vector2 = player.position
	return {"pass": room_index == initial_room and absf(end.x-target.x) < 70 and absf(end.y-target.y) < 100, "start": [start.x,start.y], "end": [end.x,end.y], "target": [target.x,target.y], "closest_px": closest, "physics_frames": frames, "health": health}

func flow_setup(index: int, start: Array = []) -> void:
	release_controls()
	health = 5
	checkpoint = {"room": index, "pos": start}
	load_room(index, start)
	await wait_physics(35)

func run_flow_qa() -> void:
	var report: Dictionary = {"engine": Engine.get_version_info().string, "method": "Graphical Godot run; Input.action_press/release; transforms only for isolated scenario starts, never inside drive_to.", "tests": [], "limitations": ["Agent scripted traversal, not human playtesting.", "All preview movement abilities enabled; progression not validated.", "External chapters intentionally not implemented.", "Save/load below checks disk serialization in one process; independent process reload requires separate QA."]}
	await flow_setup(0)
	var start_y: float = player.position.y
	await input_tap("jump")
	await wait_physics(13)
	var rise: float = start_y - player.position.y
	report.tests.append({"name": "jump_actual_input", "pass": rise > 50, "rise_px": rise})
	await wait_physics(70)
	var before: Vector2 = player.position
	await input_tap("dash")
	await wait_physics(15)
	report.tests.append({"name": "dash_actual_input", "pass": absf(player.position.x-before.x)>100, "delta_x": player.position.x-before.x})
	for index: int in [0, 1, 2]:
		await flow_setup(index)
		var destination: Dictionary = room.doors[-1] if index != 1 else room.doors[1]
		var result: Dictionary = await drive_to(point(destination.pos))
		result.name = "main_traverse_" + str(room.id)
		report.tests.append(result)
		await evidence_frame("main-traverse-"+str(index+1))
		var expected: int = int(destination.to)
		await input_tap("interact")
		report.tests.append({"name": "main_door_" + str(index+1), "pass": room_index == expected, "expected": expected, "actual": room_index})
	# Upper branch climbed from ground, with scene starts kept separate.
	await flow_setup(1, [225, 716])
	for target: Vector2 in [Vector2(100,420), Vector2(240,495), Vector2(110,265), Vector2(240,340), Vector2(90,110), Vector2(210,186)]:
		var result: Dictionary = await drive_to(target, 550)
		result.name = "float_branch_platform_" + str(int(target.y))
		report.tests.append(result)
	await input_tap("interact")
	report.tests.append({"name": "upper_branch_door", "pass": room_index == 5, "actual": room_index})
	if room_index == 5:
		var result: Dictionary = await drive_to(Vector2(100,795), 350)
		report.tests.append({"name": "upper_branch_return_approach", "result": result})
		await input_tap("interact")
		report.tests.append({"name": "upper_branch_return_door", "pass": room_index == 1, "actual": room_index})
	await flow_setup(1, [1100,690])
	for target: Vector2 in [Vector2(1130,575), Vector2(1245,465), Vector2(1360,345), Vector2(1320,230), Vector2(1570,277)]:
		var result: Dictionary = await drive_to(target, 420)
		result.name = "anchor_branch_" + str(int(target.x))
		report.tests.append(result)
	await input_tap("interact")
	report.tests.append({"name": "memory_branch_door", "pass": room_index == 6, "actual": room_index})
	await flow_setup(6, [250,572])
	var memory_result: Dictionary = await drive_to(Vector2(1300,569), 1000)
	memory_result.name = "memory_gaps_traverse"
	report.tests.append(memory_result)
	await input_tap("interact")
	report.tests.append({"name": "memory_reward", "pass": collected.get("R1-07",false)})
	var return_result: Dictionary = await drive_to(Vector2(95,568), 1000)
	return_result.name = "memory_return_traverse"
	report.tests.append(return_result)
	await input_tap("interact")
	report.tests.append({"name": "memory_return_door", "pass": room_index == 1})
	await flow_setup(3, [790,710])
	for frame: int in range(400):
		if frame % 26 == 0: Input.action_press("attack")
		if frame % 26 == 2: Input.action_release("attack")
		await get_tree().physics_frame
		if not enemies.is_empty() and not enemies[0].alive: break
	release_controls()
	report.tests.append({"name": "boss_damage_and_defeat", "pass": not enemies.is_empty() and not enemies[0].alive, "health": health})
	await evidence_frame("boss-after-fight")
	var boss_route: Dictionary = await drive_to(Vector2(1505,710),600)
	boss_route.name = "boss_exit_approach"
	report.tests.append(boss_route)
	await input_tap("interact")
	report.tests.append({"name": "boss_exit_door", "pass": room_index == 4})
	await flow_setup(4, [200,559])
	var throat_steps: Array = []
	var throat_passed: bool = true
	for target: Vector2 in [Vector2(600,577),Vector2(960,560),Vector2(1450,563),Vector2(1515,560)]:
		var throat_step: Dictionary = await drive_to(target,700)
		throat_steps.append(throat_step)
		throat_passed = throat_passed and throat_step.get("pass",false)
	report.tests.append({"name":"throat_gaps_traverse","pass":throat_passed,"segments":throat_steps})
	await evidence_frame("throat-complete")
	await input_tap("interact")
	report.tests.append({"name":"first_level_exit_completion","pass":completed})
	await flow_setup(0)
	await input_tap("interact")
	var saved_room: int = int(checkpoint.room)
	collected["QA_SENTINEL"] = true
	save_progress(false)
	collected.erase("QA_SENTINEL")
	load_progress()
	report.tests.append({"name": "disk_save_reload", "pass": collected.get("QA_SENTINEL",false) and int(checkpoint.room)==saved_room})
	await flow_setup(1, [635,661])
	health = 1
	var starting_player: int = player.get_instance_id()
	await wait_physics(240)
	report.tests.append({"name": "enemy_damage_death_respawn", "pass": health > 0 and player.get_instance_id()!=starting_player, "health": health, "room": room_index})
	await evidence_frame("death-respawn")
	release_controls()
	var passes: int = 0
	var failures: int = 0
	for test: Dictionary in report.tests:
		if test.get("pass",false): passes += 1
		elif test.has("pass"): failures += 1
	report.events = events
	report.passed = passes
	report.failed = failures
	if not qa_output.begins_with("user://"): DirAccess.make_dir_recursive_absolute(qa_output.get_base_dir())
	var output: FileAccess = FileAccess.open(qa_output, FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"	"))
	print("FLOW_QA ", qa_output, " passed=", passes," failed=",failures)
	await graceful_quit()

func evidence_frame(label: String) -> void:
	await RenderingServer.frame_post_draw
	var base: String = qa_output.get_base_dir()
	DirAccess.make_dir_recursive_absolute(base)
	get_viewport().get_texture().get_image().save_png(base.path_join(label+".png"))

func run_reload_qa() -> void:
	load_progress()
	load_room(room_index, checkpoint.get("pos",[]))
	await wait_physics(60)
	var result: Dictionary = {"pass": collected.get("QA_SENTINEL",false) and room_index == 0 and player.is_on_floor(), "room": room_index, "grounded": player.is_on_floor(), "sentinel_loaded": collected.get("QA_SENTINEL",false), "independent_process": true}
	var path: String = qa_output.get_base_dir().path_join("reload.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var output: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"\t"))
	await evidence_frame("independent-reload")
	print("RELOAD_QA ", JSON.stringify(result))
	await graceful_quit()

func has_ability(id: String) -> bool:
	return (qa and qa_full_abilities) or practice or abilities.get(id, false)

func record_event(kind: String, data: Dictionary = {}) -> void:
	event_sequence += 1
	events.append({"seq":event_sequence,"time": snappedf(clock,0.001), "event":kind,"data":data})
	if events.size() > 1500: events.pop_front()

func sfx(id: String) -> void:
	record_event("sound", {"id":id,"available":sound_bank.has(id),"muted":muted})
	if not sound_bank.has(id): return
	var cooldown: float = 0.08
	if id in ["collect","save","heal"]: cooldown = 0.18
	if clock-float(sound_last_time.get(id,-100.0))<cooldown:
		record_event("sound_suppressed",{"id":id,"reason":"same_event_cooldown"})
		return
	if get_tree().get_nodes_in_group("audio_sfx").size()>=8 or get_tree().get_nodes_in_group("audio_sfx_"+id).size()>=3:
		record_event("sound_suppressed",{"id":id,"reason":"voice_limit"})
		return
	sound_last_time[id] = clock
	var variants: Array = sound_variants.get(id,[sound_bank[id]])
	var cursor: int = int(sound_cursor.get(id,0))
	sound_cursor[id] = cursor+1
	var sound: AudioStreamPlayer = AudioStreamPlayer.new()
	sound.stream = variants[cursor%variants.size()]
	var gains: Dictionary = {"jump":-14.0,"dash":-13.0,"strike":-12.0,"hit":-11.0,"hurt":-12.0,"slam":-13.0,"heavy":-13.0,"sweep":-13.0,"collect":-16.0,"save":-16.0,"heal":-16.0}
	sound.volume_db = float(gains.get(id,-12.0))
	sound.pitch_scale = [0.99,1.01,1.0][cursor%3]
	sound.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(sound)
	sound.add_to_group("audio_sfx")
	sound.add_to_group("audio_sfx_"+id)
	record_event("sound_voice",{"id":id,"variant":cursor%variants.size(),"gain_db":sound.volume_db,"voices":get_tree().get_nodes_in_group("audio_sfx").size()})
	sound.finished.connect(sound.queue_free)
	sound.play()

func run_throat_qa() -> void:
	await flow_setup(4, [200,559])
	outlines = true
	var results: Array = []
	for target: Vector2 in [Vector2(600,577), Vector2(960,560), Vector2(1450,563)]:
		var result: Dictionary = await drive_to(target,700)
		results.append(result)
		await evidence_frame("throat-"+str(int(target.x)))
	var file: FileAccess = FileAccess.open(qa_output.get_base_dir().path_join("throat.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	print("THROAT_QA ",JSON.stringify(results))
	await graceful_quit()

func key_tap(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await wait_physics(2)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await wait_physics(2)

func run_controls_qa() -> void:
	await flow_setup(0)
	var report: Dictionary = {"tests":[]}
	qa = false
	var start: Vector2 = player.position
	await input_tap("dash")
	await wait_physics(20)
	report.tests.append({"name":"dash_locked_before_boss","pass":absf(player.position.x-start.x)<5})
	await key_tap(KEY_F9)
	start = player.position
	await input_tap("dash")
	await wait_physics(20)
	report.tests.append({"name":"explicit_practice_unlocks_dash","pass":practice and absf(player.position.x-start.x)>100})
	await key_tap(KEY_F9)
	report.tests.append({"name":"practice_restores_formal_progress","pass":not practice and not abilities.dash})
	await key_tap(KEY_ESCAPE)
	var paused_ok: bool = get_tree().paused
	start = player.position
	Input.action_press("right")
	await wait_physics(45)
	Input.action_release("right")
	report.tests.append({"name":"pause_freezes_player","pass":paused_ok and player.position.distance_to(start)<0.1})
	await key_tap(KEY_ESCAPE)
	await input_tap("jump")
	await wait_physics(12)
	report.tests.append({"name":"resume_accepts_jump","pass":not get_tree().paused and player.position.y<start.y-40})
	await key_tap(KEY_M)
	report.tests.append({"name":"mute_toggle","pass":muted and AudioServer.is_bus_mute(0)})
	await key_tap(KEY_M)
	report.tests.append({"name":"unmute_toggle","pass":not muted and not AudioServer.is_bus_mute(0)})
	await input_tap("attack")
	var audio_count: int = 0
	for child: Node in get_children():
		if child is AudioStreamPlayer and child.playing: audio_count += 1
	report.tests.append({"name":"audio_stream_playing","pass":audio_count>0,"active_streams":audio_count,"bank_size":sound_bank.size(),"note":"Runtime playback state verified; human listening not performed."})
	qa = true
	report.events = events
	var target: String = qa_output.get_base_dir().path_join("controls.json")
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	var file: FileAccess = FileAccess.open(target,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	await evidence_frame("controls")
	print("CONTROLS_QA ",JSON.stringify(report.tests))
	await graceful_quit()

func persist_events() -> void:
	var path: String = "user://artmatch_qa_events.json" if qa else "user://artmatch_events.json"
	var output: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if output != null: output.store_string(JSON.stringify(events,"\t"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		persist_events()
		graceful_quit.call_deferred()

func manual_save() -> void:
	var safe: Vector2 = player.position if player.is_on_floor() else player.last_safe
	checkpoint = {"room":room_index,"pos":[safe.x,safe.y]}
	record_event("manual_save", checkpoint)
	save_progress()

func run_actor_qa() -> void:
	var report: Dictionary = {"tests":[]}
	for index: int in [0,3,4]:
		var start: Array = [93,611] if index == 0 else ([80,645] if index == 3 else [110,553])
		await flow_setup(index,start)
		health = 3
		var before_events: int = event_sequence
		await input_tap("interact")
		var found: bool = false
		for event: Dictionary in events:
			if int(event.seq)>before_events and event.event == "physical_camp_save": found = true
		report.tests.append({"name":"physical_camp_"+str(index+1),"pass":found and health==5 and int(checkpoint.room)==index,"position":checkpoint.pos})
	await flow_setup(2)
	var before: int = event_sequence
	health = 3
	await input_tap("interact")
	var generic: bool = false
	for event: Dictionary in events:
		if int(event.seq)>before and event.event == "physical_camp_save": generic = true
	report.tests.append({"name":"no_generic_spawn_camp","pass":not generic and health==3})
	await flow_setup(0)
	Input.action_press("right")
	await wait_physics(18)
	var height: float = float(player.sprite.texture.get_image().get_used_rect().size.y)*absf(player.sprite.scale.y)
	report.tests.append({"name":"run_frame_and_scale","pass":player.visual_state=="run" and player.sprite.visible and not player.art.visible and height>=80 and height<=112,"height_px":height,"scale":player.visual_scale})
	await evidence_frame("hero-run")
	Input.action_release("right")
	await wait_physics(20)
	report.tests.append({"name":"idle_restores_animation","pass":player.visual_state=="idle" and player.idle_sprite.visible and player.idle_sprite.is_playing() and not player.art.visible and not player.sprite.visible})
	await key_tap(KEY_F5)
	report.tests.append({"name":"manual_save_current_safe","pass":point(checkpoint.pos).distance_to(player.last_safe)<8})
	await input_tap("attack")
	report.tests.append({"name":"attack_uses_frames","pass":player.visual_state=="attack" and player.sprite.visible and not player.art.visible})
	await evidence_frame("hero-attack")
	await flow_setup(1,[635,661])
	var hurt_seen: bool = false
	for frame: int in range(150):
		await get_tree().physics_frame
		if player.hurt_timer>0:
			hurt_seen = true
			await wait_physics(1)
			break
	report.tests.append({"name":"hurt_uses_frames","pass":hurt_seen and player.visual_state=="hit" and player.sprite.visible})
	await evidence_frame("hero-hurt")
	var visual: Node2D = enemies[0].visual
	var pivot: Node2D = visual.get_node_or_null("Pivot")
	var old_scale: Vector2 = pivot.scale if pivot!=null else Vector2.ONE
	await wait_physics(15)
	report.tests.append({"name":"enemy_foot_pivot_animation","pass":pivot!=null and pivot.scale.distance_to(old_scale)>0.001,"pivot_present":pivot!=null})
	await flow_setup(3,[790,710])
	var boss_visual: Node2D = enemies[0].visual
	var claw: Node2D = boss_visual.find_child("BossClaw",true,false) as Node2D
	for frame: int in range(100):
		await get_tree().physics_frame
		if enemies[0].state == "tell" and float(enemies[0].timer)>0.4: break
	report.tests.append({"name":"boss_claw_tell","pass":claw!=null and claw.rotation < -0.15,"rotation":claw.rotation if claw!=null else 0.0})
	await evidence_frame("boss-claw-tell")
	for frame: int in range(100):
		await get_tree().physics_frame
		if enemies[0].state == "active" and float(enemies[0].timer)>0.14: break
	report.tests.append({"name":"boss_claw_active","pass":claw!=null and claw.rotation > 0.20,"rotation":claw.rotation if claw!=null else 0.0,"attack_consumed":enemies[0].hit_sent})
	await evidence_frame("boss-claw-active")
	for frame: int in range(100):
		await get_tree().physics_frame
		if enemies[0].state == "recover" and float(enemies[0].timer)>0.25: break
	report.tests.append({"name":"boss_claw_recovers","pass":claw!=null and absf(claw.rotation)<0.05,"rotation":claw.rotation if claw!=null else 0.0})
	var output_path: String = qa_output.get_base_dir().path_join("actors-camps.json")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file: FileAccess = FileAccess.open(output_path,FileAccess.WRITE)
	report.events = events
	file.store_string(JSON.stringify(report,"\t"))
	print("ACTOR_QA ",JSON.stringify(report.tests))
	await graceful_quit()

func graceful_quit(code: int = 0) -> void:
	if quitting: return
	quitting = true
	release_controls()
	# Stop producers before releasing players. Killing bound fade tweens prevents
	# their callbacks from retaining outgoing audio nodes or accessing freed ones.
	set_process(false)
	set_physics_process(false)
	set_process_unhandled_key_input(false)
	for node: Node in get_tree().root.find_children("*","Node",true,false):
		if node.name=="EnvironmentMotion" or node.name=="VisualMechanisms":
			node.set_process(false)
			node.set_physics_process(false)
	for tween: Tween in get_tree().get_processed_tweens(): tween.kill()
	var audio_nodes: Array = get_tree().root.find_children("*","AudioStreamPlayer",true,false)
	for child: Node in audio_nodes:
		var sound: AudioStreamPlayer = child as AudioStreamPlayer
		sound.stop()
		sound.stream = null
		sound.queue_free()
	if is_instance_valid(scenery): scenery.queue_free()
	if is_instance_valid(reference): reference.queue_free()
	enemies.clear()
	sound_bank.clear()
	sound_variants.clear()
	get_tree().paused = false
	# Deferred frees happen first; then allow a measured mixer period to drain.
	await get_tree().process_frame
	await get_tree().process_frame
	# A stop request and its deferred playback release can span two mixer
	# updates. Include both after the output buffer, even when the next mix
	# is nearly due; one next-mix wait was intermittently insufficient.
	var mix_period: float = maxf(1.0/60.0,AudioServer.get_time_since_last_mix()+AudioServer.get_time_to_next_mix())
	var drain: float = AudioServer.get_output_latency()+mix_period*3.0
	await get_tree().create_timer(drain,true,false,true).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	print("AUDIO_SHUTDOWN players_released=",audio_nodes.size()," mix_drain_seconds=",drain)
	get_tree().quit(code)

func run_normal_qa() -> void:
	var report: Dictionary = {"engine":Engine.get_version_info().string,"method":"One uninterrupted first visit from room01 to05. QA only isolates save file; qa_full_abilities=false. No scenario reload or position writes after the ordinary startup load. Real Input action calls. Only camps heal; actual Boss defeat unlocks dash.","tests":[],"initial_abilities":abilities.duplicate(true)}
	await wait_physics(35)
	await evidence_frame("normal-01-start")
	var passed: bool = true
	for index: int in [0,1,2]:
		if room_index != index:
			passed = false
			break
		var destination: Dictionary = room.doors[-1] if index != 1 else room.doors[1]
		var result: Dictionary = await drive_to(point(destination.pos),900)
		result.name = "continuous_main_"+str(room.id)
		report.tests.append(result)
		await evidence_frame("normal-"+str(index+1)+"-exit")
		if not result.get("pass",false):
			passed = false
			break
		Input.action_press("right")
		await input_tap("interact")
		Input.action_release("right")
		await wait_physics(35)
		report.tests.append({"name":"continuous_door_"+str(index+1),"pass":room_index==index+1,"actual":room_index,"health":health})
		if room_index != index+1:
			passed = false
			break
	if passed and room_index == 3:
		var camp_route: Dictionary = await drive_to(Vector2(105,648),750)
		camp_route.name = "walk_to_boss_camp"
		report.tests.append(camp_route)
		await input_tap("interact")
		report.tests.append({"name":"boss_camp_rest","pass":health==5 and int(checkpoint.room)==3,"health":health})
		var approach: Dictionary = await drive_to(Vector2(830,710),750)
		approach.name = "boss_approach"
		report.tests.append(approach)
		await evidence_frame("normal-boss-start")
		for frame: int in range(600):
			if frame%26==0: Input.action_press("attack")
			if frame%26==2: Input.action_release("attack")
			await get_tree().physics_frame
			if defeated.get("R1-04:0",false): break
		release_controls()
		var boss_pass: bool = defeated.get("R1-04:0",false) and abilities.get("dash",false)
		report.tests.append({"name":"normal_boss_and_dash_unlock","pass":boss_pass,"health":health,"abilities":abilities.duplicate(true)})
		await evidence_frame("normal-boss-defeated")
		if boss_pass:
			var exit_route: Dictionary = await drive_to(Vector2(1505,710),750)
			exit_route.name = "boss_to_exit"
			report.tests.append(exit_route)
			Input.action_press("right")
			await input_tap("interact")
			Input.action_release("right")
			await wait_physics(35)
			report.tests.append({"name":"normal_boss_door","pass":room_index==4})
		else: passed = false
	if passed and room_index==4:
		await input_tap("interact")
		report.tests.append({"name":"throat_camp_rest","pass":health==5 and int(checkpoint.room)==4})
		var dash_start: Vector2 = player.position
		Input.action_press("right")
		await input_tap("dash")
		await wait_physics(12)
		Input.action_release("right")
		report.tests.append({"name":"earned_dash_actual_use","pass":abilities.get("dash",false) and player.position.x-dash_start.x>110,"delta_x":player.position.x-dash_start.x,"qa_full_abilities":qa_full_abilities})
		await evidence_frame("normal-earned-dash")
		for target: Vector2 in [Vector2(600,577),Vector2(960,560),Vector2(1450,563),Vector2(1515,560)]:
			var route: Dictionary = await drive_to(target,900)
			route.name = "normal_throat_"+str(int(target.x))
			report.tests.append(route)
			await evidence_frame("normal-throat-"+str(int(target.x)))
			if not route.get("pass",false):
				passed = false
				break
		if passed:
			Input.action_press("right")
			await input_tap("interact")
			Input.action_release("right")
		report.tests.append({"name":"normal_first_level_complete","pass":completed,"health":health})
		await evidence_frame("normal-complete")
	var death_count: int = 0
	var entered: Array = []
	for event: Dictionary in events:
		if event.event == "player_death": death_count+=1
		if event.event == "room_enter": entered.append(event.data.room)
	report.pass = passed and completed and not abilities.get("float",false) and not abilities.get("anchor",false)
	report.deaths = death_count
	report.room_entries = entered
	report.final_abilities = abilities
	report.final_health = health
	report.events = events
	var output_path: String = qa_output.get_base_dir().path_join("normal-run.json")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file: FileAccess = FileAccess.open(output_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("NORMAL_QA passed=",report.pass," deaths=",death_count," rooms=",JSON.stringify(entered))
	await graceful_quit()

func run_normal_reload_qa() -> void:
	load_progress()
	load_room(room_index,checkpoint.get("pos",[]))
	await wait_physics(45)
	var result: Dictionary = {"pass":room_index==4 and completed and abilities.get("dash",false) and not abilities.get("float",false) and not abilities.get("anchor",false) and player.is_on_floor(),"independent_process":true,"room":room_index,"completed":completed,"abilities":abilities,"grounded":player.is_on_floor()}
	result.boss_stable_id_saved = defeated.get("R1-04:0",false)
	await walk_to(Vector2(100,553),400)
	Input.action_press("left")
	await input_tap("interact")
	Input.action_release("left")
	await wait_physics(45)
	var gate: Node2D = scenery.get_node_or_null("World/DoorArt")
	var boss: Node2D = scenery.get_node_or_null("World/EnemyArt0")
	result.boss_room_return = room_index==3
	result.boss_removed = boss!=null and not boss.visible and not enemies.is_empty() and not enemies[0].alive
	result.boss_gate_open = gate!=null and gate.modulate.a<0.01
	result.pass = result.pass and result.boss_stable_id_saved and result.boss_room_return and result.boss_removed and result.boss_gate_open
	var path: String = qa_output.get_base_dir().path_join("normal-reload.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	await evidence_frame("normal-independent-reload")
	print("NORMAL_RELOAD_QA ",JSON.stringify(result))
	await graceful_quit()

func run_revisit_qa() -> void:
	var report: Dictionary = {"method":"03 reward uses normal locked abilities and jump; 06 revisit enables explicit F9 practice. Only initial isolated scenario starts load a room; each route uses actual input. Practice progress is written only to QA save.","tests":[]}
	await flow_setup(2)
	for target: Vector2 in [Vector2(1000,589),Vector2(1135,442)]:
		var result: Dictionary = await drive_to(target,700)
		result.name = "03_reward_approach_"+str(int(target.x))
		report.tests.append(result)
	await input_tap("interact")
	report.tests.append({"name":"03_reward_collected_normal_jump","pass":collected.get("R1-03",false),"abilities":abilities.duplicate(true),"practice":practice,"qa_full_abilities":qa_full_abilities})
	await evidence_frame("revisit-03-reward")
	for target: Vector2 in [Vector2(1320,610),Vector2(1605,612)]:
		var result: Dictionary = await drive_to(target,650)
		result.name = "03_return_main_"+str(int(target.x))
		report.tests.append(result)
	Input.action_press("right")
	await input_tap("interact")
	Input.action_release("right")
	report.tests.append({"name":"03_return_main_exit","pass":room_index==3})
	await flow_setup(1,[225,716])
	await key_tap(KEY_F9)
	report.tests.append({"name":"explicit_revisit_practice","pass":practice and not qa_full_abilities})
	for target: Vector2 in [Vector2(100,420),Vector2(240,495),Vector2(110,265),Vector2(240,340),Vector2(90,110),Vector2(210,186)]:
		var result: Dictionary = await drive_to(target,550)
		result.name = "02_upper_revisit_"+str(int(target.y))
		report.tests.append(result)
	Input.action_press("left")
	await input_tap("interact")
	Input.action_release("left")
	await wait_physics(35)
	report.tests.append({"name":"06_enter_via_02","pass":room_index==5})
	if room_index==5:
		for target: Vector2 in [Vector2(350,560),Vector2(490,643),Vector2(550,420),Vector2(760,482),Vector2(850,270),Vector2(1173,332)]:
			var result: Dictionary = await drive_to(target,750)
			result.name = "06_high_platform_"+str(int(target.y))
			report.tests.append(result)
		await input_tap("interact")
		report.tests.append({"name":"06_high_reward_collected","pass":collected.get("R1-06",false)})
		await evidence_frame("revisit-06-high-reward")
		var latch_route: Dictionary = await drive_to(Vector2(1380,335),400)
		latch_route.name = "06_far_latch_approach"
		report.tests.append(latch_route)
		Input.action_press("right")
		await input_tap("interact")
		Input.action_release("right")
		report.tests.append({"name":"06_far_latch_denies_crossing","pass":room_index==5,"message":message})
		await evidence_frame("revisit-06-far-latch")
		for target: Vector2 in [Vector2(850,482),Vector2(550,643),Vector2(200,792),Vector2(100,795)]:
			var return_route: Dictionary = await drive_to(target,700)
			return_route.name = "06_return_platform_"+str(int(target.x))
			report.tests.append(return_route)
		Input.action_press("left")
		await input_tap("interact")
		Input.action_release("left")
		await wait_physics(35)
		report.tests.append({"name":"06_returns_to_02","pass":room_index==1})
		await key_tap(KEY_F5)
		await evidence_frame("revisit-06-return-02")
	report.events = events
	report.collected = collected
	var failures: int = 0
	for test: Dictionary in report.tests:
		if not test.get("pass",false): failures+=1
	report.failed = failures
	var output_path: String = qa_output.get_base_dir().path_join("revisit.json")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file: FileAccess = FileAccess.open(output_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("REVISIT_QA failed=",failures," tests=",report.tests.size())
	await graceful_quit()

func run_reward_reload_qa() -> void:
	load_progress()
	load_room(room_index,checkpoint.get("pos",[]))
	await wait_physics(45)
	var result: Dictionary = {"pass":collected.get("R1-03",false) and collected.get("R1-06",false) and room_index==1 and player.is_on_floor(),"independent_process":true,"room":room_index,"collected":collected,"grounded":player.is_on_floor()}
	if qa_room7_reload:
		var art: Node2D = scenery.get_node_or_null("World/RewardArt")
		result.pass = collected.get("R1-07",false) and room_index==6 and player.is_on_floor() and art!=null and not art.visible
		result.reward_hidden = art!=null and not art.visible
	var path: String = qa_output.get_base_dir().path_join("reward7-reload.json" if qa_room7_reload else "reward-reload.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	await evidence_frame("reward7-independent-reload" if qa_room7_reload else "reward-independent-reload")
	print("REWARD_RELOAD_QA ",JSON.stringify(result))
	await graceful_quit()

func run_deep_qa() -> void:
	var report: Dictionary = {"method":"One initial scenario start on membrane; all later movement uses actual Input actions, no transforms. No unlocked movement abilities.","tests":[]}
	await flow_setup(2,[840,620])
	await wait_physics(90)
	var membrane: Node = scenery.get_node("VisualMechanisms")
	report.tests.append({"name":"membrane_loaded","pass":player.is_on_floor() and float(membrane.membrane_drop)>15,"drop":membrane.membrane_drop})
	Input.action_press("down")
	await input_tap("jump")
	Input.action_release("down")
	await wait_physics(55)
	report.tests.append({"name":"down_jump_enters_lower_route","pass":player.is_on_floor() and player.position.y>740 and player.collision_mask==1,"position":[player.position.x,player.position.y],"collision_mask":player.collision_mask})
	await evidence_frame("deep-entry")
	for target: Vector2 in [Vector2(350,758),Vector2(1350,750),Vector2(840,798)]:
		var result: Dictionary = await walk_to(target,650)
		result.name = "deep_explore_"+str(int(target.x))
		report.tests.append(result)
		await evidence_frame("deep-"+str(int(target.x)))
	await wait_physics(20)
	var start_y: float = player.position.y
	await input_tap("jump")
	var peak: float = player.position.y
	for frame: int in range(100):
		await get_tree().physics_frame
		peak = minf(peak,player.position.y)
	report.tests.append({"name":"membrane_rebound_returns_main","pass":player.is_on_floor() and player.position.y<730 and start_y-peak>180,"rise_px":start_y-peak,"end":[player.position.x,player.position.y]})
	await evidence_frame("deep-rebound-return")
	var exit_result: Dictionary = await drive_to(Vector2(1605,612),650)
	exit_result.name = "deep_return_to_main_exit"
	report.tests.append(exit_result)
	Input.action_press("right")
	await input_tap("interact")
	Input.action_release("right")
	report.tests.append({"name":"deep_main_exit_door","pass":room_index==3})
	report.events = events
	var failures: int = 0
	for test: Dictionary in report.tests:
		if not test.get("pass",false): failures+=1
	report.failed = failures
	var output_path: String = qa_output.get_base_dir().path_join("deep-route.json")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file: FileAccess = FileAccess.open(output_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("DEEP_QA failed=",failures," tests=",report.tests.size())
	await graceful_quit()

func walk_to(target: Vector2, budget: int = 650) -> Dictionary:
	var initial_room: int = room_index
	var start: Vector2 = player.position
	var frames: int = 0
	for frame: int in range(budget):
		frames = frame
		if room_index!=initial_room: break
		var delta: Vector2 = target-player.position
		if absf(delta.x)<30 and absf(delta.y)<50: break
		Input.action_release("left")
		Input.action_release("right")
		Input.action_press("right" if delta.x>0 else "left")
		await get_tree().physics_frame
	release_controls()
	return {"pass":room_index==initial_room and absf(player.position.x-target.x)<45 and absf(player.position.y-target.y)<60,"start":[start.x,start.y],"end":[player.position.x,player.position.y],"physics_frames":frames}
