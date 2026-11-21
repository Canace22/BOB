extends SceneTree
## Real production floor/input; explicit starts and void fixtures use an isolated save.
var host: WhalebellyMain
var failures: int = 0
var checks: Array[Dictionary] = []
const OUTPUT := "res://build/qa/fall-recovery"

func _initialize() -> void: run.call_deferred()

func tick(count: int) -> void:
	for frame: int in count: await physics_frame

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	print(("PASS " if passed else "FAIL ")+label)
	if not passed: failures += 1

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OUTPUT.path_join(label+".png"))

func place(index: int, start: Array) -> void:
	host.health = 5
	host.load_room(index,start)
	await tick(35)
	check("Fixture settles on real floor in room %d" % index,host.player.is_on_floor())

func wait_ready(index: int) -> bool:
	for frame: int in 600:
		if host.streaming.is_ready(index): return true
		await tick(1)
	return false

func memory_return() -> void:
	await place(6,[460,1050])
	var actor: int = host.player.get_instance_id()
	key(KEY_A,true)
	for frame: int in 150:
		await tick(1)
		if host.player.position.x<145 or host.health<5: break
	key(KEY_A,false)
	await tick(130)
	check("Missing the memory recovery ledge returns to that ledge exactly once",
		host.health==4 and host.room.id=="R1-07" and host.player.get_instance_id()==actor
		and host.player.is_on_floor() and absf(host.player.position.y-1050)<4)
	check("The lower tongue room is still undiscovered",not host.visited.has("R1-03"))
	await shot("04-memory-recovery")
	await tick(2)

	# Return trip after collecting float. Steer into the gap beside the recovery ledge.
	host.abilities.float = true
	key(KEY_SPACE,true)
	key(KEY_A,true)
	await tick(3)
	key(KEY_A,false)
	await tick(10)
	key(KEY_W,true)
	key(KEY_SPACE,false)
	for frame: int in 80:
		await tick(1)
		if host.player.position.y<738: break
	key(KEY_A,true)
	for frame: int in 30:
		await tick(1)
		if host.player.position.x<280: break
	key(KEY_A,false)
	key(KEY_W,false)
	await tick(45)
	check("Float out from the recovered foothold onto the memory entrance bank",
		host.player.is_on_floor() and absf(host.player.position.y-750)<3 and host.health==4)
	host.abilities.float = false

