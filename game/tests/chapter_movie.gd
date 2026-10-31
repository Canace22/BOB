extends SceneTree
## Environment viewing reel, explicit room previews, isolated QA state; not a playthrough.
var host: Node2D
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	host=(load("res://content/whalebelly/main.tscn") as PackedScene).instantiate()
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	for frame in 24: await process_frame
	for index in range(1,7):
		host.load_room(index)
		for frame in 144: await process_frame
	await host.graceful_quit()
