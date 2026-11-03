extends TestSuite

func test_movement_immunity_does_not_flash() -> void:
	var player := load("res://content/whalebelly/Player.tscn").instantiate() as TidePlayer
	player.preload_actions = false
	add(player)
	player.set_physics_process(false)
	player.world_bounds = Rect2(-10000, -10000, 20000, 20000)
	player.coyote = 0.1
	player._try_jump()
	check(player.invulnerable > 0, "jump protection preserved")
	player._physics_process(0.001)
	eq(player.body.material.get_shader_parameter("flash"), 0.0, "jump keeps original color")
	player._try_jump()
	player._physics_process(0.001)
	eq(player.damage_flash_left, 0.0, "double jump does not start damage feedback")
	player.state_duration = 0
	check(player.request_action("A1_dash"), "dash accepted")
	player._physics_process(0.001)
	check(player.invulnerable > 0, "dash protection preserved")
	eq(player.body.material.get_shader_parameter("flash"), 0.0, "dash keeps original color")
	check(not player.take_damage(1), "movement protection still rejects damage")
	eq(player.damage_flash_left, 0.0, "blocked damage does not flash")
	player.invulnerable = 0
	check(player.take_damage(1), "real damage accepted")
	check(player.damage_flash_left > 0, "real damage starts feedback")
	player._physics_process(0.001)
	eq(player.body.material.get_shader_parameter("flash"), 1.0, "damage renders white feedback")
	player._physics_process(player.hurt_invulnerability + 0.01)
	eq(player.body.material.get_shader_parameter("flash"), 0.0, "damage feedback expires")
	player.take_damage(1, Vector2.ZERO, true)
	player.respawn()
	eq(player.damage_flash_left, 0.0, "respawn clears damage feedback")
	eq(player.body.material.get_shader_parameter("flash"), 0.0, "respawn restores color immediately")
	check(player.invulnerable > 0, "respawn protection preserved")
