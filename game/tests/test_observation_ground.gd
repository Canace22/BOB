extends TestSuite
## Measured bed, generated collision, terrain master and V6 landing agree.

func room_data() -> Dictionary:
	var base: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	return CampaignWorld.load_rooms(base).filter(func(room: Dictionary) -> bool: return str(room.id)=="R2-03")[0]

func test_bed_recipe_collision_and_ground_query_share_the_measured_profile() -> void:
	var data: Dictionary=room_data()
	var recipe: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/whalebelly/world/recipes/R2-03.json"))
	var scene: Node2D=load(CampaignWorld.scene_path("R2-03")).instantiate()
	var contour: CollisionPolygon2D=scene.get_node("World/Terrain/Bed0/Contour")
	check(data.profiled_ground,"Old bed checkpoints request ground projection")
	check(not contour.one_way_collision,"Soft bed remains solid")
	check(not Geometry2D.triangulate_polygon(contour.polygon).is_empty(),"Bed polygon has no crossing edges")
	eq(data.surfaces[0].size(),recipe.beds[0].profile.size(),"Every measured point reaches runtime data")
	for i: int in data.surfaces[0].size():
		var point:=Vector2(data.surfaces[0][i][0],data.surfaces[0][i][1])
		var authored:=Vector2(recipe.beds[0].profile[i][0],recipe.beds[0].profile[i][1])*float(recipe.unit)
		check(point.distance_to(authored)<0.01 and contour.polygon[i].distance_to(point)<0.01,"Recipe and physical bed share point "+str(i))
		if i>0:
			var step: Vector2=point-contour.polygon[i-1]
			check(step.x>0 and absf(step.angle())<deg_to_rad(55),"Bed stays walkable without vertical steps")
	for i: int in range(1,data.surfaces.size()):
		var id: String=str(recipe.platforms[i-1].id)
		var shape: CollisionPolygon2D=scene.get_node("World/Terrain/Surface_"+id+"/Contour")
		check(shape.one_way_collision and shape.polygon.size()==4,"Upper platform remains unchanged: "+id)
	scene.free()

func test_measured_bed_has_bitmap_at_contact_and_no_invisible_plate() -> void:
	var host: WhalebellyMain=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true
	host.integration_external_test=true
	add(host)
	await physics_frames(8)
	var index: int=host.rooms.find_custom(func(room: Dictionary) -> bool: return str(room.id)=="R2-03")
	host.load_room(index,[1240,1424])
	await physics_frames(8)
	var origin: Vector2=host.streaming.origin(index)
	var tile: Texture2D=load("res://art/world-terrain-v2/tile_9_-2.png")
	var image: Image=tile.get_image()
	for x: int in range(720,1681,8):
		var y: float=host.ground_y(x,1424)
		var from: Vector2=origin+Vector2(x,y-6)
		var hit: Dictionary=host.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from,from+Vector2(0,12),1))
		check(not hit.is_empty() and absf(Vector2(hit.get("position",Vector2.INF)).y-origin.y-y)<0.1,"Physical bed agrees with lookup at "+str(x))
		var col: int=roundi(origin.x+x-13824)+2
		var top: int=roundi(origin.y+y+3072)+2
		var painted: bool=false
		for dy: int in range(-3,4):
			if image.get_pixel(col,top+dy).a>0.5: painted=true
		check(painted,"Current master has opaque bed at contact: "+str(x))
		if y>1427:
			var old: Vector2=origin+Vector2(x,1423)
			var ghost: Dictionary=host.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(old,old+Vector2(0,2),1))
			check(ghost.is_empty(),"Old floating horizontal plate is absent")

func test_old_bed_checkpoints_project_without_changing_upper_routes() -> void:
	var host: WhalebellyMain=load("res://content/whalebelly/main.tscn").instantiate()
	host.room=room_data()
	for x: int in [700,1080,1240,1334,1540,1640,2000,2300]:
		var restored: Vector2=host.restored_room_position(Vector2(x,1424))
		check(restored.x==x and absf(restored.y-host.ground_y(x,1424))<0.01,"Old V6 bed landing projects at "+str(x))
	eq(host.restored_room_position(Vector2(920,1160)),Vector2(920,1160),"Upper route checkpoint stays on its own level")
	eq(host.restored_room_position(Vector2(2450,1160)),Vector2(2450,1160),"Outside corridor landing is not clamped into the room")
	host.free()
