extends TestSuite
## Real scene ancestry and saved flags, without touching a player save.
class ProgressHost extends Node2D:
	var abilities: Dictionary = {}
	var practice: bool = false

func field(parent: Node, flag: String = "pressure") -> KitDriftField:
	var value := KitDriftField.new()
	value.texture = preload("res://art/world-kit/fx-particle-drift.png")
	value.bounds = Rect2(0, 0, 1000, 1000)
	value.population = 3
	value.velocity = Vector2(0, -150)
	value.opacity = 0.5
	value.unlocked_velocity = Vector2(0, -35)
	value.unlocked_opacity = 0.2
	value.progress_flag = flag
	parent.add_child(value)
	value.set_process(false)
	return value

func make_progress_host() -> ProgressHost:
	var value := ProgressHost.new()
	add(value)
	return value

func test_unflagged_field_keeps_existing_motion_and_flag_changes_are_continuous() -> void:
	var host := make_progress_host()
	var ambience := Node2D.new()
	host.add_child(ambience)
	var base := field(ambience, "")
	var current := field(ambience)
	base.update_at(100.0)
	current.update_at(100.0)
	check(base.drift_offset.is_equal_approx(Vector2(0, -15000)), "Unflagged field keeps its original path")
	check(current.drift_offset.is_equal_approx(base.drift_offset), "Locked field has no visual change")
	host.practice = true
	current.update_at(100.01)
	eq(current.progress_mix, 0.0, "Practice is not saved progress")
	host.abilities.pressure = true
	var before: Vector2 = current.motes[0].node.position
	current.update_at(current.time)
	check(current.motes[0].node.position.is_equal_approx(before), "Changing a flag without advancing time does not teleport")
	current.update_at(current.time + 0.01)
	check(current.motes[0].node.position.distance_to(before) < 3.0, "Large elapsed time does not amplify an unlock into a teleport")
	check(current.progress_mix > 0.0 and current.progress_mix < 1.0, "Unlock starts a smooth transition")

func test_progress_transition_is_frame_rate_independent_and_reload_uses_saved_state() -> void:
	var host := make_progress_host()
	var fine := field(host)
	var coarse := field(host)
	host.abilities.pressure = true
	for i: int in 60: fine.update_at(float(i + 1) / 60.0)
	coarse.update_at(1.0)
	check(fine.drift_offset.is_equal_approx(coarse.drift_offset), "Continuous integration matches across render rates")
	check(is_equal_approx(fine.progress_mix, coarse.progress_mix), "Blend reaches the same state across render rates")
	var restored := field(host)
	eq(restored.progress_mix, 1.0, "Reload starts at the saved unlocked state")
	restored.update_at(1.0)
	check(restored.drift_offset.is_equal_approx(restored.unlocked_velocity), "Reload uses slow current immediately")
	for mote: Dictionary in restored.motes:
		check(mote.node.modulate.a <= restored.unlocked_opacity, "Restored current uses unlocked opacity")

func test_progress_field_holds_when_scene_tree_pauses_and_keeps_its_pool() -> void:
	var host := make_progress_host()
	var current := field(host)
	current.process_mode = Node.PROCESS_MODE_PAUSABLE
	current.set_process(true)
	await tree.process_frame
	var before: float = current.time
	var position: Vector2 = current.motes[0].node.position
	tree.paused = true
	host.abilities.pressure = true
	for i: int in 3: await tree.process_frame
	eq(current.time, before, "Pause holds the field clock")
	eq(current.motes[0].node.position, position, "Pause holds the current pose")
	tree.paused = false
	await tree.process_frame
	check(current.time >= before, "Resume continues the same clock")
	eq(current.motes.size(), 3, "Progress and pause never replace the bounded pool")
	current.set_process(false)

func campaign(id: String) -> WhalebellyMain:
	var host := WhalebellyMain.new()
	host.qa_full_abilities = false
	var original: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	host.rooms = CampaignWorld.load_rooms(original)
	for i: int in host.rooms.size():
		if str(host.rooms[i].id) == id:
			host.room_index = i
			host.room = host.rooms[i]
	host.completed = true
	return host

func test_later_region_goals_do_not_end_at_the_first_region_milestone() -> void:
	var host := campaign("R3-01")
	# Empty the room-local list to exercise the fallback itself.
	host.room = host.room.duplicate(true)
	host.room.next = []
	check(WhaleUIMapPage.short_hint(host).contains("潮压"), "Fallback before pressure points to the next marker")
	host.abilities.pressure = true
	check(WhaleUIMapPage.short_hint(host).contains("断脊"), "Pressure opens the next leg")
	host.abilities.bone = true
	check(WhaleUIMapPage.short_hint(host).contains("静默"), "Bone leaves the ear-sea goal")
	host.abilities.silence = true
	check(WhaleUIMapPage.short_hint(host).contains("释放槽"), "All three markers point to the finale")
	host.abilities.ending = true
	check(WhaleUIMapPage.short_hint(host).contains("已归海"), "Ending reads as whole-journey completion")
	eq(CampaignGuidance.next_room(host), "", "Ending does not offer a stale local next room")
	check(CampaignGuidance.hint(host).contains("回访"), "Post-ending HUD invites exploration")
	host.free()

func test_live_later_boss_has_a_local_goal_and_old_first_region_still_works() -> void:
	var host := campaign("R2-04")
	check(WhaleUIMapPage.short_hint(host).contains("击败血巢潮群"), "A living Boss is the local objective")
	host.defeated["R2-04:0"] = true
	host.abilities.pressure = true
	check(not WhaleUIMapPage.short_hint(host).contains("首关完成"), "Victory does not imply the journey ended")
	host.free()
	var old := WhalebellyMain.new()
	old.rooms = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	old.room = old.rooms[4]
	old.completed = true
	eq(CampaignGuidance.objective(old), "首关完成", "First-region-only builds retain their original milestone")
	old.free()
