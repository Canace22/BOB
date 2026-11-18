extends SceneTree
## Explicit old-V6/room fixtures; the approach and pickup use physical-key events.
const OUT := "res://build/qa/treasure"
const ID := "R5-08:tidal-pearl"
var host: WhalebellyMain
var checks: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void: run.call_deferred()

func tick(count: int) -> void:
	for frame: int in count: await physics_frame

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code, true)
	await tick(2)
	key(code, false)
	await tick(5)

func check(label: String, passed: bool) -> void:
	checks.append({"name":label, "pass":passed})
	if not passed: failures += 1
	print("TREASURE ", "PASS " if passed else "FAIL ", label)

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label + ".png"))

func index_of(id: String) -> int:
	return host.rooms.find_custom(func(item: Dictionary) -> bool: return str(item.id) == id)

func treasure() -> KitTreasure:
	return host.scenery.get_node("World/Treasure0") as KitTreasure

func approach() -> void:
	key(KEY_A, true)
	for frame: int in 100:
		await tick(1)
		if host.player.position.x < 2395: break
	key(KEY_A, false)
	await tick(12)
	check("A walks along real floor to shell", host.player.is_on_floor() and KitInteractable.nearest(host) == treasure())
	check("F prompt identifies pearl and shield", host.player_ui.data.prompt() == treasure().prompt_text)

func pickup() -> void:
	await tap(KEY_F)
	for frame: int in 120:
		await tick(1)
		if host.collected.get(ID, false): break
	await tick(8)
	check("Physical F collects pearl", host.collected.get(ID, false))

func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite", "treasure")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	await tick(25)
	check("Save is isolated from player progress", host.save_path().contains("doorway-treasure-"))
	if "--reload-treasure" in OS.get_cmdline_user_args():
		await verify_reload()
		await finish("independent-reload")
		return
	var index: int = index_of("R5-08")
	# A player who finished the ending before this feature still has an unclaimed pearl.
	var old: Dictionary = {"version":6, "checkpoint":{"room":index, "pos":[2800,1280]}, "collected":{"R1-03":true,"R5-08":true}, "abilities":{"ending":true,"anchor":true}, "defeated":{"R5-04:0":true}, "completed":true}
	WhaleUISaveAccess.write(host.save_path(), old)
	host.load_progress()
	host.load_room(index, old.checkpoint.pos)
	await tick(45)
	check("Old ending save leaves visible unclaimed pearl", treasure().get_node("Loot").visible and not host.collected.get(ID, false))
	check("Ending sluice stays open", not host.scenery.get_node("World/RewardArt").visible)
	var loot: Sprite2D = treasure().get_node("Loot")
	check("Registered pearl bitmap loads at equal scale", loot.texture != null and loot.texture.resource_path.ends_with("/ringed-calcium-pearl.png") and is_equal_approx(loot.scale.x,loot.scale.y))
	await shot("00-old-ending-unclaimed")
	await tap(KEY_F)
	await tick(55)
	check("F at sluice cannot collect distant pearl", not host.collected.get(ID, false))
	await approach()
	await shot("01-shell-prompt")
	await tap(KEY_ESCAPE)
	await tap(KEY_F)
	check("Pause blocks pickup", paused and not host.collected.get(ID, false))
	await tap(KEY_ESCAPE)
	await tick(25)
	host.health = 3
	host.player.health = 3
	host.player.soul = 12
	var checkpoint: Dictionary = host.checkpoint.duplicate(true)
	await pickup()
	check("Pearl adds one shield and restores life and soul", CampaignRelics.capacity(host.collected) == 3 and host.relics.charges == 3 and host.player.health == 5 and host.player.soul == 99)
	check("Only contents disappear; shell remains", not loot.visible and host.scenery.get_node("World/Art/Prop2_release-bowl").visible)
	check("Pickup preserves ending, boss and checkpoint", host.abilities.get("ending",false) and host.defeated.get("R5-04:0",false) and host.checkpoint == checkpoint)
	check("Map details and unlock banner show new relic", host.player_ui.data.room_description(index).contains("归潮珠") and WhaleUnlockBanner.relic_card(ID).title == "归潮珠")
	await shot("02-collected")
	host.relics.charges = 0
	host.health = 4
	host.player_soul = 12
	host.player.health = 4
	host.player.soul = 12
	for repeat: int in 3:
		await tap(KEY_F)
		await tick(35)
	print("TREASURE repeat state ",host.relics.charges," ",host.player.health," ",host.player.soul)
	check("Repeated F cannot farm shield or recovery", host.relics.charges == 0 and host.player.health == 4 and host.player.soul == 12)
	check("Collected shell has no active pickup prompt", not treasure().nearby(host) and host.player_ui.data.prompt().is_empty())
	host.load_room(index_of("R4-06"), [1080,1320])
	await tick(35)
	check("Inactive cached treasure cannot interact", KitInteractable.nearest(host) != treasure_from_cache())
	host.load_room(index, [2390,1280])
	await tick(35)
	check("Revisit keeps empty shell without refilling shield", not treasure().get_node("Loot").visible and host.relics.charges == 0)
	host.load_progress()
	host.load_room(index, [2390,1280])
	await tick(35)
	check("V6 reload restores pearl and shield with valid room IDs", host.collected.get(ID,false) and host.relics.charges == 3 and not host.visited.has(ID))
	# Keep the earned ending save for a second, independent process.
	var saved: String = FileAccess.get_file_as_string(host.save_path())
	host.collected.clear()
	host.abilities = {"anchor":true}
	host.relics.refill(host.collected)
	host.load_room(index, [2500,1280])
	await tick(35)
	await approach()
	await pickup()
	check("Pearl is available before ending without opening sluice", not host.has_ability("ending") and not host.collected.get("R5-08",false) and host.scenery.get_node("World/RewardArt").visible and host.relics.charges == 1)
	FileAccess.open(host.save_path(),FileAccess.WRITE).store_string(saved)
	await finish("pickup")

func treasure_from_cache() -> KitInteractable:
	for node: Node in get_nodes_in_group("kit_interactables"):
		if node is KitTreasure: return node
	return null

func verify_reload() -> void:
	host.load_progress()
	host.load_room(host.room_index, host.checkpoint.pos)
	await tick(45)
	check("Independent process loads earned pearl", host.collected.get(ID,false) and host.relics.charges == 3)
	check("Independent process keeps empty shell and ending", not treasure().get_node("Loot").visible and host.has_ability("ending"))
	await shot("03-independent-reload")

func finish(label: String) -> void:
	FileAccess.open(OUT.path_join(label + ".json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Native GPU; explicit old V6 and room fixtures, physical-key A/F/Escape approach/pickup. Only separate QA save is written; not a full playthrough."},"\t"))
	await host.graceful_quit(1 if failures > 0 else 0)
