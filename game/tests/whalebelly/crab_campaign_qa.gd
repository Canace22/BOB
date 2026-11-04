extends SceneTree
## Isolated R1-04 encounter; keyboard-only fight after normal room spawn.
var host: WhalebellyMain

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var out := "res://build/qa/crab-campaign"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	host.capture_room = 3
	root.add_child(host)
	current_scene = host
	for i in 30: await physics_frame
	await shot(out.path_join("start.png"))
	var defeated := await CampaignCrabDriver.fight(host)
	await shot(out.path_join("after-fight.png"))
	var report := {"passed":defeated and host.abilities.dash,"health":host.health,"room":host.room.id,
		"defeated":host.defeated,"abilities":host.abilities,"events":host.events,
		"method":"Isolated room fixture, no position/HP writes after spawn; ordinary Input actions"}
	var file := FileAccess.open(out.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("CRAB_CAMPAIGN_QA ",JSON.stringify({"passed":report.passed,"health":host.health}))
	await host.graceful_quit(0 if report.passed else 1)

func shot(path: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
