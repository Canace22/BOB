extends SceneTree
func _initialize() -> void:
	for item: Dictionary in AudioServer.get_method_list():
		if "mix" in str(item.name) or "latency" in str(item.name): print(item.name)
	quit()
