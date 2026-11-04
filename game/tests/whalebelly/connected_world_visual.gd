extends SceneTree
var host: WhalebellyMain
func _initialize() -> void:call_deferred("run")
func step(n: int) -> void:
	for i: int in range(n):await physics_frame
func shot(id: String) -> void:
	await process_frame;await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://build/qa/xumen-connected/"+id+".png")
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.qa_connected=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host
	await step(30)
	# Explicit start fixture, then actual D input through new physical ground.
	host.player.position=Vector2(1500,host.ground_y(1500,660)-1)
	Input.action_press("right")
	await step(125);await shot("E01-actual-midpassage")
	await step(140);Input.action_release("right");await shot("E01-actual-arrival")
	for edge: Dictionary in host.connected_world.layout.edges:
		if not edge.id in ["E33","E35"]:continue
		var middle: Vector2=(edge.points[1]+edge.points[-2])*.5
		host.load_room(1,[middle.x-host.connected_world.layout.origins[1].x,middle.y-host.connected_world.layout.origins[1].y])
		host.player.set_physics_process(false)
		await step(80);await shot(str(edge.id)+"-shaft-layout-fixture")
		host.player.set_physics_process(true)
	var f:=FileAccess.open("res://build/qa/xumen-connected/visual.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(host.connected_world.snapshot(),"\t"));f.close()
	await host.graceful_quit(0)
