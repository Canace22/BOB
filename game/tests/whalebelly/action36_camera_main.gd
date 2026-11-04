extends SceneTree
## Shared main scene and isolated save. Checks camera modes, limits and room changes.
var host: Node2D
var checks: Array[Dictionary] = []
func _initialize() -> void: run.call_deferred()
func tick(count: int) -> void:
	for frame: int in count: await physics_frame
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	print("CAMERA ","PASS " if passed else "FAIL ",label)
func tab() -> void:
	for pressed: bool in [true,false]:
		var event := InputEventKey.new()
		event.physical_keycode=KEY_TAB;event.keycode=KEY_TAB;event.pressed=pressed
		Input.parse_input_event(event);Input.flush_buffered_events()
		await tick(2)
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.qa=true;host.integration_external_test=true
	root.add_child(host);current_scene=host
	await tick(30)
	for index: int in host.rooms.size():
		host.load_room(index);host.player.automatic_doors=false
		host.player.invulnerable=99.0
		await tick(60)
		var id: String=str(host.room.id)
		check(id+"_default_follows",host.camera.was_following)
		check(id+"_body_scale",host.camera.zoom.x>=.95 and host.camera.zoom.x<=1.1)
		var world: Vector2=host.point(host.room.size)
		for corner: Vector2 in [Vector2.ZERO,world]:
			host.player.position=corner;host.camera.tracked_room="fixture-reset"
			host.camera_feedback=.18;host.camera.update_follow(1.0/60.0)
			var half: Vector2=host.camera.get_viewport_rect().size/(2*host.camera.zoom)
			var center: Vector2=host.camera.position+host.camera.offset
			check(id+"_bounded_"+str(corner),center.x-half.x>=-.01 and center.y-half.y>=-.01 and center.x+half.x<=world.x+.01 and center.y+half.y<=world.y+.01)
		host.player.position=host.point(host.room.get("play_spawn",host.room.spawn))
		await tab()
		check(id+"_tab_panorama",not host.camera.was_following)
		await tab();await tick(60)
		check(id+"_tab_restores_follow",host.camera.was_following and host.camera.zoom.x>=.95)
		for mode: String in ["reference","capture","layer"]:
			host.reference_visible=mode=="reference"
			host.capture_path="qa-no-render.png" if mode=="capture" else ""
			host.layer_solo=0 if mode=="layer" else -1
			host.camera.update_follow(.016)
			check(id+"_"+mode+"_fit",not host.camera.was_following and host.camera.offset==Vector2.ZERO)
			host.capture_path="";host.layer_solo=-1;host.reference_visible=false
	var failed: int=checks.filter(func(row: Dictionary) -> bool:return not row.pass).size()
	FileAccess.open("res://build/qa/action36/camera-main.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"))
	await host.graceful_quit(1 if failed else 0)
