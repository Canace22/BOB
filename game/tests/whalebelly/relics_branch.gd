extends SceneTree
## Isolated room 06 fixture with normally earned float; route and pickup use inputs.
class BranchCampaign extends WhalebellyMain:
	func save_path() -> String:
		return "user://whalebelly/relics-branch-%s.json" % str(ProjectSettings.globalize_path("res://").hash())

var host: WhalebellyMain
var failed: int = 0
func _initialize() -> void: run.call_deferred()
func verify(label: String, passed: bool) -> void:
	print("PASS " if passed else "FAIL ", label)
	if not passed: failed += 1
func run() -> void:
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(BranchCampaign)
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	host.collected = {"R1-07":true,"R1-03":true}
	host.abilities.float = true
	host.relics.refill(host.collected)
	await host.flow_setup(5)
	for target: Vector2 in [Vector2(350,560),Vector2(490,643),Vector2(550,420),Vector2(760,482),Vector2(850,270),Vector2(1173,332)]:
		var result: Dictionary = await host.drive_to(target,750)
		verify("climb to " + str(target), result.pass)
	await create_timer(0.8).timeout
	print("INTERACT position=",host.player.position," state=",host.player.state," nearby=",host.player.interaction_nearby())
	await host.input_tap("interact")
	await create_timer(0.7).timeout
	verify("fragment adds third shield point", host.collected.get("R1-06",false) and host.relics.charges == 3 and not host.practice)
	await create_timer(0.8).timeout
	print("INTERACT position=",host.player.position," state=",host.player.state," nearby=",host.player.interaction_nearby())
	await host.input_tap("interact")
	await create_timer(0.7).timeout
	verify("duplicate pickup leaves capacity unchanged", CampaignRelics.capacity(host.collected) == 3)
	for target: Vector2 in [Vector2(850,332),Vector2(760,482),Vector2(490,643),Vector2(190,790),Vector2(100,795)]:
		await host.drive_to(target,750)
	await create_timer(0.8).timeout
	print("INTERACT position=",host.player.position," state=",host.player.state," nearby=",host.player.interaction_nearby())
	await host.input_tap("interact")
	await create_timer(0.7).timeout
	await create_timer(1).timeout
	verify("return from optional branch keeps all three points", host.room_index == 1 and host.relics.charges == 3)
	print("RELICS_BRANCH_COMPLETE failed=",failed)
	await host.graceful_quit(1 if failed else 0)
