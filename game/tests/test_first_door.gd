extends TestSuite
## Walk to the reported painted doorway using normal input, not a door-position fixture.

func test_visible_first_door_crosses_by_walking() -> void:
	var host: WhalebellyMain = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	add(host)
	await physics_frames(30)
	Input.action_press("tp_right")
	for frame: int in 600:
		await physics_frames(1)
		if host.player.position.x >= 1495.0: break
	Input.action_release("tp_right")
	await physics_frames(25)
	eq(host.room_index, 0, "approaching the visible door stays in the first room")
	check(host.player.is_on_floor(), "normal walking reaches the door on the road")
	check(host.player_ui.data.prompt_door() == null, "open streaming passage does not offer teleport interaction")
	var entrance: CampaignDoorway = host.continuity.doorways[0]
	check(is_instance_valid(entrance.inset) and is_instance_valid(entrance.lip), "passage has a visible painted entrance")
	var lip_center_x: float = entrance.lip.global_position.x + 512.0 * entrance.lip.scale.x
	check(absf(entrance.lip.global_position.y - host.ground_y(lip_center_x, entrance.position.y)) < 1.0, "foreground threshold starts at the slope, not the character waist")
	var identity: int = host.player.get_instance_id()
	Input.action_press("tp_right")
	for frame: int in 500:
		await physics_frames(1)
		if host.room_index == 1: break
	Input.action_release("tp_right")
	await physics_frames(10)
	eq(host.room_index, 1, "walking through the connection reaches the next room without E")
	eq(host.player.get_instance_id(),identity,"normal travel preserves the player")
	check(not host.continuity.travelling and not host.player.transition_locked, "transition releases controls")
	host.process_mode = Node.PROCESS_MODE_DISABLED
	for tween: Tween in tree.get_processed_tweens(): tween.kill()
	for sound: Node in host.find_children("*", "AudioStreamPlayer", true, false):
		sound.stop()
		sound.stream = null
	host.sound_bank.clear()
	host.sound_variants.clear()
	await tree.create_timer(0.3).timeout
