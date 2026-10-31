class_name LoadMembrane
extends Node
## The authored shelf and its collision move together; no new geometry is drawn.

@export var shelf: StaticBody2D
var load_time: float = 0.0
var origin: Vector2
var offset: float = 0.0


func _ready() -> void:
	origin = shelf.position


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var loaded := player.is_on_floor() and player.position.x > origin.x and player.position.x < origin.x + 384 and absf(player.position.y - shelf.position.y) < 10
	load_time = load_time + delta if loaded else 0.0
	var next := move_toward(offset, 20.0 if load_time >= 0.7 else 0.0, delta * 22)
	if loaded:
		player.position.y += next - offset
	offset = next
	shelf.position.y = origin.y + offset
