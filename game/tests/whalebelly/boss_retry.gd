extends SceneTree
## Boss/checkpoint fixtures use QA storage; keyboard events drive retry.
var host: Node2D
var failures: int = 0
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func tap(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = code
	Input.parse_input_event(event)
func run() -> void:
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.integration_external_test = true
	host.ui_interactive_in_tests = true
	root.add_child(host)
	current_scene = host
	host.checkpoint = {"room":0,"pos":[180,550]}
	host.load_room(3)
	await create_timer(0.3).timeout
	host.enemies[0].hp = 150 # Damaged Boss fixture must reset on retry.
	host.player.take_damage(5, Vector2.ZERO, true)
	await create_timer(3.3).timeout
	var ui: WhaleCampaignUI = host.player_ui
	check("lethal damage opens opaque black death screen", paused and ui.page_id == "death" and ui.shade.color == Color.BLACK)
	var before: Dictionary = host.checkpoint.duplicate(true)
	var clock_before: float = host.clock
	await tap(KEY_ESCAPE)
	await create_timer(0.2).timeout
	check("death cannot resume combat via Escape", paused and ui.page_id == "death" and host.clock == clock_before)
	await tap(KEY_R)
	await tap(KEY_R)
	await create_timer(1.2).timeout
	var boss: Dictionary = ui.data.boss()
	check("R restarts same Boss room with full health", host.room_index == 3 and host.health == 5 and host.player_soul == 99 and not boss.is_empty() and boss.hp == boss.max_hp)
	check("retry keeps checkpoint and restores control", host.checkpoint == before and not paused and not ui.busy and host.player.controls_enabled)
	host.player.take_damage(5, Vector2.ZERO, true)
	await create_timer(3.3).timeout
	ui.retry(true)
	await create_timer(1.2).timeout
	check("second death can return to original checkpoint", host.room_index == 0 and host.health == 5 and not paused and ui.page_id.is_empty())
	print("BOSS_RETRY_COMPLETE failed=", failures)
	await host.graceful_quit(1 if failures else 0)
