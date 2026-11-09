class_name WhaleUIPreferences
extends RefCounted

var path: String = "user://whalebelly/ui_settings.cfg"
var numbers: bool = true
var contrast: bool = false
var reduce_motion: bool = false
var volume: float = 0.8
var muted: bool = false

func read() -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK: return
	numbers = bool(config.get_value("ui", "numbers", true))
	contrast = bool(config.get_value("ui", "contrast", false))
	reduce_motion = bool(config.get_value("ui", "reduce_motion", false))
	volume = clampf(float(config.get_value("audio", "volume", 0.8)), 0.0, 1.0)
	muted = bool(config.get_value("audio", "muted", false))

func write() -> Error:
	var config := ConfigFile.new()
	config.set_value("ui", "numbers", numbers)
	config.set_value("ui", "contrast", contrast)
	config.set_value("ui", "reduce_motion", reduce_motion)
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "muted", muted)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return config.save(path)

func apply(host: Node2D) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, muted)
	host.muted = muted
	if is_instance_valid(host.camera):
		host.camera.shake_pixels = 0.0 if reduce_motion else host.camera_shake_pixels
		host.camera.dash_zoom = 1.0 if reduce_motion else host.camera_dash_zoom
