extends TestSuite
## Fixtures reuse existing imported bitmaps to test playback, not to approve new art.


func after_each() -> void:
	tree.paused = false
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)
	await super.after_each()


func fixture_data() -> Dictionary:
	var clips: Dictionary = {}
	for name: String in PlayerAnimationData.CLIPS:
		clips[name] = {"frames": [{"file": "attack_0.png", "durationMs": 100},
			{"file": "attack_1.png", "durationMs": 200}, {"file": "attack_2.png", "durationMs": 100}]}
		if name == "run":
			clips[name].stridePixels = 80
		if name in PlayerAnimationData.ATTACKS:
			clips[name].activeWindowMs = [100, 300]
	clips.land.frames = [{"file": "run_0.png", "durationMs": 60}, {"file": "idle_0.png", "durationMs": 60}]
	var left: Dictionary = clips.duplicate(true)
	left.idle.frames = [{"file": "run_1.png", "durationMs": 400}]
	return {"version": 1, "canvas": [384, 288], "pivot": [192, 270], "scale": 0.28,
		"directions": {"left": left, "right": clips}}


func make_player() -> Player:
	var player := add((load("res://src/player/player.tscn") as PackedScene).instantiate()) as Player
	player.position = Vector2(100, -1)
	var visual := player.get_node("Visual") as PlayerVisual
	check(visual.animations.configure(fixture_data(), "res://art/player"), "fixture metadata loads")
	return player


func surface(at: Vector2, size: Vector2) -> void:
	var body := add(StaticBody2D.new()) as StaticBody2D
	body.position = at
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	body.add_child(collision)


func test_nonuniform_timing_direction_and_invalid_fallback() -> void:
	var data := PlayerAnimationData.new()
	check(data.configure(fixture_data(), "res://art/player"), "valid metadata accepted")
	var idle := data.clip("right", "idle")
	for pair: Array in [[0, 0], [0.099, 0], [0.1, 1], [0.299, 1], [0.3, 2], [0.4, 0]]:
		eq(PlayerAnimationData.frame_at(idle, pair[0]), pair[1], "nonuniform loop boundary")
	eq(PlayerAnimationData.frame_at(data.clip("right", "jump_rise"), 3), 2, "air pose holds instead of wrapping")
	check(data.clip("left", "idle").files[0] != idle.files[0], "directions load independent resources")
	var broken := fixture_data()
	broken.directions.left.run.frames[0].file = "missing.png"
	broken.directions.left.attack.activeWindowMs = [300, 100]
	broken.directions.left.heavy.activeWindowMs = [50, 300]
	broken.directions.left.heal.frames[0].durationMs = 0
	data.configure(broken, "res://art/player")
	check(data.clip("left", "run").is_empty() and data.clip("left", "attack").is_empty() and data.clip("left", "heal").is_empty(), "invalid individual clips rejected")
	check(data.clip("left", "heavy").is_empty(), "damage phase must start/end on a visible pose boundary")
	check(not data.clip("right", "run").is_empty(), "bad left clip does not invalidate right")
	check(not data.clip("left", "idle").is_empty(), "bad clip does not invalidate neighboring clip")
	eq(data.issues.size(), 4, "invalid clip diagnostics remain explicit")


func test_actual_distance_wall_stop_turn_and_pause() -> void:
	surface(Vector2(500, 10), Vector2(1000, 20))
	surface(Vector2(260, -60), Vector2(20, 120))
	var player := make_player()
	var visual := player.get_node("Visual") as PlayerVisual
	await physics_frames(8)
	Input.action_press("move_right")
	await physics_frames(20)
	check(visual.run_distance > 50 and visual.run_distance < 75, "stride advances by actual world displacement")
	eq(visual.clip_name, "run", "ground movement selects run")
	await physics_frames(50)
	eq(visual.clip_name, "idle", "continued input into wall stops feet")
	eq(visual.run_distance, 0.0, "wall pressure adds no traveled distance")
	Input.action_release("move_right")
	Input.action_press("move_left")
	await physics_frames(5)
	eq(visual.direction, "left", "turn chooses left resources")
	check(not visual.flip_h and visual.scale.x > 0, "directional art is never mirrored")
	var snapshot := visual.animation_snapshot()
	tree.paused = true
	await physics_frames(6)
	eq(visual.animation_snapshot(), snapshot, "pause freezes animation and distance")
	tree.paused = false


func test_jump_rise_fall_landing_and_reset() -> void:
	surface(Vector2(500, 10), Vector2(1000, 20))
	var player := make_player()
	var visual := player.get_node("Visual") as PlayerVisual
	await physics_frames(8)
	Input.action_press("jump")
	await physics_frames(5)
	Input.action_release("jump")
	eq(visual.clip_name, "jump_rise", "jump begins with rising poses")
	await physics_frames(28)
	eq(visual.clip_name, "jump_fall", "descending physics selects falling poses")
	var landed := false
	for index in 60:
		await physics_frames(1)
		if visual.clip_name == "land":
			landed = true
			break
	check(landed, "ground contact plays separate landing clip")
	await physics_frames(12)
	eq(visual.clip_name, "idle", "landing ends in idle without replaying jump")
	player.reset_at(Vector2(400, -1))
	await physics_frames(4)
	eq(visual.run_distance, 0.0, "reset teleport cannot advance run cycle")
	eq(visual.clip_name, "idle", "reset does not leave stale landing")


