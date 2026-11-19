class_name CampaignPlayerMusic
extends Node
## Short, event-driven accents. The two action voices leave room for the previous
## pluck to decay; health phrases have their own voice and remain intelligible.

const STREAMS := {
	&"jump": preload("res://art/whalebelly/runtime/audio/player/jump.wav"),
	&"air_jump": preload("res://art/whalebelly/runtime/audio/player/air_jump.wav"),
	&"dash": preload("res://art/whalebelly/runtime/audio/player/dash.wav"),
	&"float": preload("res://art/whalebelly/runtime/audio/player/float.wav"),
	&"anchor": preload("res://art/whalebelly/runtime/audio/player/anchor.wav"),
	&"hit": preload("res://art/whalebelly/runtime/audio/player/hit.wav"),
	&"parry": preload("res://art/whalebelly/runtime/audio/player/parry.wav"),
	&"low": preload("res://art/whalebelly/runtime/audio/player/low.wav"),
	&"recover": preload("res://art/whalebelly/runtime/audio/player/recover.wav"),
	&"defeat": preload("res://art/whalebelly/runtime/audio/player/defeat.wav"),
}
const GAIN_DB := {&"jump": -22.0, &"air_jump": -18.0, &"dash": -21.0, &"float": -18.0,
	&"anchor": -18.0, &"hit": -22.0, &"parry": -16.0, &"low": -16.0,
	&"recover": -17.0, &"defeat": -16.0}
const REPEAT_DELAY := {&"hit": 0.24, &"float": 0.6, &"anchor": 0.4}

@onready var player := get_parent() as WhalebellyCampaignPlayer
var action_voices: Array[AudioStreamPlayer] = []
var state_voice: AudioStreamPlayer
var next_voice := 0
var elapsed := 0.0
var last_played: Dictionary = {}
var previous_health: int
var floated := false
var attached := false

func _ready() -> void:
	for i: int in 2:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		action_voices.append(voice)
	state_voice = AudioStreamPlayer.new()
	add_child(state_voice)
	player.ready.connect(_bind, CONNECT_ONE_SHOT)

func _bind() -> void:
	previous_health = player.health
	player.animation_tag.connect(_animation_tag)
	player.skill_effect.connect(_skill_effect)
	player.hit_confirmed.connect(_action.bind(&"hit"))
	player.stats_changed.connect(_stats_changed)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if not player.controls_enabled or player.health <= 0: return
	if not Input.is_action_pressed("float") or player.is_on_floor(): floated = false
	if player.floating and not floated:
		floated = true
		_action(&"float")
	if player.grapple_hanging and not attached: _action(&"anchor")
	attached = player.grapple_hanging

func _animation_tag(tag: String) -> void:
	match tag:
		"jump": _action(&"air_jump" if player.jump_count == 2 else &"jump")
		"A1_dash:start": _action(&"dash")

func _skill_effect(key: String, event: String, _origin: Vector2, _direction: float) -> void:
	if key == "parry" and event == "success": _action(&"parry")

func _stats_changed(health: int, _soul: int) -> void:
	var old := previous_health
	previous_health = health
	if health == old: return
	if health == 0:
		for voice: AudioStreamPlayer in action_voices: voice.stop()
		_play(state_voice, &"defeat")
	elif health == 1 and old > health:
		_play(state_voice, &"low")
	elif health > old and player.state == "recover":
		_play(state_voice, &"recover")

func _action(cue: StringName) -> void:
	if player.health <= 0: return
	if elapsed - float(last_played.get(cue, -10.0)) < float(REPEAT_DELAY.get(cue, 0.1)): return
	last_played[cue] = elapsed
	_play(action_voices[next_voice], cue)
	next_voice = (next_voice + 1) % action_voices.size()

func _play(voice: AudioStreamPlayer, cue: StringName) -> void:
	voice.stream = STREAMS[cue]
	voice.volume_db = GAIN_DB[cue]
	voice.play()
	player.host.record_event("player_music", {"cue": str(cue)})
