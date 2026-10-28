extends TestSuite


func test_hitbox_hits_each_target_once_per_swing() -> void:
	var body := add(Health.new()) as Health
	body.maximum = 40
	body.restore()
	var target := add(Hurtbox.new()) as Hurtbox
	target.health = body
	var box := add(Hitbox.new()) as Hitbox
	box.activate(HitData.create(10, Vector2.ZERO))
	check(box.try_hit(target), "first overlap lands")
	check(not box.try_hit(target), "same target cannot be damaged twice")
	eq(body.current, 30, "one damage application")
	box.activate(HitData.create(14, Vector2.ZERO))
	check(box.try_hit(target), "new swing can hit again")
	eq(body.current, 16, "combo second hit has its own damage")


func test_immunity_and_lethal_damage() -> void:
	var body := add(Health.new()) as Health
	var target := add(Hurtbox.new()) as Hurtbox
	target.health = body
	target.immune = true
	check(not target.receive(HitData.create(1, Vector2.ZERO)), "immunity rejects damage")
	eq(body.current, 4, "no damage while protected")
	target.immune = false
	check(target.receive(HitData.create(8, Vector2.ZERO)), "lethal damage accepted")
	eq(body.current, 0, "health clamps at zero")
	check(not target.receive(HitData.create(1, Vector2.ZERO)), "dead target cannot be hit again")


func test_player_action_costs_and_dash_gate() -> void:
	var player := add((load("res://src/player/player.tscn") as PackedScene).instantiate()) as Player
	player.set_physics_process(false)
	Input.action_press("dash")
	player.actions.step(player, 0.016)
	eq(player.actions.mode, "idle", "dash unavailable before grant")
	Input.action_release("dash")
	await tree.process_frame
	GameState.grant_ability("ability.dash")
	Input.action_press("dash")
	player.actions.step(player, 0.016)
	eq(player.actions.mode, "dash", "dash available after grant")
	Input.action_release("dash")
	player.actions.change("idle")
	await tree.process_frame
	Input.action_press("heavy")
	player.actions.step(player, 0.016)
	eq(player.actions.attack_kind, "heavy", "heavy starts")
	eq(GameState.energy, 2, "heavy costs two energy")
	Input.action_release("heavy")
