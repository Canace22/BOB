extends TestSuite


func make_boss() -> CrabPrototype:
	var player := add((load("res://src/player/player.tscn") as PackedScene).instantiate()) as Player
	player.set_physics_process(false)
	player.position = Vector2(600, 500)
	var boss := add((load("res://src/enemies/crab_prototype/crab_prototype.tscn") as PackedScene).instantiate()) as CrabPrototype
	boss.set_physics_process(false)
	boss.hitbox.set_physics_process(false)
	boss.target = player
	boss.reset_at(Vector2(400, 500))
	boss.begin()
	return boss


func test_selection_filters_distance_cooldown_repeat_and_space() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	eq(CrabMoves.select(250, 400, {}, "", 0, rng), "charge", "far target permits charge")
	eq(CrabMoves.select(250, 100, {}, "", 0, rng), "", "wall blocks charge selection")
	eq(CrabMoves.select(250, 400, {"charge": 2.0}, "", 0, rng), "", "charge cooldown filters move")
	eq(CrabMoves.select(50, 400, {}, "sweep", 2, rng), "slam", "third repeated sweep forbidden")
	eq(CrabMoves.select(50, 400, {"slam": 2.0}, "sweep", 2, rng), "", "no valid candidate waits")
	eq(CrabMoves.select(250, 400, {}, "", 0, rng, 40), "", "corner blocks heavy advance")
	eq(CrabMoves.select(50, 400, {}, "sweep", 2, rng, 40), "sweep", "corner always retains jumpable sweep")
	var boss := make_boss()
	boss.target.position.x = 1150
	boss.step_ai(0.4)
	eq(boss.selection_reason, "approach", "far player still attracts boss")
	check(boss.velocity.x > 0, "boss approaches beyond old 500px threshold")


func test_direction_lock_and_charge_tracking_cutoff() -> void:
	var boss := make_boss()
	boss.facing = 1
	boss.start_tell("sweep")
	boss.target.position.x = 100
	boss.step_ai(0.4)
	eq(boss.facing, 1.0, "sweep cannot turn during tell")
	boss.start_tell("charge")
	boss.step_ai(0.2)
	eq(boss.facing, -1.0, "early charge tell can track")
	boss.step_ai(0.75)
	boss.target.position.x = 800
	boss.step_ai(0.1)
	eq(boss.facing, -1.0, "last 450ms of charge locks facing")
	boss.step_ai(0.31)
	eq(boss.state, "active", "charge launches")
	check(boss.hitbox.active, "charge has active damage window")
	boss.step_ai(0.61)
	eq(boss.state, "recover", "charge duration bounded")
	check(not boss.hitbox.active, "charge recovery has no damage")


func test_half_health_waits_for_round_and_second_sweep_is_bounded() -> void:
	var boss := make_boss()
	boss.start_tell("sweep")
	boss.health.apply_hit(HitData.create(boss.health.maximum / 2 + 5, Vector2.ZERO))
	boss.step_ai(0.86)
	boss.step_ai(0.19)
	eq(boss.state, "recover", "crossing half health adds no surprise second sweep")
	boss.step_ai(0.86)
	eq(boss.state, "phase", "phase transition waits for recovery")
	check(not boss.hitbox.active, "phase change cannot damage")
	boss.step_ai(0.81)
	eq(boss.phase, 2, "half health transitions once")
	boss.start_tell("sweep")
	boss.step_ai(0.86)
	boss.step_ai(0.19)
	eq(boss.kind, "second", "phase two advertises second sweep")
	eq(boss.state, "tell", "second sweep has independent tell")
	check(not boss.hitbox.active, "combo gap disables attack")
	boss.step_ai(0.66)
	boss.step_ai(0.19)
	eq(boss.state, "recover", "second sweep cannot recurse")
	boss.step_ai(0.86)
	eq(boss.state, "observe", "phase transition does not repeat")


func test_death_and_retry_clear_attack_without_story_side_effects() -> void:
	var boss := make_boss()
	var before := GameState.to_save_data().duplicate(true)
	var deaths: Array[int] = []
	boss.defeated.connect(func() -> void: deaths.append(1))
	boss.start_tell("charge")
	boss.start_active()
	boss.health.apply_hit(HitData.create(999, Vector2.ZERO))
	eq(boss.state, "dead", "lethal hit wins over attack state")
	eq(deaths.size(), 1, "one defeat notification")
	check(not boss.hitbox.active, "death immediately clears attack")
	eq(GameState.to_save_data(), before, "prototype cannot grant story reward or checkpoint")
	boss.reset_at(Vector2(600, 500), 23)
	eq(boss.health.current, boss.health.maximum, "retry restores boss health")
	eq(boss.phase, 1, "retry restores first phase")
	eq(boss.streak, 0, "retry clears selection history")
	eq(boss.cooldowns, {"slam": 0.0, "charge": 0.0}, "retry clears cooldowns")
	check(not boss.running and not boss.hitbox.active and not boss.hurtbox.immune, "retry leaves clean waiting state")


