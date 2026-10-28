extends SceneTree
const PREFIX="res://assets/foreground_edges/"
var source_dir:String
var repo:String
var masks:Array[Image]=[]
var union_mask:Image
var manifest:Array=[]
func read_image(path:String,resize:bool=false)->Image:
	var im=Image.load_from_file(path);im.convert(Image.FORMAT_RGBA8)
	if resize:im.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	return im
func save(im:Image,id:String)->void:
	for folder in [source_dir+"master/",repo+"assets/runtime/xumen-foreground-edges/",ProjectSettings.globalize_path(PREFIX)]:
		im.save_png(folder+id+".png")
func alpha_at(im:Image,x:int,y:int)->float:
	return im.get_pixel(clampi(x,0,1279),clampi(y,0,719)).a
func _initialize()->void:run.call_deferred()
func run()->void:
	repo=ProjectSettings.globalize_path("res://../../");source_dir=repo+"assets/source/xumen-foreground-edges/"
	DirAccess.make_dir_recursive_absolute(PREFIX)
	DirAccess.make_dir_recursive_absolute(repo+"assets/runtime/xumen-foreground-edges")
	var original=read_image(repo+"assets/source/xumen-reference-environment/original/reference.png",true)
	var fill=read_image(source_dir+"generated/corner-backing.png",true)
	var bottom=read_image(ProjectSettings.globalize_path("res://assets/motion_elements/FRONT-CONTINUOUS.png"))
	var padded=Image.create(1344,784,false,Image.FORMAT_RGBA8)
	for y in 784:
		for x in 1344:padded.set_pixel(x,y,bottom.get_pixel(clampi(x-32,0,1279),clampi(y-32,0,719)))
	save(padded,"FRONT-BOTTOM-PAD")
	for file in ["top-left-mask.svg","bottom-right-mask.svg"]:
		var raw=Image.new();raw.load_svg_from_string(FileAccess.get_file_as_string(source_dir+"master/"+file));raw.convert(Image.FORMAT_RGBA8)
		var mask=raw.duplicate()
		for y in 720:
			for x in 1280:
				var a=0.0
				for dy in [-2,0,2]:
					for dx in [-2,0,2]:a+=alpha_at(raw,x+dx,y+dy)/9.0
				mask.set_pixel(x,y,Color(1,1,1,a))
		masks.append(mask)
	union_mask=Image.create(1280,720,false,Image.FORMAT_RGBA8)
	for y in 720:
		for x in 1280:union_mask.set_pixel(x,y,Color(1,1,1,maxf(masks[0].get_pixel(x,y).a,masks[1].get_pixel(x,y).a)))
	var jobs=[["FRONT-TOP-LEFT",Rect2i(-32,-32,336,336)],["FRONT-BOTTOM-RIGHT",Rect2i(1060,394,252,358)]]
	for i in jobs.size():
		var rect:Rect2i=jobs[i][1];var piece=Image.create(rect.size.x,rect.size.y,false,Image.FORMAT_RGBA8)
		for y in rect.size.y:
			for x in rect.size.x:
				var p=Vector2i(clampi(x+rect.position.x,0,1279),clampi(y+rect.position.y,0,719))
				var c=original.get_pixelv(p);c.a=masks[i].get_pixelv(p).a;piece.set_pixel(x,y,c)
		save(piece,jobs[i][0])
		manifest.append({"id":jobs[i][0],"position":[rect.position.x,rect.position.y],"size":[rect.size.x,rect.size.y],"layer":51,"parallax_amount":-0.14,"edge_padding":32})
	var backing=fill.duplicate()
	for y in 720:
		for x in 1280:
			var a=0.0
			for dy in [-24,-12,0,12,24]:
				for dx in [-24,-12,0,12,24]:a=maxf(a,alpha_at(union_mask,x+dx,y+dy))
			var c=backing.get_pixel(x,y);c.a=a;backing.set_pixel(x,y,c)
	save(backing,"CORNER-BACKING")
	save(union_mask,"CORNER-MASK")
	# The source list is captured once before integration; reruns never re-cut an already cut asset.
	var mapping_path=source_dir+"source-sprites.json"
	var mappings:Array=[]
	if FileAccess.file_exists(mapping_path):mappings=JSON.parse_string(FileAccess.get_file_as_string(mapping_path))
	else:
		var scene=load("res://scenes/environment/xumen_reference.tscn").instantiate()
		for node in scene.get_children():
			if node is Sprite2D and node.get_script()==null and node.texture!=null:
				mappings.append({"id":str(node.name),"path":node.texture.resource_path,"position":[node.position.x,node.position.y]})
		scene.free()
		FileAccess.open(mapping_path,FileAccess.WRITE).store_string(JSON.stringify(mappings,"\t"))
	var cleaned:Array=[]
	for entry in mappings:
		var im=read_image(ProjectSettings.globalize_path(entry.path));var removed=0
		for y in im.get_height():
			for x in im.get_width():
				var px=x+int(entry.position[0]);var py=y+int(entry.position[1])
				if px<0 or px>=1280 or py<0 or py>=720:continue
				var a=union_mask.get_pixel(px,py).a;var c=im.get_pixel(x,y)
				if a>0 and c.a>0:
					c.a*=1.0-a;im.set_pixel(x,y,c);removed+=1
		if removed>0:
			var id="CLEAN-"+str(entry.id);save(im,id)
			cleaned.append({"node":entry.id,"source":entry.path,"path":PREFIX+id+".png","removed_pixels":removed})
	FileAccess.open(source_dir+"manifest.json",FileAccess.WRITE).store_string(JSON.stringify({"foreground":manifest,"cleaned_static_layers":cleaned,"backing_layer":-1,"scope":"two corner mattes; bottom foreground unchanged"},"\t"))
	print("FOREGROUND_EDGES_EXPORTED ",manifest.size()," clean static layers ",cleaned.size())
	quit()
