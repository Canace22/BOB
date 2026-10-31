extends SceneTree
var spec: Dictionary
var manifest: Array=[]
var viewport: SubViewport
var root_canvas: Node2D
func _initialize() -> void: run.call_deferred()
func texture_file(path: String) -> ImageTexture:
	var im: Image=Image.load_from_file(path)
	im.convert(Image.FORMAT_RGBA8)
	im.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(im)
func frame() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()
func retain_attached_curtain(im: Image) -> Image:
	# Disconnected bright bubbles/fish are not part of ceiling curtains.
	var pixels: PackedByteArray=im.get_data()
	var visited: PackedByteArray=PackedByteArray()
	visited.resize(1280*720)
	var queue: PackedInt32Array=PackedInt32Array()
	for y: int in range(70):
		for x: int in range(1280):
			var i: int=y*1280+x
			if pixels[i*4+3]>12:
				visited[i]=1
				queue.append(i)
	var head: int=0
	while head<queue.size():
		var i: int=queue[head];head+=1
		for d: int in [-1281,-1280,-1279,-1,1,1279,1280,1281]:
			var n: int=i+d
			if n<0 or n>=1280*720 or absi(n%1280-i%1280)>1:continue
			if visited[n]==0 and pixels[n*4+3]>12:
				visited[n]=1;queue.append(n)
	for i: int in range(1280*720):
		if visited[i]==0:pixels[i*4+3]=0
	return Image.create_from_data(1280,720,false,Image.FORMAT_RGBA8,pixels)
func save_asset(id: String, full: Image, job: Dictionary) -> void:
	var bounds: Rect2i=full.get_used_rect()
	if bounds.size.x==0 or bounds.size.y==0:
		push_error("Empty extraction: "+id)
		return
	bounds=bounds.grow(4).intersection(Rect2i(0,0,1280,720))
	var part: Image=full.get_region(bounds)
	var path: String=str(spec.runtime)+"/"+id+".png"
	part.save_png(path)
	part.save_png(str(spec.project_runtime)+"/"+id+".png")
	var entry: Dictionary=job.duplicate(true)
	entry.path=id+".png"
	entry.source_rect=[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y]
	entry.alpha=true
	manifest.append(entry)
