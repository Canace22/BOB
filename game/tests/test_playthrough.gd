extends TestSuite
## Input-only route. Never teleports the player, changes progress, or damages enemies directly.

var main: GameMain
var jump_elapsed: float = -1.0
var attack_delay: float = 0.0
var keys: Dictionary[String, bool] = {}
var rooms_seen: Array[String] = []


func test_five_room_keyboard_route_and_reload() -> void:
	main = add((load("res://src/main/main.tscn") as PackedScene).instantiate()) as GameMain
	await physics_frames(4)
	for frame in 24000:
		await tree.physics_frame
		if main.changing or main.room == null or main.player.dead:
			continue
		if not rooms_seen.has(main.room.room_id):
			rooms_seen.append(main.room.room_id)
			print("ROUTE ", main.room.room_id, " hp=", GameState.hp)
		if GameState.has_flag("complete.r1"):
			break
		_drive(1.0 / 60.0)
		if frame % 1800 == 1799:
			print("ROUTE tick ", frame, " room=", GameState.current_room, " pos=", main.player.position, " hp=", GameState.hp)
	_release_all()
	check(GameState.has_flag("boss.r1_shell_crab"), "boss defeated through input")
	check(GameState.has_ability("ability.dash"), "dash claimed through interaction")
	check(GameState.has_flag("complete.r1"), "three dash gaps crossed to exit")
	eq(rooms_seen, ["R1-01", "R1-02", "R1-03", "R1-04", "R1-05"], "five rooms reached in order")
	GameState.autosave = true
	GameState.save_progress()
	GameState.load_progress()
	check(GameState.has_ability("ability.dash"), "dash remains after reload")
	eq(GameState.checkpoint_room, "R1-04", "boss camp remains after reload")


func _drive(delta: float) -> void:
	var player := main.player
	var id := main.room.room_id
	attack_delay = maxf(0, attack_delay - delta)
	_key("move_left", false)
	_key("move_right", true)
	for action: String in ["jump", "attack", "dash", "interact"]:
		_key(action, false)
	if id in ["R1-01", "R1-04"] and player.position.x < 4 * 64:
		if GameState.checkpoint_room != id or GameState.hp < 4:
			_tap("interact")
	var target: EnemyBase
	for node in tree.get_nodes_in_group("enemy"):
		var enemy := node as EnemyBase
		var dx := absf(enemy.position.x - player.position.x)
		if enemy.state != "dead" and ((enemy.boss and dx < 600) or (not enemy.boss and dx < 220 and absf(enemy.position.y - player.position.y) < 30)):
			target = enemy
			break
	if target != null:
		_combat(player, target)
		return
	if id == "R1-04" and GameState.has_flag("boss.r1_shell_crab") and not GameState.has_ability("ability.dash") and player.position.x > 31 * 64:
		_tap("interact")
	if id == "R1-05" and player.position.x > 2.8 * 64 and player.position.x < 5 * 64 and not GameState.has_flag("habitat.r1_clearflow"):
		_tap("interact")
	if player.is_on_floor():
		jump_elapsed = -1
		var from := player.global_position + Vector2(42, -8)
		var ray := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 30), 1)
		if player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			_tap("jump")
			jump_elapsed = 0
	elif jump_elapsed >= 0:
		jump_elapsed += delta
		if id == "R1-05" and jump_elapsed > 0.30 and not player.actions.air_dash:
			_tap("dash")
	if player.position.x > main.room.dimensions.x - 150:
		_tap("interact")


func _combat(player: Player, enemy: EnemyBase) -> void:
	var dx := enemy.position.x - player.position.x
	_key("move_right", dx > 0)
	_key("move_left", dx < 0)
	if enemy.state in ["tell", "active"]:
		if enemy.kind == "slam":
			_key("move_right", dx < 0)
			_key("move_left", dx > 0)
		else:
			if enemy.state == "tell" and enemy.timer > (0.20 if enemy.kind == "second" else 0.43) and player.is_on_floor():
				_tap("jump")
			if absf(dx) < 100:
				_key("move_left", false)
				_key("move_right", false)
	else:
		if absf(dx) < 100:
			_key("move_left", false)
			_key("move_right", false)
			if player.actions.is_free() and attack_delay <= 0:
				_tap("attack")
				attack_delay = 0.10
			elif player.actions.mode == "attack" and player.actions.attack_kind == "short1" and player.actions.elapsed > 0.31:
				_tap("attack")


func _tap(action: String) -> void:
	_key(action, true)


func _key(action: String, pressed: bool) -> void:
	if keys.get(action, false) == pressed:
		return
	keys[action] = pressed
	var binding := InputMap.action_get_events(action)[0] as InputEventKey
	var event := InputEventKey.new()
	event.physical_keycode = binding.physical_keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _release_all() -> void:
	for action: String in keys.keys():
		_key(action, false)
