extends TestSuite
## Integration invariants for remapping the seven rooms without changing their content.

func source_rooms() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))

func test_layout_preserves_stable_ids_six_internal_links_and_original_door_requirements() -> void:
	var source: Array = source_rooms()
	var original: Array = source.duplicate(true)
	var runtime: Array = CampaignWorld.load_rooms(source)
	var edges: Dictionary = {}
	for index: int in 7:
		var room: Dictionary = runtime[index]
		eq(str(room.id), "R1-0%d" % (index + 1), "Saved first-region room indices never move")
		eq(room.doors.size(), source[index].doors.size(), "Door count remains stable: " + str(room.id))
		for at: int in room.doors.size():
			var door: Dictionary = room.doors[at]
			var previous: Dictionary = source[index].doors[at]
			eq(CampaignWorld.requirements(door), CampaignWorld.requirements(previous), "Existing ability requirements remain: %s/%d" % [room.id, at])
			var target: int = int(door.to)
			if str(room.id) == "R1-05" and at == 1:
				eq(str(runtime[target].id), "R3-01", "External exit still reaches the hub")
				check(door.get("completes", false), "External exit retains its milestone")
			else: eq(target, int(previous.to), "Original graph destination remains: %s/%d" % [room.id, at])
			if target >= 0 and target < 7:
				var pair: Array[int] = [index, target]
				pair.sort()
				edges["%d-%d" % pair] = true
	var expected: Array = ["0-1", "1-2", "1-5", "1-6", "2-3", "3-4"]
	var actual: Array = edges.keys()
	actual.sort()
	eq(actual, expected, "Exactly the original six bidirectional first-region connections remain")
	eq(int(runtime[5].doors[1].to), -2, "The far-side latch remains unbuilt and closed")
	eq(source, original, "Loading the authored layout never mutates historical source data")

func test_layout_keeps_three_crabs_one_boss_and_the_same_reward_ids() -> void:
	var rooms: Array = CampaignWorld.load_rooms(source_rooms())
	var ordinary: Array[String] = []
	var bosses: Array[String] = []
	var rewards: Array[String] = []
	for room: Dictionary in rooms.slice(0, 7):
		for at: int in room.enemies.size():
			var enemy: Dictionary = room.enemies[at]
			if enemy.boss: bosses.append("%s:%d" % [room.id, at])
			else:
				ordinary.append("%s:%d" % [room.id, at])
				eq(str(enemy.type), "corpse-crab", "Ordinary encounters keep the authored crab adapter")
		if not room.get("reward", []).is_empty(): rewards.append(str(room.id))
	eq(ordinary, ["R1-02:0", "R1-03:0", "R1-03:1"], "Three crab stable IDs remain unchanged")
	eq(bosses, ["R1-04:0"], "Mother crab retains its sole persistent Boss ID")
	eq(rewards, ["R1-03", "R1-06", "R1-07"], "Shield and memory collection flags remain compatible")
	eq(CampaignRelics.capacity({"R1-03":true}), 2, "Tongue terrace still grants two shield charges")
	eq(CampaignRelics.capacity({"R1-06":true}), 1, "Upper vent still grants one shield charge")
	eq(str(rooms[6].get("reward_grants", "float")), "float", "Memory reward keeps its float semantics")

func test_every_new_room_scene_loads_the_current_layout_environment_and_terrain() -> void:
	var rooms: Array = CampaignWorld.load_rooms(source_rooms())
	for room: Dictionary in rooms.slice(0, 7):
		check(room.has("layout") and int(room.layout.version) == 1, "Authored layout is active: " + str(room.id))
		check(not room.layout.checkpoint_lanes.is_empty(), "Room has safe checkpoint landings: " + str(room.id))
		var scene: Node = load(CampaignWorld.scene_path(str(room.id))).instantiate()
		check(scene.has_node("LayoutEnvironment"), "Current scene owns layout animation: " + str(room.id))
		check(not scene.has_node("ReferenceEnvironment"), "Legacy whole-road presentation is absent: " + str(room.id))
		check(scene.has_node("World/Terrain") and scene.has_node("World/Art"), "Physical and visible terrain are both present: " + str(room.id))
		check(scene.get_node("World/Art").get_child_count() > 0, "Scene loads actual bitmap terrain: " + str(room.id))
		if str(room.id) == "R1-03":
			check(scene.has_node(str(room.layout.membrane.contour_path)), "Membrane collision binds to its actual authored node")
			for path: String in room.layout.membrane.art_paths: check(scene.has_node(path), "Membrane visual path resolves: " + path)
		scene.free()

func test_web_export_explicitly_packages_the_runtime_layout_json() -> void:
	var config := ConfigFile.new()
	eq(config.load("res://export_presets.cfg"), OK, "Export preset can be read")
	var included := str(config.get_value("preset.0", "include_filter", "")).split(",")
	check(included.has("content/whalebelly/layout/rooms.json"), "Web package explicitly includes the non-resource layout table")
	check(FileAccess.file_exists(CampaignWorld.LAYOUT), "Runtime loader targets a real exported layout table")
	eq(str(config.get_value("preset.0", "export_filter")), "all_resources", "New scenes and their real bitmap dependencies are exported")

func test_physical_camps_do_not_share_a_door_interaction_zone() -> void:
	for room: Dictionary in CampaignWorld.load_rooms(source_rooms()).slice(0,7):
		var camp: Array = room.get("camp",[])
		if camp.is_empty(): continue
		var safe: bool = false
		for lane: Dictionary in room.layout.checkpoint_lanes:
			if float(camp[0]) >= float(lane.x[0]) and float(camp[0]) <= float(lane.x[1]) and absf(float(camp[1])-float(lane.y))<2: safe = true
		check(safe,"Camp stands on a safe physical lane: "+str(room.id))
		for door: Dictionary in room.doors:
			check(absf(float(camp[0])-float(door.pos[0]))>=64 or absf(float(camp[1])-float(door.pos[1]))>=58,"At the camp E cannot accidentally select a door: "+str(room.id))

func test_final_room_soft_beds_catch_drift_below_neighboring_banks() -> void:
	var room: Dictionary = CampaignWorld.load_rooms(source_rooms())[4]
	for x: int in range(18,1623,8):
		check(room.soft_beds.any(func(bed: Dictionary) -> bool: return x>float(bed["from"]) and x<float(bed.to) and float(bed.y)<float(room.size[1])-65.0), "A fall below a bank remains recoverable at x=%d" % x)
	for surface: Array in room.surfaces:
		for coordinate: Array in surface:
			for bed: Dictionary in room.soft_beds:
				if float(coordinate[0])>float(bed["from"]) and float(coordinate[0])<float(bed.to):
					check(float(bed.y)>float(coordinate[1])+80.0,"Recovery remains below legitimate standing surfaces")
