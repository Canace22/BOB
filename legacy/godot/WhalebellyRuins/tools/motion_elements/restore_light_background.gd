extends SceneTree
## Restore the original painted pixels excised by the old polygon light masks.
func _initialize() -> void:
	var root_dir=ProjectSettings.globalize_path("res://../../")
	var source=root_dir+"assets/source/xumen-soft-light/"
	DirAccess.make_dir_recursive_absolute(source+"master")
	DirAccess.make_dir_recursive_absolute("res://assets/soft_light")
	DirAccess.make_dir_recursive_absolute(root_dir+"assets/runtime/xumen-soft-light")
	var depth=Image.load_from_file(ProjectSettings.globalize_path("res://assets/motion_elements/ENV-DEPTH.png"))
	depth.convert(Image.FORMAT_RGBA8)
	var jobs=[["BEAM-01",Vector2i(622,0)],["BEAM-02",Vector2i(788,0)],["BEAM-03",Vector2i(905,43)]]
	var restored=0
	for job in jobs:
		var beam=Image.load_from_file(ProjectSettings.globalize_path("res://assets/motion_elements/"+job[0]+".png"))
		for y in beam.get_height():
			for x in beam.get_width():
				var dest=Vector2i(x,y)+job[1]-Vector2i(20,0)
				var b=beam.get_pixel(x,y)
				if b.a<=0 or dest.x<0 or dest.y<0 or dest.x>=depth.get_width() or dest.y>=depth.get_height():continue
				var a=depth.get_pixelv(dest)
				var total=a.a+b.a
				depth.set_pixelv(dest,Color((a.r*a.a+b.r*b.a)/total,(a.g*a.a+b.g*b.a)/total,(a.b*a.a+b.b*b.a)/total,minf(total,1.0)))
				restored+=1
	for folder in [source+"master",ProjectSettings.globalize_path("res://assets/soft_light"),root_dir+"assets/runtime/xumen-soft-light"]:
		depth.save_png(folder+"/ENV-DEPTH-RESTORED.png")
	print("RESTORED_BACKGROUND_PIXELS ",restored)
	quit()
