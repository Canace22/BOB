extends "res://src/campaign/main.gd"
## Review entry with its own V6 save, original abilities and normal damage.

func _init() -> void:
	qa = true
	qa_full_abilities = false
	integration_external_test = true

func save_path() -> String:
	return "user://whalebelly/xumen-background-current-v1-manual.json"

func _ready() -> void:
	super._ready()
	_review_ready.call_deferred()

func _review_ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--review-room="):
			var target: String = argument.trim_prefix("--review-room=")
			var index: int = rooms.find_custom(func(entry: Dictionary) -> bool: return str(entry.id)==target)
			if index>=0: load_room(index,[],false)
	DisplayServer.window_set_title("鲸腹遗城 · 须门遗港（动态水光）")
	print("XUMEN_MANUAL_READY room=",room.id," save=",save_path()," health=",health," abilities=",abilities)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/qa/xumen-background-current-v1/manual-start.png")
