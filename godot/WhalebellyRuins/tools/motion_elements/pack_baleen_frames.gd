extends SceneTree
func _initialize() -> void:
	var assets:=ProjectSettings.globalize_path("res://").path_join("../../assets/")
	var source:=assets+"source/baleen-blender/"
	var jobs: Array=JSON.parse_string(FileAccess.get_file_as_string(source+"jobs.json"))
	for job: Dictionary in jobs:
		var size:=Vector2i(job.rect[2],job.rect[3])
		var atlas:=Image.create(size.x*8,size.y*9,false,Image.FORMAT_RGBA8)
		for frame in range(72):
			var im:=Image.load_from_file(source+"frames/"+str(job.id)+"/%03d.png"%frame)
			if im==null or im.get_size()!=size:push_error("Invalid frame: "+str(job.id));quit(1);return
			im.convert(Image.FORMAT_RGBA8)
			atlas.blit_rect(im,Rect2i(Vector2i.ZERO,size),Vector2i(frame%8,frame/8)*size)
		atlas.save_png(assets+"runtime/baleen-blender/"+str(job.id)+".png")
		atlas.save_png("res://assets/baleen_blender/"+str(job.id)+".png")
	print("PACKED_BLENDER_ATLASES ",jobs.size())
	quit()
