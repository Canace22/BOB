class_name StoryEnvironment
extends Node2D
## Chapter-one geometry and artwork share authored world coordinates.
## All environmental motion uses this clock; pausing never resets its pose.
const WORLD_SIZE := Vector2(3200, 1000)
const SURFACES: Array[Rect2] = [
	Rect2(0, 780, 3200, 240),
	Rect2(1410, 650, 320, 130),
	Rect2(940, 650, 270, 16),
	Rect2(1810, 650, 270, 16),
]
@export var animation_enabled: bool = true
@export_range(0.0, 2.0) var animation_speed: float = 1.0
var elapsed: float = 0.0

func _ready() -> void:
	update_at(0.0)

func _process(delta: float) -> void:
	if animation_enabled and animation_speed > 0.0:
		update_at(elapsed + delta * animation_speed)

func update_at(time: float) -> void:
	elapsed = time
	for element in $Motion.get_children():
		if element.has_method("update_at"):
			element.update_at(time)
	# Painted silt traces a local returning current, independently of bubbles.
	for i in $ReturningSilt.get_child_count():
		var wisp := $ReturningSilt.get_child(i) as Sprite2D
		var phase: float = time * TAU / 11.0 + float(i) * TAU / 9.0
		wisp.position = Vector2(2780, 658) + Vector2(cos(phase) * 115.0, sin(phase) * 39.0)
		wisp.rotation = atan2(cos(phase) * 39.0, -sin(phase) * 115.0)
		wisp.modulate = Color(0.68, 0.78, 0.64, 0.43 + 0.14 * sin(phase))

func get_surfaces() -> Array[Rect2]:
	return SURFACES.duplicate()

func get_marker_position(marker_name: StringName) -> Vector2:
	var marker := get_node_or_null(NodePath("Markers/" + String(marker_name))) as Marker2D
	assert(marker != null, "Unknown chapter marker: " + String(marker_name))
	return marker.global_position if marker != null else global_position
