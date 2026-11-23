extends SceneTree
## 正常首页真实Enter开始新档，验证开场自动触发；仅删除本夹具专用档。
class OpeningHost extends WhalebellyMain:
	func save_path() -> String: return 'user://whalebelly/cinematic-opening-menu-qa.json'
var host: WhalebellyMain
func _initialize() -> void: run.call_deferred()
func press(code: Key, down: bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.remove_absolute('user://whalebelly/cinematic-opening-menu-qa.json')
	host=load('res://content/whalebelly/main.tscn').instantiate()
	host.set_script(OpeningHost)
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	for i: int in 40: await process_frame
	print('OPENING_MENU page=',host.player_ui.page_id,' focus=',root.gui_get_focus_owner().name)
	press(KEY_ENTER,true)
	for i: int in 3: await process_frame
	press(KEY_ENTER,false)
	var seen: bool=false
	for i: int in 600:
		await process_frame
		if host.story.cinematic.active:
			seen=true
			break
	print('OPENING_AUTO movie=',seen,' stage=',host.story.stage().get('id'),' paused=',paused)
	if seen:
		for i: int in 50: await process_frame
		if DisplayServer.get_name()!='headless':
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png('res://build/qa/cinematic-opening-real-menu.png')
		host.story.cinematic.skip()
		for i: int in 65: await process_frame
	var dialogue: bool=not host.dialogue.active.is_empty()
	print('OPENING_DIALOGUE active=',dialogue,' stage=',host.story.stage().get('id'))
	host.dialogue.cancel()
	host.player_ui.close_all()
	for i: int in 15: await process_frame
	await host.graceful_quit(0 if seen and dialogue else 1)
