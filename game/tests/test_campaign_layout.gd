extends TestSuite
## Geometry compatibility only: no real progress/save files are read or changed.
class FloorPlayer extends Node2D:
	var grapple_target: Vector2 = Vector2.INF
	func is_on_floor() -> bool: return true

class LayoutHost extends Node2D:
	var room: Dictionary
	var room_index: int = 2
	var scenery: Node2D
	var player: FloorPlayer
	var event_sequence: int = 0
	var events: Array[Dictionary] = []
	var defeated: Dictionary = {}
	var reference_visible: bool = false
	var layer_solo: int = -1
	var capture_path: String = ""
	func point(value: Array) -> Vector2: return Vector2(float(value[0]),float(value[1]))
	func sfx(_sound: String) -> void: pass
	func record_event(event: String, data: Dictionary) -> void:
		event_sequence += 1
		events.append({"event":event,"data":data,"seq":event_sequence})

func room_fixture() -> Dictionary:
	return {"id":"R1-03", "size":[2000,1600], "spawn":[120,800], "doors":[], "rings":[],
		"layout":{"legacy_size":[1000,1000],"player_bounds":[24,1950],
		"checkpoint_lanes":[{"x":[100,500],"y":800},{"x":[1100,1900],"y":1300}],
		"membrane":{"load_rect":[1000,780,200,120],"dive_rect":[1000,780,200,100],
		"rebound_rect":[1000,890,200,100],"contour_path":"World/Terrain/Membrane/Contour",
		"bend_from":1000.0,"bend_to":1200.0,"max_drop":42.0,"art_paths":["World/Art/MembraneArt"]}}}

func test_old_rooms_retain_their_membrane_and_memory_wall_fallbacks() -> void:
	var tongue: Dictionary = {"id":"R1-03","size":[1672,941]}
	check(CampaignLayout.membrane_contains(tongue,"load_rect",Vector2(800,680)),"Old membrane load zone remains")
	check(CampaignLayout.membrane_contains(tongue,"dive_rect",Vector2(800,710)),"Old upper membrane can dive")
	check(CampaignLayout.membrane_contains(tongue,"rebound_rect",Vector2(800,770)),"Old lower membrane can rebound")
	check(not CampaignLayout.membrane_contains(tongue,"load_rect",Vector2(1000,680)),"Unrelated old floor is not a membrane")
	eq(CampaignLayout.player_bounds({"id":"R1-07","size":[1672,941]}),Vector2(18,1460),"Old memory-bag wall is unchanged")
	var point := Vector2(800,710)
	eq(CampaignLayout.restore_point(tongue,point),point,"Old room restoration is not rewritten by this helper")

func test_new_membrane_and_player_bounds_come_only_from_the_room_contract() -> void:
	var room: Dictionary = room_fixture()
	eq(CampaignLayout.player_bounds(room),Vector2(24,1950),"Player clamp follows the new room width")
	check(CampaignLayout.membrane_contains(room,"load_rect",Vector2(1100,800)),"New load zone can move away from old coordinates")
	check(CampaignLayout.membrane_contains(room,"dive_rect",Vector2(1100,820)),"Diving follows its new zone")
	check(CampaignLayout.membrane_contains(room,"rebound_rect",Vector2(1100,920)),"Rebounding follows the new lower floor")
	check(not CampaignLayout.membrane_contains(room,"load_rect",Vector2(800,680)),"Old tongue coordinates are inactive after layout replacement")
	room.layout.erase("membrane")
	check(CampaignLayout.membrane(room).is_empty(),"An authored room without a membrane cannot inherit the legacy tongue trigger")

func test_moved_membrane_bends_in_room_space_without_moving_its_anchors() -> void:
	var original := PackedVector2Array([Vector2(0,0),Vector2(100,0),Vector2(200,0),Vector2(200,80),Vector2(0,80)])
	var result: PackedVector2Array = CampaignLayout.bent_polygon(original,Transform2D(0.0,Vector2(1000,800)),1000,1200,42)
	check(result[0].is_equal_approx(original[0]) and result[2].is_equal_approx(original[2]),"Both fixed edges stay in place")
	check(result[1].is_equal_approx(Vector2(100,42)),"Sag peaks under the translated membrane center")
	check(not Geometry2D.triangulate_polygon(result).is_empty(),"The full sag remains a valid collision polygon")
	eq(original[1],Vector2(100,0),"Saved source polygon stays unchanged for future unloading")

