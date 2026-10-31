class_name LocalEnvironment
extends Node2D
## Shared clock for the migrated bitmap environment; no gameplay or save state.
@export var animate_environment: bool = true
@export var motion_strength: float = 1.0
@export var show_reference_character: bool = false
var elapsed: float = 0.0
var bases: Dictionary = {}

func _ready() -> void:
	for child: Node in get_children():
		if child is Sprite2D:
			bases[child.name] = child.position
	var character := get_node_or_null("CHARACTER") as CanvasItem
	if character != null:
		character.visible = show_reference_character
	update_visuals()

func _process(delta: float) -> void:
	if animate_environment:
		elapsed += delta * motion_strength
	update_visuals()

func update_visuals(camera_offset: Vector2 = Vector2.ZERO) -> void:
	for child: Node in get_children():
		if str(child.name).begins_with("BUBBLE-ZONE"):
			child.update_at(elapsed)
		elif child.has_method("update_at"):
			child.update_at(elapsed, camera_offset)
		elif child is Sprite2D:
			var amount: float = 0.0
			if child.name == &"ENV-UNDERPAINT":
				amount = 0.14
			elif str(child.name).begins_with("MID"):
				amount = 0.045
			child.position = bases[child.name] + camera_offset * amount