@warning_ignore_start("untyped_declaration")
extends SceneTree
func _initialize() -> void:
	var repo=ProjectSettings.globalize_path("res://../../")
	var image=Image.load_from_file(repo+"assets/source/xumen-soft-light/generated/underwater-light-original.png")
	image.convert(Image.FORMAT_RGBA8)
	image.resize(512,768,Image.INTERPOLATE_LANCZOS)
	# Preserve generated RGBA; remove only boundary opacity, never bake scene pixels into light.
	for y in image.get_height():
		for x in image.get_width():
			var c=image.get_pixel(x,y)
			c.a*=smoothstep(0.0,48.0,float(mini(x,511-x)))*smoothstep(0.0,96.0,float(mini(y,767-y)))
			image.set_pixel(x,y,c)
	for folder in [repo+"assets/source/xumen-soft-light/master",repo+"assets/runtime/xumen-soft-light",ProjectSettings.globalize_path("res://art/whalebelly/soft_light")]:
		image.save_png(folder+"/UNDERWATER-SOFT-LIGHT.png")
	quit()
