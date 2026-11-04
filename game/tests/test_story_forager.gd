extends TestSuite
## Real forager state/physics with a damage-counting target; no campaign or user saves.
const PATH := "user://story-forager-tests/progress.json"

class DamageProbe extends StoryPlayer:
	var damage_calls: int = 0
	func _ready() -> void: pass
	func _physics_process(_delta: float) -> void: pass
	func take_damage(amount: int = 15, _source: Vector2 = Vector2.ZERO, _force: bool = false) -> bool:
		damage_calls += 1
		health -= amount
		return true

class UIProbe extends RefCounted:
	var completed: int = 0
	func show_notice(_text: String) -> void: pass
	func show_complete() -> void: completed += 1

class AudioProbe extends RefCounted:
	func cue(_id: String) -> void: pass

class PauseHost extends StoryMain:
	func _ready() -> void: pass

class QuietUI extends StoryUI:
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass

class FlowHost extends Node2D:
	var player: DamageProbe
	var progress: StoryProgress
	var foragers: Array[StoryForager] = []
	var mender := StorySpriteAnimator.new()
	var ui := UIProbe.new()
	var audio := AudioProbe.new()
	var events: Array[String] = []
	func mark(id: String) -> Vector2:
		return {"EncounterStart":Vector2(900, 100), "MenderEnd":Vector2(2550, 100),
			"Exit":Vector2(2990, 100)}.get(id, Vector2.ZERO)
	func record(kind: String, _values: Dictionary = {}) -> void: events.append(kind)
	func _init() -> void: add_child(mender)
func before_each() -> void:
	super.before_each()
	_cleanup()

func after_each() -> void:
	tree.paused = false
	await super.after_each()
	_cleanup()

func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".before-new"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(PATH + suffix)

func _probe() -> DamageProbe:
	var target := DamageProbe.new()
	# Satisfy inherited onready references without loading the campaign player scene.
	var visual := Node2D.new()
	visual.name = "Visual"
	var sprite := Sprite2D.new()
	sprite.name = "Body"
	visual.add_child(sprite)
	target.add_child(visual)
	var animations := AnimationPlayer.new()
	animations.name = "AnimationPlayer"
	target.add_child(animations)
	var animation_tree := AnimationTree.new()
	animation_tree.name = "AnimationTree"
	target.add_child(animation_tree)
	target.position = Vector2(260, 100)
	target.health = 100
	add(target)
	return target

func _floor() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1200, 40)
	shape.shape = rectangle
	body.position = Vector2(500, 120)
	body.add_child(shape)
	add(body)

func _enemy(target: DamageProbe, home_x: float = 320) -> StoryForager:
	var enemy := StoryForager.new()
	enemy.home = Vector2(home_x, 100)
	enemy.territory = Vector2(0, 800)
	enemy.player = target
	add(enemy)
	enemy.set_physics_process(false)
	return enemy

func test_damage_causes_visible_alive_retreat_and_exactly_one_settlement() -> void:
	_floor()
	var enemy := _enemy(_probe())
	await physics_frames(2)
	var counts := {"settled":0}
	enemy.withdrew.connect(func() -> void: counts.set("settled", int(counts.settled) + 1))
	enemy.take_hit(10)
	eq(enemy.accepted_hits, 0, "Unengaged animal cannot be defeated before the encounter")
	enemy.engage()
	enemy.position.x = 220
	enemy.take_hit(0)
	enemy.take_hit(-1)
	eq(enemy.firmness, 3, "Nonpositive damage does not count as a confrontation")
	enemy.take_hit(1)
	eq(enemy.visual.current_action, &"hurt", "A nonlethal hit plays the authored hurt pose")
	for index: int in range(2): enemy.take_hit(1)
	eq(enemy.state, "retreat", "Third accepted short hit requests living retreat")
	eq(counts.settled, 0, "Damage alone cannot resolve the encounter")
	enemy.take_hit(20)
	eq(enemy.accepted_hits, 3, "Retreating animal is no longer a damage target")
	for index: int in range(90): enemy._physics_process(1.0 / 60.0)
	eq(enemy.state, "settled", "Physical return to home completes retreat")
	check(absf(enemy.position.x - enemy.home.x) < 5, "Settlement really reaches the food area")
	check(enemy.snapshot().alive and not enemy.is_queued_for_deletion(), "Settled animal remains alive and visible")
	eq(counts.settled, 1, "Arrival emits one settlement event")
	for index: int in range(60): enemy._physics_process(1.0 / 60.0)
	eq(counts.settled, 1, "Remaining at home never replays settlement")
	enemy.engage()
	eq(enemy.state, "settled", "Settled animal cannot restart pursuit")

func test_tell_direction_allows_crossing_behind_without_backwards_damage() -> void:
	var target := _probe()
	var enemy := _enemy(target)
	enemy.facing = -1
	enemy.change_state("tell")
	target.position = enemy.position + Vector2(60, 0)
	enemy.timer = 0.56
	enemy._update_behavior(0.01)
	eq(enemy.state, "lunge", "Completed warning commits the originally telegraphed lunge")
	enemy.timer = 0.07
	enemy._update_behavior(0.01)
	eq(target.damage_calls, 0, "Player who crossed behind the tell is outside the forward strike")
	enemy.change_state("lunge")
	target.position = enemy.position + Vector2(-60, 0)
	enemy.timer = 0.07
	enemy._update_behavior(0.01)
	enemy._update_behavior(0.01)
	eq(target.damage_calls, 1, "Forward target takes exactly one hit per lunge")

