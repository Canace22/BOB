class_name StoryAudio
extends Node
## Offline authored sound files; water ambience and combat cues retain their provenance.

var ambience: AudioStreamPlayer
var voice: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ambience = AudioStreamPlayer.new()
	ambience.stream = preload("res://art/whalebelly/runtime/audio/water_bed.wav")
	ambience.volume_db = -16.0
	if OS.has_feature("web"): ambience.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(ambience)
	ambience.finished.connect(ambience.play)
	voice = AudioStreamPlayer.new()
	voice.volume_db = -2.0
	if OS.has_feature("web"): voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(voice)

func begin() -> void:
	if not ambience.playing: ambience.play()

func set_paused(value: bool) -> void:
	ambience.stream_paused = value
	voice.stream_paused = value

func cue(key: String) -> void:
	var paths: Dictionary = {
		"whale":"res://art/story-c01/audio/whale-call.wav",
		"resonance":"res://art/story-c01/audio/resonance.wav",
		"strike":"res://art/whalebelly/runtime/audio/strike.wav",
		"hit":"res://art/whalebelly/runtime/audio/hit.wav",
		"hurt":"res://art/whalebelly/runtime/audio/hurt.wav",
		"jump":"res://art/whalebelly/runtime/audio/jump.wav",
		"save":"res://art/whalebelly/runtime/audio/save.wav"
	}
	if not paths.has(key): return
	voice.stream = load(paths[key])
	voice.play()