func tongue_jump() -> void:
	await place(1,[1500,710])
	check("Tongue is prepared at the main-route exit",await wait_ready(2))
	var actor: int = host.player.get_instance_id()
	key(KEY_D,true)
	for frame: int in 240:
		await tick(1)
		if host.room.id=="R1-03" and host.player.position.x>=312: break
	check("Walking from the sieve activates the tongue entrance before takeoff",
		host.room.id=="R1-03" and host.player.get_instance_id()==actor and host.player.is_on_floor()
		and host.player.position.x>=312 and host.player.position.x<346)
	key(KEY_SPACE,true)
	for frame: int in 45:
		await tick(1)
		if host.player.position.x>=500: break
	key(KEY_D,false)
	await tick(20)
	key(KEY_SPACE,false)
	await tick(12)
	check("One ordinary jump lands on the live crab platform",
		host.room.id=="R1-03" and host.player.is_on_floor() and host.player.position.x>465
		and host.player.position.x<716 and absf(host.player.position.y-440)<3 and host.health==5)
	await shot("06-tongue-landing")

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","fall-recovery")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	await tick(35)
	await memory_return()
	await tongue_jump()
	host.checkpoint = {"room":0,"pos":[180,720]}
	host.save_progress(false)
	var saved: String = FileAccess.get_file_as_string(host.save_path())
	await place(0,[980,950])
	var actor: int = host.player.get_instance_id()
	key(KEY_D,true)
	var left_floor: bool = false
	for frame: int in 100:
		await tick(1)
		if not host.player.is_on_floor():
			left_floor = true
			break
	key(KEY_D,false)
	var safe: Vector2 = host.player.last_safe
	check("D walks off the recovery bank into a real pit",left_floor and safe.x>900)
	await shot("01-falling")
	for frame: int in 240:
		await tick(1)
		if host.health<5: break
	check("Void fall costs one life instead of killing",host.health==4)
	check("Fall returns beside the ledge with same actor",host.player.position.distance_to(safe)<8 and host.player.get_instance_id()==actor)
	check("Checkpoint and on-disk progress stay unchanged",host.checkpoint=={"room":0,"pos":[180,720]} and FileAccess.get_file_as_string(host.save_path())==saved)
	await tick(60)
	check("Recovered player stays supported instead of falling again",host.health==4 and host.player.is_on_floor())
	await shot("02-recovered")
	var before: Vector2 = host.player.position
	key(KEY_A,true)
	await tick(14)
	key(KEY_A,false)
	key(KEY_SPACE,true)
	await tick(8)
	key(KEY_SPACE,false)
	check("Real movement and jump work after recovery",host.player.position.x<before.x-20 and host.player.position.y<before.y-20)
	await tick(60)
	# Mid-skill, invulnerability and platform-drop fixtures must not defeat recovery.
	await place(0,[980,950])
	safe = host.player.last_safe
	host.collected["R1-03"] = true
	host.relics.refill(host.collected)
	check("Unlocked skill is active before forced fall",host.player.skill_controller.request("up_spell") and host.player.skill_controller.active)
	host.player.invulnerable = 10
	host.player.drop_timer = 2
	host.player.wall_lock = 2
	host.player.recoil_left = 2
	host.player.position = Vector2(-500,host.player.world_bounds.end.y+150)
	await tick(2)
	check("Void recovers during invulnerability and bypasses shield",host.health==4 and host.relics.charges==2)
	check("Recovery clears skill, downward phase and stale movement",not host.player.skill_controller.active and host.player.drop_timer==0 and host.player.wall_lock==0 and host.player.recoil_left==0 and host.player.position.distance_to(safe)<8)
	await tick(60)
	check("Phase recovery lands on its original platform",host.player.is_on_floor() and host.health==4)
	# An actual streamed crossing translates last_safe into the new room frame.
	await place(0,[1500,790])
	check("Next room is prepared",await wait_ready(1))
	actor = host.player.get_instance_id()
	key(KEY_D,true)
	for frame: int in 240:
		await tick(1)
		if host.room_index==1 and host.player.position.x>240 and host.player.is_on_floor(): break
	key(KEY_D,false)
	await tick(12)
	check("Real D crosses into the next room",host.room_index==1 and host.player.get_instance_id()==actor)
	safe = host.player.last_safe
	var safe_world: Vector2 = host.player.get_parent().to_global(safe)
	host.player.position = Vector2(-500,host.player.world_bounds.end.y+150)
	await tick(2)
	check("Post-crossing fall returns to the new room ledge",host.room_index==1 and host.player.global_position.distance_to(safe_world)<8 and host.health==4 and host.player.get_instance_id()==actor)
	await tick(60)
	await shot("03-streamed-recovery")
	# Authored soft beds share recovery; only depleted health opens death UI.
	host.player.hurt(1,true)
	check("Existing soft-bed fall still loses one life locally",host.health==3 and host.player.position.distance_to(host.player.last_safe)<1)
	await tick(60)
	host.player.health = 1
	host.health = 1
	host.player.position = Vector2(-500,host.player.world_bounds.end.y+150)
	await tick(2)
	check("Last life still enters normal death",host.health==0 and host.player.state=="defeat")
	for frame: int in 300:
		if paused: break
		await process_frame
	check("Depleted health shows death menu",host.player_ui.page_id=="death")
	var report := FileAccess.open(OUTPUT.path_join("report.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failed":failures,"method":"Production main scene and physics; real key input for pit and streamed crossing; explicit starts, forced void and life fixtures; isolated save"},"\t"))
	report.close()
	print("FALL_RECOVERY_COMPLETE failed=",failures)
	await host.graceful_quit(1 if failures else 0)
