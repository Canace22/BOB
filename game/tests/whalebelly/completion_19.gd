extends SceneTree
## Visual/progress fixtures in the real campaign, isolated from the player's save.
class CompletionCampaign extends WhalebellyMain:
	func save_path() -> String:
		return "user://whalebelly/completion-19-%s.json" % str(ProjectSettings.globalize_path("res://").hash())
const OUT: String = "res://build/qa/completion-20261114/runtime"
var host: WhalebellyMain
var checks: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func check(label: String, value: bool) -> void:
	checks.append({"name":label,"pass":value})
	print("PASS " if value else "FAIL ",label)
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
func room(id: String, at: Vector2) -> void:
	host.player_ui.close_all()
	await tick(12)
	var index: int = host.rooms.find_custom(func(r: Dictionary) -> bool: return str(r.id) == id)
	host.load_room(index, [at.x,at.y], false)
	host.player.automatic_doors = false
	host.player.invulnerable = 9999.0
	await tick(35)

func motion_clip(label: String, frame_count: int) -> void:
	if not "--motion" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	var folder: String = OUT.path_join("motion").path_join(label)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for index: int in frame_count:
		await tick(2) # fixed 60Hz simulation -> 30fps source frames
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("%04d.png" % index))

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(CompletionCampaign)
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(30)
	check("all original nineteen room IDs remain",host.rooms.size()==19 and str(host.rooms[18].id)=="R5-08")
	await room("R3-01",Vector2(1392,2080))
	check("two stationary resident identities are in the real hub",host.scenery.get_node("World/Resident0/Art").texture.resource_path.ends_with("yusuo.png") and host.scenery.get_node("World/Resident1/Art").texture.resource_path.ends_with("beituo.png"))
	check("resident has discoverable real interaction prompt",host.player_ui.data.prompt().contains("余索"))
	await shot("01-hub-residents")
	var flow: KitDriftField = host.scenery.get_node("Middle/Ambient/Drift1")
	check("strong current reads actual pressure",flow.progress_flag=="pressure" and flow.progress_mix<0.01)
	host.abilities.pressure = true
	await tick(150)
	check("water calms smoothly without increasing the pool",flow.progress_mix>0.98 and flow.motes.size()==26)
	await room("R3-01",Vector2(3580,1360))
	await shot("02-pressure-open-gate")
	await room("R2-01",Vector2(448,1520))
	check("nursery has separate shell support and hinged leaf",host.scenery.has_node("World/State0/After/Art"))
	await shot("03-nursery")
	host.abilities.float = true
	await tick(45)
	check("nursery leaf responds to the same saved ability",(host.scenery.get_node("World/State0") as KitStateArt).mix>0.99)
	await room("R2-03",Vector2(1450,1040))
	check("heart remains an unanimated landmark",host.scenery.has_node("Middle/Landmark0/Art"))
	await shot("04-heart-landmark")
	await room("R2-04",Vector2(1450,1520))
	check("blood nest has its distinct core",host.enemies[0].actor.body.has_node("SwarmCore"))
	await tick(45)
	await shot("05-blood-nest-core")
	await room("R4-05",Vector2(2120,1440))
	var clam: Sprite2D = host.enemies[0].actor.body
	check("boss actually displays the eight-frame atlas",clam is KitClamVisual and clam.hframes==4 and clam.vframes==2 and clam.texture.resource_path.ends_with("clam-spit-cycle-v1.png"))
	var frames: Dictionary = {}
	for i: int in 260:
		await tick(1)
		frames[clam.frame] = true
		if clam.frame==4 and i%3==0: await shot("06-clam-open")
	check("live encounter reaches every authored phase",frames.size()==8)
	await motion_clip("clam",180)
	await room("R4-06",Vector2(640,1440))
	check("bone node is a readable device, not a fake fast travel",host.scenery.has_node("World/Resident0") and not host.scenery.get_node("World/Resident0").is_in_group("tide_transit_gates"))
	await shot("07-bone-node")
	await room("R5-01",Vector2(1520,1200))
	host.abilities.bone = true
	await tick(45)
	check("three slots track separate real marks",host.scenery.get_node("World/ProgressSlot0").mix>0.99 and host.scenery.get_node("World/ProgressSlot1").mix>0.99 and host.scenery.get_node("World/ProgressSlot2").mix<0.01)
	await shot("08-ear-slots-before")
	var wall: KitStateArt = host.scenery.get_node("World/State0")
	wall.reveal(host.player)
	await tick(40)
	check("scan can expose the voice grooves without awarding a mark",wall.mix>0.99 and not host.abilities.get("silence",false))
	host.abilities.silence = true
	await tick(300)
	check("silence makes the revealed wall and third slot permanent",wall.mix>0.99 and host.scenery.get_node("World/ProgressSlot2").mix>0.99)
	await shot("09-ear-slots-revealed")
	await room("R5-02",Vector2(1600,1360))
	await shot("10-safe-pool")
	await room("R5-04",Vector2(2400,1440))
	await shot("11-silent-grooves")
	await room("R5-08",Vector2(2250,1280))
	var school: KitLarvaSchool = host.scenery.get_node("Middle/Ambient/Ecology0")
	check("six protected larvae play real body frames",school.members.size()==6 and school.get_child_count()==6 and not school.released)
	await shot("12-larvae-pool")
	var poses: Dictionary = {}
	for i: int in 70:
		await tick(1)
		poses[school.members[0].node.frame]=true
	check("larva body is animated independently of movement",poses.size()==8)
	await motion_clip("larvae-pool",90)
	host.abilities.ending = true
	await tick(150)
	check("open sluice releases the existing bounded school",school.released and school.members.size()==6 and school.get_child_count()==6)
	await motion_clip("larvae-outflow",90)
	await shot("13-larvae-outflow")
	var failures: int = checks.filter(func(c:Dictionary)->bool:return not c["pass"]).size()
	FileAccess.open(OUT.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"real main scene, isolated position/progress fixtures; no claim of natural unlock or user art approval"},"\t"))
	# Let this coroutine release room-local visual references before engine shutdown.
	host.graceful_quit.call_deferred(1 if failures>0 else 0)
