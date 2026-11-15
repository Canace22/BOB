extends "res://tests/whalebelly/xumen_layout_routes.gd"
## Actual framebuffer contribution and landing occlusion; camera positions are fixtures.

func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func changes(a: Image, b: Image) -> int:
	var count := 0
	for y: int in range(0,a.get_height(),3):
		for x: int in range(0,a.get_width(),3):
			var first := a.get_pixel(x,y)
			var last := b.get_pixel(x,y)
			if absf(first.r-last.r)+absf(first.g-last.g)+absf(first.b-last.b)>.035: count += 1
	return count

func run() -> void:
	label = "layers"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory()))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(RouteCampaign)
	host.set("route_id",label)
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(30)
	for i: int in 7:
		host.load_room(i,[],false)
		host.player_ui.close_all()
		host.reference_follow = false
		host.zoomed = false
		await tick(30)
		paused = true
		var combined := await frame_image()
		combined.save_png(output_directory().path_join("layers-%s-combined.png" % host.room.id))
		var masses: Array[Node] = host.scenery.find_children("*_NativeMass","Sprite2D",true,false)
		if not masses.is_empty():
			for mass: Node2D in masses: mass.hide()
			var without_mass := await frame_image()
			check("%s native ground mass is actually visible" % host.room.id,changes(combined,without_mass)>5,masses.size())
			var transform: Transform2D = host.scenery.get_global_transform_with_canvas()
			var covered := 0
			for surface: Array in host.room.surfaces:
				for p: Array in surface:
					for lift: int in [4,40,80]:
						var screen: Vector2 = transform*(point(p)-Vector2(0,lift))
						var x := roundi(screen.x)
						var y := roundi(screen.y)
						if x<0 or y<0 or x>=combined.get_width() or y>=combined.get_height(): continue
						var a := combined.get_pixel(x,y)
						var b := without_mass.get_pixel(x,y)
						if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>.035: covered += 1
			check("%s native foundation does not paint across standing/body samples" % host.room.id,covered==0,covered)
			for mass: Node2D in masses: mass.show()
			await frame_image()
		for name_: String in ["Far","Middle","Foreground"]:
			var layer: Node2D = host.scenery.get_node(name_)
			layer.hide()
			var without := await frame_image()
			var contribution := changes(combined,without)
			check("%s/%s contributes painted pixels" % [host.room.id,name_],contribution>50,contribution)
			if name_=="Foreground":
				var transform: Transform2D = host.scenery.get_global_transform_with_canvas()
				var covered := 0
				var samples := 0
				for surface: Array in host.room.surfaces:
					for p: Array in surface:
						for lift: int in [4,40,80]:
							var screen: Vector2 = transform*(point(p)-Vector2(0,lift))
							var x := roundi(screen.x)
							var y := roundi(screen.y)
							if x<0 or y<0 or x>=combined.get_width() or y>=combined.get_height(): continue
							var a := combined.get_pixel(x,y)
							var b := without.get_pixel(x,y)
							samples += 1
							if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>.035: covered += 1
				check("%s foreground keeps landing/body samples clear" % host.room.id,covered==0,{"covered":covered,"samples":samples})
			layer.show()
			await frame_image()
		# Keep source layers separately inspectable in the actual renderer.
		for name_: String in ["Far","Middle","Foreground"]:
			for other: String in ["Far","Middle","World","Foreground"]:
				host.scenery.get_node(other).visible = name_==other
			var solo := await frame_image()
			solo.save_png(output_directory().path_join("layers-%s-%s.png" % [host.room.id,name_]))
		for name_: String in ["Far","Middle","World","Foreground"]: host.scenery.get_node(name_).show()
		paused = false
		host.reference_follow = true
		host.player.set_physics_process(false)
		var size: Vector2 = point(host.room.size)
		var centers: Array[Vector2] = []
		for side: Vector2 in [Vector2(100,180),Vector2(size.x-100,180),Vector2(100,size.y-140),size-Vector2(100,140)]:
			host.player.position = side
			host.player.velocity = Vector2.ZERO
			await tick(60)
			paused = true
			centers.append(host.camera.get_screen_center_position())
			await shot("%s-camera-%d-%d" % [host.room.id,side.x,side.y])
			var mid: XumenPaintedLayer = host.scenery.get_node("Middle")
			var near: XumenPaintedLayer = host.scenery.get_node("Foreground")
			check("%s camera layers stay within crop margin" % host.room.id,absf(mid.position.x)<=8 and absf(mid.position.y)<=5 and absf(near.position.x)<=12 and absf(near.position.y)<=7)
			paused = false
		check("%s camera actually reaches both horizontal edges" % host.room.id,absf(centers[0].x-centers[1].x)>100,centers)
		check("%s camera actually reaches both vertical edges" % host.room.id,absf(centers[0].y-centers[2].y)>100,centers)
		host.player.set_physics_process(true)
	var failures: int = checks.filter(func(c: Dictionary)->bool:return not c["pass"]).size()
	FileAccess.open(output_directory().path_join("layers.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Actual framebuffer subtraction at a paused shared clock; landing/body pixel samples; isolated layer renders; four camera fixtures per room. Not route or aesthetic approval."},"\t"))
	print("XUMEN_LAYERS_COMPLETE failed=",failures)
	host.graceful_quit.call_deferred(1 if failures else 0)

func point(p: Array) -> Vector2:
	return Vector2(float(p[0]),float(p[1]))
