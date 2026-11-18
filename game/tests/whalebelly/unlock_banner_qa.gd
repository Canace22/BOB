extends SceneTree
## Real reward F input; explicit room starts/Boss defeat fixture, unique QA save.
const OUTPUT := "res://build/qa/unlock-banner"
var host: WhalebellyMain
var ui: WhaleCampaignUI
var checks: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void: run.call_deferred()
func step(count: int = 4) -> void:
	for frame: int in count: await process_frame
func tap(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await step(3)
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	if not passed: failures += 1
	print(("PASS " if passed else "FAIL ") + label)
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(OUTPUT.path_join(label + ".png"))
func fits(banner: WhaleUnlockBanner) -> bool:
	return banner.card_rect.encloses(Rect2(banner.detail.position,banner.detail.size)) and banner.card_rect.position.x >= 526 and banner.card_rect.end.x <= ui.hud.size.x - 306 and banner.card_rect.size.y <= 72 and banner.card_rect.end.y <= 100

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite", "unlock-banner")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	ui = host.player_ui as WhaleCampaignUI
	ui.preferences.reduce_motion = false
	ui.preferences.contrast = false
	await step(60)
	var banner: WhaleUnlockBanner = ui.hud.unlock_banner
	check("Startup does not announce existing progress",banner.current.is_empty() and banner.pending.is_empty() and not banner.visible)
	await host.flow_setup(6,host.rooms[6].reward)
	await tap(KEY_F)
	await step(55)
	check("Real memory pickup announces float and its current key",host.abilities.get("float",false) and host.collected.get("R1-07",false) and banner.current.get("id", "") == "float" and banner.detail.text.contains(WhaleUIStyle.key("float")) and fits(banner))
	check("Unlock presentation keeps control and focus",not paused and host.player.controls_enabled and root.gui_get_focus_owner() == null)
	await shot("01-float")
	var before_move: Vector2 = host.player.position
	var move := InputEventKey.new()
	move.physical_keycode = KEY_D
	move.keycode = KEY_D
	move.pressed = true
	Input.parse_input_event(move)
	await step(12)
	move = move.duplicate() as InputEventKey
	move.pressed = false
	Input.parse_input_event(move)
	await tap(KEY_J)
	check("Movement and attack remain responsive during announcement",host.player.position.x > before_move.x + 10 and (host.player.state == "strike_01" or host.player.skill_controller.active) and not paused)
	await tap(KEY_ESCAPE)
	var age_before: float = banner.age
	await step(35)
	check("Pause preserves reading time and hides banner",ui.page_id == "pause" and not banner.is_visible_in_tree() and is_equal_approx(banner.age,age_before))
	await tap(KEY_ESCAPE)
	await step(30)
	check("Resume continues same announcement",banner.is_visible_in_tree() and banner.current.get("id", "") == "float" and banner.age > age_before)
	await tap(KEY_F)
	await step(45)
	check("Repeated pickup does not queue duplicate unlock",banner.pending.is_empty())
	# A controlled Boss defeat exercises the production award path, not combat difficulty.
	await host.flow_setup(3)
	var boss: Dictionary = ui.data.boss()
	check("Boss award fixture exists",not boss.is_empty())
	if not boss.is_empty(): host.damage_enemy(boss,int(boss.hp))
	await step(5)
	check("Boss award queues behind readable current banner",host.abilities.get("dash",false) and (banner.current.get("id", "") == "dash" or banner.pending.any(func(card: Dictionary) -> bool: return card.id == "dash")))
	for frame: int in 600:
		if banner.current.get("id", "") == "dash": break
		await step(1)
	await step(24)
	check("Dash banner keeps only essential control in HUD safe area",banner.current.get("id", "") == "dash" and banner.detail.text.contains(WhaleUIStyle.key("tp_dash")) and fits(banner))
	await shot("02-dash")
	await tap(KEY_H)
	var help_text: String = ""
	for label: Label in ui.body.find_children("*", "Label", true, false): help_text += label.text + "\n"
	check("H reopens full acquired ability instructions",ui.page_id == "help" and help_text.contains("五段连斩") and help_text.contains("空中按住") and help_text.contains("贴流冲"))
	await shot("02-help-details")
	await tap(KEY_ESCAPE)
	await step(20)
	banner.clear()
	await host.flow_setup(2,host.rooms[2].reward)
	await tap(KEY_F)
	await step(55)
	check("Relic pickup announces shield and unlocked spells",host.collected.get("R1-03",false) and host.player.skill_unlocked("R1-03") and banner.current.get("id", "") == "R1-03" and banner.detail.text.contains("上涌") and banner.detail.text.contains("下潜") and fits(banner))
	await shot("03-relic-spells")
	ui.preferences.reduce_motion = true
	ui.preferences.contrast = true
	await step(8)
	var stationary: Rect2 = banner.card_rect
	await step(18)
	check("Reduced motion holds banner; high contrast is opaque",banner.card_rect == stationary and banner.style.bg_color.a == 1.0 and is_equal_approx(banner.modulate.a,1.0))
	# Save/load must not announce old unlocks again.
	banner.clear()
	host.save_progress(false)
	host.load_progress()
	host.load_room(host.room_index)
	await step(45)
	check("Reload restores progress without replaying unlocks",host.abilities.get("float",false) and host.abilities.get("dash",false) and banner.current.is_empty() and banner.pending.is_empty())
	# Explicit event fixtures for later gates and multiple rewards in one frame.
	for id: String in ["pressure", "bone", "silence"]: host.record_event("ability_unlocked", {"id":id})
	await step(20)
	check("Multiple unlocks are queued without replacing each other",banner.current.get("id", "") == "pressure" and banner.pending.size() == 2 and fits(banner))
	await shot("04-progression")
	# Explicit overlap fixture for camera modes where the actor can reach the HUD.
	var before_overlap: Vector2 = host.player.global_position
	host.player.set_physics_process(false)
	host.camera.enabled = false
	await step(2)
	host.player.global_position = host.player.get_canvas_transform().affine_inverse() * (banner.card_rect.get_center() + Vector2(0,80))
	await step(18)
	check("Announcement fades when it would cover the actor",banner.clearance_alpha <= 0.2 and banner.modulate.a <= 0.2)
	host.player.global_position = before_overlap
	host.camera.enabled = true
	host.player.set_physics_process(true)
	await step(15)
	check("Announcement recovers after actor leaves its area",banner.clearance_alpha >= 0.95)
	ui.start_game(true)
	await step(40)
	check("New journey clears previous banners and queue",host.collected.is_empty() and banner.current.is_empty() and banner.pending.is_empty())
	var file := FileAccess.open(OUTPUT.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"fixtures":"Explicit reward-room starts, real F pickup, controlled Boss defeat; later gate events are explicit display fixtures."},"\t"))
	await host.graceful_quit(1 if failures > 0 else 0)
