extends SceneTree
## Real campaign renderer, isolated position/time fixtures, not natural play.
class ReviewCampaign extends WhalebellyMain:
	func save_path() -> String:
		return "user://whalebelly/remaining-19-review-%s.json" % str(ProjectSettings.globalize_path("res://").hash())

const VIEWS: Dictionary = {
	"R3-01":Vector2(1298,2080), "R2-01":Vector2(548,1520),
	"R2-03":Vector2(1450,1040), "R2-04":Vector2(1450,1520),
	"R4-01":Vector2(1520,1040), "R4-03":Vector2(1560,1296),
	"R4-05":Vector2(1800,1440), "R4-06":Vector2(640,1440),
	"R5-01":Vector2(1520,1200), "R5-02":Vector2(1600,1360),
	"R5-04":Vector2(2400,1440), "R5-08":Vector2(2250,1280)}
var host: WhalebellyMain
var checks: Array[Dictionary] = []
var output: String
var before: bool = false

func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func check(label: String, passed: bool, detail: Variant = "") -> void:
	checks.append({"name":label,"pass":passed,"detail":detail})
	print("PASS " if passed else "FAIL ", label, " ",detail)
func frame() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func shot(label: String) -> void:
	(await frame()).save_png(output.path_join(label+".png"))
func differences(a: Image,b: Image) -> int:
	var count: int = 0
	for y: int in range(0,a.get_height(),3):
		for x: int in range(0,a.get_width(),3):
			var p: Color = a.get_pixel(x,y)
			var q: Color = b.get_pixel(x,y)
			if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>.004: count+=1
	return count
func contribution(node: CanvasItem, base: Image) -> int:
	node.hide()
	var count: int = differences(base,await frame())
	node.show()
	await frame()
	return count

func review(id: String) -> void:
	host.load_room(host.rooms.find_custom(func(r: Dictionary) -> bool:return r.id==id),[VIEWS[id].x,VIEWS[id].y],false)
	host.player_ui.close_all()
	host.player.automatic_doors=false
	host.player.invulnerable=99999.0
	host.zoomed=true
	await tick(65)
	paused=true
	await shot(id+"-follow")
	if not before:
		var motion: Node = host.scenery.get_node("PresentationMotion")
		var held: float = motion.elapsed
		await tick(10)
		check(id+" presentation freezes on pause",motion.elapsed==held)
		var base: Image = await frame()
		check(id+" distant original painting renders",await contribution(host.scenery.get_node("Far/Organs"),base)>500)
		motion.update_at(8.0)
		check(id+" underwater light changes painted pixels",differences(base,await frame())>10)
		var lights: Array = motion.lights
		for light: CanvasItem in lights: light.hide()
		host.scenery.get_node("Far").hide()
		var protected: Image = await frame()
		motion.update_at(23.0)
		check(id+" actors terrain and UI escape the water shader",differences(protected,await frame())==0)
		host.scenery.get_node("Far").show()
		for light: CanvasItem in lights: light.show()
		motion.update_at(held)
	paused=false
	host.zoomed=false
	await tick(12)
	paused=true
	await shot(id+"-overview")
	if not before:
		var base: Image = await frame()
		var bodies: Array[Node] = host.scenery.find_children("*_NativeVolume","Sprite2D",true,false)
		if bodies.size()>0:
			for node: CanvasItem in bodies: node.hide()
			var pixels: int = differences(base,await frame())
			check(id+" native organ bodies contribute in whole-room view",pixels>10,pixels)
			for node: CanvasItem in bodies: node.show()
			await frame()
		for path: String in ["Middle","World","Foreground"]:
			check(id+" "+path+" actually renders",await contribution(host.scenery.get_node(path),base)>5)
		# Explicit edge camera fixtures exercise full-frame art coverage.
		host.camera.set_process(false)
		host.set_process(false)
		host.camera.zoom=Vector2.ONE
		var size: Vector2 = host.point(host.room.size)
		for i: int in 4:
			host.camera.position=Vector2(640 if i%2==0 else size.x-640,360 if i<2 else size.y-360)
			host.camera.force_update_scroll()
			var layer: KitParallaxLayer = host.scenery.get_node("Far/Organs")
			layer.position=layer.offset_for(host.camera.position)
			var sprite: Sprite2D = layer.get_node("Art")
			var rect: Rect2 = sprite.get_rect()
			var bounds: Rect2 = Rect2(sprite.to_global(rect.position),rect.size*sprite.scale)
			check(id+" depth covers edge "+str(i),bounds.encloses(Rect2(host.camera.position-Vector2(640,360),Vector2(1280,720))))
			await shot(id+"-edge"+str(i))
		host.set_process(true)
		host.camera.set_process(true)
		var motion: Node = host.scenery.get_node("PresentationMotion")
		motion.speed=0.0
		var held: float = motion.elapsed
		paused=false
		await tick(10)
		check(id+" zero speed holds presentation",motion.elapsed==held)
		motion.speed=1.0
		await tick(10)
		check(id+" presentation resumes",motion.elapsed>held)
	paused=false

func run() -> void:
	root.size=Vector2i(1280,720)
	before="--before" in OS.get_cmdline_user_args()
	output=OS.get_environment("REMAINING_QA_OUT")
	if output.is_empty():output="res://build/qa/remaining-19-v2/current"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(ReviewCampaign)
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(30)
	for id: String in VIEWS:
		var selected: PackedStringArray = []
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("--rooms="):selected=argument.trim_prefix("--rooms=").split(",")
		if not selected.is_empty() and not id in selected: continue
		if "--sample" in OS.get_cmdline_user_args() and id not in ["R2-01","R3-01","R4-01"]:continue
		await review(id)
	var failures: int = checks.filter(func(c: Dictionary)->bool:return not c["pass"]).size()
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Real campaign renderer; position, camera and time fixtures, isolated save. Not a natural route or art approval."},"\t"))
	print("REMAINING_REVIEW_COMPLETE failures=",failures)
	host.graceful_quit.call_deferred(1 if failures else 0)
