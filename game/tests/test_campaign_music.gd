extends TestSuite

func visit(host: WhalebellyMain, room_id: String) -> void:
	var index := host.rooms.find_custom(func(room: Dictionary) -> bool: return room.id == room_id)
	host.load_room(index)

func test_score_follows_encounter_and_sluice() -> void:
	var host: WhalebellyMain = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.integration_external_test = true
	host.qa_full_abilities = false
	add(host)
	var music := host.music
	check(music.playing and music.stream == CampaignMusic.HARBOR, "Main scene plays harbor music")
	for theme: AudioStreamOggVorbis in CampaignMusic.LEVEL_DB:
		eq(theme.loop, theme != CampaignMusic.RELEASE, "Imported loop flag for " + theme.resource_path)
	visit(host, "R4-01")
	visit(host, "R2-04")
	await physics_frames(60)
	eq(music.stream, CampaignMusic.NURSERY, "Rapid travel cancels the obsolete fade; boss is still idle")
	var swarm: KitEncounter = host.enemies[0].actor
	host.player.position = swarm.data.pos
	for frame: int in 360:
		await physics_frames(1)
		if music.stream == CampaignMusic.BATTLE: break
	eq(music.stream, CampaignMusic.BATTLE, "The first real attack tell brings in the combat score")
	host.damage_enemy(swarm.data, 100)
	await physics_frames(60)
	eq(music.stream, CampaignMusic.NURSERY, "Defeat restores the area theme")
	visit(host, "R4-03")
	await physics_frames(60)
	eq(music.stream, CampaignMusic.SPINE, "Spine theme plays")
	visit(host, "R5-08")
	host.player.position = host.point(host.room.reward)
	host.interact()
	await physics_frames(60)
	eq(music.stream, CampaignMusic.MEMORY, "Locked sluice keeps the memory theme")
	for ability: String in ["silence","bone","pressure"]: host.abilities[ability] = true
	host.player.position = host.point(host.room.reward)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F
	key.keycode = KEY_F
	key.pressed = true
	Input.parse_input_event(key)
	await physics_frames(4)
	key.pressed = false
	Input.parse_input_event(key)
	await physics_frames(60)
	check(host.collected.get("R5-08", false) and music.playing and music.stream == CampaignMusic.RELEASE, "F opens the sluice and starts the one-shot")
	visit(host, "R5-01")
	visit(host, "R5-08")
	await physics_frames(60)
	eq(music.stream, CampaignMusic.MEMORY, "Revisiting the released sluice does not replay the ending")

func test_mother_crab_approach_combat_and_return() -> void:
	var host: WhalebellyMain = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.integration_external_test = true
	add(host)
	visit(host, "R1-04")
	var crab: CampaignCrabBoss = host.enemies[0].actor
	await physics_frames(60)
	check(not crab.running and host.music.stream == CampaignMusic.SPINE, "Den entrance has a separate approach theme")
	host.player.position = crab.position - Vector2(420, 0)
	await physics_frames(60)
	check(crab.running and host.music.stream == CampaignMusic.BATTLE, "Crab engagement triggers the orchestral battle section")
	host.damage_enemy(crab.data, int(crab.data.hp))
	await physics_frames(60)
	eq(host.music.stream, CampaignMusic.HARBOR, "Victory returns to the harbor theme")
	visit(host, "R1-04")
	await physics_frames(60)
	eq(host.music.stream, CampaignMusic.HARBOR, "Cleared den stays peaceful on return")

func test_hub_rest_and_memory_score() -> void:
	var host: WhalebellyMain = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	add(host)
	visit(host, "R3-01")
	await physics_frames(60)
	eq(host.music.stream, CampaignMusic.HUB, "The stomach hub has its own exploration theme")
	host.player.position = host.point(host.room.camp)
	check(host.try_camp(), "Rest at the real hub checkpoint")
	await physics_frames(60)
	eq(host.music.stream, CampaignMusic.REST, "Rest theme plays while gameplay is paused")
	var playback := host.music.get_stream_playback()
	host.player_ui.open("camp_details")
	check(host.music.get_stream_playback() == playback, "Camp details preserve the music phrase")
	host.player_ui.close_all()
	await physics_frames(60)
	eq(host.music.stream, CampaignMusic.HUB, "Leaving camp restores the hub")
	for id: String in ["R1-07", "R5-02"]:
		visit(host, id)
		await physics_frames(60)
		eq(host.music.stream, CampaignMusic.REST, "Quiet refuge or memory pocket: " + id)
	visit(host, "R5-01")
	await physics_frames(60)
	eq(host.music.stream, CampaignMusic.MEMORY, "Ear-sea memory theme")
