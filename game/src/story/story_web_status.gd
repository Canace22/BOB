class_name StoryWebStatus
extends Node
## Read-only browser observation; no mutation/teleport hooks are exported.

var host: StoryMain
var callback: JavaScriptObject

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		callback = JavaScriptBridge.create_callback(_snapshot)
		JavaScriptBridge.get_interface("window").story_snapshot = callback
		JavaScriptBridge.eval("window.render_game_to_text=()=>{window.story_snapshot();return window.story_state_json;};")

func snapshot() -> Dictionary:
	var controls: Array[Dictionary] = []
	for child: Node in host.ui.body.get_children():
		if child is Button:
			var rect: Rect2 = child.get_global_rect()
			controls.append({"text":child.text,"x":rect.get_center().x,"y":rect.get_center().y})
	var enemies: Array[Dictionary] = []
	for enemy: StoryForager in host.foragers: enemies.append(enemy.snapshot())
	return {"campaign":"story-c01","room":StoryProgress.ROOM_ID,"flags":host.progress.flags,
		"save_path":host.progress.path,"save_error":host.progress.last_error,"paused":get_tree().paused,
		"pending_resume":host.pending_resume,"player":{"x":host.player.position.x,"y":host.player.position.y,
		"health":host.player.health,"floor":host.player.is_on_floor(),"state":host.player.state,
		"facing":host.player.facing,"controls_enabled":host.player.controls_enabled},
		"ui":{"page":host.ui.page,"line":host.ui.dialogue_index,"dialogue":host.ui.dialogue_id,
		"objective":host.ui.objective_label.text,"notice":host.ui.notice_label.text,"controls":controls},
		"mender":{"x":host.mender.position.x,"y":host.mender.position.y,"action":str(host.mender.current_action),"frame":host.mender.frame},
		"enemies":enemies,"camera":{"x":host.camera.position.x,"zoom":host.camera.zoom.x},
		"audio":{"ambience":host.audio.ambience.playing,"muted":AudioServer.is_bus_mute(0)},"events":host.events}

func _snapshot(_arguments: Array) -> void:
	JavaScriptBridge.get_interface("window").story_state_json = JSON.stringify(snapshot())
