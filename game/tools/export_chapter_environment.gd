extends SceneTree
## Deterministic pixel extraction from existing art and editable SVG selections.
var viewport: SubViewport
var canvas: Node2D
var spec: Dictionary
var repo: String
var room_data: Array

func _initialize() -> void:
	run.call_deferred()

func render_node(node: CanvasItem) -> Image:
	canvas.add_child(node)
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image()
	canvas.remove_child(node)
	node.free()
	return result

func save_image(image: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)

func padded(image: Image) -> Image:
	image.convert(Image.FORMAT_RGBA8)
	var pad := 16
	var size := image.get_size()
	var result := Image.create(size.x+pad*2,size.y+pad*2,false,Image.FORMAT_RGBA8)
	result.blit_rect(image,Rect2i(Vector2i.ZERO,size),Vector2i(pad,pad))
	for y in result.get_height():
		for x in result.get_width():
			if x>=pad and x<size.x+pad and y>=pad and y<size.y+pad: continue
			result.set_pixel(x,y,image.get_pixel(clampi(x-pad,0,size.x-1),clampi(y-pad,0,size.y-1)))
	return result

func attachment_y(element: Dictionary, x: float) -> float:
	var curve: Array = element.get("attachment_curve",[])
	if curve.is_empty(): return float(element.rect[1])
	for i in range(curve.size()-1):
		if x <= float(curve[i+1][0]):
			var weight := clampf((x-float(curve[i][0]))/maxf(1,float(curve[i+1][0])-float(curve[i][0])),0,1)
			return lerpf(float(curve[i][1]),float(curve[i+1][1]),weight)
	return float(curve[-1][1])

func run() -> void:
	repo = ProjectSettings.globalize_path("res://..").simplify_path()
	spec = JSON.parse_string(FileAccess.get_file_as_string(repo.path_join("assets/source/r1-chapter-scenes/chapter.json")))
	room_data = JSON.parse_string(FileAccess.get_file_as_string("res://art/whalebelly/rooms.json"))
	viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	canvas = Node2D.new()
	viewport.add_child(canvas)
	for room: Dictionary in spec.rooms:
		if OS.get_cmdline_user_args().size() > 0 and room.id not in OS.get_cmdline_user_args():
			continue
		await export_room(room)
	quit()

