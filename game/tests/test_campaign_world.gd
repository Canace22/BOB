extends TestSuite
## Later regions join the first-region graph without moving its indices or saves.
const SAVE := "user://test-world-save.json"

func base_rooms() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))

func make_host(id: String) -> WhalebellyMain:
	var host := WhalebellyMain.new()
	host.qa_full_abilities = false
	host.rooms = CampaignWorld.load_rooms(base_rooms())
	for i: int in host.rooms.size():
		if str(host.rooms[i].id) == id:
			host.room_index = i
			host.room = host.rooms[i]
	return host

func door_to(room: Dictionary, target: String) -> Dictionary:
	for door: Dictionary in room.doors:
		if str(door.get("to_id", "")) == target: return door
	return {}

func test_later_region_appends_and_links_the_first_exit() -> void:
	var rooms := CampaignWorld.load_rooms(base_rooms())
	for i: int in 7: eq(str(rooms[i].id), "R1-0%d" % (i + 1), "First-region indices never move")
	var order: Array = []
	for i: int in range(7, rooms.size()): order.append(str(rooms[i].id))
	eq(order.slice(0, 4), ["R3-01", "R2-01", "R2-03", "R2-04"], "Later rooms keep their append-only order")
	eq(str(rooms[7].id), "R3-01", "The hub follows the first region")
	var exit: Dictionary = rooms[4].doors[1]
	eq(int(exit.to), 7, "First-region exit resolves to the hub by ID")
	check(exit.get("completes", false), "The exit keeps its milestone")
	eq(int(base_rooms()[4].doors[1].to), -1, "Authored first-region data stays untouched")
	eq(CampaignWorld.scene_path("R1-02"), "res://content/whalebelly/r1/R1-02.tscn", "First-region scenes keep their folder")
	check(ResourceLoader.exists(CampaignWorld.scene_path("R3-01")), "Hub scene exists in its region folder")
	eq(CampaignWorld.region_name("R3-01"), "胃肠沉城", "Region title follows the room ID")

func test_v4_v5_chapters_bind_all_current_rooms_without_changing_room_count() -> void:
	var rooms := CampaignWorld.load_rooms(base_rooms())
	var covered: Dictionary = {}
	var previous := 0
	for chapter: Dictionary in CampaignWorld.chapter_map().get("chapters", []):
		eq(int(chapter.index), previous + 1, "Chapter order is contiguous")
		previous = int(chapter.index)
		for room_id: Variant in chapter.rooms:
			check(not covered.has(str(room_id)), "Room is assigned to one chapter: " + str(room_id))
			covered[str(room_id)] = true
	for entry: Dictionary in rooms:
		check(covered.has(str(entry.id)), "Current room has a formal chapter mapping: " + str(entry.id))
		check(int(entry.get("chapter_index", 0)) > 0, "Chapter index is present: " + str(entry.id))
		check(not str(entry.get("anatomy_anchor", "")).is_empty(), "Anatomy anchor is present: " + str(entry.id))
	eq(covered.size(), rooms.size(), "Chapter mapping covers exactly the current room set")
	eq(rooms.size(), 19, "Chapter mapping does not add or remove rooms")
	var layout := CampaignStreamingLayout.build(rooms)
	eq(layout.chapter_by_room.size(), rooms.size(), "Streaming layout carries chapter bindings for every room")
	eq(str(layout.chapter_by_room["R1-01"].name), "须庭", "Streaming layout keeps the first chapter anchor")
	eq(str(layout.chapter_by_room["R5-08"].name), "主闸", "Streaming layout keeps the final chapter anchor")

func test_world_map_room_x_matches_v5_anatomy_ranges() -> void:
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/whalebelly/world/anatomy_map_contract.json"))
	var tolerance := float(contract.get("toleranceX", 0.035))
	for room_id: String in contract.get("rooms", {}).keys():
		var entry: Dictionary = contract.rooms[room_id]
		var spot: Variant = CampaignWorld.map_position("world", room_id)
		check(spot is Vector2, "Anatomy contract room is placed on world map: " + room_id)
		if spot is Vector2:
			check(not str(entry.name).is_empty(), "Room contract is readable: " + room_id)
			check(absf(spot.x - float(entry.expectedX)) <= tolerance, "Room x follows V5 anatomy range: " + room_id)

