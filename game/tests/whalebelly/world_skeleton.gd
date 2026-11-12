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
var shielded: bool = false # declared fixture: later legs check routes and defeat flow, not difficulty

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

## Walks to the target. For a higher target the jump waits until the actor is close
## or at the end of its footing, as a player would; with leap it also jumps level gaps.
## Without leap the actor steps off edges to descend.
func go(target: Vector2, budget: int = 720, leap: bool = true) -> bool:
	var hold: int = 0
	var wait: int = 0
	var start_room: int = host.room_index
	var start_y: float = host.player.position.y
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
		# Past the apex of a held jump, float carries the rest of a tall rise.
		if not p.is_on_floor() and delta.y < 20.0 and absf(target.y - p.position.y) > 0.0 and hold < 4 and p.position.y > target.y - 20.0 and target.y < start_y - 170.0: Input.action_press("float")
		else: Input.action_release("float")
		if p.is_on_floor() and wait <= 0 and ((delta.y < -40.0 and (absf(delta.x) < 190.0 or footing_ends(signf(delta.x)))) or (leap and absf(delta.x) > 90.0 and footing_ends(signf(delta.x)))):
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
	elif "--endgame" in OS.get_cmdline_user_args():
		await endgame()
	elif "--reload-endgame" in OS.get_cmdline_user_args():
		host.load_progress()
		verify("new process keeps the three marks and the ending", host.abilities.get("pressure", false) and host.abilities.get("bone", false) and host.abilities.get("silence", false) and host.abilities.get("ending", false) and host.collected.get("R5-08", false), host.abilities)
	else:
		await enter_hub()
		if str(host.room.id) == "R3-01":
			await explore_hub()
			await lung_route()
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

## Walks to the visible door for the expected room and enters it with the interact key.
func pass_door(expected: String, leap: bool = true) -> void:
	var entrance: CampaignDoorway = door(expected)
	if entrance != null: await go(entrance.position + Vector2(-entrance.direction * 30.0, 0), 400, leap)
	await tick(12)
	verify("door prompt names " + expected, entrance != null and entrance.nearby() and not entrance.prompt().is_empty(), host.player.position)
	await host.input_tap("interact")
	var faded: bool = false
	for frame: int in 200:
		faded = faded or host.continuity.transition.active
		if str(host.room.id) == expected and not host.continuity.travelling: break
		await physics_frame
	await tick(60)
	if shielded: host.player.invulnerable = 99999.0
	verify("door fades into " + expected, faded and str(host.room.id) == expected and host.player.is_on_floor() and not host.player.transition_locked, [host.room.id, host.player.position])

## Hub → 育床 (float granted by the nursery sac) → 心室观察台 (camp) → 血巢 → back to the hub.
func lung_route() -> void:
	for step: Vector2 in [Vector2(1300,2080), Vector2(960,2080), Vector2(640,1960), Vector2(960,1840), Vector2(800,1720), Vector2(520,1600), Vector2(240,1480)]:
		await go(step, 720, step.y < 2080.0)
	await pass_door("R2-01")
	verify("no float yet: the first rise is out of reach", not host.abilities.get("float", false) and not (await go(Vector2(880, 1260), 220)), host.player.position)
	await go(Vector2(448, 1520), 400, false)
	await host.input_tap("interact")
	await tick(50)
	verify("nursery sac grants float once", host.abilities.get("float", false) and host.collected.get("R2-01", false) and host.health == 5)
	await shot("06-nursery")
	for step: Vector2 in [Vector2(880,1260), Vector2(1400,1000), Vector2(1960,740)]:
		verify("float rise to %d,%d" % [int(step.x), int(step.y)], await go(step), host.player.position)
	await pass_door("R2-03")
	await go(Vector2(360, 1280), 200)
	await host.input_tap("interact")
	await tick(50)
	verify("observation camp records the checkpoint", str(host.rooms[int(host.checkpoint.room)].id) == "R2-03" and host.last_save_ok)
	await shot("07-observation")
	# The upper ledge sits on the jump arc from the middle deck, so the route goes over it and steps off.
	for step: Vector2 in [Vector2(900,1160), Vector2(1400,1040), Vector2(1960,920), Vector2(2240,1160)]:
		verify("observation deck to %d,%d" % [int(step.x), int(step.y)], await go(step, 720, step.y < 1100.0), host.player.position)
	await pass_door("R2-04")
	await shot("08-nest")
	verify("nest floor reaches the far wall", await go(Vector2(2700, 1520), 600), host.player.position)
	verify("walk back to the nest entrance", await go(Vector2(300, 1520), 600), host.player.position)
	await pass_door("R2-03")
	for step: Vector2 in [Vector2(2000,1160), Vector2(1400,1040), Vector2(900,1160), Vector2(300,1280)]:
		verify("deck back to %d,%d" % [int(step.x), int(step.y)], await go(step), host.player.position)
	await pass_door("R2-01")
	for step: Vector2 in [Vector2(1400,1000), Vector2(880,1260), Vector2(300,1520)]:
		verify("step down to %d,%d" % [int(step.x), int(step.y)], await go(step, 720, false), host.player.position)
	await pass_door("R3-01")
	for step: Vector2 in [Vector2(520,1600), Vector2(800,1720), Vector2(1040,1840), Vector2(1300,2080)]:
		await go(step, 720, false)

