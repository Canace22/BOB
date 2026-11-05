extends SceneTree
var host: WhalebellyMain
func _initialize() -> void:call_deferred("run")
func step(n: int) -> void:
	for i: int in range(n):await physics_frame
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host;await step(35)
	host.set_process(false);host.connected_world.set_physics_process(false)
	for actor: Node in get_nodes_in_group("tide_enemies"):actor.set_physics_process(false)
	host.player.set_physics_process(false)
	var points: Array[Vector2]=[Vector2(800,550),Vector2(1900,631.847),Vector2(2860,590),Vector2(4100,626.847),Vector2(5200,680),Vector2(6284,661.847),Vector2(7350,730),Vector2(8387,722.847),Vector2(9450,750),Vector2(2123,-320),Vector2(3893,-390),Vector2(3030,-1010),Vector2(4800,-900)]
	for pass_index: int in range(2):
		host.connected_world.unified.foreground_enabled=pass_index==0
		for i: int in range(points.size()):
			host.player.position=points[i]-host.connected_world.origin
			host.camera.follow_anchor=host.player.position
			host.camera.position=host.player.position+Vector2(85,-175)
			await step(12);await process_frame;RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://build/qa/xumen-unified/"+("no-front-" if pass_index==1 else "view-")+str(i)+".png")
	print("UNIFIED_VISUAL_COMPLETE fixed coordinates; actual traversal separate")
	await host.graceful_quit()