func test_pause_freezes_retreat_physics_and_authored_frames() -> void:
	_floor()
	var enemy := _enemy(_probe())
	enemy.engage()
	enemy.position.x -= 80
	enemy.take_hit(3)
	enemy.set_physics_process(true)
	await physics_frames(4)
	tree.paused = true
	var snapshot := {"position":enemy.position, "timer":enemy.timer,
		"elapsed":enemy.visual.elapsed, "frame":enemy.visual.frame}
	await tree.create_timer(0.08, true, false, true).timeout
	eq(enemy.position, snapshot.position, "Pause stops physical retreat")
	eq(enemy.timer, snapshot.timer, "Pause stops settlement timing")
	eq(enemy.visual.elapsed, snapshot.elapsed, "Pause holds authored animation time")
	eq(enemy.visual.frame, snapshot.frame, "Pause holds the current pose")
	tree.paused = false
	await physics_frames(4)
	check(enemy.timer > float(snapshot.timer), "Resume advances the same retreat")

func _pause_host() -> PauseHost:
	var host := PauseHost.new()
	add(host)
	host.set_process(false)
	host.set_physics_process(false)
	host.player = _probe()
	host.audio = StoryAudio.new()
	host.add_child(host.audio)
	host.ui = QuietUI.new()
	host.add_child(host.ui)
	host.mender = StoryArt.actor("mender", 90)
	host.add_child(host.mender)
	return host

func test_dialogue_plays_mender_while_pause_menu_freezes_it() -> void:
	var host := _pause_host()
	host.mender.set_action(&"talk")
	host.ui.page = "dialogue"
	host._pause(true)
	await tree.create_timer(0.08, true, false, true).timeout
	check(tree.paused and not host.player.controls_enabled, "Dialogue pauses gameplay input")
	check(host.mender.elapsed > 0, "Mender communication frames keep their animation clock")
	host.ui.page = "pause"
	host._pause(true)
	var elapsed: float = host.mender.elapsed
	await tree.create_timer(0.08, true, false, true).timeout
	eq(host.mender.elapsed, elapsed, "Pause menu freezes even the mender")
	tree.paused = false

func test_same_tick_interact_release_waits_for_a_physics_boundary() -> void:
	WhalebellyTideInput.install()
	var host := _pause_host()
	host._pause(true)
	var press := InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	Input.parse_input_event(press)
	var release: InputEventKey = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	check(not Input.is_physical_key_pressed(KEY_E), "The physical interaction key is already released")
	check(Input.is_action_just_pressed("tp_interact"), "Same-tick press and release retains the stale action edge")
	host._pause(false)
	host._physics_process(1.0 / 60.0)
	check(tree.paused and not host.player.controls_enabled, "First released tick cannot feed stale E back to gameplay")
	check(host.pending_resume, "Resume remains pending for a complete physics boundary")
	await tree.physics_frame
	host._physics_process(1.0 / 60.0)
	check(not tree.paused and host.player.controls_enabled, "Second released tick safely restores gameplay")
	check(not host.pending_resume, "Resume request clears after the boundary")

func test_progress_requires_both_arrivals_then_route_then_exit() -> void:
	var host := FlowHost.new()
	host.player = _probe()
	host.progress = StoryProgress.new(PATH)
	host.foragers = [_enemy(host.player), _enemy(host.player, 600)]
	add(host)
	var flow := StoryFlow.new()
	flow.host = host
	flow.reset()
	host.player.position = Vector2(3100, 100)
	flow.tick(2)
	check(not flow.encounter_started and host.progress.flags.is_empty(), "Jumping to exit before introduction earns no progress")
	eq(host.progress.advance("c01.met_mender"), OK, "Isolated introduction persists")
	flow.tick(2)
	for enemy: StoryForager in host.foragers: enemy.take_hit(3)
	flow.tick(0.1)
	check(not host.progress.has_flag("c01.foragers_retreated"), "Two depleted animals still travelling are not resolved")
	host.foragers[0].reset(true)
	flow.tick(0.1)
	check(not host.progress.has_flag("c01.foragers_retreated"), "One settled side cannot resolve both threats")
	host.foragers[1].reset(true)
	flow.tick(0.1)
	check(host.progress.has_flag("c01.foragers_retreated"), "Both confirmed arrivals allow the retreat event")
	check(not host.progress.has_flag("c01.completed"), "Standing at exit without route conversation cannot finish")
	eq(host.progress.advance("c01.route_known"), OK, "Route conversation is a separate saved prerequisite")
	host.player.position.x = 2980
	flow.tick(0.1)
	check(not host.progress.has_flag("c01.completed"), "Knowing direction before actually crossing exit is not completion")
	host.player.position.x = 2995
	flow.tick(0.1)
	check(host.progress.has_flag("c01.completed"), "Active player crossing the unlocked exit completes chapter")
	flow.tick(1)
	eq(host.ui.completed, 1, "Exit completion is presented only once")
