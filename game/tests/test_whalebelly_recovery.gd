extends TestSuite

func test_recovered_campaign_is_default_and_all_seven_rooms_exist() -> void:
	eq(ProjectSettings.get_setting("application/run/main_scene"), "res://content/whalebelly/main.tscn", "F5 opens the recovered campaign")
	var rooms: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	eq(rooms.size(), 7, "All authored rooms recovered")
	for room: Dictionary in rooms:
		check(ResourceLoader.exists("res://content/whalebelly/r1/" + str(room.id) + ".tscn"), "Authored room exists: " + str(room.id))
	check(ResourceLoader.exists("res://src/main/main.tscn"), "Modular campaign remains available")

func test_recovered_runtime_dependencies_exist_in_game() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/whalebelly/recovery-manifest.json"))
	for entry: Dictionary in manifest.files:
		var destination: String = str(entry.destination).trim_prefix("game/")
		check(FileAccess.file_exists("res://" + destination), "Recovered dependency exists: " + destination)
	var player := (load("res://content/whalebelly/CampaignPlayer.tscn") as PackedScene).instantiate()
	eq(player.max_speed, 265.0, "Original movement baseline retained")
	eq(player.max_health, 5, "Original campaign health retained")
	player.free()

func test_campaign_save_directory_is_separate() -> void:
	CampaignSaveBridge.prepare(false)
	check(DirAccess.dir_exists_absolute("user://whalebelly"), "V6 campaign gets its own directory")
	eq(GameState.save_path, TEST_SAVE, "Preparing V6 saves does not mutate the modular test save")

func test_legacy_save_import_is_validated_and_never_overwrites() -> void:
	var source := "user://test-whalebelly-import/source"
	var target := "user://test-whalebelly-import/target"
	DirAccess.make_dir_recursive_absolute(source)
	DirAccess.make_dir_recursive_absolute(target)
	var filename := "artmatch_save.json"
	if FileAccess.file_exists(target.path_join(filename)):
		DirAccess.remove_absolute(target.path_join(filename))
	_write_fixture(source.path_join(filename), "{invalid")
	CampaignSaveBridge.import_from(source, target)
	check(not FileAccess.file_exists(target.path_join(filename)), "Invalid old save is rejected")
	_write_fixture(source.path_join(filename), '{"version":6,"checkpoint":{"room":3,"pos":[100,648]}}')
	CampaignSaveBridge.import_from(source, target)
	var original := FileAccess.get_file_as_string(target.path_join(filename))
	check(original.contains('"version":6'), "V6 save copied to isolated destination")
	_write_fixture(source.path_join(filename), '{"version":6,"checkpoint":{"room":0}}')
	CampaignSaveBridge.import_from(source, target)
	eq(FileAccess.get_file_as_string(target.path_join(filename)), original, "Existing progress is never overwritten")

func _write_fixture(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
