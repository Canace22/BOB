extends SceneTree
## Production startup and real input; unique test save, no legacy import.
class MenuHost extends WhalebellyMain:
	func _init() -> void:
		integration_external_test = true
		qa_full_abilities = false
		qa_output = "res://build/qa/home-menu/events.json"
	func save_path() -> String:
		return "user://whalebelly/home-menu-%s.json" % ProjectSettings.globalize_path("res://").sha256_text().left(10)

var host: WhalebellyMain
var ui: WhaleCampaignUI
var failures: int = 0
var checks: Array[Dictionary] = []
const OUTPUT := "res://build/qa/home-menu"

func _initialize() -> void:
	run.call_deferred()

func step(count: int = 4) -> void:
	for frame: int in range(count): await process_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code,true)
	await step(2)
	key(code,false)
	await step()

func button(id: String) -> Button:
	return ui.body.find_child(id,true,false) as Button

func click(id: String) -> void:
	await step()
	var target: Button = button(id)
	assert(target != null, "Missing button: "+id)
	var point: Vector2 = target.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	for pressed: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await step(2)
	await step()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	if not passed: failures += 1
	print(("PASS " if passed else "FAIL ")+label)

func gameplay() -> void:
	for frame: int in range(180):
		if not paused and host.player.controls_enabled and ui.page_id.is_empty(): return
		await step(1)
	check("Gameplay resumes within three seconds",false)

func screenshot(id: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await step(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT.path_join(id+".png"))

func clean_save() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".before-new"]:
		if FileAccess.file_exists(host.save_path()+suffix): DirAccess.remove_absolute(host.save_path()+suffix)

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(MenuHost)
	clean_save()
	root.add_child(host)
	current_scene = host
	ui = host.player_ui as WhaleCampaignUI
	await step(20)
	check("Normal startup shows home and freezes world",ui.page_id == "title" and paused and not host.player.controls_enabled)
	check("Fresh home offers Start and disables Continue",button("Continue").disabled and button("NewGame").text == "开始旅程")
	await screenshot("01-home-new")
	await tap(KEY_ESCAPE)
	check("Escape cannot bypass home",ui.page_id == "title" and paused)
	await click("NewGame")
	await gameplay()
	var before: Vector2 = host.player.position
	key(KEY_D,true)
	await step(24)
	key(KEY_D,false)
	check("New journey accepts real movement",host.player.position.x > before.x+30)
	# Explicit permanent-progress fixture distinguishes Continue from a fresh reset.
	host.abilities.dash = true
	host.collected["R1-03"] = true
	host.defeated["R1-04:0"] = true
	host.checkpoint = {"room":1,"pos":[]}
	host.save_progress(false)
	var saved: String = FileAccess.get_file_as_string(host.save_path())
	await tap(KEY_ESCAPE)
	check("Pause offers direct Restart and Home",button("Restart").text == "重新开始" and button("Title").text == "返回首页")
	var fits: bool = true
	for control: Dictionary in ui.control_snapshot():
		fits = fits and control.y >= 0 and control.y+control.height <= ui.panel.size.y
	check("Pause controls fit 1280x720",fits)
	await screenshot("02-pause")
	before = host.player.position
	await click("Restart")
	check("Restart requires confirmation and defaults to Cancel",ui.page_id == "confirm_new" and root.gui_get_focus_owner() == button("CancelNew"))
	await screenshot("03-confirm")
	await tap(KEY_ENTER)
	check("Cancel keeps position, progress and pause",ui.page_id == "pause" and paused and host.player.position == before and FileAccess.get_file_as_string(host.save_path()) == saved)
	await click("Title")
	check("Home with save offers Continue and Restart",ui.page_id == "title" and not button("Continue").disabled and button("NewGame").text == "重新开始")
	await screenshot("04-home-saved")
	await tap(KEY_ESCAPE)
	check("Returning home clears pause history",ui.page_id == "title" and ui.history.is_empty())
	await click("Continue")
	await gameplay()
	check("Continue restores saved checkpoint and abilities",host.room_index == 1 and host.abilities.dash and host.collected.has("R1-03"))
	await tap(KEY_ESCAPE)
	await click("Restart")
	await tap(KEY_ESCAPE)
	check("Escape from confirmation restores pause focus",ui.page_id == "pause" and root.gui_get_focus_owner() == button("Restart"))
	await click("Restart")
	var before_restart: String = FileAccess.get_file_as_string(host.save_path())
	await click("ConfirmNew")
	await gameplay()
	check("Confirmed restart clears permanent progress at first room",host.room_index == 0 and not host.abilities.dash and not host.abilities.float and host.abilities.anchor and host.collected.is_empty() and host.defeated.is_empty())
	check("Restart backs up exact old save",FileAccess.get_file_as_string(host.save_path()+".before-new") == before_restart)
	before = host.player.position
	key(KEY_D,true)
	await step(24)
	key(KEY_D,false)
	await tap(KEY_SPACE)
	check("Restart restores movement and jumping",host.player.position.x > before.x+30 and not host.player.is_on_floor())
	await screenshot("05-restarted")
	# Home must also confirm when a save already exists.
	await tap(KEY_ESCAPE)
	await click("Title")
	await click("NewGame")
	check("Home restart shares confirmation",ui.page_id == "confirm_new")
	await click("CancelNew")
	check("Home cancel returns home",ui.page_id == "title")
	var report := FileAccess.open(OUTPUT.path_join("report.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Production startup; parsed keyboard/mouse input; explicit saved-progress fixture; isolated save"},"\t"))
	report.close()
	clean_save()
	await host.graceful_quit(1 if failures > 0 else 0)
