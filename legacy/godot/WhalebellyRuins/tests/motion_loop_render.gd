extends SceneTree
var scene: Node2D
var results: Array=[]
func _initialize() -> void: run.call_deferred()
func pixels() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	scene=load("res://scenes/environment/xumen_reference.tscn").instantiate()
	root.add_child(scene);scene.set_process(false)
	for id: String in ["BALEEN-LEFT","PLANT-02","WATER-SURFACE"]:
		var element=scene.get_node(id)
		scene.elapsed=0;scene.update_visuals()
		var before: Image=await pixels()
		element.update_at(element.period)
		var after: Image=await pixels()
		var a:=before.get_data();var b:=after.get_data()
		var maximum:=0
		for i in range(a.size()):maximum=maxi(maximum,absi(int(a[i])-int(b[i])))
		results.append({"id":id,"rendered_loop_max_channel_error":maximum,"pass":maximum<=2})
	var fish=scene.get_node("FISH-02-01")
	var wrap: float=(fish.home.x-545.0)/220.0*fish.swim_period
	fish.update_at(wrap-0.001)
	var a: float=fish.modulate.a
	fish.update_at(wrap+0.001)
	results.append({"id":"FISH-02-01","wrap_alpha_before":a,"wrap_alpha_after":fish.modulate.a,"pass":a<0.0001 and fish.modulate.a<0.0001})
	var failed=results.filter(func(r):return not r.pass)
	FileAccess.open("res://evidence/motion_elements/loop-render.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":results,"failures":failed.size(),"note":"Rendered material loop endpoints; path reset visibility. Naturalness remains a visual judgement."},"\t"))
	print("LOOP_RENDER ",JSON.stringify(results))
	quit(0 if failed.is_empty() else 1)
