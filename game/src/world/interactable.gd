class_name Interactable
extends Node2D

@export var prompt: String = "E 交互"
@export var radius: float = 100.0


func _ready() -> void:
	add_to_group("interactable")
	var label := get_node_or_null("Prompt") as Label
	if label != null:
		label.text = prompt


func available() -> bool:
	return true


func use() -> void:
	pass
