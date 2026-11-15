extends "res://tests/whalebelly/xumen_layout_routes.gd"
## Renderer/state fixtures, not gameplay or aesthetic approval.
var performance: Dictionary = {}

func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func changes(a: Image, b: Image) -> int:
	var count := 0
	for y: int in range(0,a.get_height(),2):
		for x: int in range(0,a.get_width(),2):
			var p := a.get_pixel(x,y)
			var q := b.get_pixel(x,y)
			if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>.012: count+=1
	return count

func contribution(nodes: Array, base: Image) -> int:
	for node: CanvasItem in nodes: node.hide()
	var different := changes(base,await frame_image())
	for node: CanvasItem in nodes: node.show()
	await frame_image()
	return different

func snapshot(groups: Array, bubbles: Array, snow: KitDriftField) -> String:
	var data: Array = []
	for group: ChapterFishGroup in groups:
		for fish: Sprite2D in group.sprites: data.append([fish.position,fish.frame,fish.modulate])
	for emitter: EnvironmentBubbleEmitter in bubbles:
		for bubble: Dictionary in emitter.bubbles: data.append([bubble.node.position,bubble.node.modulate])
	for mote: Dictionary in snow.motes: data.append([mote.node.position,mote.node.modulate])
	return var_to_str(data)

func measure() -> void:
	var times: Array[float] = []
	var previous: int = Time.get_ticks_usec()
	for i: int in 120:
		await process_frame
		var now: int = Time.get_ticks_usec()
		times.append(float(now-previous)/1000.0)
		previous=now
	times.sort()
	performance={"frames":times.size(),"median_ms":times[60],"p95_ms":times[114],"resolution":[root.size.x,root.size.y],"recording":false,"note":"Local native process-frame intervals; other open apps not controlled. No baseline speedup or target claim."}

func run() -> void:
	label="atmosphere"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory()))
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(RouteCampaign)
	host.set("route_id",label)
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(30)
	var selected: Array = [0] if "--sample" in OS.get_cmdline_user_args() else [0,1,2,3,4,5,6]
	for index: int in selected:
		host.load_room(index,[],false)
		host.player_ui.close_all()
		host.player.invulnerable=99999.0
		host.reference_follow=false
		host.zoomed=false
		await tick(90)
		var id: String=host.room.id
		var groups: Array=host.scenery.find_children("*","ChapterFishGroup",true,false)
		var emitters: Array=host.scenery.find_children("*","EnvironmentBubbleEmitter",true,false)
		var snow: KitDriftField=host.scenery.get_node("Middle/MarineSnow")
		check(id+" four distinct fish schools",groups.size()==4)
		check(id+" bounded bubble fields",emitters.size()==3)
		check(id+" snow uses campaign clock",snow.external_clock and absf(snow.time-host.clock)<.05)
		var first:=snapshot(groups,emitters,snow)
		await tick(45)
		check(id+" swimmers and particles move",snapshot(groups,emitters,snow)!=first)
		paused=true
		var held:=snapshot(groups,emitters,snow)
		var clock: float=host.clock
		await tick(18)
		check(id+" pause freezes every family",held==snapshot(groups,emitters,snow) and clock==host.clock)
		var combined:=await frame_image()
		combined.save_png(output_directory().path_join(id+"-ambient-overview.png"))
		check(id+" fish actually render",await contribution(groups,combined)>40)
		check(id+" bubbles actually render",await contribution(emitters,combined)>12)
		check(id+" snow actually renders",await contribution([snow],combined)>4)
		check(id+" near bubbles are behind actor",host.scenery.get_node("World/NearBubbles").z_index<host.player.z_index)
		var stable:=true
		for group: ChapterFishGroup in groups:
			for time: float in [0.0,30.0,180.0,600.0]:
				group.update_at(time)
				for fish: Sprite2D in group.sprites:
					stable=stable and fish.position.is_finite() and fish.frame>=0 and fish.frame<32
			stable=stable and group.sprites.size()==group.population and group.population<=18
			if group.migrate:
				var edge_time: float = (ceil(clock/group.path_seconds+group.phase/TAU)-group.phase/TAU)*group.path_seconds
				group.update_at(edge_time-.001)
				stable=stable and group.sprites[0].modulate.a<.001
				group.update_at(edge_time+.001)
				stable=stable and group.sprites[0].modulate.a<.001
			group.update_at(clock)
		check(id+" fish population and atlas remain bounded",stable)
		var recycled:=true
		for emitter: EnvironmentBubbleEmitter in emitters:
			emitter.update_at(600.0)
			recycled=recycled and emitter.recycled>0 and emitter.bubbles.size()==emitter.population
			for bubble: Dictionary in emitter.bubbles:
				recycled=recycled and emitter.bounds.grow(4).has_point(bubble.node.position)
			emitter.update_at(clock)
		check(id+" bubbles recycle inside authored room bounds",recycled)
		snow.update_at(600.0)
		check(id+" snow pool stays bounded",snow.motes.size()==snow.population)
		snow.update_at(clock)
		var restored:=snapshot(groups,emitters,snow)
		for group: ChapterFishGroup in groups: group.update_at(clock)
		for emitter: EnvironmentBubbleEmitter in emitters: emitter.update_at(clock)
		snow.update_at(clock)
		check(id+" repeated shared time is stable",restored==snapshot(groups,emitters,snow))
		for group: ChapterFishGroup in groups: group.update_at(42.0)
		for emitter: EnvironmentBubbleEmitter in emitters: emitter.update_at(42.0)
		snow.update_at(42.0)
		var reload_pose:=snapshot(groups,emitters,snow)
		host.load_room(index,[],false)
		host.player_ui.close_all()
		groups=host.scenery.find_children("*","ChapterFishGroup",true,false)
		emitters=host.scenery.find_children("*","EnvironmentBubbleEmitter",true,false)
		snow=host.scenery.get_node("Middle/MarineSnow")
		for group: ChapterFishGroup in groups: group.update_at(42.0)
		for emitter: EnvironmentBubbleEmitter in emitters: emitter.update_at(42.0)
		snow.update_at(42.0)
		check(id+" room reload reconstructs identical ecology",reload_pose==snapshot(groups,emitters,snow))
		restored=snapshot(groups,emitters,snow)
		paused=false
		await tick(15)
		check(id+" resume advances without new instances",snapshot(groups,emitters,snow)!=restored and snow.motes.size()==snow.population)
		host.reference_follow=true
		await tick(45)
		(await frame_image()).save_png(output_directory().path_join(id+"-ambient-follow.png"))
		host.reference_follow=false
		await tick(30)
		if index==0:
			await measure()
			if "--clip" in OS.get_cmdline_user_args(): await capture_clip()
	var failures: int=checks.filter(func(c: Dictionary)->bool:return not c["pass"]).size()
	FileAccess.open(output_directory().path_join(label+".json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"performance":performance,"method":"Room/camera fixtures, actual framebuffer hiding differences, shared-clock pause/resume, accelerated lifecycle seek. Performance measured without capture. Not a route/difficulty or listening test."},"\t"))
	print("XUMEN_ATMOSPHERE_COMPLETE failed=",failures)
	host.graceful_quit.call_deferred(1 if failures else 0)

func capture_clip() -> void:
	var frames: Array = []
	for i: int in 48:
		await tick(8)
		var bitmap:=await frame_image()
		bitmap.save_png(output_directory().path_join("clip-%03d.png"%i))
		frames.append({"frame":i,"campaign_time":host.clock})
	FileAccess.open(output_directory().path_join("clip-timing.json"),FileAccess.WRITE).store_string(JSON.stringify(frames,"\t"))