func leave_hub() -> void:
	verify("seams back to the camp bank", await go(Vector2(960, 2080), 1500), host.player.position)
	verify("lowest stair is the step over the last seam", await go(Vector2(640, 1960)), host.player.position)
	verify("step off to the entry bank", await go(Vector2(300, 2080), 400, false), host.player.position)
	await pass_door("R1-05", false)
	verify("passage returns to 流膜育窝", str(host.room.id) == "R1-05" and host.player.position.distance_to(Vector2(1450, 563)) < 120.0, [host.room.id, host.player.position])
	await tick(40)
	verify("return arrival is stable", str(host.room.id) == "R1-05" and host.player.is_on_floor() and host.player.health > 0)
	verify("checkpoint points at the last camp used", str(host.rooms[int(host.checkpoint.room)].id) == "R2-03")

func reload() -> void:
	host.load_progress()
	host.load_room(host.room_index, host.checkpoint.get("pos", []))
	await tick(60)
	verify("new process restores the observation camp", str(host.room.id) == "R2-03" and host.player.is_on_floor() and host.player.position.distance_to(Vector2(360, 1280)) < 200.0, [host.room.id, host.player.position])
	verify("milestone, dash and granted float survive", host.completed and host.abilities.get("dash", false) and host.abilities.get("float", false) and not host.abilities.get("pressure", false))
	await shot("07-reload")

## Position fixtures for visual review only; "-- --views --outlines" adds collision lines.
func views() -> void:
	host.outlines = "--outlines" in OS.get_cmdline_user_args()
	host.visited = {}
	for index: int in range(7, host.rooms.size()):
		host.visited[str(host.rooms[index].id)] = true
		host.load_room(index)
		await tick(70)
		await shot("room-" + str(host.rooms[index].id))
		if not host.enemies.is_empty():
			host.load_room(index, [float(host.enemies[0].pos.x) - 330.0, float(host.room.spawn[1])])
			await tick(150)
			await shot("enemy-" + str(host.rooms[index].id))
	for entry: Dictionary in host.rooms: host.visited[str(entry.id)] = true
	for page: Array in [[1, "map-r1", "map"], [7, "map-r3", "map"], [8, "map-r2", "map"], [11, "map-r4", "map"], [15, "map-r5", "map"], [18, "ending-page", "ending"]]:
		host.load_room(int(page[0]))
		await tick(30)
		host.player_ui.open(str(page[2]))
		await tick(20)
		await shot("view-" + str(page[1]))
		host.player_ui.close_all()
		await tick(10)

func room_index(id: String) -> int:
	return host.rooms.find_custom(func(entry: Dictionary) -> bool: return str(entry.id) == id)

