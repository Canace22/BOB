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
	var environment := host.scenery.get_node_or_null("ChapterEnvironment") as ChapterRoomEnvironment
	var ambience: AudioStreamPlayer=host.scenery.get_node_or_null("EnvironmentMotion/WaterAmbience")
	var audio_state: Dictionary={"playing":false,"playback_type":-1,"muted":AudioServer.is_bus_mute(0)}
	if ambience!=null:
		audio_state.merge({"playing":ambience.playing,"playback_type":ambience.playback_type,"paused":ambience.stream_paused},true)
	var environment_state: Dictionary = {}
	if environment != null:
		environment_state = {"room":environment.room_id,"time":environment.elapsed,"counts":environment.content_counts()}
	var enemies: Array[Dictionary] = []
	for enemy: Dictionary in host.enemies:
		enemies.append({"x": enemy.pos.x, "y": enemy.pos.y, "boss": enemy.boss, "hp": enemy.hp, "alive": enemy.alive})
	return {
		"campaign": "WhalebellyRuins", "room": host.room.id,
		"hp": host.health, "soul": host.player_soul, "completed": host.completed,
		"abilities": host.abilities, "paused": get_tree().paused,
		"ui": {"page":host.player_ui.page_id,"pending_resume":host.player_ui.pending_resume,
			"numbers":host.player_ui.preferences.numbers,"contrast":host.player_ui.preferences.contrast,
			"reduce_motion":host.player_ui.preferences.reduce_motion,"visited":host.visited,
			"save_ok":host.last_save_ok,"map_nodes":host.player_ui.data.map_rooms(),
			"controls":host.player_ui.control_snapshot(),"width":host.player_ui.panel.size.x,"height":host.player_ui.panel.size.y},
		"checkpoint": host.checkpoint,
		"camera": {"x":host.camera.position.x,"y":host.camera.position.y,
			"zoom":host.camera.zoom.x,"following":host.camera.was_following,
			"offset_x":host.camera.offset.x,"offset_y":host.camera.offset.y,
			"room_width":host.room.size[0],"room_height":host.room.size[1]},
		"player": {"x": host.player.position.x, "y": host.player.position.y,
			"floor": host.player.is_on_floor(), "state": host.player.state,
			"facing": host.player.facing, "controls_enabled": host.player.controls_enabled,
			"skill_active":host.player.skill_controller.active,
			"skill_key":host.player.skill_controller.visual_key,
			"skill_elapsed":host.player.skill_controller.elapsed,
			"attack_id":host.player.skill_controller.attack_id},
		"enemies": enemies,
		"audio": audio_state,
		"environment": environment_state,
	}

func _snapshot(_arguments: Array) -> void:
	var window := JavaScriptBridge.get_interface("window")
	window.whalebelly_state_json = JSON.stringify(snapshot())
