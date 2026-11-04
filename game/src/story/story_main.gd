class_name StoryMain
extends Node2D
## Isolated narrative sample. Never loads or migrates campaign V6 progress.

@export var qa_save: bool = false
var progress: StoryProgress
var ui: StoryUI
var world: Node2D
var environment: Node2D
var player: StoryPlayer
var mender: StorySpriteAnimator
var foragers: Array[StoryForager] = []
var audio: StoryAudio
var camera: Camera2D
var flow := StoryFlow.new()
var started: bool = false
var pending_resume: bool = false
var released_frames: int = 0
var full_view: bool = false
var events: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ThemeDB.fallback_font = preload("res://art/fonts/WhalefallUI.ttf")
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--story-qa": qa_save = true
	progress = StoryProgress.new("user://story-c01-qa/progress.json" if qa_save else "user://story-c01/progress.json")
	var has_save: bool = progress.load_progress()
	flow.host = self
	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	environment = preload("res://content/story/xuting_environment.tscn").instantiate()
	world.add_child(environment)
	player = preload("res://content/story/player.tscn").instantiate()
	player.position = mark("PlayerSpawn")
	player.z_index = 6
	world.add_child(player)
	mender = StoryArt.actor("mender", 90.0)
	mender.position = mark("MenderStart")
	mender.z_index = 5
	world.add_child(mender)
	_spawn_foragers()
	audio = StoryAudio.new()
	world.add_child(audio)
	player.died.connect(_died)
	player.damaged.connect(func() -> void: audio.cue("hurt"))
	player.animation_tag.connect(func(tag: String) -> void:
		if tag == "jump": audio.cue("jump")
		elif tag == "strike_01:start": audio.cue("strike"))
	player.interaction_requested.connect(func(_target: Node) -> void: flow.interact())
	camera = Camera2D.new()
	camera.position = Vector2(640, 640)
	add_child(camera)
	ui = StoryUI.new()
	add_child(ui)
	player.notification.connect(ui.show_notice)
	ui.start_requested.connect(_start)
	ui.retry_requested.connect(_retry)
	ui.pause_changed.connect(_pause)
	ui.title_requested.connect(_title)
	ui.dialogue_finished.connect(flow.dialogue_finished)
	ui.dialogue_closed.connect(func(_id: String) -> void: mender.set_action(&"mend"))
	var observer := StoryWebStatus.new()
	observer.host = self
	add_child(observer)
	_restore_world()
	ui.show_title(has_save)
	_pause(true)
	if progress.last_error != OK and progress.last_error != ERR_FILE_NOT_FOUND:
		ui.show_notice(progress.last_message)

func mark(id: String) -> Vector2:
	return environment.get_node("Markers/"+id).global_position

func _spawn_foragers() -> void:
	for index: int in range(2):
		var enemy := StoryForager.new()
		enemy.stable_id = "forager-left" if index==0 else "forager-right"
		enemy.home = mark("EnemyHomeLeft" if index==0 else "EnemyHomeRight")
		enemy.territory = Vector2(900, 1360) if index==0 else Vector2(1780, 2180)
		enemy.player = player
		enemy.z_index = 5
		world.add_child(enemy)
		enemy.struck.connect(func() -> void: audio.cue("hit"))
		foragers.append(enemy)

func _restore_world() -> void:
	var settled: bool = progress.has_flag("c01.foragers_retreated")
	for enemy: StoryForager in foragers: enemy.reset(settled)
	mender.position = mark("MenderEnd" if settled else "MenderStart")
	mender.set_action(&"idle" if settled else &"mend")
	player.spawn_point = mark("MenderEnd")-Vector2(140,0) if settled else mark("Camp") if progress.has_flag("c01.met_mender") else mark("PlayerSpawn")
	player.respawn()
	flow.reset()

func _start(fresh: bool) -> void:
	if fresh and progress.reset_progress()!=OK:
		ui.show_title(not progress.flags.is_empty())
		ui.show_notice(progress.last_message)
		_pause(true)
		return
	started = true
	_restore_world()
	audio.begin()
	_pause(false)

func _retry() -> void:
	_restore_world()
	_pause(false)
	record("respawn")

func _died() -> void:
	ui.show_death()
	_pause(true)
	record("death")

func _title() -> void:
	started = false
	ui.show_title(FileAccess.file_exists(progress.path))
	_pause(true)

func _pause(value: bool) -> void:
	released_frames = 0
	audio.set_paused(value and ui.page != "dialogue")
	mender.process_mode = Node.PROCESS_MODE_ALWAYS if value and ui.page == "dialogue" else Node.PROCESS_MODE_PAUSABLE
	player.controls_enabled = false
	player.clear_input()
	if value:
		pending_resume = false
		get_tree().paused = true
	else: pending_resume = true

func _physics_process(delta: float) -> void:
	if pending_resume:
		if _held_inputs():
			released_frames = 0
			return
		# A released physical key can still have a just_pressed edge this tick.
		# Keep one full physics boundary before the player reads actions again.
		released_frames += 1
		if released_frames < 2: return
		pending_resume = false
		player.clear_input()
		player.controls_enabled = true
		get_tree().paused = false
	if not started or get_tree().paused: return
	flow.tick(delta)
	player.interacted_target = self if _near_interaction() else null
	_update_camera(delta)
	if player.position.y>960: player.take_damage(5, Vector2.ZERO, true)

func _process(_delta: float) -> void:
	if ui != null: ui.set_hud(player.health, StoryText.objective(progress), flow.hint() if started else "")

func _near_interaction() -> bool:
	return player.position.distance_to(mender.position)<135 or player.position.distance_to(mark("Camp"))<110 or player.position.distance_to(mark("Exit"))<170

func _held_inputs() -> bool:
	for key: int in [KEY_A,KEY_D,KEY_LEFT,KEY_RIGHT,KEY_J,KEY_Q,KEY_K,KEY_SPACE,KEY_E,KEY_ENTER,KEY_R]:
		if Input.is_physical_key_pressed(key): return true
	return false

func _update_camera(delta: float) -> void:
	if full_view:
		camera.zoom = Vector2.ONE*0.4
		camera.position = Vector2(1600,500)
	else:
		camera.zoom = Vector2.ONE
		var target := Vector2(clampf(player.position.x+80*player.facing,640,2560),640)
		camera.position = camera.position.lerp(target,1.0-exp(-6.0*delta))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode == KEY_M:
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))
	elif event.physical_keycode == KEY_TAB and started:
		full_view = not full_view
		_update_camera(1.0)

func record(kind: String, values: Dictionary = {}) -> void:
	events.append({"kind":kind,"values":values,"ticks":Time.get_ticks_msec()})
	if events.size()>80: events.pop_front()

func _exit_tree() -> void:
	get_tree().paused = false