func test_scene_asset_coordinate_contract_covers_all_formal_rooms() -> void:
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/whalebelly/world/scene_asset_coordinate_contract.json"))
	eq(int(contract.get("roomCount", 0)), 19, "Asset contract keeps the formal nineteen-room scope")
	eq(int(contract.get("dynamicRoomCount", 0)), 19, "Every formal room has a dynamic environment recipe")
	var seen: Dictionary = {}
	for entry: Dictionary in contract.get("rooms", []):
		var room_id := str(entry.id)
		seen[room_id] = true
		check(ResourceLoader.exists(str(entry.gameScene)), "Asset contract scene exists: " + room_id)
		check(entry.get("anatomy", {}).get("rangePercent", []).size() == 2, "Original-art range is recorded: " + room_id)
		var whale_spot: Variant = CampaignWorld.map_position("world", room_id)
		var contract_spot: Array = entry.get("whaleWorld", [])
		check(whale_spot is Vector2 and contract_spot.size() == 2, "Whale/game coordinate pair exists: " + room_id)
		if whale_spot is Vector2 and contract_spot.size() == 2:
			check(is_equal_approx(whale_spot.x, float(contract_spot[0])) and is_equal_approx(whale_spot.y, float(contract_spot[1])), "Whale coordinate is shared by map and scene contract: " + room_id)
		check(entry.get("streamingLocal", {}).get("size", []).size() == 2, "Streaming local size is recorded: " + room_id)
		check(entry.get("assets", []).size() > 0, "Independent 2D assets are registered: " + room_id)
		check(entry.get("dynamic", []).size() > 0, "Dynamic/effect coverage is registered: " + room_id)
	eq(seen.size(), 19, "Asset coordinate contract covers exactly the formal room set")

func test_unbuilt_targets_stay_closed_and_requirements_combine() -> void:
	var host := make_host("R3-01")
	eq(CampaignWorld.restriction(host, {"to":-2}), CampaignWorld.UNBUILT, "Unknown target stays closed")
	eq(str(host.rooms[int(door_to(host.room, "R2-01").to)].id), "R2-01", "Built target resolves by ID")
	eq(CampaignWorld.restriction(host, door_to(host.room, "R2-01")), "", "Lung exit opens once its room exists")
	eq(CampaignWorld.restriction(host, door_to(host.room, "R1-05")), "", "Return to the first region is open")
	var gate: Dictionary = door_to(host.room, "R4-01")
	eq(CampaignWorld.restriction(host, gate), "需要潮压", "Only the missing key is named")
	host.abilities.anchor = false
	eq(CampaignWorld.restriction(host, gate), "需要潮压＋锚定", "Missing keys combine")
	host.abilities.anchor = true
	host.abilities["pressure"] = true
	eq(CampaignWorld.restriction(host, gate), "", "The spine gate opens once pressure is earned")
	eq(CampaignWorld.restriction(host, {"to":-2, "requires":["bone"]}), "需要骨音", "A requirement is named before the unbuilt notice")
	eq(CampaignWorld.restriction(host, {"to":3, "locked":"far_latch", "locked_message":"从另一侧闩着"}), "从另一侧闩着", "Far-side latch explains itself")
	check(CampaignWorld.restriction(host, {"to":5, "ability":"float"}).contains("浮游"), "Float gate names its ability")
	eq(host.room.doors.size(), 3, "The trimmed hub keeps the way back, the lung exit and the spine gate")
	eq(host.rooms.size(), 19, "The trimmed map is nineteen rooms")
	for entry: Dictionary in host.rooms:
		check(ResourceLoader.exists(CampaignWorld.scene_path(str(entry.id))), "Scene exists: " + str(entry.id))
		for door: Dictionary in entry.doors:
			if CampaignWorld.region(str(entry.id)) != "R1": check(int(door.to) >= 0, "Every later-region door leads to a built room: %s → %s" % [entry.id, door.get("to_id")])
	host.free()

func test_saves_stay_valid_across_the_longer_room_list() -> void:
	var rooms := CampaignWorld.load_rooms(base_rooms())
	var payload: Dictionary = {"version":6, "checkpoint":{"room":4, "pos":[110,503]}, "collected":{}, "defeated":{"R1-04:0":true}, "abilities":{"dash":true}, "completed":true}
	WhaleUISaveAccess.write(SAVE, payload)
	check(not WhaleUISaveAccess.read(SAVE, rooms).is_empty(), "Existing first-region checkpoint still loads")
	payload.checkpoint = {"room":7, "pos":[1120,2080]}
	WhaleUISaveAccess.write(SAVE, payload)
	check(not WhaleUISaveAccess.read(SAVE, rooms).is_empty(), "Hub checkpoint is valid with the hub present")
	check(WhaleUISaveAccess.read(SAVE, base_rooms()).is_empty(), "Hub checkpoint is rejected when the room is absent")
	for suffix: String in ["", ".bak"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))