func test_attack_visual_and_damage_windows_agree() -> void:
	var player := make_player()
	var visual := player.get_node("Visual") as PlayerVisual
	visual.set_physics_process(false)
	for kind: String in ["short1", "short2", "heavy"]:
		player.actions.begin_attack(player, kind)
		var start := player.actions.attack_active_start()
		var end := player.actions.attack_active_end()
		for sample: float in [start - 0.001, start, (start + end) / 2, end, player.actions.attack_duration() - 0.001]:
			player.actions.elapsed = sample
			player.actions.update_attack(player)
			visual._physics_process(0.001)
			var active := sample >= start and sample < end
			eq(player.hitbox.active, active, "actual damage window: " + kind)
			eq(visual.frame_index, 0 if sample < start else (1 if active else 2), "pose phase matches damage: " + kind)
			eq(visual.clip_name, "heavy" if kind == "heavy" else ("attack2" if kind == "short2" else "attack"), "distinct strike selection")


func test_moving_landing_uses_stride_instead_of_stationary_pose() -> void:
	surface(Vector2(500, 10), Vector2(1000, 20))
	var player := make_player()
	var visual := player.get_node("Visual") as PlayerVisual
	await physics_frames(8)
	Input.action_press("move_right")
	Input.action_press("jump")
	await physics_frames(5)
	Input.action_release("jump")
	check(not player.is_on_floor(), "fixture leaves the floor using jump input")
	for index in 75:
		await physics_frames(1)
		if player.is_on_floor():
			break
	check(player.is_on_floor(), "moving jump actually lands")
	eq(visual.clip_name, "run", "moving landing does not hold planted landing feet")
	var landed_x := player.position.x
	await physics_frames(5)
	check(player.position.x > landed_x + 10, "movement continues across landing")
	eq(visual.clip_name, "run", "stride remains active throughout former landing buffer")
	check(visual.run_distance > 10, "landing motion advances stride from actual distance")


func test_ground_strikes_plant_then_move_in_recovery() -> void:
	surface(Vector2(500, 10), Vector2(1000, 20))
	var player := make_player()
	var visual := player.get_node("Visual") as PlayerVisual
	await physics_frames(8)
	Input.action_press("move_right")
	for kind: String in ["short1", "short2", "heavy"]:
		player.actions.begin_attack(player, kind)
		var start_x := player.position.x
		await physics_frames(ceili(player.actions.attack_active_end() * 60) - 2)
		check(player.actions.elapsed < player.actions.attack_active_end(), "sample is inside planted attack phase")
		check(absf(player.position.x - start_x) < 0.01, "grounded anticipation/contact cannot slide: " + kind)
		await physics_frames(4)
		eq(player.actions.mode, "attack", "moving recovery keeps the same action commitment")
		check(not player.hitbox.active, "recovery movement starts after damage ends")
		check(player.position.x > start_x + 1, "recovery still permits the existing reduced movement")
		eq(visual.clip_name, "run", "recovery movement uses gait instead of planted recovery art")
		var recovery_x := player.position.x
		Input.action_release("move_right")
		Input.action_press("move_left")
		await physics_frames(5)
		check(player.position.x < recovery_x - 1, "opposite input can still retreat in recovery")
		eq(player.facing, 1.0, "recovery does not change attack facing")
		check(visual.run_distance < 0, "backward recovery has signed stride displacement")
		eq(visual.frame_index, 2, "retreat wraps backward into the final gait pose")
		player.actions.change("idle")
		Input.action_release("move_left")
		Input.action_press("move_right")
	Input.action_press("jump")
	await physics_frames(5)
	Input.action_release("jump")
	player.actions.begin_attack(player, "short1")
	var air_x := player.position.x
	await physics_frames(3)
	check(not player.is_on_floor() and player.position.x > air_x + 1, "airborne attack retains horizontal control")
	eq(visual.clip_name, "attack", "air attack keeps its attack pose")


func test_action_time_and_missing_direction_are_explicit() -> void:
	var player := make_player()
	var visual := player.get_node("Visual") as PlayerVisual
	visual.set_physics_process(false)
	for mode: String in ["hurt", "dash", "heal"]:
		player.actions.change(mode)
		var duration := 0.18 if mode == "hurt" else (player.tuning.dash_duration if mode == "dash" else player.tuning.heal_duration)
		player.actions.elapsed = duration * 0.8
		visual._physics_process(0.001)
		eq(visual.clip_name, mode, "action overrides air/ground clip")
		eq(visual.frame_index, 2, "action time determines pose rather than a global clock")
	player.facing = -1
	visual.animations.directions.left.erase("heal")
	visual._physics_process(0.001)
	var snapshot := visual.animation_snapshot()
	check(not snapshot.using_directional, "missing direction is visibly reported as fallback")
	check(snapshot.file.ends_with("heal_0.png"), "legacy fault path is used explicitly")
	check(not snapshot.file.ends_with("attack_2.png"), "missing left clip never silently borrows right clip")
	player.set_physics_process(false)
	visual._physics_process(0.001)
	eq(visual.clip_name, "idle", "menu/victory freezes control in idle, not a stale airborne/action pose")
	check(not visual.effect.visible, "inactive control cannot leave an action effect visible")
