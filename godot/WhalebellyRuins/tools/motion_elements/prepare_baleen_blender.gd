extends SceneTree
func interpolate(points: Array, x: float) -> float:
	for i in range(points.size()-1):
		if x<=points[i+1][0]:return lerpf(points[i][1],points[i+1][1],clampf(inverse_lerp(points[i][0],points[i+1][0],x),0,1))
	return points[-1][1]
func clean_attached_strands(paint: Image, origin: Vector2i) -> void:
	var roots: Array=[[250,120],[275,104],[440,55],[595,40],[742,18],[900,0],[1040,5],[1160,65],[1230,170]]
	var tips: Array=[[250,300],[270,300],[320,285],[365,270],[410,275],[460,257],[500,254],[550,227],[590,186],[620,145],[650,165],[680,170],[710,182],[750,155],[790,157],[830,123],[850,100],[870,40],[900,30],[940,115],[980,181],[1020,207],[1080,236],[1120,266],[1170,280],[1230,255]]
	var width:=paint.get_width();var height:=paint.get_height()
	var seen:=PackedByteArray();seen.resize(width*height)
	var queue:=PackedInt32Array()
	for y in range(height):
		for x in range(width):
			var p:=origin+Vector2i(x,y);var c:=paint.get_pixel(x,y)
			var tip:=interpolate(tips,p.x)
			c.a*=1.0-smoothstep(tip-5.0,tip+6.0,float(p.y))
			if p.y>tip-25.0:c.a*=smoothstep(-0.01,0.055,c.r-c.b*0.72)
			if p.x>860 and p.x<908 and p.y>20:c.a*=smoothstep(-0.01,0.045,c.r-c.b*0.72)
			paint.set_pixel(x,y,c)
			if c.a>0.025 and p.y<interpolate(roots,p.x)+60.0:seen[y*width+x]=1;queue.append(y*width+x)
	var head:=0
	while head<queue.size():
		var i:=queue[head];head+=1
		for delta in [-width-1,-width,-width+1,-1,1,width-1,width,width+1]:
			var j: int=i+delta
			if j<0 or j>=width*height or absi(j%width-i%width)>1 or seen[j]==1:continue
			if paint.get_pixel(j%width,j/width).a>0.025:seen[j]=1;queue.append(j)
	for y in range(height):
		for x in range(width):
			if seen[y*width+x]==0:
				var c:=paint.get_pixel(x,y);c.a=0;paint.set_pixel(x,y,c)
func _initialize() -> void:
	var base:=ProjectSettings.globalize_path("res://").path_join("../../assets/source/")
	var source:=base+"baleen-blender/"
	var layout: Array=JSON.parse_string(FileAccess.get_file_as_string(base+"xumen-motion-elements/master/scene-layout.json"))
	var full:=Image.create(1280,720,false,Image.FORMAT_RGBA8)
	for e: Dictionary in layout:
		if str(e.id).begins_with("BALEEN") and not str(e.id).ends_with("ROOT"):
			var im:=Image.load_from_file("res://assets/motion_elements/"+str(e.id)+".png")
			im.convert(Image.FORMAT_RGBA8)
			full.blend_rect(im,Rect2i(Vector2i.ZERO,im.get_size()),Vector2i(e.pos[0],e.pos[1]))
	var jobs: Array=[
		{"id":"BALEEN-LEFT","rect":[250,-16,430,360],"partition":[250,650],"amplitude":7.0,"phase":0.0,"z":4},
		{"id":"BALEEN-CENTER","rect":[630,-16,290,230],"partition":[650,900],"amplitude":5.0,"phase":1.7,"z":4},
		{"id":"BALEEN-RIGHT","rect":[880,-16,350,330],"partition":[900,1230],"amplitude":6.0,"phase":3.2,"z":4},
		{"id":"BALEEN-DISTANT","rect":[860,100,220,300],"partition":[860,1080],"amplitude":1.8,"phase":2.4,"z":-31}
	]
	var clean:=Image.load_from_file(base+"xumen-reference-environment/generated/dynamic-backing.png")
	clean.convert(Image.FORMAT_RGBA8);clean.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	for e: Dictionary in jobs:
		var rect:=Rect2i(e.rect[0],e.rect[1],e.rect[2],e.rect[3])
		var paint:=Image.create(rect.size.x,rect.size.y,false,Image.FORMAT_RGBA8)
		for y in range(rect.size.y):
			for x in range(rect.size.x):
				var p:=rect.position+Vector2i(x,y)
				if not Rect2i(0,0,1280,720).has_point(p):continue
				if e.id=="BALEEN-DISTANT":
					var c:=clean.get_pixelv(p)
					# Inset of the distant blue hanging curtain; cap and contour stay pinned.
					var left:=lerpf(930.0,880.0,clampf((p.y-135.0)/245.0,0,1))
					var right:=lerpf(1030.0,1052.0,clampf((p.y-135.0)/245.0,0,1))
					c.a=smoothstep(left,left+14.0,p.x)*(1.0-smoothstep(right-14.0,right,p.x))*smoothstep(135,175,p.y)*(1.0-smoothstep(355,388,p.y))
					paint.set_pixel(x,y,c)
				elif p.x>=e.partition[0] and p.x<e.partition[1]:paint.set_pixel(x,y,full.get_pixelv(p))
		if e.id!="BALEEN-DISTANT":clean_attached_strands(paint,rect.position)
		paint.save_png(source+"paint/"+str(e.id)+".png")
		e.frames=72;e.fps=12;e.period_seconds=6;e.atlas_columns=8;e.atlas_rows=9
	FileAccess.open(source+"jobs.json",FileAccess.WRITE).store_string(JSON.stringify(jobs,"\t"))
	print("BALEEN_PAINT_READY ",jobs.size())
	quit()
