@warning_ignore_start("untyped_declaration")
extends SceneTree
func _initialize()->void:
	var repo=ProjectSettings.globalize_path("res://../../")
	var source=repo+"assets/source/xumen-underbridge-repair/"
	for folder in [source+"master",repo+"assets/runtime/xumen-underbridge-repair",ProjectSettings.globalize_path("res://art/whalebelly/underbridge")]:DirAccess.make_dir_recursive_absolute(folder)
	var original=Image.load_from_file(repo+"assets/source/xumen-reference-environment/original/reference.png")
	original.convert(Image.FORMAT_RGBA8);original.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	var old=Image.load_from_file(ProjectSettings.globalize_path("res://art/whalebelly/foreground_edges/CLEAN-FOREGROUND-BACKING.png"));old.convert(Image.FORMAT_RGBA8)
	var result=old.duplicate()
	var foreground_mask=Image.new()
	foreground_mask.load_svg_from_string(FileAccess.get_file_as_string(repo+"assets/source/xumen-motion-elements/master/foreground-mask.svg"))
	var foreground_top:PackedInt32Array=[]
	for x in 1280:
		var top=719
		for y in range(430,720):
			if foreground_mask.get_pixel(x,y).a>0.5:top=y;break
		foreground_top.append(top)
	var protected=0
	for y in range(415,690):
		for x in range(180,1100):
			var c=old.get_pixel(x,y);var a=0.0
			for dy in [-8,-4,0,4,8]:
				for dx in [-8,-4,0,4,8]:a+=old.get_pixel(clampi(x+dx,0,1279),clampi(y+dy,0,719)).a/25.0
			var tissue=original.get_pixel(x,y)
			var protect=smoothstep(0.005,0.065,tissue.r-tissue.b*0.72)*smoothstep(0.08,0.18,maxf(tissue.r,maxf(tissue.g,tissue.b)))
			# Preserve bridge tissue only, never re-expose the foreground's baked coral tips.
			protect*=1.0-smoothstep(float(foreground_top[x]-35),float(foreground_top[x]-10),float(y))
			var region=smoothstep(180.0,220.0,float(x))*(1.0-smoothstep(1060.0,1100.0,float(x)))*smoothstep(415.0,440.0,float(y))*(1.0-smoothstep(665.0,690.0,float(y)))
			var target=maxf(c.a,a)*(1.0-protect)
			if protect>0.9 and c.a>0.1:protected+=1
			c.a=lerpf(c.a,target,region);result.set_pixel(x,y,c)
	for folder in [source+"master",repo+"assets/runtime/xumen-underbridge-repair",ProjectSettings.globalize_path("res://art/whalebelly/underbridge")]:result.save_png(folder+"/FOREGROUND-BACKING-SOFT.png")
	# Restore the original hanging tissue below the old straight road polygon.
	# RGB is sampled from the approved source; blue water stays transparent.
	var road=Image.load_from_file(ProjectSettings.globalize_path("res://art/whalebelly/foreground_edges/CLEAN-ROAD.png"))
	road.convert(Image.FORMAT_RGBA8)
	for y in range(495,610):
		for x in range(410,560):
			var c=original.get_pixel(x,y)
			var edge=smoothstep(410.0,425.0,float(x))*(1.0-smoothstep(545.0,560.0,float(x)))
			edge*=smoothstep(495.0,505.0,float(y))*(1.0-smoothstep(600.0,610.0,float(y)))
			var tissue=smoothstep(0.0,0.035,minf(c.r-c.b*0.90,c.g-c.b*1.07))
			var foreground=1.0-smoothstep(float(foreground_top[x]-38),float(foreground_top[x]-30),float(y))
			var prior=road.get_pixel(x,y-392)
			var restore=edge*tissue*foreground
			# VINE-02 already owns this rectangle and sways independently.
			if x>=447 and x<=493 and y>=534:restore=0.0
			if restore>prior.a:
				c.a=restore;road.set_pixel(x,y-392,c)
	for folder in [source+"master",repo+"assets/runtime/xumen-underbridge-repair",ProjectSettings.globalize_path("res://art/whalebelly/underbridge")]:road.save_png(folder+"/ROAD-UNDERSIDE-RESTORED.png")
	print("UNDERBRIDGE protected tissue pixels ",protected)
	quit()
