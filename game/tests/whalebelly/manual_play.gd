extends "res://src/campaign/main.gd"
## Native keyboard rehearsal; uses only the campaign's isolated QA save.
var sample_elapsed: float = 0.0
var start_position: Vector2
var max_distance: float = 0.0
var min_y: float = INF
var observed_states: Dictionary = {}

func _init() -> void:
	qa = true
	qa_full_abilities = false
	integration_external_test = true

func _ready() -> void:
	super._ready()
	start_position = player.position

func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(player):
		return
	max_distance = maxf(max_distance, absf(player.position.x - start_position.x))
	min_y = minf(min_y, player.position.y)
	observed_states[player.state] = true
	sample_elapsed += delta
	if sample_elapsed < 0.25:
		return
	sample_elapsed = 0.0
	var output := FileAccess.open("res://build/qa/whalebelly-recovery/native-input.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"room": room.id, "position": player.position,
		"max_distance": max_distance, "min_y": min_y, "states": observed_states,
		"health": health, "save_isolated": qa}))
