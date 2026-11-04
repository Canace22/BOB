extends TestSuite

const PATH := "user://story-progress-tests/progress.json"

func before_each() -> void:
	_cleanup()

func after_each() -> void:
	_cleanup()

func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".before-new"]:
		if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(PATH + suffix)
	if DirAccess.dir_exists_absolute(PATH + ".tmp"):
		DirAccess.remove_absolute(PATH + ".tmp")

func _write_raw(value: String, suffix: String = "") -> void:
	DirAccess.make_dir_recursive_absolute(PATH.get_base_dir())
	var file := FileAccess.open(PATH + suffix, FileAccess.WRITE)
	file.store_string(value)
	file.close()

func test_order_and_round_trip() -> void:
	var state := StoryProgress.new(PATH)
	check(not state.load_progress(), "No implicit progress for a new player")
	eq(state.advance("c01.completed"), ERR_INVALID_DATA, "Cannot skip required encounters")
	eq(state.advance("unknown"), ERR_INVALID_PARAMETER, "Unknown event rejected")
	for stage: String in StoryProgress.STAGES:
		eq(state.advance(stage), OK, "Ordered event persists")
	var restored := StoryProgress.new(PATH)
	check(restored.load_progress(), "Saved progress reloads")
	eq(restored.flags, state.flags, "Every completed stage survives reload")
	var backup_before: String = FileAccess.get_file_as_string(PATH + ".bak")
	eq(restored.advance("c01.completed"), OK, "Repeated event is idempotent")
	eq(FileAccess.get_file_as_string(PATH + ".bak"), backup_before, "Repeated event retains previous backup")

func test_corruption_recovers_previous_complete_save() -> void:
	var state := StoryProgress.new(PATH)
	state.advance("c01.met_mender")
	state.advance("c01.foragers_retreated")
	_write_raw("{interrupted")
	var restored := StoryProgress.new(PATH)
	check(restored.load_progress(), "Valid backup restores corrupt primary")
	check(restored.recovered_from_backup, "Recovery is reported")
	check(restored.has_flag("c01.met_mender"), "Previous complete event retained")
	check(not restored.has_flag("c01.foragers_retreated"), "Corrupt event never inferred")
	var second := StoryProgress.new(PATH)
	check(second.load_progress() and not second.recovered_from_backup, "Recovered primary is usable")

func test_invalid_schema_and_out_of_order_flags_fail_closed() -> void:
	for data: Dictionary in [
		{"version": 6, "room_id": StoryProgress.ROOM_ID, "flags": {}},
		{"version": true, "room_id": StoryProgress.ROOM_ID, "flags": {}},
		{"version": 1, "room_id": "R1-01", "flags": {}},
		{"version": 1, "room_id": StoryProgress.ROOM_ID, "flags": {"c01.completed": true}},
		{"version": 1, "room_id": StoryProgress.ROOM_ID, "flags": {"c01.met_mender": 1}},
		{"version": 1, "room_id": StoryProgress.ROOM_ID, "flags": {"unknown": true}}]:
		_write_raw(JSON.stringify(data))
		var state := StoryProgress.new(PATH)
		check(not state.load_progress(), "Malformed or foreign state rejected")
		check(state.flags.is_empty(), "Malformed state cannot complete any event")
		eq(state.last_error, ERR_FILE_CORRUPT, "Invalid save reported explicitly")

func test_write_failure_does_not_publish_flags() -> void:
	var state := StoryProgress.new(PATH)
	state.advance("c01.met_mender")
	var before: String = FileAccess.get_file_as_string(PATH)
	DirAccess.make_dir_absolute(PATH + ".tmp")
	check(state.advance("c01.foragers_retreated") != OK, "Unavailable temp target reports failure")
	check(not state.has_flag("c01.foragers_retreated"), "Failed event does not update memory")
	eq(FileAccess.get_file_as_string(PATH), before, "Failed write preserves existing save")
	check(state.reset_progress() != OK, "Failed new journey is reported")
	check(state.has_flag("c01.met_mender"), "Failed reset retains existing in-memory progress")
	eq(FileAccess.get_file_as_string(PATH), before, "Failed reset retains existing file")
	DirAccess.remove_absolute(PATH + ".tmp")
	eq(state.advance("c01.foragers_retreated"), OK, "Same event can be retried")

func test_new_journey_retains_backup_and_isolates_path() -> void:
	var state := StoryProgress.new(PATH)
	state.advance("c01.met_mender")
	var before: String = FileAccess.get_file_as_string(PATH)
	eq(state.reset_progress(), OK, "Explicit new journey writes empty chapter progress")
	eq(FileAccess.get_file_as_string(PATH + ".before-new"), before, "Old journey preserved")
	check(state.flags.is_empty(), "New journey starts without flags")
	var restored := StoryProgress.new(PATH)
	check(restored.load_progress() and restored.flags.is_empty(), "Fresh empty progress is valid")
	check(StoryProgress.new().path == "user://story-c01/progress.json", "Default is separate from V6")

func test_flags_snapshot_cannot_bypass_persistence() -> void:
	var state := StoryProgress.new(PATH)
	var snapshot: Dictionary = state.flags
	snapshot["c01.completed"] = true
	check(not state.has_flag("c01.completed"), "External snapshot cannot publish unsaved progress")
	check(not FileAccess.file_exists(PATH), "Reading state does not create a save")
