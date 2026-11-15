extends TestSuite
## Preserve movement, progression and surfaces; honor explicitly removed walls.
const PHYSICS := "res://content/whalebelly/layout/physics-v1.json"
const INPUT := "res://tests/fixtures/xumen-layout-input-v1.json"
const CONTRACT := "res://tests/fixtures/xumen-gameplay-v1.json"

func object_at(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(parsed is Dictionary, "Contract object loads: " + path)
	return parsed if parsed is Dictionary else {}

func runtime_rooms() -> Array:
	var source: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	return CampaignWorld.load_rooms(source)

func point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func room_polygon(scene: Node2D, shape: CollisionPolygon2D) -> PackedVector2Array:
	var transform := Transform2D.IDENTITY
	var node: Node2D = shape
	while node != scene:
		transform = node.transform * transform
		node = node.get_parent() as Node2D
	return transform * shape.polygon

func check_polygon(scene: Node2D, id: String, expected: PackedVector2Array, one_way: bool) -> void:
	var path := "World/Terrain/%s/Contour" % id
	var shape := scene.get_node_or_null(path) as CollisionPolygon2D
	check(shape != null, "Frozen collider exists: %s/%s" % [scene.name,id])
	if shape == null: return
	var actual: PackedVector2Array = room_polygon(scene,shape)
	eq(actual.size(),expected.size(),"Collider vertex count stays fixed: %s/%s" % [scene.name,id])
	for index: int in mini(actual.size(),expected.size()):
		# Scene text rounds coordinates to three decimals; metadata remains exact.
		check(actual[index].distance_to(expected[index])<0.001,"Frozen vertex stays in room space: %s/%s/%d" % [scene.name,id,index])
	eq(shape.one_way_collision,one_way,"One-way rule stays fixed: %s/%s" % [scene.name,id])
	check(not Geometry2D.triangulate_polygon(actual).is_empty(),"Collider remains valid: %s/%s" % [scene.name,id])

func test_seven_runtime_surfaces_and_safe_lanes_equal_both_frozen_inputs() -> void:
	var frozen: Array = object_at(PHYSICS).rooms
	var inputs: Array = object_at(INPUT).rooms
	var rooms: Array = runtime_rooms()
	eq(frozen.size(),7,"All seven physical rooms are frozen")
	eq(inputs.size(),7,"All seven style inputs are present")
	for index: int in mini(7,mini(frozen.size(),inputs.size())):
		eq(str(rooms[index].id),str(frozen[index].id),"Frozen IDs retain their saved indices")
		eq(str(inputs[index].id),str(frozen[index].id),"Independent style input names the same room")
		eq(rooms[index].surfaces,frozen[index].surfaces,"Runtime ground lookup remains byte-value equivalent: " + str(rooms[index].id))
		eq(rooms[index].surfaces,inputs[index].surfaces,"Runtime ground lookup matches pre-style input: " + str(rooms[index].id))
		eq(rooms[index].layout.checkpoint_lanes,frozen[index].checkpoint_lanes,"Safe lanes remain exactly frozen: " + str(rooms[index].id))
		eq(rooms[index].layout.checkpoint_lanes,inputs[index].layout.checkpoint_lanes,"Safe lanes match independent pre-style input: " + str(rooms[index].id))

func test_generated_surfaces_and_retained_walls_preserve_physics_and_removed_walls_are_absent() -> void:
	var frozen: Array = object_at(PHYSICS).rooms
	var recipes: Array = object_at("res://content/whalebelly/layout/recipes.json").rooms
	var original_rooms: Array = object_at(CONTRACT).rooms
	for index: int in mini(frozen.size(),recipes.size()):
		var recipe: Dictionary = recipes[index]
		eq(str(recipe.id),str(frozen[index].id),"Platform recipes retain frozen room order")
		eq(recipe.platforms.size(),frozen[index].surfaces.size(),"One frozen surface per platform")
		var scene: Node2D = load(CampaignWorld.scene_path(str(recipe.id))).instantiate()
		var remaining: Array = recipe.walls.filter(func(wall: Dictionary) -> bool: return not wall.get("removed",false))
		eq(scene.get_node("World/Terrain").get_child_count(),recipe.platforms.size()+remaining.size(),"Only platforms and retained walls have collision: " + str(recipe.id))
		for at: int in mini(recipe.platforms.size(),frozen[index].surfaces.size()):
			var spec: Dictionary = recipe.platforms[at]
			var surface: Array = frozen[index].surfaces[at]
			var polygon := PackedVector2Array()
			for coordinate: Array in surface: polygon.append(point(coordinate))
			var depth: float = 100.0 if spec.get("membrane",false) else 30.0
			polygon.append(Vector2(float(spec.x)+float(spec.w)-14.0,float(spec.y)+depth))
			polygon.append(Vector2(float(spec.x)+14.0,float(spec.y)+depth))
			check_polygon(scene,str(spec.id),polygon,bool(spec.get("one_way",false)))
		for wall: Dictionary in recipe.walls:
			if wall.get("removed",false):
				check(scene.get_node_or_null("World/Terrain/"+str(wall.id))==null,"Removed wall has no invisible collider: %s/%s" % [recipe.id,wall.id])
				check(scene.find_children(str(wall.id)+"_*","",true,false).is_empty(),"Removed wall has no painting or roof join: %s/%s" % [recipe.id,wall.id])
				continue
			var box: Array = wall.box
			var left: float = float(box[0])+12.0
			var right: float = float(box[0])+float(box[2])-12.0
			var top: float = float(box[1])+12.0
			var bottom: float = float(box[1])+float(box[3])-12.0
			check_polygon(scene,str(wall.id),PackedVector2Array([Vector2(left,top),Vector2(right,top),Vector2(right,bottom),Vector2(left,bottom)]),false)
			var archived: Array = original_rooms[index].frozen_geometry.actual_collision_nodes.filter(func(item: Dictionary) -> bool: return str(item.node.get("parent",""))=="World/Terrain/"+str(wall.id) and str(item.node.get("type",""))=="CollisionPolygon2D")
			eq(archived.size(),1,"Wall retains an independent pre-style snapshot: " + str(wall.id))
			if archived.size()==1:
				var coordinates: Array = archived[0].properties.polygon
				var original := PackedVector2Array()
				for coordinate: int in range(0,coordinates.size(),2): original.append(Vector2(float(coordinates[coordinate]),float(coordinates[coordinate+1])))
				check_polygon(scene,str(wall.id),original,false)
		scene.free()

func test_character_parameters_and_skill_unlock_rules_keep_the_current_contract() -> void:
	var contract: Dictionary = object_at(CONTRACT)
	var actor: WhalebellyCampaignPlayer = load("res://content/whalebelly/CampaignPlayer.tscn").instantiate()
	var parameters: Dictionary = contract.player.exported_parameters_before_ready
	for key: String in ["max_speed","acceleration","friction","gravity","terminal_speed","fall_multiplier","air_control","jump_height","short_jump_height","double_jump_speed","wall_slide_speed","wall_jump_x","wall_jump_height","dash_speed","dash_duration","dash_cooldown","max_health","max_soul","melee_damage","orb_damage","heavy_damage","heal_amount","float_time","float_lift_speed","float_lift_accel"]:
		eq(actor.get(key),parameters[key],"Current movement/combat parameter is frozen: " + key)
	eq(actor.collision_size,point(parameters.collision_size),"Physical player envelope is frozen")
	eq(TideSkillCatalog.ACTIONS.size(),contract.player.catalog_actions.size(),"Style work adds no new gameplay action")
	for key: String in contract.player.catalog_actions:
		var expected: Dictionary = contract.player.catalog_actions[key].duplicate(true)
		expected.erase("title")
		# JSON numbers are floats; normalize the native integer fields likewise.
		var actual: Dictionary = JSON.parse_string(JSON.stringify(TideSkillCatalog.definition(key)))
		eq(actual,expected,"Skill timeline, cost and unlock stay fixed: " + key)
	var host := WhalebellyMain.new()
	host.qa = false
	host.practice = false
	host.abilities = {"anchor":true,"dash":false,"float":false}
	host.collected = {}
	host.completed = false
	actor.host = host
	check(actor.skill_unlocked("always") and host.has_ability("anchor"),"Fresh game keeps base actions and anchor")
	check(not actor.skill_unlocked("dash") and not actor.skill_unlocked("chapter") and not actor.skill_unlocked("R1-03") and not actor.skill_unlocked("float"),"Fresh game cannot inherit practice or later rewards")
	check(not actor.ability_available("A1_dash") and not actor.ability_available("A5_slit"),"Base dash and slit still require mother-crab progress")
	host.collected["R1-03"] = true
	check(actor.ability_available("up_spell") and actor.ability_available("dive") and not actor.ability_available("shadow_dash"),"Tongue relic unlocks its own spells without chapter completion")
	host.abilities.dash = true
	check(actor.ability_available("A1_dash") and actor.ability_available("A5_slit") and actor.ability_available("crystal_dash"),"Earned dash opens the existing dash skill group")
	host.completed = true
	check(actor.ability_available("shadow_dash") and actor.ability_available("dark_dive") and actor.ability_available("shadow_orb"),"First-region milestone keeps chapter upgrades")
	host.abilities.float = true
	check(actor.skill_unlocked("float"),"Actual float flag remains the source of float access")
	actor.free()
	host.free()

func test_nineteen_room_order_and_grants_are_the_current_game_not_older_designs() -> void:
	var contract: Dictionary = object_at(CONTRACT)
	var rooms: Array = runtime_rooms()
	eq(rooms.size(),19,"Style restoration retains the nineteen-room game")
	var grants: Dictionary = {}
	for index: int in mini(rooms.size(),contract.rooms.size()):
		var room: Dictionary = rooms[index]
		var previous: Dictionary = contract.rooms[index]
		eq(str(room.id),str(previous.id),"Append-only saved room order remains intact")
		eq(room.enemies.size(),previous.enemies.size(),"Encounter count stays fixed: " + str(room.id))
		for enemy: Dictionary in room.enemies:
			if enemy.get("boss",false): grants[str(room.id)+":0"] = str(enemy.get("grants","dash"))
	eq(grants,{"R1-04:0":"dash","R2-04:0":"pressure","R4-05:0":"bone","R5-04:0":"silence"},"Current four Boss rewards retain their sources")
	eq(str(rooms[6].get("reward_grants","float")),"float","Memory bag remains the optional first float source")
	eq(str(rooms[8].reward_grants),"float","Nursery retains the alternate float source")
	eq(str(rooms[18].reward_grants),"ending","Release retains the ending grant")
	eq(rooms[18].reward_requires,["pressure","bone","silence"],"Release still requires all three later marks")

func test_frozen_gameplay_script_hashes_allow_independent_art_and_scene_changes() -> void:
	var hashes: Dictionary = {}
	for item: Dictionary in object_at(CONTRACT).source_hashes: hashes[str(item.path)] = str(item.sha256)
	# Deliberately exclude generators, scenes, image files and presentation scripts.
	for path: String in ["src/campaign/tide_player.gd","src/campaign/campaign_player.gd","src/campaign/tide_skill_catalog.gd","src/campaign/tide_skill_input.gd","src/campaign/tide_skill_controller.gd","src/campaign/tide_input.gd","src/campaign/campaign_relics.gd","src/campaign/campaign_save_bridge.gd","src/campaign/boss/crab_boss.gd","src/campaign/boss/crab_shell.gd","src/campaign/boss/crab_moves.gd","src/campaign/enemies/corpse_crab.gd","src/campaign/enemies/kit_encounter.gd","src/ui/ui_save_access.gd"]:
		check(hashes.has("game/"+path),"Baseline contains gameplay source: " + path)
		eq(FileAccess.get_sha256("res://"+path),str(hashes.get("game/"+path,"")),"Gameplay bytes remain unchanged during visual restoration: " + path)

func test_solid_wall_cores_have_actual_painted_coverage() -> void:
	var images: Dictionary = {}
	for recipe: Dictionary in object_at("res://content/whalebelly/layout/recipes.json").rooms:
		var scene: Node2D = load(CampaignWorld.scene_path(str(recipe.id))).instantiate()
		for wall: Dictionary in recipe.walls:
			if wall.get("removed",false): continue
			var box: Array = wall.box
			for row: int in 5:
				for column: int in 5:
					var p := Vector2(float(box[0])+12+(float(box[2])-24)*(column+.5)/5.0,float(box[1])+12+(float(box[3])-24)*(row+.5)/5.0)
					var painted: bool = false
					for node: Node in scene.get_node("World/Art").get_children():
						if not node is Sprite2D or not str(node.name).begins_with(str(wall.id)+"_"): continue
						var sprite: Sprite2D = node
						var path: String = sprite.texture.resource_path
						if not images.has(path): images[path] = sprite.texture.get_image()
						var bitmap: Image = images[path]
						var placement := Transform2D.IDENTITY
						var part: Node2D = sprite
						while part != scene:
							placement = part.transform * placement
							part = part.get_parent() as Node2D
						var pixel: Vector2 = placement.affine_inverse() * p - sprite.offset
						if sprite.region_enabled: pixel += sprite.region_rect.position
						var x: int = roundi(pixel.x)
						var y: int = roundi(pixel.y)
						if x>=0 and y>=0 and x<bitmap.get_width() and y<bitmap.get_height() and bitmap.get_pixel(x,y).a*sprite.modulate.a>=0.45:
							painted = true
							break
					check(painted,"A solid obstacle never looks like clear water: %s/%s/%s" % [recipe.id,wall.id,p])
		scene.free()

func test_rejected_mushroom_cap_assembly_is_absent_from_current_seven_rooms() -> void:
	for recipe: Dictionary in object_at("res://content/whalebelly/layout/recipes.json").rooms:
		var scene: Node2D = load(CampaignWorld.scene_path(str(recipe.id))).instantiate()
		for node: Node in scene.find_children("*","Sprite2D",true,false):
			var sprite: Sprite2D = node
			var source: String = sprite.texture.resource_path if sprite.texture != null else ""
			for rejected: String in ["anatomy-fracture.png","porous-wall.png","cavity-roof.png"]:
				check(not source.ends_with(rejected),"User-rejected cap/pillar family is not still rendered: %s/%s" % [recipe.id,node.name])
		scene.free()
