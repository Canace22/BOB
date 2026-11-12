extends SceneTree
## Fixture: R1-05 with the Boss defeated and dash earned. Everything after is
## real Input: the exit into 胃枢, its camp, stairs, rings and locked doors, then back.
## Run windowed for screenshots; "-- --reload-world" verifies the save in a new process.
class WorldCampaign extends WhalebellyMain:
	func save_path() -> String:
		return "user://whalebelly/world-skeleton-%s.json" % str(ProjectSettings.globalize_path("res://").hash())

var host: WhalebellyMain
var failed: int = 0
var output: String = "res://build/qa/world-skeleton"

func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for i: int in count: await physics_frame
func verify(label: String, passed: bool, detail: Variant = "") -> void:
	print("PASS " if passed else "FAIL ", label, "" if passed else "  " + str(detail))
	if not passed: failed += 1
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func door(target: String) -> CampaignDoorway:
	for entrance: CampaignDoorway in host.continuity.doorways:
		if entrance.destination_id == target: return entrance
	return null

func footing_ends(direction: float) -> bool:
	var p: Vector2 = host.player.position
	for surface: Array in host.room.surfaces:
		var a: Vector2 = host.point(surface[0])
		var b: Vector2 = host.point(surface[-1])
		if absf(p.y - a.y) < 30.0 and p.x > a.x - 20.0 and p.x < b.x + 20.0:
			return (b.x - p.x if direction > 0 else p.x - a.x) < 46.0
	return false

## Walks to the target; a jump is held to its apex when the target is higher or,
## with leap, when footing ends. Without leap the actor steps off edges to descend.
func go(target: Vector2, budget: int = 720, leap: bool = true) -> bool:
	var hold: int = 0
	var wait: int = 0
	var start_room: int = host.room_index
	for frame: int in budget:
		var p: WhalebellyCampaignPlayer = host.player
		var delta: Vector2 = target - p.position
		if host.room_index != start_room or (absf(delta.x) < 30.0 and absf(delta.y) < 40.0 and p.is_on_floor()): break
		Input.action_release("left")
		Input.action_release("right")
		if absf(delta.x) > 14.0: Input.action_press("right" if delta.x > 0 else "left")
		hold -= 1
		wait -= 1
		if hold == 0: Input.action_release("jump")
		if p.is_on_floor() and wait <= 0 and (delta.y < -40.0 or (leap and absf(delta.x) > 90.0 and footing_ends(signf(delta.x)))):
			Input.action_press("jump")
			hold = 26
			wait = 44
		await physics_frame
	host.release_controls()
	await tick(8)
	var end: Vector2 = host.player.position
	return host.room_index == start_room and absf(end.x - target.x) < 60.0 and absf(end.y - target.y) < 60.0

func setup() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(WorldCampaign)
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(10)

func run() -> void:
	await setup()
	if "--reload-world" in OS.get_cmdline_user_args():
		await reload()
	elif "--views" in OS.get_cmdline_user_args():
		await views()
	else:
		await enter_hub()
		if str(host.room.id) == "R3-01":
			await explore_hub()
			await leave_hub()
	print("WORLD_SKELETON_COMPLETE failed=", failed)
	await host.graceful_quit(1 if failed else 0)

func enter_hub() -> void:
	host.defeated = {"R1-04:0": true}
	host.abilities.dash = true
	await host.flow_setup(4)
	host.checkpoint = {"room": 4, "pos": []}
	var exit: CampaignDoorway = door("chapter-exit")
	verify("first-region exit binds to the linked room", exit != null and str(exit.data.get("to_id", "")) == "R3-01" and int(exit.data.to) >= 7)
	for target: Vector2 in [Vector2(600,577), Vector2(960,560), Vector2(1450,563), Vector2(1515,560)]:
		verify("throat crossing %d" % int(target.x), await go(target), host.player.position)
	# Re-read the entrance: a fall that reloads the room would free the earlier node.
	verify("throat crossed without a room reload", is_instance_valid(exit) and host.health == 5, host.events.slice(-12).map(func(event: Dictionary) -> String: return str(event.event)))
	exit = door("chapter-exit")
	verify("exit prompt names the hub", exit != null and exit.prompt().contains("胃枢"))
	await host.input_tap("interact")
	await tick(150)
	verify("exit enters 胃枢", str(host.room.id) == "R3-01", host.room.id)
	verify("milestone saved once on the way", host.completed and host.last_save_ok)
	verify("arrival is grounded and unlocked", host.player.is_on_floor() and not host.player.transition_locked and not host.continuity.travelling, host.player.position)
	verify("region title follows the room", CampaignWorld.region_name(str(host.room.id)) == "胃肠沉城")
	await tick(40)
	verify("no bounce back through the passage", str(host.room.id) == "R3-01")
	await shot("01-arrival")

