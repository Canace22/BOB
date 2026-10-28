extends Node
## Desktop visual verification with an isolated progress file. Never touches the user's save.


func _ready() -> void:
	GameState.save_path = "user://manual-preview.json"
	GameState.autosave = false
	GameState.apply(SaveService.default_data())
	add_child((load("res://src/main/main.tscn") as PackedScene).instantiate())
