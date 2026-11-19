extends "res://src/campaign/main.gd"
## 可反复试玩的开场样板；独立存档，不导入或覆盖用户主线进度。
func _init() -> void:
	qa=true
	qa_full_abilities=false
	integration_external_test=true
	ui_interactive_in_tests=true
func save_path() -> String:
	return "user://whalebelly/dialogue-manual-"+ProjectSettings.globalize_path("res://").sha256_text().left(12)+".json"
func _ready() -> void:
	super._ready()
	dialogue.enabled=true
	DisplayServer.window_set_title("鲸落万物生 · 开场引导试玩")
	print("DIALOGUE_PLAY_READY isolated_save=",save_path())
