extends SceneTree
## Run this external harness against --main-pack from an empty working directory.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/tide-picker-action36/animations.json"))
	var actions: Dictionary = manifest.actions
	var textures: Dictionary = {}
	for key: String in actions:
		for layer_id: String in ["body", "fx"]:
			var layer: Variant = actions[key].get(layer_id)
			if layer == null: continue
			var texture: Texture2D = load(str(layer.texture)) as Texture2D
			if texture == null:
				quit(1)
				return
			textures[str(layer.texture)] = true
	var scene: PackedScene = load("res://content/whalebelly/main.tscn") as PackedScene
	var host: Node2D = scene.instantiate()
	host.qa = true
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	for frame: int in 20: await physics_frame
	for index: int in 7:
		host.load_room(index, [], false)
		for frame: int in 10: await physics_frame
		var player: TidePlayer = host.player
		if player.run_visual.available.values().has(false):
			printerr("Unavailable packed action in room ", index + 1)
			quit(1)
			return
		for clip: Array in player.textures.values():
			for texture: Texture2D in clip:
				if texture.resource_path != "res://art/whalebelly/animations/player/body/idle/000.png":
					printerr("Unexpected legacy texture in room ", index + 1)
					quit(1)
					return
	if ResourceLoader.exists("res://content/whalebelly/test/PlayerTest.tscn"):
		printerr("Development scene leaked into release")
		quit(1)
		return
	print("PACKAGED PASS ", actions.size(), " action definitions, ", textures.size(), " body/FX atlases; seven rooms; idle seed only; development scene absent")
	await host.graceful_quit()
