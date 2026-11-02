class_name PlayerAnimationData
extends RefCounted
## Direction-specific bitmap clips. Invalid/missing clips use the explicit legacy fallback.

const CLIPS := ["idle", "run", "jump_rise", "jump_fall", "land", "attack", "attack2", "heavy", "hurt", "dash", "heal"]
const ATTACKS := ["attack", "attack2", "heavy"]

var canvas := Vector2i(192, 192)
var pivot := Vector2(96, 171)
var display_scale: float = 0.55
var directions: Dictionary = {}
var issues: PackedStringArray = []


func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		issues.append("Invalid animation JSON: " + parser.get_error_message())
		return false
	return configure(parser.data, path.get_base_dir())


func configure(data: Variant, base: String) -> bool:
	directions.clear()
	issues.clear()
	if not data is Dictionary or data.get("version") != 1:
		issues.append("Animation metadata must have version 1")
		return false
	if not _pair(data.get("canvas"), true) or not _pair(data.get("pivot"), false):
		issues.append("Animation canvas/pivot must have two finite numbers")
		return false
	canvas = Vector2i(int(data.canvas[0]), int(data.canvas[1]))
	pivot = Vector2(float(data.pivot[0]), float(data.pivot[1]))
	if float(data.canvas[0]) != canvas.x or float(data.canvas[1]) != canvas.y:
		issues.append("Animation canvas dimensions must be integer pixels")
		return false
	if not _positive(data.get("scale")) or not data.get("directions") is Dictionary or canvas.x < 1 or canvas.y < 1:
		issues.append("Animation scale/directions/canvas is invalid")
		return false
	if pivot.x < 0 or pivot.y < 0 or pivot.x > canvas.x or pivot.y > canvas.y:
		issues.append("Animation pivot must be inside the common canvas")
		return false
	display_scale = float(data.scale)
	for direction: String in ["left", "right"]:
		var source: Variant = data.directions.get(direction, {})
		var accepted: Dictionary = {}
		if not source is Dictionary:
			issues.append("Invalid direction: " + direction)
			continue
		for name: String in source:
			if name not in CLIPS:
				issues.append("Unknown animation clip: " + name)
				continue
			var parsed := _read_clip(source[name], name, base)
			if parsed.is_empty():
				issues.append("Invalid or missing animation frames: " + direction + "/" + name)
			else:
				accepted[name] = parsed
		directions[direction] = accepted
	return not directions.is_empty()


func clip(direction: String, name: String) -> Dictionary:
	return directions.get(direction, {}).get(name, {})


func _read_clip(source: Variant, name: String, base: String) -> Dictionary:
	if not source is Dictionary or not source.get("frames") is Array or source.frames.is_empty():
		return {}
	var result: Dictionary = {"textures": [], "files": [], "durations": [], "duration": 0.0, "loop": name == "idle"}
	for frame: Variant in source.frames:
		if not frame is Dictionary or not frame.get("file") is String or not _positive(frame.get("durationMs")):
			return {}
		var file: String = frame.file
		if file.is_absolute_path() or ".." in file.split("/"):
			return {}
		var path := base.path_join(file)
		if not ResourceLoader.exists(path, "Texture2D"):
			return {}
		var texture := load(path) as Texture2D
		if texture == null or Vector2i(texture.get_size()) != canvas:
			return {}
		var duration := float(frame.durationMs) / 1000.0
		result.textures.append(texture)
		result.files.append(path)
		result.durations.append(duration)
		result.duration = float(result.duration) + duration
	if name == "idle":
		result.loop = bool(source.get("loop", true))
	if name == "run":
		if not _positive(source.get("stridePixels")):
			return {}
		result.stride = float(source.stridePixels)
		result.loop = true
	if name in ATTACKS:
		var window: Variant = source.get("activeWindowMs")
		if not _pair(window, true) or window[1] <= window[0] or float(window[1]) / 1000.0 >= float(result.duration):
			return {}
		result.active_window = Vector2(float(window[0]), float(window[1])) / 1000.0
		if not _frame_boundary(result.durations, result.active_window.x) or not _frame_boundary(result.durations, result.active_window.y):
			return {}
	return result


func _frame_boundary(durations: Array, boundary: float) -> bool:
	var elapsed: float = 0
	for duration: float in durations:
		elapsed += duration
		if is_equal_approx(elapsed, boundary):
			return true
	return false


func _positive(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) > 0


func _pair(value: Variant, positive: bool) -> bool:
	if not value is Array or value.size() != 2:
		return false
	for item: Variant in value:
		if not (item is float or item is int) or not is_finite(float(item)) or (positive and float(item) <= 0):
			return false
	return true


static func frame_at(animation: Dictionary, seconds: float) -> int:
	var durations: Array = animation.durations
	var time := maxf(0, seconds)
	if bool(animation.loop):
		time = fposmod(time, float(animation.duration))
	var end: float = 0
	for index in durations.size():
		end += float(durations[index])
		if time < end - 0.0000001:
			return index
	return durations.size() - 1


static func attack_time(animation: Dictionary, elapsed: float, active_start: float, active_end: float, duration: float) -> float:
	var window: Vector2 = animation.active_window
	if elapsed < active_start:
		return remap(maxf(0, elapsed), 0, active_start, 0, window.x)
	if elapsed < active_end:
		return remap(elapsed, active_start, active_end, window.x, window.y)
	return remap(clampf(elapsed, active_end, duration), active_end, duration, window.y, float(animation.duration))
