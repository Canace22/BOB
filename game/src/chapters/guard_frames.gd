class_name GuardFrames
extends RefCounted
## Drawn poses share a registered root; animation time is gameplay time.

const ROOT := "res://art/chapters/guard/"
var clips: Dictionary = {}
var textures: Dictionary = {}
var current_clip: String = "idle"
var current_frame: int = 0


func _init() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "animations.json"))
	clips = data.clips
	for clip: String in clips:
		var frames: Array[Texture2D] = []
		for filename: String in clips[clip].files:
			frames.append(load(ROOT + filename) as Texture2D)
		textures[clip] = frames


func display(sprite: Sprite2D, clip: String, elapsed: float, facing: float) -> void:
	current_clip = clip
	var durations: Array = clips[clip].durations_ms
	var total := 0.0
	for duration: float in durations:
		total += duration
	var time := maxf(0, elapsed * 1000)
	if clips[clip].loop:
		time = fmod(time, total)
	current_frame = durations.size() - 1
	for index in durations.size():
		if time < float(durations[index]):
			current_frame = index
			break
		time -= float(durations[index])
	sprite.texture = textures[clip][current_frame]
	sprite.flip_h = facing > 0


func snapshot() -> Dictionary:
	return {"clip": current_clip, "frame": current_frame,
		"file": ROOT + str(clips[current_clip].files[current_frame])}
