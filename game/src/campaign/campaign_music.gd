class_name CampaignMusic
extends AudioStreamPlayer
## A single persistent player carries the score across the streamed world.

const HARBOR := preload("res://art/whalebelly/runtime/audio/score/lost-town.ogg")
const NURSERY := preload("res://art/whalebelly/runtime/audio/score/love_theme.ogg")
const BATTLE := preload("res://art/whalebelly/runtime/audio/score/breaking_the_chains.ogg")
const SPINE := preload("res://art/whalebelly/runtime/audio/score/the-black-temple.ogg")
const MEMORY := preload("res://art/whalebelly/runtime/audio/score/elvish-theme.ogg")
const RELEASE := preload("res://art/whalebelly/runtime/audio/score/first-light.ogg")
const HUB := preload("res://art/whalebelly/runtime/audio/score/into_the_shadows.ogg")
const REST := preload("res://art/whalebelly/runtime/audio/score/journeys-end.ogg")
# Measured integrated levels in the exploration / battle mix, before master volume.
const LEVEL_DB := {HARBOR: -7.5, NURSERY: -13.5, HUB: -10.5, BATTLE: -8.0,
	SPINE: -6.0, MEMORY: -9.5, REST: -12.5, RELEASE: -6.0}

var room_score: AudioStream = HARBOR
var world_cue: AudioStream = HARBOR
var resting := false
var requested: AudioStream
var fade: Tween
var waiting_for: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	finished.connect(_on_finished)
	set_process(false)

func set_room(id: String, enemies: Array) -> void:
	waiting_for = {}
	for enemy: Dictionary in enemies:
		if enemy.boss and enemy.alive and is_instance_valid(enemy.get("actor")):
			waiting_for = enemy
			break
	if id == "R1-04" and not waiting_for.is_empty():
		room_score = SPINE
	elif id.begins_with("R2-"):
		room_score = NURSERY
	elif id.begins_with("R3-"):
		room_score = HUB
	elif id.begins_with("R4-"):
		room_score = SPINE
	elif id in ["R1-07", "R5-02"]:
		room_score = REST
	elif id.begins_with("R5-"):
		room_score = MEMORY
	else:
		room_score = HARBOR
	set_process(not waiting_for.is_empty())
	if waiting_for.get("music_engaged", false):
		_start_encounter()
	else:
		_set_world_cue(room_score)

func _process(_delta: float) -> void:
	var actor: Node = waiting_for.get("actor")
	if actor is CampaignCrabBoss and actor.running:
		_start_encounter()
	elif actor is KitEncounter and actor.state != "rest":
		_start_encounter()

func _start_encounter() -> void:
	waiting_for["music_engaged"] = true
	waiting_for = {}
	set_process(false)
	_set_world_cue(BATTLE)

func play_ending() -> void:
	_set_world_cue(RELEASE)

func set_story_encounter(active: bool) -> void:
	# 新章节使用完整执行器，不伪装成旧母蟹字典；混音仍由本播放器唯一拥有。
	waiting_for={}
	set_process(false)
	_set_world_cue(BATTLE if active else room_score)

func _on_finished() -> void:
	if stream == RELEASE and requested == RELEASE:
		_set_world_cue(room_score)

func set_resting(active: bool) -> void:
	if resting == active: return
	resting = active
	_request(REST if active else world_cue)

func _set_world_cue(next: AudioStream) -> void:
	world_cue = next
	if not resting: _request(next)

func _request(next: AudioStream) -> void:
	if next == requested: return
	requested = next
	if fade: fade.kill()
	fade = create_tween()
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if playing and stream != next:
		fade.tween_property(self, "volume_db", -58.0, 0.15 if next == BATTLE else 0.3)
		fade.tween_callback(_start.bind(next))
	elif not playing:
		_start(next)
	fade.tween_property(self, "volume_db", LEVEL_DB[next], 0.18 if next == BATTLE else 0.45)

func _start(next: AudioStream) -> void:
	stream = next
	volume_db = -58.0
	# Start where the orchestral battle passage gathers, skipping its quiet opening.
	play(BATTLE.loop_offset if next == BATTLE else 0.0)
