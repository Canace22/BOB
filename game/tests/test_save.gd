extends TestSuite


func test_roundtrip_keeps_progress() -> void:
	var data := SaveService.default_data()
	data["checkpoint_room"] = "R1-04"
	data["abilities"] = ["ability.dash"]
	data["flags"] = ["boss.r1_shell_crab"]
	check(SaveService.write(data, TEST_SAVE), "write succeeds")
	eq(SaveService.read(TEST_SAVE), data, "read returns written data")


func test_corrupt_file_falls_back_to_backup() -> void:
	var first := SaveService.default_data()
	first["checkpoint_room"] = "R1-04"
	SaveService.write(first, TEST_SAVE)
	SaveService.write(SaveService.default_data(), TEST_SAVE)
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	eq(SaveService.read(TEST_SAVE)["checkpoint_room"], "R1-04", "backup is used")


func test_invalid_data_starts_new_journey() -> void:
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 99, "checkpoint_room": "R1-04"}))
	file.close()
	eq(SaveService.read(TEST_SAVE), SaveService.default_data(), "unknown version is rejected")
	eq(SaveService.validate({"version": 1, "checkpoint_room": "R1-01", "abilities": [3], "flags": []}), {}, "non-string ability is rejected")


func test_game_state_persists_abilities_and_flags() -> void:
	GameState.autosave = true
	GameState.grant_ability("ability.dash")
	GameState.set_flag("boss.r1_shell_crab")
	GameState.rest_at("R1-04")
	GameState.apply(SaveService.default_data())
	check(not GameState.has_ability("ability.dash"), "state cleared before reload")
	GameState.load_progress()
	check(GameState.has_ability("ability.dash"), "ability restored")
	check(GameState.has_flag("boss.r1_shell_crab"), "flag restored")
	eq(GameState.checkpoint_room, "R1-04", "checkpoint restored")


func test_stats_clamp() -> void:
	check(not GameState.damage(1), "first hit does not kill")
	eq(GameState.hp, GameState.MAX_HP - 1, "hp decreased")
	GameState.heal(5)
	eq(GameState.hp, GameState.MAX_HP, "heal clamps to max")
	check(GameState.spend_energy(2), "energy spent")
	check(not GameState.spend_energy(3), "cannot overspend")
	check(GameState.damage(10), "lethal damage reports death")
	eq(GameState.hp, 0, "hp floors at zero")


func test_unknown_room_and_corrupt_primary_do_not_poison_backup() -> void:
	var data := SaveService.default_data()
	data["checkpoint_room"] = "unknown-room"
	eq(SaveService.validate(data), {}, "unknown checkpoint rejected")
	data["checkpoint_room"] = "R1-04"
	check(SaveService.write(data, TEST_SAVE), "valid first save")
	check(SaveService.write(data, TEST_SAVE), "valid backup created")
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("corrupt")
	file.close()
	check(SaveService.write(SaveService.default_data(), TEST_SAVE), "new primary written")
	file = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("corrupt again")
	file.close()
	eq(SaveService.read(TEST_SAVE)["checkpoint_room"], "R1-04", "last healthy backup retained")