func test_hub_scene_matches_its_room_data() -> void:
	var hub: Dictionary = CampaignWorld.load_rooms(base_rooms())[7]
	var scene: Node = load(CampaignWorld.scene_path("R3-01")).instantiate()
	for layer: String in ["Far", "Middle", "World", "Foreground"]: check(scene.has_node(layer), "Layer present: " + layer)
	var entrances: Node = scene.get_node("Doorways")
	eq(entrances.get_child_count(), hub.doors.size(), "One entrance node per door")
	for i: int in hub.doors.size(): eq(str(entrances.get_child(i).destination_id), str(hub.doors[i].to_id), "Entrance order follows door order")
	var terrain: Node = scene.get_node("World/Terrain")
	eq(terrain.get_child_count(), hub.surfaces.size(), "One collider per surface")
	for body: Node in terrain.get_children():
		eq(body.get_node("Contour").one_way_collision, not str(body.name).begins_with("Bed"), "Platforms pass upward, the bed is solid: " + str(body.name))
	scene.free()

func test_layout_fits_the_current_jump() -> void:
	var player := (load("res://content/whalebelly/CampaignPlayer.tscn") as PackedScene).instantiate()
	var single: float = player.jump_height
	player.free()
	check(120.0 < single * 0.9, "Lung stairs rise within one ordinary jump")
	check(2224.0 - 2080.0 < single, "The bed returns to the low banks by one ordinary jump")

func test_ambient_fields_use_library_bitmaps_and_stay_bounded() -> void:
	var scene: Node = load(CampaignWorld.scene_path("R3-01")).instantiate()
	var fields: Array = scene.get_node("Middle/Ambient").get_children().filter(func(node: Node) -> bool: return node is KitDriftField)
	check(fields.size() >= 2, "Fat motes and the gate current are present")
	for field: KitDriftField in fields:
		check(field.texture != null and field.texture.resource_path.begins_with("res://art/world-kit/"), "Drift field draws a synced bitmap")
		_nodes.append(field)
	tree.root.add_child(scene)
	_nodes.append(scene)
	for field: KitDriftField in fields:
		field.update_at(97.3)
		for mote: Dictionary in field.motes:
			check(field.bounds.grow(field.sway + 1.0).has_point(mote.node.position), "Motes wrap inside their field")

func test_guidance_and_map_follow_the_link() -> void:
	var host := make_host("R1-05")
	eq(CampaignGuidance.next_room(host), "R3-01", "The exit is the recommended next room")
	check(CampaignGuidance.door_label(host, host.room.doors[1]).contains("胃枢"), "Exit prompt names the hub")
	host.completed = true
	check(CampaignGuidance.hint(host).contains("胃枢"), "Completion points onward instead of a dead end")
	host.visited = {"R1-05":true}
	var data := WhaleUICampaignData.new()
	data.host = host
	check(data.map_rooms().any(func(n: Dictionary) -> bool: return n.id == "R3-01" and n.next), "Hub is known and recommended from the exit room")
	check(CampaignWorld.on_map_page("R1", "R3-01") and CampaignWorld.on_map_page("R3", "R1-05"), "Linked neighbours are placed on both pages")
	check(not CampaignWorld.on_map_page("R3", "R1-02"), "Unlinked rooms stay off the other page")
	host.free()
	var hub := make_host("R3-01")
	check(CampaignGuidance.door_label(hub, door_to(hub.room, "R1-05")).begins_with("返回"), "Way back is labelled as a return")
	check(CampaignGuidance.hint(hub).contains("潮压"), "Hub hint names what the spine gate needs")
	eq(CampaignGuidance.next_room(hub), "R2-01", "Hub recommends the lung route until pressure is earned")
	hub.abilities["pressure"] = true
	eq(CampaignGuidance.next_room(hub), "R4-01", "With pressure the hub recommends the spine")
	hub.free()

func test_map_pages_place_rooms_on_the_whale_without_overlap() -> void:
	var spots: Dictionary = {}
	for page: String in ["world", "R1", "R2", "R3", "R4", "R5"]:
		var host := make_host("R4-01")
		for entry: Dictionary in host.rooms: host.visited[str(entry.id)] = true
		var map := WhaleUIMap.new()
		map.data = WhaleUICampaignData.new()
		map.data.host = host
		map.theme = WhaleUIStyle.theme()
		map.size = Vector2(1176, 346)
		map.page = page
		tree.root.add_child(map)
		check(map.anatomy.texture == (WhaleUIMap.HEAD if map.page == "R1" else WhaleUIMap.WHALE), "%s page shows its whale backdrop" % map.page)
		var boxes: Array = map.buttons.values()
		for i: int in boxes.size():
			var box: Button = boxes[i]
			check(map.frame().grow(1.0).encloses(box.get_rect()), "%s stays on the %s backdrop" % [box.name, map.page])
			for j: int in range(i + 1, boxes.size()):
				check(not box.get_rect().grow(4.0).intersects(boxes[j].get_rect()), "%s and %s do not overlap on %s" % [box.name, boxes[j].name, map.page])
		for room: Dictionary in map.nodes:
			if map.page == "R1": continue
			var spot: Variant = CampaignWorld.map_position(map.page, str(room.id))
			eq(spots.get_or_add(str(room.id), spot), spot, "%s keeps one place on the whale across pages" % room.id)
		map.free()
		host.free()