func export_room(room: Dictionary) -> void:
	var dimensions := Vector2i(int(room.size[0]), int(room.size[1]))
	viewport.size = dimensions
	var original := (load(room.original_scene) as PackedScene).instantiate()
	var clean := Image.load_from_file(ProjectSettings.globalize_path(room.source_clean))
	var repaired_path := repo.path_join(room.clean_file)
	if not FileAccess.file_exists(repaired_path):
		push_error("Missing repaired cleanup plate: " + repaired_path)
		original.free()
		return
	var repaired := Image.load_from_file(repaired_path)
	repaired.resize(dimensions.x, dimensions.y, Image.INTERPOLATE_LANCZOS)
	var repaired_texture := ImageTexture.create_from_image(repaired)
	var old_shader := FileAccess.get_file_as_string("res://src/campaign/layer.gdshader")
	var replacement := Shader.new()
	replacement.code = old_shader.replace("uniform sampler2D classes", "uniform sampler2D repaired_background;\nuniform sampler2D classes").replace("COLOR=vec4(c.rgb,c.a*float(k==layer_id));", "if(k==0)c=texture(repaired_background,uv); COLOR=vec4(c.rgb,c.a*float(k==layer_id));")
	var layers: Dictionary = {}
	for layer: String in ["Far", "Middle", "World", "Foreground"]:
		var source: Sprite2D = original.get_node(layer + "/" + layer + "OriginalPixels")
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture = repaired_texture
		var material := source.material.duplicate() as ShaderMaterial
		material.shader = replacement
		material.set_shader_parameter("repaired_background", repaired_texture)
		material.set_shader_parameter("clean_plate", repaired_texture)
		sprite.material = material
		layers[layer] = await render_node(sprite)
	# Opaque underpaint keeps source-size hidden surfaces available at small offsets.
	var far := Image.load_from_file(ProjectSettings.globalize_path("res://art/whalebelly/clean/" + room.id + "-far.png"))
	var repaired_far := repo.path_join("assets/source/r1-chapter-scenes/generated/" + room.id + "-far-clean.png")
	if FileAccess.file_exists(repaired_far):
		far = Image.load_from_file(repaired_far)
		far.resize(dimensions.x, dimensions.y)
	save_image(padded(far), repo.path_join(room.runtime + "/underpaint.png"))
	var exports: Array[Dictionary] = []
	var actor_mask := Image.new()
	actor_mask.load_svg_from_string(FileAccess.get_file_as_string("res://art/whalebelly/masks/"+room.id+"-actors.svg"))
	var rings: Array = []
	for data: Dictionary in room_data:
		if data.id==room.id: rings=data.get("rings",[])
	for element: Dictionary in room.elements:
		if element.kind not in ["flex", "lamp", "water"]:
			continue
		var selection := Image.new()
		selection.load_svg_from_string(FileAccess.get_file_as_string(repo.path_join("assets/source/r1-chapter-scenes/master/" + element.mask_file)))
		var part := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
		part.fill(Color.TRANSPARENT)
		var rect := Rect2i(int(element.rect[0]), int(element.rect[1]), int(element.rect[2]), int(element.rect[3])).intersection(Rect2i(Vector2i.ZERO, dimensions))
		var owned: int = 0
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if selection.get_pixel(x,y).r < 0.5:
					continue
				var color := clean.get_pixel(x,y)
				if element.kind == "water":
					color = repaired.get_pixel(x,y)
				var selected := true
				if element.kind == "flex":
					selected = color.r > color.b * 0.92 and color.r > 0.12
					if str(element.id).contains("BALEEN") and element.status == "motion":
						selected = selected and color.g > color.r*.84 and (layers.Middle as Image).get_pixel(x,y).a > .8 and y >= attachment_y(element,x)
						var actor_pixel := actor_mask.get_pixel(x,y)
						if actor_pixel.r+actor_pixel.g+actor_pixel.b>.05: selected=false
						for ring: Array in rings:
							if pow((float(x)-float(ring[0]))/80.0,2)+pow((float(y)-float(ring[1]))/110.0,2)<1.0: selected=false
					if element.get("selector", "") == "plant":
						selected = color.g > color.r * 0.83 and color.g > color.b * 1.25 and color.r < 0.68
				if element.kind == "water":
					selected = (layers.Far as Image).get_pixel(x,y).a > 0.8 and color.b > color.r * 1.35
				if element.kind == "lamp":
					selected = color.r > color.b*1.4 and color.r > 0.3 and color.g > 0.2
				if not selected:
					continue
				# Every moving pixel has exactly one visible owner, across all four layers.
				if element.kind != "water":
					for layer: String in layers:
						(layers[layer] as Image).set_pixel(x,y,Color.TRANSPARENT)
				color.a = 1.0
				if element.kind == "water":
					var distance := minf(minf(x-rect.position.x,rect.end.x-x),minf(y-rect.position.y,rect.end.y-y))
					color = Color(1,1,1,smoothstep(0,65,distance))
				part.set_pixel(x,y,color)
				owned += 1
		var bounds := part.get_used_rect()
		if bounds.size.x == 0:
			push_error("Empty selected element: " + element.id)
			continue
		bounds = bounds.grow(12).intersection(Rect2i(Vector2i.ZERO,dimensions))
		var cropped := part.get_region(bounds)
		if element.kind == "water":
			cropped = padded(part)
			bounds = Rect2i(Vector2i(-16,-16),cropped.get_size())
		save_image(cropped, repo.path_join(room.runtime + "/" + element.id + ".png"))
		var roots: Array[float] = []
		for column in 13:
			roots.append(clampf((attachment_y(element,bounds.position.x+float(column)*bounds.size.x/12.0)-bounds.position.y)/maxf(1,bounds.size.y),0,.92))
		exports.append({"id":element.id,"origin":[bounds.position.x,bounds.position.y],"size":[bounds.size.x,bounds.size.y],"pixels":owned,"root_profile":roots})
	for layer: String in layers:
		save_image(padded(layers[layer]), repo.path_join(room.runtime + "/" + layer + ".png"))
	FileAccess.open(repo.path_join(room.master + "/export-map.json"), FileAccess.WRITE).store_string(JSON.stringify({"room":room.id,"elements":exports,"tool":"Godot native SVG masks + source-pixel extraction","source_dimensions":room.size},"\t"))
	original.free()
	print("CHAPTER_EXPORT ", room.id, " elements=", exports.size())
