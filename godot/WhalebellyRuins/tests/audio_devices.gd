extends SceneTree
func _initialize() -> void:
	print("AUDIO_DEVICE_LIST ",JSON.stringify({"driver":AudioServer.get_driver_name(),"outputs":AudioServer.get_output_device_list(),"current":AudioServer.output_device}))
	quit()
