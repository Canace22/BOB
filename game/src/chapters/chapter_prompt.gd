class_name ChapterPrompt
extends Label


func _ready() -> void:
	z_index = 20
	add_theme_font_size_override("font_size", 17)
	add_theme_color_override("font_outline_color", Color(0.04, 0.09, 0.11))
	add_theme_constant_override("outline_size", 4)
	position.x = maxf(position.x, 24 - get_parent().position.x)


func _process(_delta: float) -> void:
	var actor := get_tree().get_first_node_in_group("player") as Player
	var interaction := get_parent() as Interactable
	visible = false
	if actor == null or not interaction.available():
		return
	var distance := actor.global_position.distance_to(interaction.global_position)
	if distance >= interaction.radius:
		return
	# Match the nearest available target selected by Player.interact().
	for node in get_tree().get_nodes_in_group("interactable"):
		var other := node as Interactable
		if other == interaction or not other.available():
			continue
		var other_distance := actor.global_position.distance_to(other.global_position)
		if other_distance < other.radius and other_distance < distance:
			return
	visible = true