func test_overview_at_combination_gate_distinguishes_visits_boss_and_rewards() -> void:
	var host := make_host("R4-01")
	host.visited = {"R4-01":true, "R3-01":true, "R2-04":true}
	host.collected["R5-08:tidal-pearl"] = true
	var map := WhaleUIMap.new()
	map.data = WhaleUICampaignData.new()
	map.data.host = host
	map.theme = WhaleUIStyle.theme()
	map.size = Vector2(1176, 392)
	tree.root.add_child(map)
	eq(map.buttons.size(), host.rooms.size(), "C map includes every region before discovery")
	var route := map.recommended_route()
	check(route.size() == 2 and not Rect2(route[0], Vector2.ZERO).expand(route[1]).grow(6).intersects(map.caption.get_rect()), "Combination gate caption leaves the gold arrow visible")
	for room: Dictionary in map.nodes:
		var button := map.buttons[int(room.index)]
		var expected := WhaleMapMarker.Kind.CURRENT if room.current else (WhaleMapMarker.Kind.VISITED if room.visited else WhaleMapMarker.Kind.UNKNOWN)
		eq(button.kind, expected, "Room symbol follows current position and saved visits")
		check(button.text.is_empty() and button.get_child_count() == 0, "Map markers do not repeat room names or status labels")
		check(button.accessibility_name.contains(room.name) and button.accessibility_name.contains(WhaleUICampaignData.visit_label(room)), "Every marker has a spoken name and status")
		check(map.frame().grow(1).encloses(button.get_rect()), "Node fits on the full map")
		for other: int in map.buttons:
			if other > int(room.index): check(not button.get_rect().grow(3).intersects(map.buttons[other].get_rect()), "Overview nodes stay separate")
	var boss: int = host.rooms.find_custom(func(r: Dictionary) -> bool: return r.id == "R2-04")
	eq(map.data.map_objectives(boss).get("守关者"), "待击败", "Visiting a boss room never counts as a kill")
	host.defeated["R2-04:0"] = true
	eq(map.data.map_objectives(boss).get("守关者"), "已击败", "Permanent defeat appears on revisit")
	var release: int = host.rooms.find_custom(func(r: Dictionary) -> bool: return r.id == "R5-08")
	eq(map.data.map_objectives(release), {"导流闸":"待开启", "归潮珠":"已收集"}, "Side treasure is independent of opening the release gate")
	map.select_room(release)
	eq(map.caption.text, str(host.rooms[release].name), "Inspection reveals the selected room name")
	check(WhaleUIMapPage.room_detail(map,release).contains("归潮珠已收集"), "Inspector includes the selected room’s reward progress")
	map.show_page("R5")
	eq(host.visited.size(), 3, "Inspecting another region never discovers its rooms")
	eq(str(host.room.id), "R4-01", "Inspecting never moves the player")
	map.free()
	host.free()

func test_bosses_grant_the_three_marks_and_the_ending_needs_all() -> void:
	var rooms := CampaignWorld.load_rooms(base_rooms())
	var grants: Dictionary = {}
	for entry: Dictionary in rooms:
		for enemy: Dictionary in entry.get("enemies", []):
			if enemy.get("boss", false) and enemy.has("grants"): grants[str(enemy.grants)] = str(entry.id)
	eq(grants, {"pressure":"R2-04", "bone":"R4-05", "silence":"R5-04"}, "Each mark comes from one Boss room")
	var release: Dictionary = rooms.filter(func(entry: Dictionary) -> bool: return str(entry.id) == "R5-08")[0]
	eq(release.reward_requires, ["pressure", "bone", "silence"], "The release needs all three marks")
	eq(str(release.reward_grants), "ending", "The release closes the loop")
	for entry: Dictionary in rooms:
		for enemy: Dictionary in entry.get("enemies", []):
			if not enemy.has("config"): continue
			for role: String in enemy.config.sprites:
				check(ResourceLoader.exists(str(enemy.config.sprites[role].path)), "Enemy bitmap is synced: " + str(enemy.config.sprites[role].path))
