extends SceneTree
## 隔离档与入口夹具只负责布置起点，过门和地图开合均由实际按键触发。
var host: WhalebellyMain
var failures: int = 0
const OUTPUT := "res://build/qa/minimap"

func _initialize() -> void: run.call_deferred()

func tick(count: int) -> void:
	for i: int in count: await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code,true)
	await tick(3)
	key(code,false)
	await tick(25)

func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(label+".png"))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","minimap")
	host.qa = true
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	await tick(40)
	var ui: WhaleCampaignUI = host.player_ui
	var map: WhaleCampaignMinimap = ui.hud.minimap
	check("HUD minimap visible at top right",map.is_visible_in_tree() and map.position.x>800 and map.position.y==24)
	await shot("01-start")
	# 起点放到门前，随后通过真实 E 触发换房并等待淡黑结束。
	var door: CampaignDoorway = host.continuity.doorways[0]
	host.player.position = door.position + Vector2(-door.direction*35,-4)
	host.player.invulnerable = 100
	await tick(30)
	door.armed = true
	await tap(KEY_E)
	await tick(120)
	check("Keyboard doorway updates current room",host.room_index==1 and map.rooms.any(func(r: Dictionary) -> bool: return r.current and r.id=="R1-02"))
	check("Junction reveals its two side branches",map.positions.has(5) and map.positions.has(6))
	await shot("02-junction")
	await tap(KEY_C)
	check("C still opens full map",ui.page_id=="map" and not ui.hud.visible)
	await tap(KEY_ESCAPE)
	await tick(30)
	check("Escape restores minimap",ui.page_id.is_empty() and map.is_visible_in_tree())
	# 跨区截图只验布局，不冒充从开局自然通关。
	for index: int in [7,9,14,18]:
		host.load_room(index)
		await tick(35)
		check("Region follows room " + str(host.room.id),map.page==CampaignWorld.region(str(host.room.id)) and map.positions.has(index))
		await shot(str(host.room.id))
	print("MINIMAP_COMPLETE failed=",failures)
	await host.graceful_quit(1 if failures else 0)
