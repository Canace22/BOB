extends SceneTree
## Isolated checkpoint/death fixture; door input is exercised by the Web route.
var host: Node2D
var failures: int = 0

func _initialize() -> void: run.call_deferred()

func check(label: String, ok: bool) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func run() -> void:
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await create_timer(0.3).timeout
	var fade: XumenContinuityTransition = host.continuity.transition
	check("fade covers HUD and runs while paused", fade.layer > host.player_ui.layer and fade.process_mode == Node.PROCESS_MODE_ALWAYS)
	host.checkpoint = {"room":0,"pos":[180,550]}
	host.player.health = 0
	host.health = 0
	host.ui_interactive_in_tests = true
	host.on_player_died()
	check("death menu pauses world", paused and host.player_ui.page_id == "death")
	var old_actor: int = host.player.get_instance_id()
	host.player_ui.retry()
	host.player_ui.retry()
	host.respawn()
	await create_timer(0.34, true).timeout
	check("full black before replacement", fade.active and is_equal_approx(fade.plate.modulate.a, 1.0) and host.player.get_instance_id() == old_actor)
	await create_timer(0.8, true).timeout
	check("retry finishes despite paused death screen", not fade.active and not fade.plate.visible and not host.player_ui.busy and not paused)
	check("checkpoint restores healthy unlocked actor", host.room_index == 0 and host.player.get_instance_id() != old_actor and host.player.health == 5 and not host.player.transition_locked and host.player.controls_enabled)
	var deaths: int = 0
	for event: Dictionary in host.events:
		if event.event == "player_death": deaths += 1
	check("repeat retry produces one respawn", deaths == 1)
	var initial_x: float = host.player.position.x
	Input.action_press("tp_right")
	await create_timer(0.25).timeout
	Input.action_release("tp_right")
	check("movement works after fade", host.player.position.x > initial_x + 10)
	print("SCREEN_FADE_COMPLETE failed=", failures)
	await host.graceful_quit(1 if failures else 0)