## Waits unprotected inside an enemy's reach until its real attack lands.
func takes_hit(label: String, seconds: float) -> void:
	var before: int = host.health
	for frame: int in int(seconds * 60.0):
		if host.health < before: break
		await physics_frame
	verify(label, host.health == before - 1, [before, host.health])

## Chases the first enemy on its level and strikes with the attack key until it falls.
func fight(label: String, budget: int) -> void:
	var enemy: Dictionary = host.enemies[0]
	for frame: int in budget:
		if not enemy.alive: break
		var delta: Vector2 = Vector2(enemy.pos) - host.player.position
		Input.action_release("left")
		Input.action_release("right")
		if absf(delta.x) > 95.0 or frame % 16 == 0: Input.action_press("right" if delta.x > 0 else "left")
		if absf(delta.x) <= 110.0 and absf(delta.y) < 120.0:
			if frame % 16 == 2: Input.action_press("attack")
			if frame % 16 == 6: Input.action_release("attack")
		await physics_frame
	host.release_controls()
	await tick(60)
	verify(label, not enemy.alive, [enemy.hp, host.player.position])

func walk(label: String, steps: Array, leap: bool = true) -> void:
	for step: Vector2 in steps:
		verify("%s %d,%d" % [label, int(step.x), int(step.y)], await go(step, 720, leap), host.player.position)

## Legs of the closing route. A full run starts at 心室观察台 with dash and float as the only
## fixtures; "--from=<leg>" starts later with the marks earlier legs would have granted.
## Invulnerability is switched on after each enemy has shown its attack lands, so this
## proves routes and flow, not difficulty.
func endgame() -> void:
	var legs: Array[String] = ["lung", "hub", "spine", "ear", "release"]
	var fixtures: Dictionary = {"lung":["R2-03", [360,1280], []], "hub":["R3-01", [256,1480], ["pressure"]], "spine":["R4-01", [256,1280], ["pressure"]], "ear":["R5-01", [256,1440], ["pressure","bone"]], "release":["R4-06", [2440,1320], ["pressure","bone","silence"]]}
	var from: String = "lung"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--from="): from = argument.trim_prefix("--from=")
	host.defeated = {"R1-04:0": true}
	host.abilities.dash = true
	host.abilities.float = true
	host.completed = true
	for mark: String in fixtures[from][2]: host.abilities[mark] = true
	await host.flow_setup(room_index(str(fixtures[from][0])), fixtures[from][1])
	shielded = from != "lung"
	if shielded: host.player.invulnerable = 99999.0
	for leg: String in legs.slice(legs.find(from)):
		print("LEG ", leg)
		await call("leg_" + leg)
		if failed > 0: return

func leg_lung() -> void:
	await walk("to the swarm lane", [Vector2(900,1160)])
	await takes_hit("端足群流 sweeps a player standing in its lane", 9.0)
	shielded = true
	host.player.invulnerable = 99999.0
	await walk("observation deck", [Vector2(1400,1040), Vector2(1960,920)])
	await go(Vector2(2240,1160), 720, false)
	await pass_door("R2-04")
	if failed > 0: return
	shielded = false
	host.player.invulnerable = 0.0
	await go(Vector2(1400,1520), 600)
	await takes_hit("血巢潮群 sweeps the floor lane", 12.0)
	await shot("09-nest-boss")
	shielded = true
	host.player.invulnerable = 99999.0
	await fight("血巢潮群 falls to attack inputs", 9000)
	if failed > 0: return
	verify("pressure is granted and saved", host.abilities.get("pressure", false) and host.defeated.get("R2-04:0", false) and host.last_save_ok)
	await pass_door("R2-03")
	if failed > 0: return
	await walk("deck back", [Vector2(2000,1160), Vector2(1400,1040), Vector2(900,1160), Vector2(300,1280)])
	await pass_door("R2-01")
	if failed > 0: return
	await walk("step down", [Vector2(1400,1000), Vector2(880,1260), Vector2(300,1520)], false)
	await pass_door("R3-01")
	if failed > 0: return

