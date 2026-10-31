@warning_ignore_start("untyped_declaration")
extends SceneTree
func _initialize()->void:run.call_deferred()
func shot(name:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/qa/whalebelly/evidence/underbridge/"+name+".png")
func run()->void:
	var scene=load("res://content/whalebelly/environment/xumen_reference.tscn").instantiate();root.add_child(scene);scene.set_process(false)
	# Pin the pre-repair baseline even after the shared scene has been updated.
	scene.get_node("ROAD").texture=load("res://art/whalebelly/foreground_edges/CLEAN-ROAD.png")
	scene.get_node("FOREGROUND-BACKING").texture=load("res://art/whalebelly/foreground_edges/CLEAN-FOREGROUND-BACKING.png")
	for id in ["BUBBLE-ZONE-05","BUBBLE-ZONE-06","BUBBLE-ZONE-07"]:scene.get_node(id).visible=false
	var camera=Camera2D.new();root.add_child(camera);camera.position=Vector2(640,360);camera.zoom=Vector2.ONE*1.16
	await shot("before")
	for name in ["FOREGROUND-BACKING","ENV-DEPTH","MID-01","MID-02","ROAD"]:
		scene.get_node(name).visible=false
		await shot("without_"+name)
		scene.get_node(name).visible=true
	quit()
