extends Node
var host: Node
var checks: Array=[]

func key(code: int) -> void:
	var e=InputEventKey.new()
	e.physical_keycode=code
	e.pressed=true
	Input.parse_input_event(e)
	await get_tree().create_timer(0.08,true).timeout
	e=InputEventKey.new()
	e.physical_keycode=code
	e.pressed=false
	Input.parse_input_event(e)

func check(id: String,pass_value: bool) -> void:
	checks.append({"id":id,"passed":pass_value})
	print("ART_CHECK ",id," ",pass_value)

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png(host.evidence_dir+"/"+name+".png")

func run(main: Node) -> Dictionary:
	host=main
	var boss_before: bool=host.game.data.boss
	host.game.data.boss=false
	host.tap("preview")
	await get_tree().create_timer(0.25).timeout
	host.preview_fit=true
	for index in range(7):
		host.change_room(index)
		await get_tree().create_timer(0.25).timeout
		var r=host.rooms[index]
		var scene=host.level.scenery
		var geometry=true
		for platform in r.platforms:
			var shelf=scene.get_node("World/Shelf_"+str(platform.id))
			geometry=geometry and shelf.position.is_equal_approx(Vector2(platform.x,platform.y)*64)
			geometry=geometry and absf(shelf.get_node("Collision").shape.size.x-platform.w*64)<0.01
		check(str(r.id)+"_coordinates",geometry)
		check(str(r.id)+"_all_authored_doors",host.level.route_system.door_nodes.size()==r.doors.size())
		for d in r.doors:check(str(r.id)+"_"+str(d.id),host.level.route_system.door_nodes[d.id].position.is_equal_approx(Vector2(d.x,d.y)*64))
		check(str(r.id)+"_middle_parallax",scene.get_node("Middle").parallax==Vector2(0.5,0.5))
		check(str(r.id)+"_front_parallax",scene.get_node("Foreground").parallax==Vector2(1.2,1.2))
		for layer in range(5):
			host.inspector.layer_index=layer
			host.inspector.apply_layers()
			await get_tree().create_timer(0.08).timeout
			await capture(str(r.id)+"-"+["composite","far","middle","play","front"][layer])
		host.inspector.layer_index=0
		host.inspector.apply_layers()
		host.route_overlay=true
		await get_tree().create_timer(0.1).timeout
		await capture(str(r.id)+"-coordinates")
		host.route_overlay=false
		host.set_overlay("reference")
		await get_tree().create_timer(0.1,true).timeout
		await capture(str(r.id)+"-reference")
		host.set_overlay("")
	# Verify parallax movement and fixed world contacts at two distinct camera positions.
	host.change_room(1)
	await get_tree().create_timer(0.2).timeout
	host.preview_fit=false
	host.preview_camera=Vector2(750,650)
	await get_tree().create_timer(0.2).timeout
	var middle_before: Vector2=host.level.scenery.get_node("Middle").position
	var world_before: Vector2=host.level.scenery.get_node("World").global_position
	var gate_before: Vector2=host.level.route_system.door_nodes.E35.global_position
	host.preview_camera=Vector2(1550,650)
	await get_tree().create_timer(0.2).timeout
	check("middle_moves_with_camera",host.level.scenery.get_node("Middle").position.distance_to(middle_before)>200)
	check("world_and_doors_fixed",host.level.scenery.get_node("World").global_position==world_before and host.level.route_system.door_nodes.E35.global_position==gate_before)
	await capture("R1-02-game-scale")
	host.set_overlay("map")
	await get_tree().create_timer(0.1,true).timeout
	await capture("world-connections")
	host.set_overlay("")
	await key(KEY_F8)
	check("F8_opens_reference",host.inspector.panel.visible and host.overlay=="reference")
	await key(KEY_ESCAPE)
	check("escape_closes_reference",not host.inspector.panel.visible and host.overlay=="")
	await key(KEY_F7)
	check("F7_routes_toggle",host.route_overlay)
	await key(KEY_F7)
	await key(KEY_F10)
	check("F10_isolates_far",host.inspector.layer_index==1 and not host.level.scenery.get_node("World").visible)
	host.game.data.boss=boss_before
	await key(KEY_F6)
	await get_tree().create_timer(0.2).timeout
	check("leaving_preview_restores_layers",not host.scenery_preview and host.level.scenery.get_node("World").visible)
	return {"passed":checks.all(func(c):return c.passed),"checks":checks,"type":"actual graphical engine; original/coordinates + seven rooms x four layers"}
