extends TestSuite

func layout_data() -> Dictionary:
	var base: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var rooms: Array = CampaignWorld.load_rooms(base)
	return CampaignStreamingLayout.build(rooms)

func test_all_rooms_are_placed_without_rectangle_overlap() -> void:
	var layout: Dictionary = layout_data()
	eq(layout.origins.size(),19,"All nineteen rooms have a world origin")
	for a: int in layout.origins:
		var rect: Rect2 = CampaignStreamingLayout.room_rect(layout.rooms,layout.origins,a)
		for b: int in layout.origins:
			if b<=a: continue
			check(not rect.intersects(CampaignStreamingLayout.room_rect(layout.rooms,layout.origins,b)),"Room rectangles do not overlap %s/%s" % [layout.rooms[a].id,layout.rooms[b].id])

func test_connections_keep_authored_anchors_and_bounded_steps() -> void:
	var layout: Dictionary = layout_data()
	eq(layout.links.size(),18,"Tree graph retains all eighteen bidirectional connections")
	for link: Dictionary in layout.links:
		var path: PackedVector2Array = link.path
		eq(path[0],link.from,"Path starts at the authored source door")
		eq(path[-1],link.to,"Path ends at the authored destination door")
		for i: int in range(1,path.size()):
			var delta: Vector2 = path[i]-path[i-1]
			check(absf(delta.x)<=200.1 and absf(delta.y)<=110.1,"Each step stays within jumpable spacing")
		for point: Vector2 in path:
			for index: int in layout.origins:
				if index==int(link.a) or index==int(link.b): continue
				var platform := Rect2(point-Vector2(64,0),Vector2(128,18))
				check(not CampaignStreamingLayout.room_rect(layout.rooms,layout.origins,index).intersects(platform),"Corridor platform does not overlap unrelated room " + str(layout.rooms[index].id))

func test_vertical_stairs_clear_both_horizontal_entry_and_exit_platforms() -> void:
	var layout: Dictionary = layout_data()
	for link: Dictionary in layout.links:
		var bends: PackedVector2Array = CampaignStreamingLayout._route(layout.rooms,layout.origins,int(link.a),int(link.b),link.from,link.to)
		var path: PackedVector2Array = link.path
		for i: int in range(1,bends.size()):
			var start: Vector2 = bends[i-1]
			var end: Vector2 = bends[i]
			if not is_zero_approx(end.x-start.x) or is_zero_approx(end.y-start.y): continue
			var first: int = path.find(start)
			var last: int = path.find(end)
			check(first>=0 and last>first+1,"Vertical segment keeps both anchors and intermediate steps")
			if first<0 or last<=first+1: continue
			for step: int in range(first+1,last+1):
				check(absf(path[step].x-path[step-1].x)>=94.9,"Descending onto the next centre clears the previous 128px platform")
			if i>1 and not is_zero_approx(start.x-bends[i-2].x):
				check((path[first+1].x-start.x)*(start.x-bends[i-2].x)>0,"First ladder step leaves the horizontal approach behind")
			if i+1<bends.size() and not is_zero_approx(bends[i+1].x-end.x):
				check((path[last-1].x-end.x)*(bends[i+1].x-end.x)<0,"Reverse descent clears the horizontal exit platform")
	var short: PackedVector2Array = CampaignStreamingLayout._stairs(PackedVector2Array([Vector2.ZERO,Vector2(0,110)]))
	eq(short.size(),3,"Even a short shaft gets an offset intermediate step")
	check(absf(short[1].x-short[0].x)>=95 and absf(short[2].x-short[1].x)>=95,"Short-shaft endpoints also clear the platform edges")

