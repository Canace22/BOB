extends SceneTree
var host: WhalebellyMain
var edge: String="E33"
func _initialize() -> void:call_deferred("run")
func step(n: int) -> void:
	for i: int in range(n):await physics_frame
func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--edge="):edge=arg.trim_prefix("--edge=")
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host;await step(35)
	host.abilities["float" if edge=="E33" else "anchor"]=true
	host.load_room(1,[150,188]);await step(5);host.player.set_physics_process(false)
	var axis: float=2123 if edge=="E33" else 3893
	var bottom: float=103.847 if edge=="E33" else 190.847
	var rise: float=785 if edge=="E33" else 1102
	for pass_index: int in range(2):
		if pass_index==1:
			host.connected_world.e01.foreground_enabled=false
			for chunk: Node in host.connected_world.chunks.values():
				var front: Node2D=chunk.get_node_or_null("ChapterEnvironment/Foreground")
				if front!=null:front.hide()
		for i: int in range(3):
			var at:=Vector2(axis,bottom-rise*.5*i)
			host.player.position=at-host.connected_world.origin
			host.camera.position=at+Vector2(85,-175)-host.connected_world.origin
			host.camera.follow_anchor=host.player.position
			await step(15);await process_frame;await process_frame;RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://build/qa/xumen-transitions/"+edge+"-"+("no-front-" if pass_index==1 else "")+str(i)+".png")
	print(edge,"_VISUAL_COMPLETE coordinate fixture, not traversal")
	await host.graceful_quit()
