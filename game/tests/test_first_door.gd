extends TestSuite
## The complete ascent is covered by xumen_layout_routes.gd; this fixture
## isolates the final bank, visible threshold, input and transition contract.

func test_visible_first_door_accepts_interaction() -> void:
	var host: WhalebellyMain = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	add(host)
	await physics_frames(30)
	var door: Dictionary = host.room.doors[0]
	var lane: Dictionary = host.room.layout.checkpoint_lanes.filter(func(value: Dictionary) -> bool: return float(value.x[0]) < float(door.pos[0]) and float(value.x[1]) > float(door.pos[0]) and absf(float(value.y) - float(door.pos[1])) < 24.0)[0]
	host.player.position = Vector2(float(lane.x[0]) + 4.0, float(lane.y) - 4.0)
	host.player.velocity = Vector2.ZERO
	await physics_frames(15)
	var approach_x: float = float(door.pos[0]) - 45.0
	Input.action_press("tp_right")
	for frame: int in 120:
		await physics_frames(1)
		if host.player.position.x >= approach_x: break
	Input.action_release("tp_right")
	await physics_frames(25)
	eq(host.room_index, 0, "approaching the visible door stays in the first room")
	check(host.player.position.x >= approach_x and host.player.is_on_floor(), "normal input approaches the visible door from its final bank")
	check(not host.player_ui.data.prompt().is_empty() and host.player_ui.data.prompt_door() != null, "painted door approach offers interaction")
	var entrance: CampaignDoorway = host.continuity.doorways[0]
	check(is_instance_valid(entrance.inset) and is_instance_valid(entrance.lip), "passage has a visible painted entrance")
	var lip_center_x: float = entrance.lip.global_position.x + 512.0 * entrance.lip.scale.x
	check(absf(entrance.lip.global_position.y - host.ground_y(lip_center_x, entrance.position.y)) < 1.0, "foreground threshold starts at the slope, not the character waist")
	Input.action_press("tp_interact")
	await physics_frames(2)
	Input.action_release("tp_interact")
	await physics_frames(120)
	eq(host.room_index, 1, "E at the visible doorway reaches the next room")
	check(not host.continuity.travelling and not host.player.transition_locked, "transition releases controls")
	host.process_mode = Node.PROCESS_MODE_DISABLED
	for tween: Tween in tree.get_processed_tweens(): tween.kill()
	for sound: Node in host.find_children("*", "AudioStreamPlayer", true, false):
		sound.stop()
		sound.stream = null
	host.sound_bank.clear()
	host.sound_variants.clear()
	await tree.create_timer(0.3).timeout
