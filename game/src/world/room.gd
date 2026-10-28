class_name Room
extends Node2D

@export var room_id: String = ""
@export var display_name: String = ""
@export var dimensions: Vector2 = Vector2(1920, 1152)
@export var fall_damage: int = 0


func _ready() -> void:
	for node in find_children("*", "Label", true, false):
		(node as Label).theme = preload("res://src/ui/theme.tres")
	# Old decorative gates duplicated the interactive scene nodes after migration.
	for node_name: String in ["Gate_A2", "Gate_A3", "GateLabel_A2", "GateLabel_A3", "LungSideLockedGate"]:
		var node := get_node_or_null("Scenery/World/" + node_name) as CanvasItem
		if node != null:
			node.hide()


func entry_position(id: String) -> Vector2:
	var entry := get_node_or_null("Entries/" + id) as Marker2D
	if entry == null:
		entry = get_node("Entries/default") as Marker2D
	return entry.position
