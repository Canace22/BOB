extends TestSuite
## The complete ascent is covered by xumen_layout_routes.gd; this fixture
## isolates the final bank, visible threshold, input and transition contract.

func test_visible_first_door_crosses_by_walking() -> void:
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
	check(host.player.is_on_floor(), "normal walking reaches the door on the road")
	check(host.player_ui.data.prompt_door() == null, "open streaming passage does not offer teleport interaction")

	var entrance: CampaignDoorway = host.continuity.doorways[0]
	check(not is_instance_valid(entrance.inset) and not is_instance_valid(entrance.lip), "black passage art is removed")
	var score_playback := host.music.get_stream_playback()
	var identity: int = host.player.get_instance_id()
	Input.action_press("tp_right")
	for frame: int in 500:
		await physics_frames(1)
		if host.room_index == 1: break
	Input.action_release("tp_right")
	await physics_frames(10)
	eq(host.room_index, 1, "walking through the connection reaches the next room without E")
	check(host.music.playing and host.music.get_stream_playback() == score_playback, "walking between harbor rooms preserves the active music playback")
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