func test_checkpoint_projection_keeps_current_spawns_and_migrates_old_points_without_save_mutation() -> void:
	var room: Dictionary = room_fixture()
	var untouched: Dictionary = room.duplicate(true)
	eq(CampaignLayout.restore_point(room,Vector2(1700,1300)),Vector2(1700,1300),"New exact door positions are not rescaled as legacy data")
	eq(CampaignLayout.restore_point(room,Vector2(1700,1312)),Vector2(1700,1300),"A new checkpoint settles on the same nearby lane")
	eq(CampaignLayout.restore_point(room,Vector2(900,750)),Vector2(1800,1300),"An invalid old point projects to a safe lane after legacy-size conversion")
	eq(room,untouched,"Projection never edits room metadata or a save payload")
	room.layout.checkpoint_lanes = []
	eq(CampaignLayout.restore_point(room,Vector2(-500,4000)),Vector2(120,800),"Missing safe lanes fall back to an authored spawn, not arbitrary solid space")

func make_mechanism() -> Dictionary:
	var host := LayoutHost.new()
	host.room = room_fixture()
	add(host)
	host.scenery = Node2D.new()
	host.add_child(host.scenery)
	var world := Node2D.new()
	world.name = "World"
	host.scenery.add_child(world)
	var terrain := Node2D.new()
	terrain.name = "Terrain"
	world.add_child(terrain)
	var membrane := StaticBody2D.new()
	membrane.name = "Membrane"
	membrane.position = Vector2(1000,800)
	terrain.add_child(membrane)
	var contour := CollisionPolygon2D.new()
	contour.name = "Contour"
	contour.polygon = PackedVector2Array([Vector2(0,0),Vector2(100,0),Vector2(200,0),Vector2(200,80),Vector2(0,80)])
	membrane.add_child(contour)
	var art := Node2D.new()
	art.name = "Art"
	world.add_child(art)
	var surface := Sprite2D.new()
	surface.name = "MembraneArt"
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float membrane_drop = 0.0;"
	var material := ShaderMaterial.new()
	material.shader = shader
	surface.material = material
	art.add_child(surface)
	for label: String in ["DoorArt","RewardArt"]:
		var item := Node2D.new()
		item.name = label
		item.position = Vector2(600,900) if label == "DoorArt" else Vector2(1200,700)
		world.add_child(item)
	host.player = FloorPlayer.new()
	host.player.position = Vector2(1100,800)
	host.add_child(host.player)
	var mechanism := WhalebellyMechanisms.new()
	mechanism.host = host
	host.scenery.add_child(mechanism)
	mechanism.set_process(false)
	mechanism.set_physics_process(false)
	return {"host":host,"mechanism":mechanism,"contour":contour,"surface":surface}

func test_mechanism_binds_the_new_contour_and_art_then_unloads_and_pauses() -> void:
	var fixture: Dictionary = make_mechanism()
	var mechanism: WhalebellyMechanisms = fixture.mechanism
	for i: int in 70: mechanism._physics_process(1.0/60.0)
	check(mechanism.membrane_drop > 15.0,"New load zone activates the existing sag mechanic")
	check(is_equal_approx(fixture.contour.polygon[1].y,mechanism.membrane_drop),"Translated collision follows the actual sag")
	check(is_equal_approx(float(fixture.surface.material.get_shader_parameter("membrane_drop")),mechanism.membrane_drop),"New artwork receives the identical sag value")
	mechanism.set_physics_process(true)
	tree.paused = true
	var before: float = mechanism.membrane_drop
	for i: int in 3: await tree.process_frame
	eq(mechanism.membrane_drop,before,"Pause holds the deformed contour")
	tree.paused = false
	mechanism.set_physics_process(false)
	fixture.host.player.position.x = 1600
	for i: int in 150: mechanism._physics_process(1.0/60.0)
	check(mechanism.membrane_drop < 0.01,"Leaving the membrane restores its original shape")
	eq(mechanism.membrane_events,1,"A single sustained load generates one sag event")

func test_new_reward_and_gate_rest_positions_are_not_reset_to_the_old_origin() -> void:
	var fixture: Dictionary = make_mechanism()
	var mechanism: WhalebellyMechanisms = fixture.mechanism
	mechanism._process(0.3)
	check(absf(mechanism.reward.position.y-700.0)<=2.5,"Reward bobbing stays around its authored height")
	eq(mechanism.reward.position.x,1200.0,"Reward bobbing preserves its new horizontal placement")
	eq(mechanism.gate.position.y,900.0,"Closed Boss gate keeps its new position")
	fixture.host.defeated["R1-04:0"] = true
	mechanism._process(1.0)
	check(mechanism.gate.position.y>=882.0 and mechanism.gate.position.y<900.0,"Opening gate moves relative to its new origin")
