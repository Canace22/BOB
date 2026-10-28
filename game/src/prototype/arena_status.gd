class_name CrabArenaStatus
extends Node
## Read-only status. All browser interactions still use actual keys/buttons.

var callback: JavaScriptObject
@onready var arena: CrabArena = get_parent() as CrabArena


func _ready() -> void:
	if OS.has_feature("web"):
		callback = JavaScriptBridge.create_callback(_snapshot)
		var window := JavaScriptBridge.get_interface("window")
		window.bob_snapshot = callback
		JavaScriptBridge.eval("window.render_game_to_text = () => { window.bob_snapshot(); return window.bob_state_json; };")


func snapshot() -> Dictionary:
	var p := arena.player
	return {"room": "prototype.crab", "stage": arena.stage, "paused": get_tree().paused,
		"hp": GameState.hp, "energy": GameState.energy, "time": arena.battle_time,
		"dash_enabled": arena.dash_enabled, "freeze": arena.freeze_left,
		"save_enabled": GameState.autosave, "flags": GameState.flags,
		"player": {"x": p.position.x, "y": p.position.y, "floor": p.is_on_floor(),
			"mode": p.actions.mode, "kind": p.actions.attack_kind, "elapsed": p.actions.elapsed,
			"facing": p.facing, "dead": p.dead}, "boss": arena.boss.snapshot()}


func _snapshot(_arguments: Array) -> void:
	var window := JavaScriptBridge.get_interface("window")
	window.bob_state_json = JSON.stringify(snapshot())
