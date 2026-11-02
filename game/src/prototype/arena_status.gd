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
		"hp": GameState.hp, "max_hp": arena.player.health.maximum,
		"energy": GameState.energy, "time": arena.battle_time,
		"skills": arena.skills.snapshot(),
		"help_visible": (arena.get_node("UI") as CrabArenaUI).help_panel.visible,
		"environment": _environment_snapshot(),
		"dash_enabled": arena.dash_enabled, "freeze": arena.freeze_left,
		"save_enabled": GameState.autosave, "flags": GameState.flags,
		"player": {"x": p.position.x, "y": p.position.y, "floor": p.is_on_floor(),
			"mode": p.actions.mode, "kind": p.actions.attack_kind, "elapsed": p.actions.elapsed,
			"facing": p.facing, "dead": p.dead, "invulnerable": p.invulnerable,
			"animation": (p.get_node("Visual") as PlayerVisual).animation_snapshot()},
		"boss": arena.boss.snapshot()}


func _environment_snapshot() -> Dictionary:
	var schools: Array[Dictionary] = []
	var baleen: Array[Dictionary] = []
	for node: Node in arena.get_node("World/Scenery/Environment/EnvironmentMotion").get_children():
		if node is AmbientFishSchool:
			var school := node as AmbientFishSchool
			schools.append({"species": school.species, "count": school.fish.size(),
				"time": school.elapsed, "frame": school.fish[0].frame,
				"position": [school.fish[0].position.x, school.fish[0].position.y],
				"texture": school.fish[0].texture.resource_path})
		elif node is AmbientAtlas:
			var sprite := node as AmbientAtlas
			baleen.append({"frame": sprite.frame, "time": sprite.elapsed,
				"texture": sprite.texture.resource_path})
	return {"schools": schools, "baleen": baleen}


func _snapshot(_arguments: Array) -> void:
	var window := JavaScriptBridge.get_interface("window")
	window.bob_state_json = JSON.stringify(snapshot())
