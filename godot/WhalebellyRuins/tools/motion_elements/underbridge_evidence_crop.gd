extends SceneTree
func _initialize()->void:
	for name in ["before","after","repair_without_bubbles","without_FOREGROUND-BACKING"]:
		var path=ProjectSettings.globalize_path("res://evidence/underbridge/"+name+".png")
		var image=Image.load_from_file(path)
		image.get_region(Rect2i(300,450,440,210)).save_png(path.replace(".png","-detail.png"))
	quit()
