extends TestSuite

func test_chapter01_dynamic_room_art_paths_load() -> void:
	for room: Dictionary in Chapter01Layout.rooms():
		check(load(str(room.environment_scene)) is PackedScene,"房间完整环境必须真实加载："+str(room.id))


func test_chapter01_graph_keeps_branch_loop_and_shortcut() -> void:
	var data := Chapter01Layout.rooms()
	eq(data.size(), 10, "第一章预览应包含十个房间")
	var links := 0
	for room: Dictionary in data:
		for door: Dictionary in room.doors:
			links += 1
			var target := Chapter01Layout.by_id(data, str(door.to))
			check(not target.is_empty(), "出口必须有目标房间")
			var reciprocal := false
			for reverse: Dictionary in target.doors:
				reciprocal = reciprocal or reverse.to == room.id
			check(reciprocal, "探索通道必须允许原路返回")
	eq(links, 22, "十一组双向通路")
	var lower := Chapter01Layout.by_id(data, "lower-nest")
	for door: Dictionary in lower.doors:
		if door.to == "supply-return":
			check(not Chapter01Layout.door_open(door, {}), "返程索不能提前接通")
			check(Chapter01Layout.door_open(door, {"jaw-arena": true}), "抵达守口场后可接通")


func test_chapter01_scene_isolated_from_campaign_progress() -> void:
	var scene := load("res://content/prototypes/chapter01/main.tscn") as PackedScene
	var preview := add(scene.instantiate()) as Chapter01Preview
	await physics_frames(6)
	eq(str(preview.current.id), "mouth-seam", "预览从巡视缝起步")
	check(preview.player.is_on_floor(), "角色应落在真实地形上")
	eq(preview.visited.size(), 1, "仅记录本次探索")
	check(not GameState.autosave, "测试和预览不启用正式存档")


func test_chapter01_all_curved_platforms_form_valid_polygons() -> void:
	for room: Dictionary in Chapter01Layout.rooms():
		for index in range(room.surfaces.size()):
			var bottom: float = room["size"].y + 180 if index == 0 else 0.0
			var polygon := Chapter01RoomView.collision_contour(room.surfaces[index], bottom)
			check(not Geometry2D.decompose_polygon_in_convex(polygon).is_empty(), "房间曲面需要有效碰撞：" + str(room.id))
