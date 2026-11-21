extends SceneTree
## Production camp and real keys; room, damage, ownership and save-failure fixtures.
const OUT := "res://build/qa/camp-ui"
var host: WhalebellyMain
var ui: WhaleCampaignUI
var checks: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void: run.call_deferred()

func tick(count: int = 8) -> void:
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
	await tick()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label, "pass":passed})
	if not passed: failures += 1
	print(("PASS " if passed else "FAIL ") + label)

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label + ".png"))

func visible_text() -> String:
	var text: String = ""
	for label: Label in ui.body.find_children("*", "Label", true, false): text += label.text + "\n"
	return text

func fits() -> bool:
	var scroll: ScrollContainer = ui.body.get_parent() as ScrollContainer
	var area: Rect2 = scroll.get_global_rect()
	var leave: Control = ui.body.find_child("LeaveCamp", true, false) as Control
	var details: Control = ui.body.find_child("CampDetails", true, false) as Control
	return area.encloses(leave.get_global_rect()) and area.encloses(details.get_global_rect()) and not scroll.get_v_scroll_bar().visible and ui.panel.get_global_rect().encloses(ui.margin.get_global_rect())

func rest() -> void:
	await tap(KEY_F)
	for frame: int in 120:
		if ui.page_id == "camp": break
		await tick(1)
	await tick(10)
	check("Physical F opens actual paused camp", ui.page_id == "camp" and paused)
	if ui.page_id != "camp":
		print("CAMP DIAGNOSTIC ", host.room.id, " ", host.player.position, " ", ui.data.camp_position(), " ", host.player.state)
		await shot("failed-camp")

func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(OUT)
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite", "camp-ui")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	ui = host.player_ui as WhaleCampaignUI
	ui.preferences.path = "user://whalebelly/camp-ui-settings.cfg"
	ui.preferences.contrast = false
	ui.preferences.reduce_motion = false
	await tick(85)
	host.player.health = 2
	host.health = 2
	host.player.soul = 44
	await rest()
	check("Rest heals, preserves energy and saves checkpoint", host.player.health == host.player.max_health and host.player.soul == 44 and host.last_save_ok and FileAccess.file_exists(host.save_path()))
	check("Rest page keeps mood and leaves resource numbers in details", not visible_text().contains("护盾") and not visible_text().contains(" / ") and visible_text().contains("让潮声平息"))
	if ui.page_id != "camp":
		await host.graceful_quit(1)
		return
	check("Continue is focused and both actions fit without scrolling", root.gui_get_focus_owner().name == "LeaveCamp" and fits())
	check("Only available actions are shown", not visible_text().contains("未开放") and not visible_text().contains("未收集") and ui.control_snapshot().size() == 2)
	await shot("01-first-camp")
	var saved: String = FileAccess.get_file_as_string(host.save_path())
	await tap(KEY_TAB)
	await tap(KEY_ENTER)
	check("Tab and Enter open actual resource values and rules", ui.page_id == "camp_details" and visible_text().contains("44 / 99") and visible_text().contains("通过战斗获得"))
	await tap(KEY_ESCAPE)
	check("Details return to camp and restore action focus", ui.page_id == "camp" and root.gui_get_focus_owner().name == "CampDetails")
	check("Reading details does not save or restore again", FileAccess.get_file_as_string(host.save_path()) == saved and host.player.soul == 44)
	await tap(KEY_ESCAPE)
	await tick(25)
	var before: Vector2 = host.player.position
	key(KEY_D, true)
	await tick(5)
	key(KEY_D, false)
	await tick(5)
	check("Leaving camp restores actual movement", not paused and host.player.controls_enabled and host.player.position.x > before.x + 5)
	key(KEY_A, true)
	await tick(5)
	key(KEY_A, false)
	await tick(6)
	await rest()
	check("Reentering camp defaults to continue", root.gui_get_focus_owner().name == "LeaveCamp")
	await tap(KEY_ENTER)
	await tick(25)
	check("Enter continues without an extra confirmation", ui.page_id.is_empty() and not paused)
	# Match the reported room with one owned relic. This is an explicit room fixture.
	for index: int in host.rooms.size():
		if str(host.rooms[index].id) == "R2-03": host.load_room(index)
	await tick(75)
	var camp: Array = ui.data.camp_position()
	host.player.position = host.point(camp)
	host.player.velocity = Vector2.ZERO
	host.collected["R1-03"] = true
	host.player.health = 3
	host.health = 3
	host.player.soul = 11
	host.relics.charges = 0
	await tick(10)
	await rest()
	check("Owned shield refills while energy remains unchanged", host.relics.charges == 2 and host.player.soul == 11 and visible_text().contains("生命与护盾已恢复") and fits())
	await shot("02-observation-camp")
	await tap(KEY_TAB)
	await tap(KEY_ENTER)
	check("Details show actual shield, owned relic and fall exception", visible_text().contains("护盾 2 / 2") and visible_text().contains("11 / 99") and visible_text().contains("护潮壳") and visible_text().contains("跌落不受护盾保护") and not visible_text().contains("厚壳碎片"))
	await shot("03-details")
	await tap(KEY_ENTER)
	check("Details button returns without leaving camp", ui.page_id == "camp")
	for dimensions: Vector2i in [Vector2i(960, 540), Vector2i(1280, 720)]:
		root.size = dimensions
		await tick(12)
		check("All main actions visible at " + str(dimensions), fits())
		await shot("04-size-" + str(dimensions.x))
	host.last_save_ok = false
	ui.open("camp", false)
	await tick(12)
	check("Save failure stays distinct from recovered health", visible_text().contains("生命与护盾已恢复") and visible_text().contains("进度写入失败") and not visible_text().contains("检查点已记录") and fits())
	await shot("05-save-failure-fixture")
	host.last_save_ok = true
	ui.preferences.contrast = true
	ui.preferences.reduce_motion = true
	ui.open("camp", false)
	await tick(10)
	var surface := ui.frame.get_theme_stylebox("panel") as StyleBoxFlat
	check("High contrast keeps opaque local panel and actions visible", ui.frame.visible and surface.bg_color.a == 1.0 and fits())
	await shot("06-high-contrast")
	await tap(KEY_ESCAPE)
	await tick(25)
	await tap(KEY_ESCAPE)
	check("Pause layout resets after compact camp", ui.page_id == "pause" and ui.margin.offset_left == 0 and ui.shade.offset_top == 0 and ui.ornament.visible)
	await tap(KEY_ESCAPE)
	await tick(25)
	var file := FileAccess.open(OUT.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks, "failures":failures, "fixtures":"Native production scene; physical F/Tab/Enter/Esc/A/D. Damage, energy, relic ownership, R2-03 spawn and save-result flag are explicit fixtures; separate QA save, no player save."}, "\t"))
	await host.graceful_quit(1 if failures > 0 else 0)
