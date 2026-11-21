extends SceneTree
## 隔离档与入口夹具只负责布置起点，过门和地图开合均由实际按键触发。
var host: WhalebellyMain
var failures: int = 0
var output: String = OS.get_environment("MINIMAP_QA_OUT")

func _initialize() -> void: run.call_deferred()

func tick(count: int) -> void:
	for i: int in count: await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

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
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func run() -> void:
	if output.is_empty(): output = "res://build/qa/minimap"
	DirAccess.make_dir_recursive_absolute(output)
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","minimap")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	await tick(40)
	var ui: WhaleCampaignUI = host.player_ui
	var map: WhaleCampaignMinimap = ui.hud.minimap
	check("HUD minimap visible at top right",map.is_visible_in_tree() and map.position.x>800 and map.position.y==24)
	await shot("01-start")
	# 末段平台为显式起点；连接段通过D连续步行，不使用旧E传送驱动。
	for frame: int in 900:
		if host.streaming.is_ready(1): break
		await tick(1)
	var door: Dictionary = host.room.doors[0]
	var lane: Dictionary = host.room.layout.checkpoint_lanes.filter(func(value: Dictionary) -> bool: return float(value.x[0])<float(door.pos[0]) and float(value.x[1])>float(door.pos[0]) and absf(float(value.y)-float(door.pos[1]))<24)[0]
	host.player.position = Vector2(float(lane.x[0])+4,float(lane.y)-4)
	host.player.velocity = Vector2.ZERO
	await tick(15)
	for frame: int in 600:
		key(KEY_D,true)
		await tick(1)
		if host.room_index==1: break
	key(KEY_D,false)
	await tick(25)
	check("Keyboard doorway updates current room",host.room_index==1 and map.exits.size()==4)
	if host.room_index!=1 or map.exits.size()!=4:
		print("Doorway fixture stopped: ",host.room.id," ",host.player.position," ",ui.page_id," ",host.streaming.snapshot())
		await host.graceful_quit(1)
		return
	check("Junction shows its two upper branch exits",map.exits[2].point.y<map.exits[0].point.y and map.exits[3].point.y<map.exits[1].point.y)
	await shot("02-junction")
	await tap(KEY_C)
	check("C still opens full map",ui.page_id=="map" and not ui.hud.visible)
	var full: WhaleUIMap = ui.body.find_child("RouteMap",true,false)
	check("Global view fits all nineteen rooms without scrolling",full.page=="world" and full.buttons.size()==19 and not WhaleUIMapPage.snapshot(ui).needs_scroll)
	var total: Label = ui.body.find_child("MapCount",true,false)
	check("Crossing updates the global count",total.text.ends_with("2/19"))
	await shot("03-world-map")
	check("Opening the junction shows the next step without listing exits", WhaleUIMapPage.snapshot(ui).detail.is_empty())
	await tap(KEY_ENTER)
	check("Enter on the current junction reveals its exits", str(WhaleUIMapPage.snapshot(ui).detail).contains("鲸须记忆袋"))
	var inspected_before := full.inspected
	var position_before := full.buttons[inspected_before].get_global_rect().get_center()
	await tap(KEY_TAB)
	check("Tab inspects a different room in place",full.inspected != inspected_before and full.caption.text == str(host.rooms[full.inspected].name))
	check("Inspection leaves the route in place", position_before.is_equal_approx(full.buttons[inspected_before].get_global_rect().get_center()))
	var selected_button := full.buttons[4]
	var hover := InputEventMouseMotion.new()
	hover.position = selected_button.get_global_rect().get_center()
	root.push_input(hover, true)
	await tick(3)
	check("Hover changes the same single room label", full.inspected == 4 and full.caption.text == str(host.rooms[4].name))
	var return_button := full.buttons[0]
	var click := InputEventMouseButton.new()
	click.position = return_button.get_global_rect().get_center()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click, true)
	click.pressed = false
	root.push_input(click, true)
	await tick(3)
	check("Click inspects a visited room without travelling", full.inspected == 0 and host.room_index == 1)
	var before_visits: Dictionary = host.visited.duplicate()
	for region: String in CampaignWorld.REGIONS:
		var tab: Button = ui.body.find_child("Map_"+region,true,false)
		tab.grab_focus()
		await tap(KEY_ENTER)
		check("Keyboard opens region "+region,full.page==region and tab.button_pressed)
		var members := full.rooms.filter(func(room: Dictionary) -> bool: return CampaignWorld.region(room.id)==region)
		var visits := members.filter(func(room: Dictionary) -> bool: return room.visited)
		check("Count follows selected region "+region, total.text.ends_with("%d/%d" % [visits.size(),members.size()]))
		await shot("map-"+region)
	check("Browsing every region leaves exploration intact",host.room_index==1 and host.visited==before_visits)
	await tap(KEY_ESCAPE)
	await tick(30)
	check("Escape restores minimap",ui.page_id.is_empty() and map.is_visible_in_tree())
	host.load_room(0)
	await tick(30)
	await tap(KEY_C)
	full = ui.body.find_child("RouteMap",true,false)
	check("Opening from the slope identifies the player and next route", full.caption.text=="外伤坡" and full.recommended_route().size()==2 and WhaleUIMapPage.snapshot(ui).hint=="前往须筛" and WhaleUIMapPage.snapshot(ui).detail.is_empty())
	await shot("05-slope-overview")
	var original_size := root.size
	root.size = Vector2i(900,506)
	await tick(20)
	check("Small window keeps route and return control in view", not WhaleUIMapPage.snapshot(ui).needs_scroll and ui.panel.get_global_rect().encloses(ui.body.find_child("Back",true,false).get_global_rect()))
	await shot("06-slope-small")
	root.size = original_size
	await tap(KEY_ESCAPE)
	await tick(30)
	# 跨区截图只验布局，不冒充从开局自然通关。
	for index: int in [7,9,14,18]:
		host.load_room(index)
		await tick(35)
		check("Plan follows room " + str(host.room.id),map.room_size==host.point(host.room.size) and map.exits.size()==host.room.doors.size())
		await shot(str(host.room.id))
	# Match the reported viewpoint with a partial exploration record.
	host.visited = {"R1-01":true,"R1-02":true,"R1-03":true,"R1-04":true,"R1-05":true,"R3-01":true,"R2-01":true,"R2-03":true,"R2-04":true}
	host.defeated = {"R1-04:0":true,"R2-04:0":true}
	host.abilities["pressure"] = true
	host.abilities["dash"] = true
	host.load_room(11)
	await tick(35)
	await tap(KEY_C)
	full = ui.body.find_child("RouteMap",true,false)
	check("Combination gate reopens on all rooms with the next route",full.page=="world" and full.buttons.size()==19 and WhaleUIMapPage.snapshot(ui).hint=="前往上锚路线" and full.recommended_route().size()==2)
	await shot("04-combination-gate")
	await tap(KEY_ESCAPE)
	await tick(30)
	# An acquired-memory fixture exercises the optional reader without touching the player save.
	host.collected["R1-07"] = true
	host.load_room(6)
	await tick(30)
	await tap(KEY_C)
	full = ui.body.find_child("RouteMap",true,false)
	var read: Button = ui.body.find_child("ReadMemory",true,false)
	check("Acquired memory has an opt-in reader", read.is_visible_in_tree() and not WhaleUIMapPage.snapshot(ui).memory_visible)
	read.grab_focus()
	await tap(KEY_ENTER)
	check("Enter expands acquired memory", WhaleUIMapPage.snapshot(ui).memory_visible)
	await tap(KEY_ENTER)
	check("Enter collapses memory", not WhaleUIMapPage.snapshot(ui).memory_visible)
	full.buttons[1].grab_focus()
	check("Browsing another room clears the memory action", not read.is_visible_in_tree() and host.room_index==6)
	await tap(KEY_ESCAPE)
	print("MINIMAP_COMPLETE failed=",failures)
	await host.graceful_quit(1 if failures else 0)
