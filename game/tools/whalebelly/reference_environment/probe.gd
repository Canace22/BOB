@warning_ignore_start("untyped_declaration")
extends SceneTree
func _initialize() -> void:
	var source: Image=Image.load_from_file("G:/鲸落万物生/BOB/assets/source/xumen-reference-environment/original/reference.png")
	source.convert(Image.FORMAT_RGBA8)
	var checks: Array=[{"id":"fish2","rect":Rect2i(550,140,240,100)},{"id":"fish3","rect":Rect2i(860,315,220,100)},{"id":"vine4","rect":Rect2i(1000,515,230,180)}]
	for check: Dictionary in checks:
		var detail: Image=source.get_region(check.rect)
		detail.resize(detail.get_width()*3,detail.get_height()*3,Image.INTERPOLATE_NEAREST)
		detail.save_png("res://build/qa/whalebelly/evidence/reference_environment/probe-"+str(check.id)+".png")
	var out: Image=Image.create(800,200,false,Image.FORMAT_RGBA8)
	var rects: Array[Rect2i]=[Rect2i(875,207,35,35),Rect2i(830,245,35,35),Rect2i(444,318,35,35),Rect2i(175,280,35,35)]
	for i: int in range(rects.size()):
		var part: Image=source.get_region(rects[i])
		part.resize(190,190,Image.INTERPOLATE_NEAREST)
		out.blit_rect(part,Rect2i(0,0,190,190),Vector2i(i*200,0))
	out.save_png("res://build/qa/whalebelly/evidence/reference_environment/bubble-probes.png")
	quit()