func test_tail_shaft_opens_runtime_data_collision_and_bitmap_without_editing_source() -> void:
	var base: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var rooms: Array = CampaignWorld.load_rooms(base)
	var source: Dictionary = rooms[14]
	var source_surfaces: Array = source.surfaces.duplicate(true)
	var layout: Dictionary = CampaignStreamingLayout.build(rooms)
	eq(source.surfaces,source_surfaces,"Original room dictionary keeps the authored floor")
	for surface: Array in layout.rooms[14].surfaces:
		var y: float = float(surface[0][1])
		if y!=1320 and y!=1584: continue
		check(float(surface[0][0])>=1270 or float(surface[-1][0])<=890,"Runtime P1 and bed surfaces leave the full shaft open")
	var scene: Node2D = load("res://content/whalebelly/r4/R4-06.tscn").instantiate()
	scene.position = layout.origins[14]
	var original: Sprite2D = scene.get_node("World/Art/P1_0") as Sprite2D
	var texture: Texture2D = original.texture
	var scale: Vector2 = original.scale
	CampaignStreamingCorridors.prepare_scene(14,scene,layout)
	for name: String in ["Surface_P1","Bed0"]:
		var body: Node = scene.get_node("World/Terrain/"+name)
		eq(body.get_child_count(),2,"Physical floor splits into two sides: "+name)
		for contour: CollisionPolygon2D in body.get_children():
			var bounds := Rect2(contour.polygon[0],Vector2.ZERO)
			for point: Vector2 in contour.polygon: bounds = bounds.expand(point)
			check(bounds.end.x<=890 or bounds.position.x>=1270,"Physical floor cannot cover the shaft centre")
	for name: String in ["P1_0ShaftLeft","P1_0ShaftRight"]:
		var piece: Sprite2D = scene.get_node("World/Art/"+name) as Sprite2D
		check(piece.region_enabled,"Platform art is actually cropped")
		eq(piece.texture,texture,"Cut pieces reuse the original bitmap")
		eq(piece.scale,scale,"Cut pieces keep the original equal scale")
	var flipped: Sprite2D = scene.get_node("World/Art/Bed0_1ShaftLeft") as Sprite2D
	check(flipped.flip_h and is_equal_approx(flipped.region_rect.end.x,flipped.texture.get_width()),"Mirrored bed keeps the correct original texture span")
	CampaignStreamingCorridors.prepare_scene(14,scene,layout)
	eq(scene.get_node("World/Terrain/Bed0").get_child_count(),2,"Preparing a cached scene twice does not cut or duplicate again")
	scene.free()

func test_corridor_scene_uses_bitmap_surfaces_and_collision() -> void:
	var corridors := CampaignStreamingCorridors.new()
	corridors.layout = layout_data()
	add(corridors)
	corridors.build()
	check(corridors.platform_count>0,"Physical bitmap platforms fill the exterior connections")
	var first: Dictionary = corridors.layout.links[0]
	var sample: PackedVector2Array = first.path
	check(not corridors.corridor_segment_near(sample[sample.size()/2]).is_empty(),"World position resolves to a corridor segment")

func test_water_backdrop_uses_one_mirrored_bitmap_surface() -> void:
	var corridors := CampaignStreamingCorridors.new()
	corridors.layout = layout_data()
	add(corridors)
	corridors.build()
	var backdrop: Sprite2D = corridors.get_node("ContinuousWater") as Sprite2D
	check(backdrop != null and backdrop.get_child_count()==0,"Backdrop is one draw surface without overlapping tiles")
	check(backdrop is CampaignStreamBackdrop,"One world parallax driver owns the complete panorama")
	var water_material: ShaderMaterial = backdrop.material
	check(water_material.shader.code.contains("mod(uv,2.0)") and water_material.shader.code.contains("repeat_disable"),"Shader mirrors each biome bitmap and clamps border filtering to avoid thin wrap seams")
	check(is_equal_approx(backdrop.scale.x,backdrop.scale.y),"Original bitmap keeps equal scale on both axes")
	var bounds: Rect2 = Rect2(corridors.layout.bounds).grow(1200)
	eq(backdrop.position,bounds.position,"Backdrop starts outside the world bounds")
	check((backdrop.region_rect.size*backdrop.scale).is_equal_approx(bounds.size),"Repeated bitmap covers the full world margin")
