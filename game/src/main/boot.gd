class_name GameBoot
extends Node
## Explicit prototype entry; the default route keeps the campaign.


func _ready() -> void:
	var prototype := OS.get_cmdline_user_args().has("--crab-prototype")
	if OS.has_feature("web"):
		prototype = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('prototype') === 'crab' || location.pathname.includes('/godot-boss/')"))
	var path := "res://src/prototype/crab_arena.tscn" if prototype else "res://src/main/main.tscn"
	var chapters := OS.get_cmdline_user_args().has("--chapters")
	if OS.has_feature("web"):
		chapters = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('chapters') === '1' || location.pathname.includes('/godot-chapters/')"))
	if chapters:
		path = "res://src/chapters/chapter_flow.tscn"
	add_child((load(path) as PackedScene).instantiate())
