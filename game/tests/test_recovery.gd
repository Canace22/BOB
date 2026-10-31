extends TestSuite


func test_death_returns_to_checkpoint_and_retains_progress() -> void:
	GameState.grant_ability("ability.dash")
	GameState.set_flag("boss.r1_shell_crab")
	GameState.rest_at("R1-04")
	var main := add((load("res://src/main/main.tscn") as PackedScene).instantiate()) as GameMain
	await physics_frames(5)
	main.player.invulnerable = 0
	main.player.hurtbox.immune = false
	main.player.hurtbox.receive(HitData.create(10, main.player.position))
	check(main.player.dead, "lethal hit enters death state")
	await physics_frames(30)
	eq(GameState.current_room, "R1-04", "respawn uses stable checkpoint ID")
	eq(GameState.hp, GameState.MAX_HP, "respawn restores health")
	check(not main.player.dead, "player can act again")
	check(GameState.has_ability("ability.dash") and GameState.has_flag("boss.r1_shell_crab"), "permanent progress survives death")


func test_pause_freezes_player_and_world_then_resumes() -> void:
	var main := add((load("res://src/main/main.tscn") as PackedScene).instantiate()) as GameMain
	await physics_frames(5)
	var menu := main.get_node("Pause") as GamePause
	menu.open_map()
	var before := main.player.position
	Input.action_press("move_right")
	await physics_frames(10)
	eq(main.player.position, before, "world does not move while map is open")
	menu.close()
	await physics_frames(10)
	check(main.player.position.x > before.x, "movement resumes")
	Input.action_release("move_right")
