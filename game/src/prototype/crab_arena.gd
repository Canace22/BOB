class_name CrabArena
extends Node2D
## Standalone sparring session. Never reads or writes campaign save files.

const ARENA := Vector2(760, 1860)
@onready var player: Player = $World/Player
@onready var boss: CrabPrototype = $World/Boss
@onready var camera: Camera2D = $World/Camera
@onready var world: Node2D = $World
var stage: String = "ready"
var dash_enabled: bool = false
var shake_enabled: bool = true
var battle_time: float = 0.0
var start_delay: float = 0.0
var shake_left: float = 0.0
var freeze_left: float = 0.0
var saved: Dictionary = {}


func _enter_tree() -> void:
	saved = {"data": GameState.to_save_data(), "autosave": GameState.autosave,
		"path": GameState.save_path, "loaded": GameState.loaded, "room": GameState.current_room,
		"hp": GameState.hp, "energy": GameState.energy, "arena": GameState.arena_active}
	GameState.autosave = false
	GameState.apply(SaveService.default_data())
	GameState.current_room = "prototype.crab"


func _ready() -> void:
	player.tuning = player.tuning.duplicate() as PlayerTuning
	player.tuning.prototype_controls = true
	player.collision_mask = 5
	player.bounds = Rect2(0, 0, 2304, 1200)
	player.arena_bounds = ARENA
	boss.arena_bounds = Vector2(ARENA.x + 180, ARENA.y - 180)
	boss.retreat_bounds = ARENA
	boss.target = player
	boss.defeated.connect(_victory)
	EventBus.player_died.connect(_defeat)
	EventBus.hit_landed.connect(_hit_feedback)
	EventBus.sfx.connect(_impact_feedback)
	prepare()


func _exit_tree() -> void:
	get_tree().paused = false
	GameState.apply(saved.data)
	GameState.autosave = saved.autosave
	GameState.save_path = saved.path
	GameState.loaded = saved.loaded
	GameState.current_room = saved.room
	GameState.hp = saved.hp
	GameState.energy = saved.energy
	GameState.arena_active = saved.arena


func prepare() -> void:
	get_tree().paused = false
	freeze_left = 0
	shake_left = 0
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	GameState.apply(SaveService.default_data())
	GameState.current_room = "prototype.crab"
	GameState.arena_active = true
	if dash_enabled:
		GameState.grant_ability("ability.dash")
	player.reset_at(Vector2(920, 893))
	boss.reset_at(Vector2(1520, 893), 7)
	player.set_physics_process(false)
	camera.offset = Vector2.ZERO
	camera.zoom = Vector2.ONE
	stage = "ready"
	battle_time = 0


func start() -> void:
	prepare()
	stage = "entering"
	start_delay = 0.45
	camera.zoom = Vector2(1.06, 1.06)


func toggle_dash() -> void:
	if stage in ["ready", "won", "lost"]:
		dash_enabled = not dash_enabled
		prepare()


func toggle_pause() -> void:
	if stage in ["fighting", "entering"]:
		get_tree().paused = not get_tree().paused


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ENTER:
		if stage in ["ready", "won", "lost"]:
			start()
	if freeze_left > 0 and not get_tree().paused and not event.is_echo():
		if event.is_action_pressed("jump"):
			player.locomotion.buffer_jump(player.tuning)
		for action: StringName in [&"attack", &"heavy", &"heal", &"dash"]:
			if event.is_action_pressed(action):
				player.actions.buffer_input(action)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if freeze_left > 0:
		freeze_left = maxf(0, freeze_left - delta)
		if freeze_left <= 0:
			world.process_mode = Node.PROCESS_MODE_PAUSABLE
		return
	if stage == "entering":
		start_delay -= delta
		camera.zoom = Vector2.ONE * (1.0 + 0.06 * maxf(start_delay, 0) / 0.45)
		if start_delay <= 0:
			stage = "fighting"
			player.set_physics_process(true)
			boss.begin()
	elif stage == "fighting":
		battle_time += delta
	shake_left = maxf(0, shake_left - delta)
	camera.offset = Vector2(sin(shake_left * 180) * 3, cos(shake_left * 150) * 2) if shake_enabled and shake_left > 0 else Vector2.ZERO


func _hit_feedback(_at: Vector2, heavy: bool) -> void:
	if stage != "fighting":
		return
	freeze_left = 0.06 if heavy else 0.035
	world.process_mode = Node.PROCESS_MODE_DISABLED
	if heavy:
		shake_left = 0.1


func _impact_feedback(id: String) -> void:
	if stage == "fighting" and id == "slam":
		shake_left = 0.1


func _victory() -> void:
	_finish("won")


func _defeat() -> void:
	_finish("lost")


func _finish(result: String) -> void:
	stage = result
	freeze_left = 0
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	if result != "won":
		boss.stop()
	player.hitbox.deactivate()
	player.set_physics_process(false)
	camera.offset = Vector2.ZERO
	shake_left = 0
	GameState.arena_active = false
