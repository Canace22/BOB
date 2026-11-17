extends TestSuite

func layout() -> Dictionary:
	return {"room_bounds":{0:Rect2(0,0,1600,1600),1:Rect2(1920,0,1600,1600),2:Rect2(0,-2400,1600,1600)},
		"links":[{"path":PackedVector2Array([Vector2(1500,800),Vector2(2020,800)])}],"bounds":Rect2(0,-2400,3520,4000)}

func bounds() -> CampaignCameraWorldBounds:
	var result:=CampaignCameraWorldBounds.new()
	result.configure(layout())
	return result

func test_external_edge_keeps_view_inside_and_actor_can_leave_center() -> void:
	var edges:=bounds()
	var half:=Vector2(640,360)
	var left: Vector2=edges.target(Vector2(120,800),half,120)
	eq(left.x,640.0,"First bank left edge stays outside the viewport")
	check(left.x>120,"Actor moves toward the left screen edge")
	eq(edges.target(Vector2(3400,800),half,120).x,2880.0,"Last bank right edge also clamps")
	eq(edges.target(Vector2(800,-2350),half,120).y,-2040.0,"Top branch uses its own exterior contour")

func test_connected_room_seam_does_not_limit_camera() -> void:
	var edges:=bounds()
	for x: float in [1300.0,1500.0,1600.0,1760.0,1920.0,2100.0]:
		var actor:=Vector2(x,800)
		eq(edges.target(actor,Vector2(640,360),120),actor,"Connected banks and bridge keep the same center at "+str(x))

func test_soft_stop_has_continuous_speed_and_returns_to_exact_follow() -> void:
	var edges:=bounds()
	var previous: Vector2=edges.target(Vector2(630,800),Vector2(640,360),120)
	for x: int in range(631,801):
		var next: Vector2=edges.target(Vector2(x,800),Vector2(640,360),120)
		check(next.x>=previous.x and next.x-previous.x<1.34,"Soft rail is monotonic without a positional jump")
		previous=next
	eq(edges.target(Vector2(900,800),Vector2(640,360),120),Vector2(900,800),"Interior returns to exact center without temporal lag")

func test_viewport_size_and_narrow_connector_keep_actor_visible() -> void:
	var edges:=bounds()
	for half: Vector2 in [Vector2(640,360),Vector2(960,540),Vector2(360,640)]:
		var actor:=Vector2(40,800)
		var center: Vector2=edges.target(actor,half,120)
		check(absf(center.x-actor.x)<=half.x,"Wide and tall viewports keep the actor on screen")
	var corridor:=CampaignCameraWorldBounds.new()
	corridor.configure({"room_bounds":{0:Rect2(0,0,200,300)},"links":[]})
	eq(corridor.target(Vector2(100,150),Vector2(640,360),120),Vector2(100,150),"Open narrow space cannot force an impossible viewport fit")

func test_actual_world_connections_do_not_snap_at_old_room_boundaries() -> void:
	var source: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var data: Dictionary=CampaignStreamingLayout.build(CampaignWorld.load_rooms(source))
	var edges:=CampaignCameraWorldBounds.new()
	edges.configure(data)
	for link: Dictionary in data.links:
		var path: PackedVector2Array=link.path
		var previous: Vector2=edges.target(path[0],Vector2(640,360),120)
		var maximum: float=0.0
		for segment: int in range(1,path.size()):
			var count: int=maxi(1,ceili(path[segment-1].distance_to(path[segment])/6.0))
			for step: int in range(1,count+1):
				var actor: Vector2=path[segment-1].lerp(path[segment],float(step)/count)
				var next: Vector2=edges.target(actor,Vector2(640,360),120)
				maximum=maxf(maximum,previous.distance_to(next))
				previous=next
		check(maximum<24.0,"Continuous camera target on "+str(data.rooms[link.a].id)+"/"+str(data.rooms[link.b].id)+" max step="+str(maximum))

func test_actual_room_walk_lanes_do_not_jump_when_contour_changes() -> void:
	var source: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	var data: Dictionary=CampaignStreamingLayout.build(CampaignWorld.load_rooms(source))
	var edges:=CampaignCameraWorldBounds.new()
	edges.configure(data)
	for index: int in data.room_bounds:
		var rect: Rect2=data.room_bounds[index]
		var y: float=rect.position.y+float(data.rooms[index].spawn[1])
		var previous: Vector2=edges.target(Vector2(rect.position.x+40,y),Vector2(640,360),120)
		var peak: float=0.0
		for x: int in range(int(rect.position.x)+46,int(rect.end.x)-40,6):
			var next: Vector2=edges.target(Vector2(x,y),Vector2(640,360),120)
			peak=maxf(peak,previous.distance_to(next))
			previous=next
		check(peak<30.0,"No contour snap along "+str(data.rooms[index].id)+" peak="+str(peak))
