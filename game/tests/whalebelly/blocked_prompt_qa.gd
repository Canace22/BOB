extends SceneTree
## Production gates and HUD; isolated progress, approach/retreat/crossing use keys.
const OUTPUT := "res://build/qa/blocked-prompt"
var host: WhalebellyMain
var ui: WhaleCampaignUI
var checks: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void: run.call_deferred()

func step(count: int = 5) -> void:
	for frame: int in count: await physics_frame
	await process_frame

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
	await step(10)

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
	return prompt.card_rect.encloses(Rect2(prompt.caption.position,prompt.caption.size)) and (not prompt.detail.visible or prompt.card_rect.encloses(Rect2(prompt.detail.position,prompt.detail.size))) and prompt.card_rect.position.x >= 24 and prompt.card_rect.end.x <= ui.hud.size.x - 24 and prompt.card_rect.end.y <= ui.hud.size.y - 170

func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	host = load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","blocked-prompt")
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	ui = host.player_ui as WhaleCampaignUI
	ui.preferences.path = "user://whalebelly/blocked-prompt-settings.cfg"
	ui.preferences.contrast = false
	ui.preferences.reduce_motion = false
	host.load_room(7)
	await step(70)
	var gates := host.streaming.gates as CampaignStreamingGates
	var entry: Dictionary = gates.entries.filter(func(item: Dictionary) -> bool: return item.source == 7 and CampaignWorld.requirements(item.door).has("pressure"))[0]
	var foot: Vector2 = entry.body.global_position
	var prompt: WhaleInteractionPrompt = ui.hud.interaction_prompt
	host.player.global_position = foot - Vector2(260,10)
	host.player.velocity = Vector2.ZERO
	host.player.invulnerable = 100
	await step(15)
	check("Pressure gate starts out of prompt range",gates.nearby_prompt().is_empty())
	key(KEY_D,true)
	await step(85)
	key(KEY_D,false)
	await step(20)
	check("Walking into actual gate explains pressure at center",host.player.global_position.x < foot.x and prompt.visible and prompt.blocked and prompt.message == "需要潮压" and absf(prompt.card_rect.get_center().x-ui.hud.size.x*0.5)<1 and fits(prompt))
	check("Guidance points to authored pressure boss without a false action key",prompt.explanation == "前往肺心潮庭 · 击败血巢潮群" and not prompt.key_label.visible and prompt.caption.get_theme_font_size("font_size")>WhaleInteractionPrompt.FONT_SIZE)
	await shot("01-pressure-gate")
	var age: float = prompt.age
	await step(250)
	check("Reason persists at gate without replaying entrance or spamming notice",prompt.visible and prompt.age > age+3.5 and ui.notice_text != "需要潮压")
	await tap(KEY_SPACE)
	await step(10)
	check("Jumping against upper barrier retains explanation",prompt.visible and prompt.blocked and prompt.message == "需要潮压")
	await step(65)
	await tap(KEY_ESCAPE)
	check("Pause hides gate card",ui.page_id == "pause" and not prompt.is_visible_in_tree())
	await tap(KEY_ESCAPE)
	await step(20)
	key(KEY_A,true)
	await step(60)
	key(KEY_A,false)
	await step(15)
	check("Walking away clears the blocked card",gates.nearby_prompt().is_empty() and not prompt.blocked)
	key(KEY_D,true)
	await step(60)
	key(KEY_D,false)
	await step(15)
	ui.preferences.contrast = true
	ui.preferences.reduce_motion = true
	await step(15)
	var border: Color = prompt.card_style.border_color
	await step(30)
	check("Contrast and reduced motion keep an opaque stable readable card",prompt.visible and prompt.card_style.bg_color.a == 1 and prompt.card_style.border_color == border and fits(prompt))
	root.size = Vector2i(960,540)
	await step(15)
	check("Small window contains both lines above skill bar",fits(prompt) and prompt.detail.visible)
	await shot("02-small-contrast")
	root.size = Vector2i(1280,720)
	ui.preferences.contrast = false
	ui.preferences.reduce_motion = false
	# Explicit ability fixture tests gate opening, not natural acquisition.
	host.abilities["pressure"] = true
	for frame: int in 250:
		if host.streaming.is_ready(int(entry.target)): break
		await step(1)
	await step(15)
	check("Satisfied condition clears card and physical gate",not entry.blocked and entry.shape.disabled and gates.nearby_prompt().is_empty() and not prompt.blocked)
	key(KEY_D,true)
	await step(50)
	key(KEY_D,false)
	await step(10)
	check("After unlock real movement passes the same barrier",host.player.global_position.x > foot.x+35)
	await shot("03-open-gate")
	# Loading failures are explicit state fixtures on the same production gate.
	host.load_room(7)
	await step(45)
	host.player.global_position = foot - Vector2(60,10)
	host.player.velocity = Vector2.ZERO
	host.streaming.failed[int(entry.target)] = ERR_CANT_OPEN
	await step(20)
	check("Load failure uses readable card and its actual recovery instruction",prompt.blocked and prompt.message == "邻房加载失败，请返回标题后重试" and prompt.explanation.is_empty() and fits(prompt))
	await shot("04-load-failure")
	host.streaming.failed.erase(int(entry.target))
	await step(10)
	check("Recovery clears failure card without stale reason",not prompt.blocked)
	var door: Dictionary = entry.door
	entry.door = {"ability":"float"}
	await step(15)
	check("Float restriction uses same card with actual pickup direction",prompt.blocked and prompt.message == "需要浮游" and prompt.explanation == "先到鲸须记忆袋获得浮游" and fits(prompt))
	entry.door = {"locked":"qa_far_latch", "locked_message":"通路从另一侧闩着"}
	await step(15)
	check("Far side latch explains itself without ability guidance",prompt.blocked and prompt.message == "通路从另一侧闩着" and prompt.explanation.is_empty() and fits(prompt))
	var target: int = entry.target
	entry.target = -2
	await step(15)
	check("Unbuilt exit uses same readable return instruction",prompt.blocked and prompt.message == CampaignWorld.UNBUILT and fits(prompt))
	entry.target = target
	entry.door = door
	await step(15)
	check("Other requirement hints use authored sources",CampaignGuidance.requirement_hint(host,{"requires":["bone"]}).contains("断脊") and CampaignGuidance.requirement_hint(host,{"ability":"float"}).contains("鲸须记忆袋"))
	check("Inactive room gates do not explain current room",gates.entries.any(func(item: Dictionary) -> bool: return item.source != host.streaming.active and not gates.reason(item.source,item.target,item.door).is_empty()) and gates.nearby_prompt().is_empty())
	var file := FileAccess.open(OUTPUT.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"fixtures":"Hub approach starts at authored gate; keys handle approach, retreat, jump, pause and unlocked crossing. Ability and loading failure states are explicit fixtures."},"\t"))
	await host.graceful_quit(1 if failures>0 else 0)
