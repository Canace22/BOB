extends TestSuite

func test_static_terrain_and_live_membrane_have_distinct_ownership() -> void:
	for id: String in ["R1-03","R2-01","R4-06"]:
		var scene: Node2D=load(CampaignWorld.scene_path(id)).instantiate()
		var ground: Node=scene.get_node("World/Art/MembraneArt") if id=="R1-03" else scene.get_node("World/Art/Bed0_0")
		eq(CampaignWorldTerrain.owns(ground),id!="R1-03","Live deforming membrane stays independent; static ground comes from master")
		if id=="R1-03":
			CampaignStreamPresentation.apply(scene,Vector2.ZERO,Vector2(1672,941))
			check(ground.visible,"Membrane remains visible and responds to its original mechanism")
			eq(ground.material.get_shader_parameter("seam_count"),0,"Live playable surface never fades under a room patch")
		scene.free()

func test_chunks_keep_grid_and_gutter_without_room_alpha_materials() -> void:
	var records: Array=JSON.parse_string(FileAccess.get_file_as_string(CampaignWorldTerrain.DATA))
	check(records.size()>30,"World master has actual exported terrain chunks")
	var seen: Dictionary={}
	for entry: Dictionary in records:
		check(not seen.has(entry.file),"Each master grid cell has one owner")
		seen[entry.file]=true
		var texture: Texture2D=load(CampaignWorldTerrain.DATA.get_base_dir()+"/"+str(entry.file))
		eq(texture.get_size(),Vector2(1540,1540),"1536px cell has 2px sampling gutter on each side")
		check(fmod(float(entry.x),1536.0)==0 and fmod(float(entry.y),1536.0)==0,"Tiles use one world grid, including negative positions")

func test_all_repeated_shaft_roots_are_marked_for_master_export() -> void:
	var base: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var corridors:=CampaignStreamingCorridors.new()
	corridors.layout=CampaignStreamingLayout.build(CampaignWorld.load_rooms(base))
	add(corridors)
	corridors.build()
	var marked: int=0
	var renamed: int=0
	for node: Node in corridors.find_children("*","Sprite2D",true,false):
		if node.has_meta("stream_master_ledge"):
			marked+=1
			if node.name!="RegisteredLedge": renamed+=1
	check(marked>50,"Every physical shaft keeps its repeated bitmap roots for export")
	check(renamed>0,"Auto-renamed siblings remain discoverable through metadata")

func test_structural_repaints_keep_dynamic_membrane_and_world_scale() -> void:
	var file: String="res://art/world-seam-repaint-v3/registration.json"
	var entries: Array=JSON.parse_string(FileAccess.get_file_as_string(file))
	var rooms: Array=CampaignWorld.load_rooms(JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json")))
	var layout: Dictionary=CampaignStreamingLayout.build(rooms)
	var config: Dictionary=CampaignLayout.membrane(rooms[2])
	var load_zone: Array=config.load_rect
	var active_membrane:=Rect2(layout.origins[2]+Vector2(load_zone[0],load_zone[1]),Vector2(load_zone[2],load_zone[3]))
	for entry: Dictionary in entries:
		var rect:=Rect2(entry.world[0],entry.world[1],entry.world[2],entry.world[3])
		check(not rect.intersects(active_membrane),"Repainting static banks must not freeze the middle deforming membrane: "+str(entry.id))
		var texture: Texture2D=load(file.get_base_dir()+"/"+str(entry.file))
		var basis: Texture2D=load(file.get_base_dir()+"/"+str(entry.basis))
		eq(texture.get_size(),basis.get_size(),"Repaint and original context share one pixel frame")
		check(is_equal_approx(rect.size.x/texture.get_width(),rect.size.y/texture.get_height()),"Repaint keeps equal scale and registered footprint")
