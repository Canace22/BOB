extends SceneTree
## Production streaming scene; isolated save/settings and real keyboard input.
const OUTPUT := "res://build/qa/interaction-prompt"
var host: WhalebellyMain
var ui: WhaleCampaignUI
var checks: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void: run.call_deferred()

func step(count: int = 4) -> void:
	for frame: int in count: await process_frame

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code, true)
	await step(2)
	key(code, false)
	await step(8)

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	if not passed: failures += 1
	print(("PASS " if passed else "FAIL ") + label)

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(OUTPUT.path_join(label + ".png"))

func fits(prompt: WhaleInteractionPrompt) -> bool:
	var label_rect := Rect2(prompt.caption.position, prompt.caption.size)
	return prompt.card_rect.encloses(label_rect) and prompt.card_rect.position.x >= 24 and prompt.card_rect.end.x <= ui.hud.size.x - 24 and prompt.card_rect.end.y < ui.hud.size.y - 150

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite", "interaction-prompt")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	ui = host.player_ui as WhaleCampaignUI
	ui.preferences.path = "user://whalebelly/interaction-prompt-settings.cfg"
	ui.preferences.reduce_motion = false
	ui.preferences.contrast = false
	await step(80)
	var prompt: WhaleInteractionPrompt = ui.hud.interaction_prompt
	check("Production camp shows centered large F prompt",host.streaming.enabled and prompt.visible and prompt.message == "在营地歇息" and prompt.action_key == "F" and absf(prompt.card_rect.get_center().x - ui.hud.size.x * 0.5) < 1 and fits(prompt))
	check("Stable target finishes entrance without restarting",prompt.age > 0.4 and is_equal_approx(prompt.modulate.a,1.0))
	await shot("01-camp")
	await tap(KEY_F)
	await step(70)
	check("Displayed F opens actual camp and hides prompt",ui.page_id == "camp" and not prompt.is_visible_in_tree() and FileAccess.file_exists(host.save_path()))
	await tap(KEY_ESCAPE)
	await step(30)
	var start_x: float = host.player.position.x
	key(KEY_D, true)
	for frame: int in 100:
		if not ui.data.at_camp(): break
		await step(1)
	key(KEY_D, false)
	await step(12)
	check("Walking out of range clears prompt",host.player.position.x > start_x + 10 and not ui.data.at_camp() and not prompt.visible)
	key(KEY_A, true)
	for frame: int in 160:
		if host.player.position.x <= start_x + 25: break
		await step(1)
	key(KEY_A, false)
	await step(20)
	check("Walking back restores readable prompt",prompt.visible and prompt.message == "在营地歇息" and fits(prompt))
	await tap(KEY_ESCAPE)
	check("Pause hides interaction overlay",ui.page_id == "pause" and not prompt.is_visible_in_tree())
	await tap(KEY_ESCAPE)
	await step(25)
	# Display follows InputMap; this task does not add a rebinding interface.
	var original: Array[InputEvent] = InputMap.action_get_events("tp_interact")
	InputMap.action_erase_events("tp_interact")
	var rebound := InputEventKey.new()
	rebound.physical_keycode = KEY_Z
	InputMap.action_add_event("tp_interact", rebound)
	await step(20)
	check("Prompt reads current InputMap binding",prompt.action_key == "Z" and prompt.age > 0.18)
	InputMap.action_erase_events("tp_interact")
	for event: InputEvent in original: InputMap.action_add_event("tp_interact",event)
	await step(25)
	ui.preferences.reduce_motion = true
	ui.preferences.contrast = true
	await step(15)
	var still_rect: Rect2 = prompt.card_rect
	var still_border: Color = prompt.card_style.border_color
	await step(35)
	check("Reduce motion holds layout and glow; contrast is opaque",prompt.card_rect == still_rect and prompt.card_style.border_color == still_border and prompt.card_style.bg_color.a == 1.0 and prompt.modulate.a == 1.0)
	await shot("02-high-contrast")
	# Explicit layout fixtures, using existing in-game text; no invented content.
	ui.hud.set_process(false)
	prompt.present(CampaignGuidance.description(host, "R1-06"), "G", false)
	await step(5)
	check("Long traversal text wraps within card",fits(prompt) and prompt.caption.get_line_count() >= 2)
	await shot("03-traversal-wrap")
	prompt.present(CampaignWorld.UNBUILT, "", true)
	await step(5)
	check("Unavailable entrance does not advertise an action key",prompt.blocked and not prompt.key_label.visible and fits(prompt))
	await shot("04-blocked")
	root.size = Vector2i(960,540)
	prompt.present("牵引前方圆环 · 到环停挂 · 空格跃离", "G", false)
	await step(8)
	check("Small viewport keeps prompt above skill bar",fits(prompt))
	await shot("05-small-viewport")
	var file := FileAccess.open(OUTPUT.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"fixtures":"Real camp input and movement; traversal/blocked strings are explicit layout fixtures."},"\t"))
	ui.hud.set_process(true)
	await host.graceful_quit(1 if failures > 0 else 0)
