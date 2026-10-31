@warning_ignore_start("untyped_declaration")
extends SceneTree
## Render the authored main-scene layout without gameplay initialization.
## This is a saved-layout render, not an editor screenshot or traversal test.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var scene: Node2D=load("res://content/whalebelly/main.tscn").instantiate()
	scene.set_script(null)
	var room: Node2D=scene.get_node("LevelMap")
	var environment: Node2D=room.get_node("ReferenceEnvironment")
	environment.set_script(null)
	var source: Node2D=load("res://content/whalebelly/environment/xumen_reference.tscn").instantiate()
	var mismatches: Array=[]
	for child in source.get_children():
		if not child is Sprite2D or child.name=="CHARACTER": continue
		var applied: Sprite2D=environment.get_node(str(child.name))
		if child.texture!=applied.texture or child.transform!=applied.transform or child.z_index!=applied.z_index:
			mismatches.append(str(child.name))
	var report={"main_room":room.scene_file_path,"environment_source":environment.scene_file_path,"image_transform_mismatches":mismatches,"display_character_hidden":not environment.get_node("CHARACTER").visible,"preview_player_present":room.has_node("World/PlayerArt/OriginalSilhouette")}
	source.free()
	scene.scale=Vector2.ONE*(1280.0/1671.0)
	root.add_child(scene)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/qa/whalebelly/evidence/main_scene_sync/authored-main-layout.png")
	FileAccess.open("res://build/qa/whalebelly/evidence/main_scene_sync/source-binding.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if mismatches.is_empty() and report.display_character_hidden else 1)
