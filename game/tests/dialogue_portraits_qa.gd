extends SceneTree
## 独立原生UI夹具：检查头像换人和窄窗排版，不冒充正式剧情路线。
const OUT: String="res://build/qa/dialogue-portraits"
var panel: WhaleDialoguePanel

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("dialogue_portraits_qa requires native rendering")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720)
	var backdrop:=ColorRect.new()
	backdrop.color=Color("18333d")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	panel=WhaleDialoguePanel.new()
	root.add_child(panel)
	panel.show()
	for speaker: String in ["拾潮者","补巢者","负壳守卫","泵庭执卫","封梁卫","老守护者","住户","旁白"]:
		panel.present(speaker,"绳索已经接住了，先让靠近水线的住户走。我留在这里，你把另一头递过来。")
		await capture(WhaleDialoguePortraits.identity(speaker) if speaker!="旁白" else "narration")
	root.size=Vector2i(640,360)
	panel.present("老守护者","先不要松手。这边的旧撑还在晃，等我把绳索扣进骨缝，你再退到台面上。")
	await capture("small-window")
	root.size=Vector2i(480,360)
	panel.present("补巢者","这块巢片还在滴水。我先扶住它，你帮我把绳索扎紧。")
	await capture("narrow-window")
	print("DIALOGUE_PORTRAITS_GPU captures=10")
	quit()

func capture(name_text: String) -> void:
	for frame: int in 4: await process_frame
	panel.reveal=float(panel.text_label.get_total_character_count())
	panel.text_label.visible_characters=-1
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(name_text+".png"))
