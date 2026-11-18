extends SceneTree
## Bake the repaired curtain and remove its static duplicate in source coordinates.
const SOURCE := "res://../assets/source/r1-02-curtain-cleanup-v1/"
const OUTPUT := "res://../assets/runtime/sprites/r1-02-curtain-cleanup-v1/"

func _initialize() -> void:
	var curtain := Image.load_from_file(SOURCE+"curtain-generated.png")
	var middle := Image.load_from_file(SOURCE+"Middle-original.png")
	if curtain == null or middle == null:
		quit(1)
		return
	curtain.convert(Image.FORMAT_RGBA8)
	# Fit uniformly into the old crop with the same transparent sampling margin.
	var ratio := minf(790.0/curtain.get_width(),375.0/curtain.get_height())
	curtain.resize(roundi(curtain.get_width()*ratio),roundi(curtain.get_height()*ratio),Image.INTERPOLATE_LANCZOS)
	var framed := Image.create_empty(814,399,false,Image.FORMAT_RGBA8)
	framed.blit_rect(curtain,Rect2i(Vector2i.ZERO,curtain.get_size()),Vector2i(12,4))
	framed.save_png(OUTPUT+"R1-02-BALEEN-1.png")
	# Preserve the ceiling above its authored attachment curve, and all side walls.
	for y: int in middle.get_height():
		for x: int in range(548,1380):
			var p := Vector2(x-16,y-16)
			var attachment := 8.0
			if p.x>1050: attachment=lerpf(8.0,18.0,clampf((p.x-1050)/200.0,0,1))
			if p.x>1250: attachment=lerpf(18.0,55.0,clampf((p.x-1250)/105.0,0,1))
			if p.y<attachment or p.y>428: continue
			var color := middle.get_pixel(x,y)
			color.a=0.0
			middle.set_pixel(x,y,color)
	middle.save_png(OUTPUT+"Middle.png")
	print("CURTAIN_EXPORT ",curtain.get_size()," -> ",framed.get_size()," static ",middle.get_size())
	quit()