func leg_hub() -> void:
	for step: Vector2 in [Vector2(520,1600), Vector2(800,1720), Vector2(1040,1840), Vector2(1300,2080)]: await go(step, 720, false)
	await go(Vector2(2820,2080), 1200)
	for ring: int in 4:
		Input.action_press("right")
		await host.input_tap("grapple")
		Input.action_release("right")
		for frame: int in 120:
			if host.player.grapple_hanging: break
			await physics_frame
	await host.input_tap("jump")
	await tick(90)
	verify("spine gate shows its open state", door("R4-01").restriction().is_empty() and door("R4-01").get_node("Open").visible and not door("R4-01").get_node("Closed").visible)
	await shot("10-gate-open")
	await pass_door("R4-01")
	if failed > 0: return

func leg_spine() -> void:
	await walk("spine entry", [Vector2(900,1160), Vector2(1500,1040)])
	await go(Vector2(2100,1160), 720, false)
	await pass_door("R4-03")
	if failed > 0: return
	await walk("anchor route", [Vector2(960,1296), Vector2(1560,1296)])
	shielded = false
	host.player.invulnerable = 0.0
	await takes_hit("吐珠鸣贝 lands a pearl", 9.0)
	shielded = true
	host.player.invulnerable = 99999.0
	await fight("吐珠鸣贝 falls", 1800)
	if failed > 0: return
	await go(Vector2(2500,1440), 720)
	await pass_door("R4-05")
	if failed > 0: return
	await go(Vector2(1500,1440), 600)
	await shot("11-clam-boss")
	await fight("悬脊鸣贝 falls to attack inputs", 9000)
	if failed > 0: return
	verify("bone is granted", host.abilities.get("bone", false) and host.defeated.get("R4-05:0", false))
	await pass_door("R4-06")
	if failed > 0: return
	await go(Vector2(400,1440), 300)
	await host.input_tap("interact")
	await tick(50)
	verify("transit camp records the checkpoint", str(host.rooms[int(host.checkpoint.room)].id) == "R4-06")
	await walk("transit decks", [Vector2(1100,1320), Vector2(1700,1200)])
	await go(Vector2(2300,1320), 720, false)
	await pass_door("R5-01")
	if failed > 0: return

func leg_ear() -> void:
	await walk("ear entry", [Vector2(900,1320), Vector2(1500,1200)])
	await go(Vector2(2100,1320), 720, false)
	await shot("12-three-slots")
	await pass_door("R5-02")
	if failed > 0: return
	await walk("safe pool", [Vector2(1000,1240)])
	await go(Vector2(1600,1360), 720, false)
	await walk("safe pool", [Vector2(2200,1240)])
	await pass_door("R5-04")
	if failed > 0: return
	await go(Vector2(1500,1440), 600)
	shielded = false
	host.player.invulnerable = 0.0
	await takes_hit("缄声覆膜 closes on the old position", 9.0)
	await shot("13-membrane-boss")
	shielded = true
	host.player.invulnerable = 99999.0
	await fight("缄声覆膜 falls to attack inputs", 9000)
	if failed > 0: return
	verify("silence is granted", host.abilities.get("silence", false) and host.defeated.get("R5-04:0", false))
	await pass_door("R5-02")
	if failed > 0: return
	await go(Vector2(1600,1360), 720, false)
	await walk("safe pool back", [Vector2(1000,1240)])
	await go(Vector2(300,1360), 720, false)
	await pass_door("R5-01")
	if failed > 0: return
	await walk("ear entry back", [Vector2(1500,1200)])
	await go(Vector2(900,1320), 720, false)
	await go(Vector2(300,1440), 720, false)
	await pass_door("R4-06")
	if failed > 0: return

func leg_release() -> void:
	await walk("transit back", [Vector2(1700,1200)])
	await go(Vector2(1160,1320), 720, false)
	await pass_door("R5-08")
	if failed > 0: return
	await go(Vector2(2720,1280), 900)
	await host.input_tap("interact")
	await tick(60)
	verify("release opens with all three marks", host.collected.get("R5-08", false) and host.abilities.get("ending", false) and host.last_save_ok and not host.scenery.get_node("World/RewardArt").visible)
	await shot("14-release")