func run() -> void:
	spec=JSON.parse_string(FileAccess.get_file_as_string("res://tools/reference_environment/build-spec.json"))
	DirAccess.make_dir_recursive_absolute(str(spec.runtime))
	DirAccess.make_dir_recursive_absolute(str(spec.project_runtime))
	var original: ImageTexture=texture_file(str(spec.source))
	var clean: ImageTexture=texture_file(str(spec.clean))
	var underpaint: ImageTexture=texture_file(str(spec.underpaint))
	var extract: Shader=load("res://tools/reference_environment/extract.gdshader")
	viewport=SubViewport.new()
	viewport.size=Vector2i(1280,720)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	root_canvas=Node2D.new();viewport.add_child(root_canvas)
	var sprite: Sprite2D=Sprite2D.new();sprite.centered=false;root_canvas.add_child(sprite)
	var material: ShaderMaterial=ShaderMaterial.new();material.shader=extract;sprite.material=material
	var full_images: Array[Image]=[]
	var backing_mat: ShaderMaterial=ShaderMaterial.new()
	backing_mat.shader=load("res://tools/reference_environment/backing.gdshader")
	backing_mat.set_shader_parameter("backing",texture_file(str(spec.backing)))
	sprite.material=backing_mat;sprite.texture=clean
	clean=ImageTexture.create_from_image(await frame())
	sprite.material=material
	# Make a foliage matte first. Patch the tiny hidden strips behind moving
	# foliage, rather than leaving a second baked copy in road/decor/background.
	var foliage: Image=Image.create(1280,720,false,Image.FORMAT_RGBA8)
	for job: Dictionary in spec.jobs:
		if not str(job.id).begins_with("PLANT") and not str(job.id).begins_with("VINE"): continue
		var mask: Image=Image.new()
		mask.load_svg_from_string(FileAccess.get_file_as_string(str(job.mask)))
		material.set_shader_parameter("selection",ImageTexture.create_from_image(mask))
		material.set_shader_parameter("mode",3)
		sprite.texture=original
		var im: Image=await frame()
		foliage.blend_rect(im,Rect2i(0,0,1280,720),Vector2i.ZERO)
	var repair_material: ShaderMaterial=ShaderMaterial.new()
	repair_material.shader=load("res://tools/reference_environment/repair.gdshader")
	repair_material.set_shader_parameter("moving_mask",ImageTexture.create_from_image(foliage))
	sprite.material=repair_material
	sprite.texture=original
	var repaired_original: ImageTexture=ImageTexture.create_from_image(await frame())
	sprite.texture=clean
	var repaired_clean: ImageTexture=ImageTexture.create_from_image(await frame())
	sprite.material=material
	for job: Dictionary in spec.jobs:
		var mask: Image=Image.new()
		mask.load_svg_from_string(FileAccess.get_file_as_string(str(job.mask)))
		var mode: int=0
		if job.mode=="warm":mode=1
		if job.mode=="fish":mode=2
		if str(job.id).begins_with("PLANT") or str(job.id).begins_with("VINE"):mode=3
		if str(job.id).begins_with("BALEEN"):mode=4
		material.set_shader_parameter("selection",ImageTexture.create_from_image(mask))
		material.set_shader_parameter("mode",mode)
		var flexible: bool=str(job.id).begins_with("PLANT") or str(job.id).begins_with("VINE")
		sprite.texture=repaired_clean if job.source=="clean" else (original if flexible else repaired_original)
		var im: Image=await frame()
		if str(job.id).begins_with("BALEEN"):im=retain_attached_curtain(im)
		save_asset(str(job.id),im,job)
		if job.mode!="fish": full_images.append(im)
	# All selected layers removed from the visible blue-water plate, avoiding a
	# full-scene backdrop behind the moving components.
	sprite.visible=false
	for im: Image in full_images:
		var item: Sprite2D=Sprite2D.new();item.centered=false;item.texture=ImageTexture.create_from_image(im);root_canvas.add_child(item)
	var coverage: Image=await frame()
	for child: Node in root_canvas.get_children():
		if child!=sprite: child.queue_free()
	await process_frame
	sprite.visible=true;sprite.texture=repaired_clean
	material=ShaderMaterial.new();material.shader=load("res://tools/reference_environment/inverse.gdshader");material.set_shader_parameter("coverage",ImageTexture.create_from_image(coverage));sprite.material=material
	var depth: Image=await frame()
	save_asset("ENV-DEPTH",depth,{"id":"ENV-DEPTH","layer":-60,"motion":"static","source":"clean"})
	sprite.material=null;sprite.texture=underpaint
	var far: Image=await frame()
	save_asset("ENV-UNDERPAINT",far,{"id":"ENV-UNDERPAINT","layer":-70,"motion":"static","source":"generated_hidden_fill"})
	# One real painted bubble from this turn's reference, isolated without
	# inventing a procedural ring texture.
	var bubble: Image=original.get_image().get_region(Rect2i(883,232,12,12))
	for y: int in range(12):
		for x: int in range(12):
			var c: Color=bubble.get_pixel(x,y)
			var radius: float=Vector2(x-5.5,y-5.5).length()
			c.a=smoothstep(.32,.58,c.g)*(1.0-smoothstep(4.6,5.8,radius))
			bubble.set_pixel(x,y,c)
	for dir: String in [str(spec.runtime),str(spec.project_runtime)]:bubble.save_png(dir+"/bubble.png")
	manifest.append({"id":"BUBBLE-TEXTURE","path":"bubble.png","source_rect":[883,232,12,12],"layer":-20,"motion":"rise_recycle","alpha":true})
	var json_text: String=JSON.stringify({"canvas":[1280,720],"assets":manifest,"extraction":"Godot native SubViewport, SVG selections and per-family color/contrast edge isolation; original pixels retained for foreground objects."},"\t")
	FileAccess.open(str(spec.runtime)+"/manifest.json",FileAccess.WRITE).store_string(json_text)
	FileAccess.open(str(spec.project_runtime)+"/manifest.json",FileAccess.WRITE).store_string(json_text)
	print("ENVIRONMENT_ASSETS ",manifest.size())
	quit()