func explore_hub() -> void:
	await go(Vector2(840, 2224), 240, false)
	verify("walking into the first seam lands on the bed unharmed", host.player.is_on_floor() and absf(host.player.position.y - 2224.0) < 12.0 and host.health == 5, host.player.position)
	verify("bed returns to the camp bank by an ordinary jump", await go(Vector2(1120, 2080)), host.player.position)
	await host.input_tap("interact")
	await tick(50)
	verify("hub camp records the checkpoint", int(host.checkpoint.room) == host.room_index and host.health == 5 and host.last_save_ok, host.checkpoint)
	await shot("02-camp")
	for step: Vector2 in [Vector2(960,2080), Vector2(640,1960), Vector2(960,1840), Vector2(800,1720), Vector2(520,1600), Vector2(240,1480)]:
		verify("stair to %d,%d" % [int(step.x), int(step.y)], await go(step), host.player.position)
	await go(Vector2(96, 1480), 120)
	await tick(20)
	verify("lung exit stays honest", str(host.room.id) == "R3-01" and door("R2-01").prompt() == CampaignWorld.UNBUILT, door("R2-01").prompt())
	await shot("03-lung-door")
	for step: Vector2 in [Vector2(520,1600), Vector2(800,1720), Vector2(1040,1840), Vector2(1300,2080)]:
		verify("step down to %d,%d" % [int(step.x), int(step.y)], await go(step, 720, false), host.player.position)
	verify("cross the seams to the gut bank", await go(Vector2(2820, 2080), 1200), host.player.position)
	for ring: int in 4:
		Input.action_press("right")
		await host.input_tap("grapple")
		Input.action_release("right")
		for frame: int in 120:
			if host.player.grapple_hanging: break
			await physics_frame
		verify("ring %d holds" % (ring + 1), host.player.grapple_hanging and host.player.position.distance_to(host.point(host.room.rings[ring]) + Vector2(0, 55)) < 30.0, host.player.position)
		if ring == 1: await shot("04-current-and-rings")
	await host.input_tap("jump")
	await tick(90)
	verify("last ring drops onto the gate bank", host.player.is_on_floor() and absf(host.player.position.y - 1360.0) < 20.0, host.player.position)
	await go(Vector2(3690, 1360), 200)
	await host.input_tap("interact")
	await tick(30)
	verify("combined gate names the missing key only", str(host.room.id) == "R3-01" and door("R4-01").restriction() == "需要潮压", door("R4-01").restriction())
	await shot("05-gate")
	verify("walk off to the low bank", await go(Vector2(3300, 2080), 400, false), host.player.position)

func leave_hub() -> void:
	verify("seams back to the camp bank", await go(Vector2(960, 2080), 1500), host.player.position)
	verify("lowest stair is the step over the last seam", await go(Vector2(640, 1960)), host.player.position)
	verify("step off to the entry bank", await go(Vector2(300, 2080), 400, false), host.player.position)
	Input.action_press("left")
	for frame: int in 160:
		if str(host.room.id) != "R3-01": break
		await physics_frame
	Input.action_release("left")
	await tick(90)
	verify("passage returns to 流膜育窝", str(host.room.id) == "R1-05" and host.player.position.distance_to(Vector2(1450, 563)) < 120.0, [host.room.id, host.player.position])
	await tick(40)
	verify("return arrival is stable", str(host.room.id) == "R1-05" and host.player.is_on_floor() and host.player.health > 0)
	verify("checkpoint still points at the hub camp", str(host.rooms[int(host.checkpoint.room)].id) == "R3-01")

func reload() -> void:
	host.load_progress()
	host.load_room(host.room_index, host.checkpoint.get("pos", []))
	await tick(60)
	verify("new process restores the hub checkpoint", str(host.room.id) == "R3-01" and host.player.is_on_floor() and host.player.position.distance_to(Vector2(1120, 2080)) < 200.0, [host.room.id, host.player.position])
	verify("milestone and earned dash survive", host.completed and host.abilities.get("dash", false) and not host.abilities.get("pressure", false))
	await shot("07-reload")

## Position fixtures for visual review only; "-- --views --outlines" adds collision lines.
func views() -> void:
	host.outlines = "--outlines" in OS.get_cmdline_user_args()
	var hub: int = host.rooms.find_custom(func(entry: Dictionary) -> bool: return str(entry.id) == "R3-01")
	var spots: Dictionary = {"entry":[256,2080], "camp":[1120,2080], "stairs":[800,1720], "lung-door":[160,1480], "middle":[2400,2080], "current":[2780,2080], "gate":[3640,1360]}
	for label: String in spots:
		host.load_room(hub, spots[label])
		await tick(45)
		await shot("view-" + label)
	host.visited = {"R1-04":true, "R1-05":true, "R3-01":true}
	for page: Array in [[hub, "map-r3"], [4, "map-r1"]]:
		host.load_room(int(page[0]))
		await tick(30)
		host.player_ui.open("map")
		await tick(20)
		await shot("view-" + str(page[1]))
		host.player_ui.close_all()
		await tick(10)
