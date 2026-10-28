class_name GameBoot
extends Node
## Explicit prototype entry; the default route keeps the campaign.


func _ready() -> void:
	var prototype := OS.get_cmdline_user_args().has("--crab-prototype")
	if OS.has_feature("web"):
		prototype = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('prototype') === 'crab' || location.pathname.includes('/godot-boss/')"))
	var path := "res://src/prototype/crab_arena.tscn" if prototype else "res://src/main/main.tscn"
	add_child((load(path) as PackedScene).instantiate())
