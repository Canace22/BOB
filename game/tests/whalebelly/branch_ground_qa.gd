extends SceneTree
## 正式场景、隔离档、真实按键；夹具仅用于起点和台下穿透检查。
const OUTPUT := "res://build/qa/branch-ground/"
var host: WhalebellyMain
var failed: int=0
var checks: Array[Dictionary]=[]
var unsupported: int=0
var max_error: float=0.0

func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for frame: int in count: await physics_frame
func key(code: Key, down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	print("PASS " if passed else "FAIL ",label)
	if not passed: failed+=1
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OUTPUT+label+".png")
func walk(target: float) -> void:
	var direction: float=signf(target-host.player.position.x)
	var code: Key=KEY_D if direction>0 else KEY_A
	key(code,true)
	for frame: int in 360:
		await tick(1)
		var p: WhalebellyCampaignPlayer=host.player
		if not p.is_on_floor(): unsupported+=1
		max_error=maxf(max_error,absf(p.position.y-host.ground_y(p.position.x,p.position.y)))
		if (p.position.x-target)*direction>=0: break
	key(code,false)
	await tick(15)
	check("Walk to "+str(target),absf(host.player.position.x-target)<20 and host.player.is_on_floor())

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size=Vector2i(1280,720)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","branch-ground")
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(10)
	host.load_room(1,[1835,210])
	host.player.invulnerable=1000
	await tick(35)
	check("Old floating checkpoint lands on slope",host.player.is_on_floor() and absf(host.player.position.x-1835)<1 and absf(host.player.position.y-137.5)<4)
	await shot("01-screenshot-position-fixed")
	host.player.position=Vector2(1480,205)
	host.player.velocity=Vector2.ZERO
	await tick(20)
	await walk(1835)
	await shot("02-uphill")
	await walk(1940)
	await shot("03-first-step")
	await walk(1480)
	check("Both directions keep ground contact",unsupported==0 and max_error<5)
	await shot("04-return")
	await walk(1835)
	var start: Vector2=host.player.position
	key(KEY_SPACE,true)
	await tick(2)
	key(KEY_SPACE,false)
	await tick(3)
	check("Jump leaves painted slope",not host.player.is_on_floor() and host.player.position.y<start.y-10)
	await tick(70)
	check("Short jump lands on same slope",host.player.is_on_floor() and host.player.position.distance_to(start)<4)
	# A jump below the one-way slope must pass upward, then settle on its top.
	host.player.position=Vector2(1835,190)
	host.player.velocity=Vector2.ZERO
	host.player.jump_count=0
	await tick(1)
	key(KEY_SPACE,true)
	await tick(10)
	key(KEY_SPACE,false)
	check("Jump from below passes through",host.player.position.y<130)
	await tick(100)
	check("Downward landing uses the painted top",host.player.is_on_floor() and absf(host.player.position.y-137.5)<4)
	await shot("05-jump-return")
	FileAccess.open(OUTPUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"unsupported":unsupported,"max_ground_error":max_error}))
	print("BRANCH_GROUND_COMPLETE failed=",failed," unsupported=",unsupported," error=",max_error)
	await host.graceful_quit(1 if failed else 0)
