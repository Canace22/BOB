extends SceneTree
var host: WhalebellyMain
func _initialize() -> void:call_deferred("run")
func step(n: int) -> void:
	for i: int in range(n):await physics_frame
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host
	await step(40)
	host.load_room(1,[1400,715]);await step(15)
	host.player.set_physics_process(false)
	for pass_index: int in range(2):
		if pass_index==1:
			host.connected_world.e01.foreground_enabled=false
			for chunk: Node in host.connected_world.chunks.values():
				var front: Node2D=chunk.get_node_or_null("ChapterEnvironment/Foreground")
				if front!=null:front.hide()
		for x: float in [3510.0,4100.0,4650.0]:
			host.player.position=Vector2(x,626.847)-host.connected_world.origin
			host.camera.position=Vector2(x+85,451.847)-host.connected_world.origin
			host.camera.follow_anchor=host.player.position
			await step(15);await process_frame;await process_frame;RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://build/qa/xumen-transitions/E02-"+("no-front-" if pass_index==1 else "")+str(int(x))+".png")
	print("E02_VISUAL_COMPLETE fixed coordinate fixture, traversal tested separately")
	await host.graceful_quit()
