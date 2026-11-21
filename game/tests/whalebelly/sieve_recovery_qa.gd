extends SceneTree
## Isolated starting positions; actual keyboard input with normal base abilities.
const OUTPUT := "res://build/qa/sieve-recovery"
var host: WhalebellyMain
var checks: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()

func tick(frames: int) -> void:
	for i: int in frames: await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed,"position":[host.player.position.x,host.player.position.y]})
	print("PASS " if passed else "FAIL ",label," ",host.player.position)

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	# An occluded desktop window can skip its regular draw indefinitely.
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OUTPUT.path_join(label+".png"))

func fixture(x: float) -> void:
	key(KEY_SPACE,false)
	key(KEY_A,false)
	key(KEY_D,false)
	host.player.position = Vector2(x,1048)
	host.player.velocity = Vector2.ZERO
	host.player.last_safe = host.player.position
	host.player.invulnerable = 999.0 # Isolate traversal from the live crab's damage.
	await tick(25)
	check("recovery floor at " + str(int(x)),host.player.is_on_floor() and absf(host.player.position.y-1050)<5)

func double_jump(first_hold: int = 24) -> void:
	key(KEY_SPACE,true)
	await tick(first_hold)
	key(KEY_SPACE,false)
	await tick(1)
	key(KEY_SPACE,true)
	await tick(30)
	key(KEY_SPACE,false)
	await tick(25)

func walk_on_landing(code: Key, target_x: float) -> void:
	var grounded := true
	var max_error := 0.0
	var crossed_target := false
	key(code,true)
	for frame: int in 60:
		await tick(1)
		var pos: Vector2 = host.player.position
		grounded = grounded and host.player.is_on_floor()
		max_error = maxf(max_error, absf(pos.y-host.ground_y(pos.x,850)))
		if (pos.x-target_x)*(1 if code==KEY_D else -1) >= 0:
			crossed_target = true
			break
	key(code,false)
	await tick(8)
	check("Walk across the painted deck to %d (error %.2f px)" % [target_x,max_error],
			crossed_target and grounded and max_error<1 and host.player.is_on_floor()
			and absf(host.player.position.y-host.ground_y(host.player.position.x,850))<1)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","sieve-recovery")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(45)
	host.player_ui.close_all()
	host.abilities = {"anchor":true,"float":false,"dash":false}
	host.load_room(1)
	await tick(40)
	check("base abilities only",not host.has_ability("float") and not host.has_ability("dash") and not host.practice)
	# At this timing the feet turn downward inside the old 30 px collision polygon.
	await fixture(600)
	await double_jump(10)
	check("Shallow double jump falls back to the lower floor",host.player.is_on_floor() and absf(host.player.position.y-1050)<2)
	await double_jump()
	check("Full double jump stands on the visible top at the screenshot position",
			host.player.is_on_floor() and absf(host.player.position.y-host.ground_y(host.player.position.x,850))<1)
	await shot("06-screenshot-footing")
	await walk_on_landing(KEY_A,465)
	await walk_on_landing(KEY_D,625)
	await fixture(545)
	await shot("01-under-left")
	await double_jump()
	check("double jump from directly below left platform",host.player.is_on_floor() and absf(host.player.position.y-850)<5)
	await shot("02-left-landing")
	await fixture(870)
	await double_jump()
	check("crab platform keeps its solid low ceiling",host.player.is_on_floor() and absf(host.player.position.y-1050)<5)
	key(KEY_A,true)
	for frame: int in 90:
		if host.player.position.x<550: break
		await tick(1)
	key(KEY_A,false)
	await tick(8)
	await double_jump()
	check("return from below crab via left platform",host.player.is_on_floor() and absf(host.player.position.y-850)<5)
	await shot("03-return-from-crab")
	await fixture(690)
	key(KEY_SPACE,true)
	await tick(24)
	key(KEY_SPACE,false)
	await tick(1)
	key(KEY_SPACE,true)
	key(KEY_A,true)
	await tick(20)
	key(KEY_A,false)
	await tick(25)
	key(KEY_SPACE,false)
	check("diagonal return from screenshot gap",host.player.is_on_floor() and absf(host.player.position.y-850)<5)
	await shot("04-gap-return")
	key(KEY_D,true)
	for frame: int in 60:
		if host.player.position.x>625: break
		await tick(1)
	key(KEY_SPACE,true)
	await tick(28)
	key(KEY_D,false)
	await tick(50)
	key(KEY_SPACE,false)
	# The live crab can carry the player on its shell; walk past it to the deck.
	key(KEY_D,true)
	for frame: int in 90:
		if host.player.position.x>960: break
		await tick(1)
	key(KEY_D,false)
	await tick(35)
	check("continue along main route onto crab platform",host.player.is_on_floor() and absf(host.player.position.y-830)<5)
	await shot("05-main-route")
	host.load_room(1,[600,869.6])
	await tick(35)
	check("Old embedded checkpoint restores to the painted top",
			host.player.is_on_floor() and absf(host.player.position.x-600)<1 and absf(host.player.position.y-850)<1)
	var failed: int = checks.filter(func(row: Dictionary)->bool:return not row.pass).size()
	FileAccess.open(OUTPUT.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"))
	await host.graceful_quit(1 if failed else 0)