func test_attack_shapes_and_recovery_cooldown_contract() -> void:
	var boss := make_boss()
	var shape := boss.hitbox.get_node("Shape") as CollisionShape2D
	boss.start_tell("sweep")
	eq((shape.shape as RectangleShape2D).size.y, 85.0, "low sweep fits the authored claw with a small forgiving margin")
	boss.start_tell("slam")
	eq((shape.shape as RectangleShape2D).size.y, 280.0, "slam requires retreat rather than small jump")
	boss.start_active()
	boss.step_ai(0.19)
	eq(float(boss.cooldowns["slam"]), 0.0, "cooldown waits for recovery completion")
	boss.step_ai(1.51)
	eq(float(boss.cooldowns["slam"]), 4.0, "completed slam starts four second cooldown")


func make_floor() -> void:
	var ground := StaticBody2D.new()
	ground.position = Vector2(650, 520)
	ground.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1500, 40)
	shape.shape = rect
	ground.add_child(shape)
	add(ground)


func test_charge_physics_stops_at_arena_boundary() -> void:
	make_floor()
	var boss := make_boss()
	boss.stop()
	boss.position = Vector2(1160, 500)
	boss.target.position = Vector2(1400, 500)
	boss.set_physics_process(true)
	await physics_frames(3)
	boss.running = true
	boss.facing = 1
	boss.start_tell("charge")
	boss.start_active()
	await physics_frames(6)
	check(boss.position.x <= boss.arena_bounds.y, "moving charge cannot leave arena bounds")
	eq(boss.state, "recover", "hitting arena edge immediately starts recovery")
	check(not boss.hitbox.active, "boundary stops charge damage")
	check(boss.is_on_floor(), "boundary stop remains grounded")


func test_large_shell_charge_requires_retreat_not_jumping_through() -> void:
	make_floor()
	var boss := make_boss()
	var player := boss.target
	player.position.x = 700
	player.collision_mask = 5
	boss.stop()
	boss.set_physics_process(true)
	boss.hitbox.set_physics_process(true)
	player.set_physics_process(true)
	await physics_frames(3)
	boss.running = true
	boss.facing = 1
	boss.start_tell("charge")
	var jumped := false
	for frame in 150:
		await tree.physics_frame
		if not jumped and boss.state == "active":
			Input.action_press("jump")
			jumped = true
		if boss.state == "recover":
			break
	Input.action_release("jump")
	eq(GameState.hp, 3, "jumping cannot pass through the full-height giant shell")
	check(player.position.x > boss.position.x, "solid shell prevents crossing to the back")
	boss.reset_at(Vector2(400, 500))
	GameState.restore()
	player.reset_at(Vector2(700, 500))
	await physics_frames(65)
	boss.begin()
	boss.facing = 1
	boss.start_tell("charge")
	var retreated := false
	for frame in 150:
		await tree.physics_frame
		if not retreated and boss.state == "tell" and boss.timer >= 0.6:
			Input.action_press("move_right")
			retreated = true
		if boss.state == "recover":
			break
	Input.action_release("move_right")
	check(retreated and player.position.x > 800, "keyboard retreat creates clear distance")
	eq(GameState.hp, 4, "advance can be avoided without dash or jump")


func test_large_boss_low_claw_sweep_can_be_jumped_in_place() -> void:
	make_floor()
	var boss := make_boss()
	var player := boss.target
	player.position.x = 650
	player.collision_mask = 5
	boss.stop()
	boss.set_physics_process(true)
	boss.hitbox.set_physics_process(true)
	player.set_physics_process(true)
	await physics_frames(3)
	boss.running = true
	boss.facing = 1
	boss.start_tell("sweep")
	var jumped := false
	for frame in 120:
		await tree.physics_frame
		if not jumped and boss.state == "tell" and boss.timer >= 0.44:
			Input.action_press("jump")
			jumped = true
		if boss.state == "recover":
			break
	Input.action_release("jump")
	check(jumped, "player jumped while low claw pulled back")
	eq(GameState.hp, 4, "stationary jump clears only the low claw, not the full shell")
