@warning_ignore_start("untyped_declaration")
extends SceneTree
## Extract the painted upper water surface; no new scene painting.
func _initialize() -> void:
	var base := ProjectSettings.globalize_path("res://").path_join("../../assets/")
	var im := Image.load_from_file(base+"source/xumen-reference-environment/generated/dynamic-backing.png")
	im.convert(Image.FORMAT_RGBA8)
	im.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	var rect := Rect2i(350,0,740,150)
	var water := im.get_region(rect)
	for y in range(water.get_height()):
		for x in range(water.get_width()):
			var c := water.get_pixel(x,y)
			var edge := smoothstep(0.0,45.0,float(x))*smoothstep(0.0,45.0,740.0-float(x))*(1.0-smoothstep(95.0,150.0,float(y)))
			# Blue/cyan water only: leave roof and distant bone silhouettes rigid.
			var water_color := smoothstep(0.37,0.58,c.g)*smoothstep(0.18,0.33,c.b-c.r)
			c.a=edge*water_color
			water.set_pixel(x,y,c)
	for folder: String in ["source/xumen-motion-elements/master/","runtime/xumen-motion-elements/"]:
		water.save_png(base+folder+"WATER-SURFACE.png")
	water.save_png("res://art/whalebelly/motion_elements/WATER-SURFACE.png")
	print("WATER_SURFACE_EXTRACTED ",rect)
	quit()
