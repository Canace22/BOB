extends SceneTree
const OUT="res://evidence/soft_light/"
func _initialize() -> void: run.call_deferred()
func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
func run() -> void:
	var scene=load("res://scenes/environment/xumen_reference.tscn").instantiate()
	root.add_child(scene);scene.set_process(false);scene.level_mode=true
	var camera=Camera2D.new();root.add_child(camera);camera.zoom=Vector2.ONE*1.28
	for side in [-1,0,1]:
		camera.position=Vector2(640+side*128,310)
		scene.level_camera_offset=Vector2(side*128,0);scene.update_visuals()
		for id in ["BEAM-01","BEAM-02","BEAM-03"]:scene.get_node(id).visible=true
		await shot("before_%s"%side)
		for id in ["BEAM-01","BEAM-02","BEAM-03"]:scene.get_node(id).visible=false
		await shot("old_beams_hidden_%s"%side)
	quit()
