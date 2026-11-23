extends SceneTree
## 胃枢右岸与高层出口取证；定位仅为复现机位，不视为真实通关。
var host: WhalebellyMain
var failures: int=0
const OUT: String="res://build/qa/stomach-exit"

func _initialize() -> void: run.call_deferred()

func frames(count: int) -> void:
	for i: int in count: await physics_frame
	await process_frame

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))

func check(label: String, passed: bool) -> void:
	print(("PASS " if passed else "FAIL ")+label)
	if not passed: failures+=1

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.suite="stomach-exit"
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	var index: int=0
	for i: int in host.rooms.size():
		if str(host.rooms[i].id)=="R3-01": index=i
	host.load_room(index,[3760,2080])
	await frames(90)
	check("Lower shore explains the upper exit without an action key",host.player_ui.hud.interaction_prompt.message=="下层断岸 · 出口在上层" and host.player_ui.hud.interaction_prompt.action_key.is_empty())
	check("Map shows onward connection upper-right",WhaleCampaignMinimap.CELLS.R3["R4-01"].y<WhaleCampaignMinimap.CELLS.R3["R3-01"].y)
	print("LOWER ",host.player.position," READY ",host.streaming.cached.keys())
	await shot("01-lower-edge")
	for link: Dictionary in host.streaming.layout.links:
		if int(link.a)==index or int(link.b)==index:
			print("LINK ",host.rooms[link.a].id," -> ",host.rooms[link.b].id," local-from ",link.from-host.streaming.origin(index)," local-to ",link.to-host.streaming.origin(index))
	host.player.position=Vector2(3710,1360)
	host.player.velocity=Vector2.ZERO
	await frames(45)
	check("Upper exit has no lower-shore warning",CampaignGuidance.elevated_exit_hint(host).is_empty())
	print("UPPER ",host.player.position)
	await shot("02-upper-exit")
	# 独立夹具授予旧门所需潮压；这一腿只用D真实输入验证连接，不把定位当通关。
	host.abilities.pressure=true
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_D
	event.keycode=KEY_D
	event.pressed=true
	Input.parse_input_event(event)
	await frames(125)
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await frames(10)
	check("Actual upper connection reaches the loaded next room",str(host.room.id)=="R4-01")
	await shot("03-next-room")
	await host.graceful_quit(1 if failures else 0)
