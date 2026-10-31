@warning_ignore_start("untyped_declaration")
extends SceneTree
const BASE="res://build/qa/whalebelly/evidence/reference_environment/"
var scene: Node2D
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(BASE+name+".png")
func inspect(node: Node, violations: Array) -> void:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D:
		violations.append(str(node.get_path()))
	for child in node.get_children(): inspect(child,violations)
func run() -> void:
	scene=load("res://content/whalebelly/environment/xumen_reference.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.animate_environment=false
	scene.update_visuals()
	var violations: Array=[]
	inspect(scene,violations)
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/reference_environment/manifest.json"))
	var entries: Array=[]
	for asset: Dictionary in manifest.assets:
		var im: Image=(load("res://art/whalebelly/reference_environment/"+str(asset.path)) as Texture2D).get_image()
		var bound=im.get_used_rect()
		entries.append({"id":asset.id,"loaded":not im.is_empty(),"nonempty_alpha":bound.size.x>0 and bound.size.y>0,"node_present":scene.has_node(str(asset.id)) or asset.id=="BUBBLE-TEXTURE"})
	await shot("static-final")
	# Each view is a genuine Godot render with the corresponding nodes isolated.
	for layer in ["background","structure","foliage","atmosphere","foreground","character"]:
		for node in scene.get_children():
			var id=str(node.name)
			var group="structure"
			if id.begins_with("ENV") or id.begins_with("MID"):group="background"
			if id.begins_with("BALEEN") or id.begins_with("PLANT") or id.begins_with("VINE"):group="foliage"
			if id.begins_with("BEAM") or id.begins_with("FISH") or id.begins_with("BUBBLE") or id=="LAMP":group="atmosphere"
			if id.begins_with("FRONT"):group="foreground"
			if id=="CHARACTER":group="character"
			node.visible=group==layer
		await shot("layer-"+layer)
	for node in scene.get_children():node.visible=true
	scene.animate_environment=true
	scene.camera_drift=true
	for t in [6.0,12.0,18.0,24.0]:
		scene.elapsed=t
		scene.update_visuals()
		await shot("pan-%02d"%int(t))
	var out={"assets":entries,"physics_nodes":violations,"asset_count":entries.size(),"scene_children":scene.get_child_count(),"review":"Image comparisons and layer sheets are separate visual evidence; node presence is not by itself visual acceptance."}
	FileAccess.open(BASE+"asset-audit.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print("ASSET_AUDIT assets=",entries.size()," physics=",violations.size())
	quit()
