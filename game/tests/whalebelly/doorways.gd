extends SceneTree
## Room fixtures isolate entrances; actual Input drives their interaction.
var host: Node2D
var failures: int = 0
var count: int = 0
var output: String = "res://build/qa/doorways"

func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
	for i: int in n: await physics_frame
func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(15)
	for index: int in host.rooms.size():
		var doors: Array = host.rooms[index].doors.duplicate(true)
		for door_index: int in doors.size():
			host.load_room(index)
			var entrance: CampaignDoorway = host.continuity.doorways[door_index]
			var data: Dictionary = entrance.data
			var label: String = str(host.room.id) + "-" + entrance.destination_id
			count += 1
			check(label + " authored graph binding", data == doors[door_index])
			host.player.position = entrance.position + Vector2(-entrance.direction * 35.0, -4)
			host.player.invulnerable = 100.0
			host.player.automatic_doors = false
			entrance.armed = true
			await tick(30)
			check(label + " reachable prompt", entrance.nearby())
			check(label + " prompt matches input", host.player_ui.data.prompt_door() == entrance)
			if entrance.kind == "door": check(label + " bitmap loaded", is_instance_valid(entrance.inset) and entrance.inset.texture != null)
			await shot(label)
			if entrance.restriction() == "先击败负壳守卫":
				host.enter_door(data)
				check(label + " boss locks travel", not host.continuity.travelling)
				for enemy: Dictionary in host.enemies:
					if enemy.boss: enemy.alive = false
			if entrance.kind == "passage":
				host.player.automatic_doors = true
				entrance.armed = true
				Input.action_press("tp_right")
				await tick(100)
				Input.action_release("tp_right")
			else:
				Input.action_press("tp_interact")
				await tick(2)
				Input.action_release("tp_interact")
				await tick(110)
			if int(data.to) >= 0:
				check(label + " input changes room", host.room_index == int(data.to))
				check(label + " fade releases controls", not host.continuity.travelling and not host.player.transition_locked)
				var arrived: int = host.room_index
				await tick(40)
				check(label + " no immediate return", host.room_index == arrived)
				check(label + " safe arrival", host.player.health > 0 and host.player.position.y < float(host.room.size[1]))
			else:
				check(label + " terminal stays in room", host.room_index == index and not host.continuity.travelling)
				if entrance.kind == "exit": check(label + " completes chapter", host.completed)
	check("all 14 configured door endpoints", count == 14)
	host.qa_full_abilities = false
	host.abilities.float = false
	host.load_room(1, [190, 190])
	await tick(20)
	var locked: CampaignDoorway = host.continuity.doorways[2]
	locked.armed = true
	check("ability restriction is shown", locked.restriction() == "需要浮游")
	Input.action_press("tp_interact")
	await tick(2)
	Input.action_release("tp_interact")
	await tick(70)
	check("ability restriction prevents input travel", host.room_index == 1 and not host.continuity.travelling)
	host.qa_full_abilities = true
	host.load_room(1, [195, 185])
	await tick(20)
	check("arrival inside door starts disarmed", not host.continuity.doorways[2].armed)
	Input.action_press("tp_interact")
	await tick(2)
	Input.action_release("tp_interact")
	await tick(70)
	check("new E press cannot bounce before leaving", host.room_index == 1 and not host.continuity.travelling)

	# Return door wins only in its small range; nearby camp remains usable.
	host.load_room(4, [210, 552])
	await tick(20)
	check("camp remains separately accessible", host.player_ui.data.prompt() == "在营地歇息")
	print("DOORWAYS_COMPLETE count=", count, " failed=", failures)
	await host.graceful_quit(1 if failures else 0)
