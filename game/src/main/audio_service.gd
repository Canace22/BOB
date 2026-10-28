class_name GameAudio
extends Node

@onready var voices: Array[AudioStreamPlayer] = [$Voice0, $Voice1, $Voice2, $Voice3]
var index: int = 0


func _ready() -> void:
	EventBus.sfx.connect(play)


func play(id: String) -> void:
	var path := "res://art/audio/%s.wav" % id
	if not ResourceLoader.exists(path):
		return
	var voice := voices[index]
	index = (index + 1) % voices.size()
	voice.stream = load(path) as AudioStream
	voice.play()
