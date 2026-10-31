extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var game: Node2D=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	# Normal boot path above; isolate the event log before injecting window close.
	game.qa=true
	for frame: int in range(90): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidence/normal-window-startup.png")
	print("NORMAL_BOOT ready=",is_instance_valid(game.player)," room=",game.room.id," grounded=",game.player.is_on_floor())
	game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
