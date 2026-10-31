extends SceneTree
## Native bitmap extraction. No painting is synthesized by this exporter.
var spec: Dictionary
var entries: Array = []
func _initialize() -> void: run.call_deferred()

func read_image(path: String, full: bool = false) -> Image:
	var im := Image.load_from_file(path)
	im.convert(Image.FORMAT_RGBA8)
	if full: im.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	return im

func save(im: Image, id: String) -> void:
	for folder: String in [spec.runtime, spec.project_runtime, spec.source_dir+"/master"]:
		im.save_png(folder+"/"+id+".png")
	entries.append({"id":id,"size":[im.get_width(),im.get_height()],"path":id+".png"})

func root_y(x: float) -> float:
	var points := [Vector2(0,180),Vector2(180,155),Vector2(275,104),Vector2(440,55),Vector2(595,40),Vector2(742,18),Vector2(900,0),Vector2(1040,5),Vector2(1160,65),Vector2(1280,240)]
	for i in range(points.size()-1):
		if x <= points[i+1].x: return lerpf(points[i].y,points[i+1].y,inverse_lerp(points[i].x,points[i+1].x,x))
	return 240.0

func sample(im: Image, p: Vector2) -> Color:
	var x := clampf(p.x,0,im.get_width()-1.001)
	var y := clampf(p.y,0,im.get_height()-1.001)
	var ix := int(x)
	var iy := int(y)
	return im.get_pixel(ix,iy).lerp(im.get_pixel(ix+1,iy),x-ix).lerp(im.get_pixel(ix,iy+1).lerp(im.get_pixel(ix+1,iy+1),x-ix),y-iy)

