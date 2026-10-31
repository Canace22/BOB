class_name CampaignWebStatus
extends Node
## Read-only observation for the recovered campaign. It cannot mutate gameplay.
var host: Node2D
var callback: JavaScriptObject

func _ready() -> void:
	if not OS.has_feature("web"):
		return
	callback = JavaScriptBridge.create_callback(_snapshot)
	var window := JavaScriptBridge.get_interface("window")
	window.whalebelly_snapshot = callback
	JavaScriptBridge.eval("window.render_game_to_text = () => { window.whalebelly_snapshot(); return window.whalebelly_state_json; };")

func snapshot() -> Dictionary:
	var enemies: Array[Dictionary] = []
	for enemy: Dictionary in host.enemies:
		enemies.append({"x": enemy.pos.x, "y": enemy.pos.y, "boss": enemy.boss, "hp": enemy.hp, "alive": enemy.alive})
	return {
		"campaign": "WhalebellyRuins", "room": host.room.id,
		"hp": host.health, "soul": host.player_soul, "completed": host.completed,
		"abilities": host.abilities, "paused": get_tree().paused,
		"checkpoint": host.checkpoint,
		"player": {"x": host.player.position.x, "y": host.player.position.y,
			"floor": host.player.is_on_floor(), "state": host.player.state,
			"facing": host.player.facing, "controls_enabled": host.player.controls_enabled},
		"enemies": enemies,
	}

func _snapshot(_arguments: Array) -> void:
	var window := JavaScriptBridge.get_interface("window")
	window.whalebelly_state_json = JSON.stringify(snapshot())
