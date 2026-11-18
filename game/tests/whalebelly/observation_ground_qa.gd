extends SceneTree
## Native GPU, isolated QA save. Pose fixtures only set leg starts; travel uses keys.
const OUT := "res://build/qa/observation-ground/"
var host: WhalebellyMain
var checks: Array[Dictionary]=[]
var unsupported: int=0
var max_error: float=0.0

func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func key(code: Key, down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func check(label: String, ok: bool, detail: Variant=null) -> void:
	checks.append({"name":label,"pass":ok,"detail":detail})
	print("PASS " if ok else "FAIL ",label," ",detail)
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
func walk(target: float, capture: String="") -> void:
	var direction: float=signf(target-host.player.position.x)
	var code: Key=KEY_D if direction>0 else KEY_A
	key(code,true)
	for i: int in 420:
		await tick(1)
		var p: WhalebellyCampaignPlayer=host.player
		if not p.is_on_floor(): unsupported+=1
		max_error=maxf(max_error,absf(p.position.y-host.ground_y(p.position.x,p.position.y)))
		if (p.position.x-target)*direction>=0: break
	if not capture.is_empty(): await shot(capture)
	key(code,false)
	await tick(12)
	check("Walk to "+str(target),absf(host.player.position.x-target)<18 and host.player.is_on_floor(),host.player.position)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size=Vector2i(1280,720)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","observation-ground")
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(12)
	var index: int=host.rooms.find_custom(func(room: Dictionary) -> bool: return str(room.id)=="R2-03")
	host.load_room(index,[1240,1424])
	host.player.invulnerable=1000
	await tick(45)
	check("Screenshot dip loads onto the measured bed",host.player.is_on_floor() and absf(host.player.position.y-host.ground_y(1240,1424))<4,host.player.position)
	await shot("01-screenshot-dip-fixed")
	await walk(1660)
	await shot("02-right-ridge")
	await walk(2350)
	await walk(80)
	await shot("03-left-return")
	await walk(1240,"03b-running-contact")
	check("Two-way travel stays grounded",unsupported==0 and max_error<5,{"unsupported":unsupported,"ground_error":max_error})
	var start: Vector2=host.player.position
	key(KEY_SPACE,true)
	await tick(8)
	key(KEY_SPACE,false)
	check("Jump leaves the measured bed",not host.player.is_on_floor() and host.player.position.y<start.y-25)
	await tick(80)
	check("Jump lands back on the painted top",host.player.is_on_floor() and host.player.position.distance_to(start)<4,host.player.position)
	await shot("04-jump-land")
	# Old checkpoints on the raised rim must project before a body is spawned.
	host.load_room(index,[1640,1424])
	host.player.invulnerable=1000
	await tick(35)
	check("Old checkpoint below a ridge restores above it",host.player.is_on_floor() and absf(host.player.position.y-host.ground_y(1640,1424))<4,host.player.position)
	host.manual_save()
	var saved: Dictionary=WhaleUISaveAccess.read(host.save_path(),host.rooms)
	check("QA V6 save retains the corrected floor",not saved.is_empty() and absf(float(saved.checkpoint.pos[1])-host.player.position.y)<2)
	host.load_progress()
	host.load_room(int(host.checkpoint.room),host.checkpoint.pos)
	await tick(35)
	check("QA reload lands on the same ridge",host.player.is_on_floor() and absf(host.player.position.x-1640)<3)
	await shot("05-save-reload")
	var failed: int=checks.filter(func(item: Dictionary) -> bool: return not item["pass"]).size()
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"unsupported":unsupported,"max_ground_error":max_error}))
	print("OBSERVATION_GROUND_COMPLETE failed=",failed)
	await host.graceful_quit(1 if failed else 0)