func run() -> void:
	spec=JSON.parse_string(FileAccess.get_file_as_string("res://tools/motion_elements/spec.json"))
	var original := read_image(spec.source,true)
	var fill := read_image(spec.source_dir+"/generated/foreground-backing.png",true)
	var foreground_mask := Image.new()
	foreground_mask.load_svg_from_string(FileAccess.get_file_as_string(spec.source_dir+"/master/foreground-mask.svg"))
	foreground_mask.convert(Image.FORMAT_RGBA8)
	# Add dark coral tips immediately above the traced ridge, preserving their pixels.
	for x in range(1280):
		var top := 719
		for y in range(450,720):
			if foreground_mask.get_pixel(x,y).a>0.5: top=y; break
		for y in range(maxi(450,top-32),top):
			var c := original.get_pixel(x,y)
			var a := (1.0-smoothstep(0.065,0.18,maxf(c.r,maxf(c.g,c.b))))*smoothstep(float(top-32),float(top-9),float(y))
			foreground_mask.set_pixel(x,y,Color(1,1,1,a))
	var front: Image = original.duplicate()
	var behind: Image = fill.duplicate()
	for y in range(720):
		for x in range(1280):
			var a := foreground_mask.get_pixel(x,y).a
			var c := front.get_pixel(x,y); c.a=a; front.set_pixel(x,y,c)
			# Only reveal the new paint underneath the foreground's swept area.
			# A broad bottom overlay would replace visible midground and make seams.
			var cover := 0.0
			for dx in [-20,0,20]:
				for dy in [-7,0,7]:
					cover=maxf(cover,foreground_mask.get_pixel(clampi(x+dx,0,1279),clampi(y+dy,0,719)).a)
			c=behind.get_pixel(x,y);c.a=cover;behind.set_pixel(x,y,c)
	save(front,"FRONT-CONTINUOUS")
	save(behind,"FOREGROUND-BACKING")
	# Remove foreground from each old plate that could leave a duplicate when panning.
	for job: Dictionary in spec.assets:
		var id := str(job.id)
		if id.begins_with("FRONT") or id.begins_with("FISH") or id=="BUBBLE-TEXTURE": continue
		var im := read_image(spec.old+"/"+str(job.path))
		var origin := Vector2i(job.source_rect[0],job.source_rect[1])
		for y in range(im.get_height()):
			for x in range(im.get_width()):
				var p := origin+Vector2i(x,y)
				if p.x>=1280 or p.y>=720: continue
				var c := im.get_pixel(x,y)
				c.a *= 1.0-foreground_mask.get_pixelv(p).a
				im.set_pixel(x,y,c)
		if id.begins_with("BALEEN"):
			var rigid: Image = im.duplicate()
			for y in range(im.get_height()):
				for x in range(im.get_width()):
					var p := origin+Vector2i(x,y)
					var c := im.get_pixel(x,y)
					# Roots and architecture remain a separate stationary piece.
					var flex := smoothstep(root_y(p.x)+8.0,root_y(p.x)+18.0,float(p.y))
					flex*=smoothstep(268.0,290.0,float(p.x))*(1.0-smoothstep(1160.0,1180.0,float(p.x)))
					var r := c; r.a*=1.0-flex;rigid.set_pixel(x,y,r)
					c.a*=flex;im.set_pixel(x,y,c)
			var rigid_pad := Image.create(im.get_width()+32,im.get_height(),false,Image.FORMAT_RGBA8)
			rigid_pad.blit_rect(rigid,Rect2i(Vector2i.ZERO,rigid.get_size()),Vector2i(16,0))
			save(rigid_pad,id+"-ROOT")
			var moving_pad := Image.create(im.get_width()+32,im.get_height(),false,Image.FORMAT_RGBA8)
			moving_pad.blit_rect(im,Rect2i(Vector2i.ZERO,im.get_size()),Vector2i(16,0))
			im=moving_pad
		save(im,id)
	# Each fish keeps the corresponding painted silhouette and a transparent edge.
	for fish: Dictionary in spec.fish:
		var center := Vector2(fish.center[0],fish.center[1])
		var radius := Vector2(fish.radius[0],fish.radius[1])
		var im := Image.create(40,20,false,Image.FORMAT_RGBA8)
		var bg := original.get_pixelv(Vector2i(center+Vector2(0,-radius.y-3)))
		for y in range(20):
			for x in range(40):
				var d := Vector2(x-20,y-10)
				var c := original.get_pixelv(Vector2i(center+d))
				var contour := 1.0-smoothstep(0.85,1.18,(d/(radius+Vector2(2,1))).length())
				c.a=contour*smoothstep(0.015,0.105,bg.g-c.g)
				im.set_pixel(x,y,c)
		# Upscaled source registered once. Tail bends, head remains fixed in each frame.
		im.resize(120,60,Image.INTERPOLATE_CUBIC)
		save(im,str(fish.id)+"-source")
		var atlas := Image.create(120*12,60,false,Image.FORMAT_RGBA8)
		for frame in range(12):
			var phase := float(frame)*TAU/12.0
			for y in range(60):
				for x in range(120):
					var tail := smoothstep(0.44,0.79,float(x)/120.0)
					var p := Vector2(x,y+sin(phase)*4.0*tail)
					atlas.set_pixel(frame*120+x,y,sample(im,p))
		save(atlas,str(fish.id))
	var light := read_image(spec.source_dir+"/generated/caustic-master.png")
	light.resize(768,432,Image.INTERPOLATE_LANCZOS)
	# Retain only painted luminous ribbons; discard the generator's broad blue wash.
	for y in range(light.get_height()):
		for x in range(light.get_width()):
			var c := light.get_pixel(x,y)
			c.a*=smoothstep(0.64,0.91,c.r)*0.65
			light.set_pixel(x,y,c)
	save(light,"CAUSTIC-RIBBONS")
	FileAccess.open(spec.source_dir+"/master/export-manifest.json",FileAccess.WRITE).store_string(JSON.stringify(entries,"\t"))
	print("MOTION_ASSETS ",entries.size())
	quit()
