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
	eq(str(rooms[7].id), "R3-01", "The hub follows the first region")
	var exit: Dictionary = rooms[4].doors[1]
	eq(int(exit.to), 7, "First-region exit resolves to the hub by ID")
	check(exit.get("completes", false), "The exit keeps its milestone")
	eq(int(base_rooms()[4].doors[1].to), -1, "Authored first-region data stays untouched")
	eq(CampaignWorld.scene_path("R1-02"), "res://content/whalebelly/r1/R1-02.tscn", "First-region scenes keep their folder")
	check(ResourceLoader.exists(CampaignWorld.scene_path("R3-01")), "Hub scene exists in its region folder")
	eq(CampaignWorld.region_name("R3-01"), "胃肠沉城", "Region title follows the room ID")

func test_unbuilt_targets_stay_closed_and_requirements_combine() -> void:
	var host := make_host("R3-01")
	eq(int(door_to(host.room, "R2-01").to), -2, "Unknown target stays unresolved")
	eq(CampaignWorld.restriction(host, door_to(host.room, "R2-01")), CampaignWorld.UNBUILT, "Unbuilt exit does not promise entry")
	eq(CampaignWorld.restriction(host, door_to(host.room, "R1-05")), "", "Return to the first region is open")
	var gate: Dictionary = door_to(host.room, "R4-01")
	eq(CampaignWorld.restriction(host, gate), "需要潮压", "Only the missing key is named")
	host.abilities.anchor = false
	eq(CampaignWorld.restriction(host, gate), "需要潮压＋锚定", "Missing keys combine")
	host.abilities.anchor = true
	host.abilities["pressure"] = true
	eq(CampaignWorld.restriction(host, gate), CampaignWorld.UNBUILT, "Met requirements reveal the unbuilt notice")
	eq(CampaignWorld.restriction(host, {"to":3, "locked":"far_latch", "locked_message":"从另一侧闩着"}), "从另一侧闩着", "Far-side latch explains itself")
	check(CampaignWorld.restriction(host, {"to":5, "ability":"float"}).contains("浮游"), "Float gate names its ability")
	eq(host.room.doors.size(), 3, "The trimmed hub keeps the way back, the lung exit and the spine gate")
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
	check(CampaignGuidance.hint(hub).contains("尚未开放"), "Hub hint is honest about closed routes")
	hub.free()
