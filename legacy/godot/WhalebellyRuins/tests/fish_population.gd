extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
	var host: Node2D = load("res://scripts/main.gd").new()
	root.add_child(host)
	host.qa = true
	var report: Array = []
	for index: int in range(7):
		host.load_room(index)
		for frame: int in range(5): await process_frame
		var environment: Node2D = host.scenery.get_node("EnvironmentMotion")
		var expected: int = 0 if index in [4,5] else 7
		report.append({"room":host.room.id,"expected":expected,"actual":environment.fish.size(),"pass":environment.fish.size()==expected})
	var file: FileAccess = FileAccess.open("res://evidence/fish-population.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	await host.graceful_quit()
