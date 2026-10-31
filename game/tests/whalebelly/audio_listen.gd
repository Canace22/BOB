@warning_ignore_start("untyped_declaration")
extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var host: Node2D=load("res://content/whalebelly/main.tscn").instantiate()
	root.add_child(host)
	host.qa=true
	host.load_room(0)
	host.status.text="声音试听：水流环境底音"
	await create_timer(2.0).timeout
	for id: String in ["jump","jump","jump","dash","strike","strike","hit","hurt","slam","collect","save"]:
		host.status.text="声音试听："+id+"（间隔播放）"
		host.sfx(id)
		await create_timer(1.2).timeout
	host.status.text="声音试听结束"
	await create_timer(1.0).timeout
	print("AUDIO_LISTEN_COMPLETE driver=",AudioServer.get_driver_name())
	await host.graceful_quit()
