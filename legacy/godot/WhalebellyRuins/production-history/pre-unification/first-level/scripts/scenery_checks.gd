extends Node
var host: Node
var checks: Array=[]
var normal_hash: String

func check(id: String, passed: bool, detail: Dictionary={}) -> void:
	checks.append({"id":id,"passed":passed,"detail":detail})
	print("SCENERY_CHECK ",id," ",passed)

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png(host.evidence_dir+"/"+name+".png")

func run(main: Node) -> Dictionary:
	host=main
	process_mode=Node.PROCESS_MODE_ALWAYS
	normal_hash=FileAccess.get_sha256("user://save-v1.json") if FileAccess.file_exists("user://save-v1.json") else "absent"
	var return_room: int=host.game.room_index
	host.tap("preview")
	await get_tree().create_timer(0.35).timeout
	check("preview_input_enters",host.scenery_preview)
	# Show the undefeated boss without changing any stored progress.
	var old_boss: bool=host.game.data.boss
	host.game.data.boss=false
	for i in range(7):
		host.change_room(i)
		await get_tree().create_timer(0.4).timeout
		var room: Dictionary=host.rooms[i]
		var scene: Node2D=host.level.scenery
		check(str(room.id)+"_four_layers",scene.has_node("Far") and scene.has_node("Middle") and scene.has_node("World") and scene.has_node("Foreground"))
		var geometry_ok=true
		for p in room.platforms:
			var body: StaticBody2D=scene.get_node("World/Shelf_"+str(p.id))
			var collision: CollisionShape2D=body.get_node("Collision")
			geometry_ok=geometry_ok and body.position.is_equal_approx(Vector2(p.x,p.y)*64) and absf(collision.shape.size.x-p.w*64)<0.01
		check(str(room.id)+"_authored_collision_geometry",geometry_ok,{"platforms":room.platforms.size()})
		check(str(room.id)+"_inspection_freezes_player",not host.level.player.is_physics_processing())
		var left=Vector2(760,float(room.platforms[0].y)*64-230)
		if i==0: left.x=400
		var middle=Vector2(float(room.width)*32,float(room.platforms[0].y)*64-230)
		var right=Vector2(float(room.width)*64-700,float(room.platforms[-1].y)*64-220)
		if i==1: right=Vector2(1700,610)
		for pair in [["left",left],["middle",middle],["right",right]]:
			host.preview_camera=pair[1]
			await get_tree().create_timer(0.15).timeout
			await capture(str(room.id)+"-"+str(pair[0]))
		var moving: Node2D=scene.get_node("Far/FarDrift")
		var before=moving.elapsed
		await get_tree().create_timer(0.3).timeout
		check(str(room.id)+"_dynamics_running",moving.elapsed>before)
		if i==0:check("open_jaw_separate_sprites",scene.has_node("Middle/OpenUpperJaw") and scene.has_node("Middle/LowerJawSkin"))
		if i in [4,5]:check(str(room.id)+"_no_baleen_nodes",scene.find_children("*Baleen*","",true,false).is_empty())
		if i==6:
			check("memory_four_anchors",scene.find_children("AnchorRing_*","Line2D",true,false).size()==4)
			check("memory_closed_right",scene.has_node("World/ClosedRightWall"))
	var selection=InputEventKey.new()
	selection.physical_keycode=KEY_2
	selection.pressed=true
	Input.parse_input_event(selection)
	await get_tree().create_timer(0.2).timeout
	check("number_key_selects_room",host.game.room_index==1)
	host.set_overlay("map")
	await get_tree().create_timer(0.1,true).timeout
	await capture("head-atlas")
	var elapsed: float=host.level.scenery.get_node("Far/FarDrift").elapsed
	await get_tree().create_timer(0.2,true).timeout
	check("map_pauses_environment",elapsed==host.level.scenery.get_node("Far/FarDrift").elapsed)
	host.set_overlay("")
	host.game.data.boss=old_boss
	host.tap("preview")
	await get_tree().create_timer(0.35).timeout
	check("preview_input_returns",not host.scenery_preview and host.game.room_index==return_room)
	var after=FileAccess.get_sha256("user://save-v1.json") if FileAccess.file_exists("user://save-v1.json") else "absent"
	check("normal_save_untouched",after==normal_hash)
	return {"passed":checks.all(func(c):return c.passed),"checks":checks,"note":"Actual rendered seven-room inspection. Static collisions match design. No claim A2/A3 progression or gameplay route verified by screenshots."}
