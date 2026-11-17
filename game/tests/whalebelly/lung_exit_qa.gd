extends "res://tests/whalebelly/streaming_world_qa.gd"
## 从育床底层自然走到左出口，再沿原返程通道回胃枢；不以门前夹具代替房内路线。
var bitmaps: Dictionary={}

func walk(target: Vector2, budget: int=600) -> bool:
	var reached: bool=await super.walk(target,budget)
	if reached:
		var foot: Vector2=host.player.global_position
		var alpha: float=0.0
		for record: Dictionary in JSON.parse_string(FileAccess.get_file_as_string(CampaignWorldTerrain.DATA)):
			var rect:=Rect2(record.x,record.y,record.width,record.height)
			if not rect.has_point(foot): continue
			if not bitmaps.has(record.file): bitmaps[record.file]=load("res://art/world-terrain-v1/"+str(record.file)).get_image()
			for depth: int in range(21):
				var pixel:=Vector2i(foot-rect.position)+Vector2i(2,2+depth)
				if pixel.y<bitmaps[record.file].get_height(): alpha=maxf(alpha,bitmaps[record.file].get_pixelv(pixel).a)
		check("Visible support at "+str(foot),alpha>=0.5)
	return reached

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","lung-natural-exit")
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(30)
	var nursery: int=-1
	for index: int in host.rooms.size():
		if host.rooms[index].id=="R2-01": nursery=index
	host.load_room(nursery)
	host.player.position=Vector2(800,1650)
	host.player.invulnerable=1000
	await tick(30)
	var link: Dictionary=host.streaming.layout.links.filter(func(edge: Dictionary)->bool: return str(host.rooms[int(edge.a)].id)=="R3-01" and int(edge.b)==nursery)[0]
	check("Lung return neighbor ready",await wait_ready(int(link.a)))
	var start: Vector2=host.streaming.origin(nursery)
	check("Walk from nursery bed",await walk(start+Vector2(260,1664)))
	check("Jump from bed to left exit",await walk(start+Vector2(260,1520)))
	var path: PackedVector2Array=link.path
	path.reverse()
	for slot: int in path.size():
		drop_direction=0
		var reached: bool=await walk(path[slot],300)
		check("Return step %d"%slot,reached)
		print("LUNG_EXIT_POINT slot=",slot," world=",path[slot]," local=",host.player.position)
		await shot("lung-return-%02d"%slot)
		if not reached: break
	check("Return reaches stomach",host.room_index==int(link.a))
	var blood: int=-1
	for index: int in host.rooms.size():
		if host.rooms[index].id=="R2-04": blood=index
	host.defeated["R2-04:0"]=true
	host.load_room(blood)
	host.player.position=Vector2(2600,1510)
	host.player.invulnerable=1000
	await tick(30)
	press(KEY_D,true)
	await tick(100)
	press(KEY_D,false)
	check("Blood nest right boundary stops walking on visible floor",host.player.position.x<2810 and host.player.is_on_floor() and host.player.is_on_wall())
	await shot("blood-nest-closed-end")
	check("Blood nest retains exactly one left exit",host.room.doors.size()==1 and int(host.room.doors[0].to)>=0)
	check("Walk back across blood nest",await walk(host.streaming.origin(blood)+Vector2(80,1520),700))
	var back: Dictionary=host.streaming.layout.links.filter(func(edge: Dictionary)->bool: return int(edge.b)==blood)[0]
	check("Blood nest left neighbor ready",await wait_ready(int(back.a)))
	path=back.path
	path.reverse()
	for point: Vector2 in path:
		drop_direction=0
		if not await walk(point,300):
			check("Blood nest left return",false)
			break
	check("Blood nest returns left to observation room",host.room_index==int(back.a))
	await finish()
