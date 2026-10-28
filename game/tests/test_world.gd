extends TestSuite


func test_seven_rooms_have_valid_entries_and_links() -> void:
	for id: String in WorldGraph.ROOMS:
		var room := (load(WorldGraph.room_path(id)) as PackedScene).instantiate() as Room
		eq(room.room_id, id, "scene stable ID agrees with registry")
		check(room.has_node("Entries/default") and room.has_node("Entries/camp"), "fallback entries exist")
		for node in room.get_node("Gameplay").get_children():
			if node is RoomDoor:
				var door := node as RoomDoor
				if WorldGraph.ROOMS.has(door.target_room):
					var target := (load(WorldGraph.room_path(door.target_room)) as PackedScene).instantiate() as Room
					check(target.has_node("Entries/" + door.target_entry), "reciprocal entry exists")
					target.free()
		room.free()


func test_boss_victory_and_dash_claim_are_separate() -> void:
	var room := add((load(WorldGraph.room_path("R1-04")) as PackedScene).instantiate()) as Room
	var door := room.get_node("Gameplay/Door_E04") as RoomDoor
	var pickup := room.get_node("Gameplay/Reward0") as Pickup
	check(not door.denied().is_empty(), "exit locked before boss")
	pickup.use()
	check(not GameState.has_ability("ability.dash"), "cannot claim before boss")
	GameState.set_flag("boss.r1_shell_crab")
	check(not GameState.has_ability("ability.dash"), "victory alone does not grant ability")
	check(not door.denied().is_empty(), "exit still requires claim")
	pickup.use()
	check(GameState.has_ability("ability.dash"), "interaction grants dash")
	eq(door.denied(), "", "exit opens after claim")


func test_optional_abilities_and_far_side_latch_remain_locked() -> void:
	var door := add(RoomDoor.new()) as RoomDoor
	door.required_abilities = ["ability.float"]
	check(not door.denied().is_empty(), "float gate remains locked")
	GameState.grant_ability("ability.float")
	eq(door.denied(), "", "required ability opens gate")
	door.required_flags = ["shortcut.blowhole"]
	check(not door.denied().is_empty(), "far-side latch is independent of ability")


func test_bridge_and_camp_progress_survive_reload() -> void:
	GameState.autosave = true
	var room := add((load(WorldGraph.room_path("R1-03")) as PackedScene).instantiate()) as Room
	var lever := room.get_node("Gameplay/Lever") as ShellLever
	check(not lever.bridge.visible, "bridge starts closed")
	lever.use()
	check(lever.bridge.visible, "lever opens authored bridge")
	GameState.rest_at("R1-04")
	GameState.load_progress()
	check(GameState.has_flag("latch.r1_tongue"), "latch persists")
	eq(GameState.checkpoint_room, "R1-04", "checkpoint persists")
