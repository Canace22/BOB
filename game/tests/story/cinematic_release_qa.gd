extends SceneTree
## 正式流式场景分段夹具；键盘/鼠标走输入管线，故障注入与自然播放分别记录。
const OUT: String="res://build/qa/cinematic-release"
var host: WhalebellyMain
var failures: int=0
var checks: Array[Dictionary]=[]

func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
	for i: int in n: await physics_frame
func key(code: Key, down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func tap(code: Key) -> void:
	key(code,true)
	await tick(2)
	key(code,false)
	await tick(3)
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	if not passed: failures+=1
	print("PASS " if passed else "FAIL ",label)
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))

func prepare() -> void:
	for code: Key in [KEY_D,KEY_F,KEY_ENTER,KEY_ESCAPE]: key(code,false)
	Input.action_release("tp_interact")
	var prefix: Array[String]=[]
	var facts: Dictionary={}
	for stage: Dictionary in host.story.catalog.stages:
		if str(stage.id)=="ch03_flood": break
		prefix.append(str(stage.id))
		for flag: String in stage.get("grant",[]): facts[flag]=true
	host.story.restore({"version":1,"completed":prefix,"facts":facts})
	var stage: Dictionary=host.story.stage()
	var room: int=host.rooms.find_custom(func(r: Dictionary) -> bool:return str(r.id)==str(stage.room_id))
	host.health=5
	host.load_room(room,stage.at)
	host.player_ui.close_all()
	host.player_ui.pending_resume=false
	host.player.controls_enabled=true
	host.story.interaction_armed=true
	paused=false
	await tick(90)

func start() -> bool:
	await prepare()
	await tap(KEY_F)
	for i: int in 120:
		if host.story.cinematic.active: break
		await tick(1)
	check("F starts the actual flood cinematic",host.story.cinematic.active)
	return host.story.cinematic.active

func wait_end(capture: String="") -> void:
	var film: CampaignCinematic=host.story.cinematic
	var captured: bool=false
	for i: int in 1400:
		if not film.active or film.waiting_release: break
		if not capture.is_empty() and not captured and film.cursor==film.shots.size()-1 and film.clock>0.4:
			await shot(capture)
			captured=true
		await tick(1)
	await tick(5)

func verify_return(label: String) -> void:
	check(label+": control and normal camera restored",not host.story.cinematic.active and not paused and host.player.controls_enabled and host.camera.is_current())
	check(label+": observation completes once",host.story.completed.count("ch03_flood")==1 and str(host.story.stage().id)=="ch03_after")
	var at: Vector2=host.player.position
	key(KEY_D,true)
	await tick(12)
	key(KEY_D,false)
	await tick(3)
	check(label+": D moves the actual player",host.player.position.x>at.x+5)

func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUT)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","cinematic-release")
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(40)
	host.ui_interactive_in_tests=true
	host.dialogue.enabled=true
	host.story.allow_in_tests=true
	host.story.set_process(false)
	check("QA progress is isolated",host.save_path().contains("cinematic-release"))
	check("Current streaming world is enabled",host.streaming.enabled)
	if not await start(): await host.graceful_quit(1); return
	await wait_end("01-final-caption")
	await verify_return("natural playback")
	await shot("02-restored")
	if not await start(): await host.graceful_quit(1); return
	Input.action_press("tp_interact")
	check("Injected orphan has no physical F held",not Input.is_physical_key_pressed(KEY_F))
	await wait_end()
	await verify_return("orphaned action")
	for resume_key: Key in [KEY_F,KEY_ENTER]:
		if not await start(): await host.graceful_quit(1); return
		key(KEY_D,true) # Deliberately omit keyup to model a lost browser release.
		await wait_end()
		check("Held movement still waits for release",host.story.cinematic.waiting_release and paused)
		await shot("03-wait-"+str(resume_key))
		await tap(resume_key)
		check("Fresh confirmation clears the lost movement key",not Input.is_physical_key_pressed(KEY_D))
		await verify_return("resume "+str(resume_key))
	if not await start(): await host.graceful_quit(1); return
	key(KEY_D,true)
	await tap(KEY_ESCAPE)
	await tap(KEY_ESCAPE)
	await wait_end()
	var film: CampaignCinematic=host.story.cinematic
	check("Final mouse button is actionable",film.waiting_release and film.view.skip_button.text=="继续游戏")
	var at: Vector2=film.view.skip_button.get_global_rect().get_center()
	for down: bool in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=at
		event.global_position=at
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=down
		Input.parse_input_event(event)
		await tick(2)
	await verify_return("mouse continue")
	await shot("04-after-mouse")
	var report: Dictionary={"checks":checks,"failures":failures,"method":"Native GPU, formal streaming scene, isolated stage starts and InputEvent keys/mouse; action-only and missing-keyup faults are injected. Not a continuous campaign playthrough."}
	var output: FileAccess=FileAccess.open(OUT.path_join("report.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	print("CINEMATIC_RELEASE_QA ",checks.size()," checks, ",failures," failures")
	await host.graceful_quit(0 if failures==0 else 1)
