class_name WebStatus
extends Node
## Read-only browser observability. Test drivers live in tests/ and send keyboard events.

@export var player: Player
var callback: JavaScriptObject


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	callback = JavaScriptBridge.create_callback(_snapshot)
	var window := JavaScriptBridge.get_interface("window")
	window.bob_snapshot = callback
	JavaScriptBridge.eval("window.render_game_to_text = () => { window.bob_snapshot(); return window.bob_state_json; };")


func _snapshot(_arguments: Array) -> void:
	var enemies: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as EnemyBase
		enemies.append({"x": enemy.position.x, "y": enemy.position.y, "boss": enemy.boss, "hp": enemy.health.current, "state": enemy.state, "timer": enemy.timer, "kind": enemy.kind})
	var from := player.global_position + Vector2(42, -8)
	var ray := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 30), 1)
	var state := {
		"room": GameState.current_room, "checkpoint": GameState.checkpoint_room,
		"hp": GameState.hp, "energy": GameState.energy,
		"abilities": GameState.abilities, "flags": GameState.flags,
		"paused": get_tree().paused, "arena_active": GameState.arena_active,
		"room_width": player.bounds.size.x,
		"player": {"x": player.position.x, "y": player.position.y, "floor": player.is_on_floor(),
			"dead": player.dead, "facing": player.facing, "mode": player.actions.mode,
			"elapsed": player.actions.elapsed, "kind": player.actions.attack_kind, "air_dash": player.actions.air_dash,
			"floor_ahead": not player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()},
		"enemies": enemies,
	}
	var window := JavaScriptBridge.get_interface("window")
	window.bob_state_json = JSON.stringify(state)
