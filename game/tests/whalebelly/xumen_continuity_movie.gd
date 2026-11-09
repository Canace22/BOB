extends SceneTree
## Real engine environmental reel; room loads after the first door are previews.
var host: WhalebellyMain
func _initialize() -> void:run.call_deferred()
func tick(count:int) -> void:
	for frame in count:await process_frame
func run() -> void:
	host=(load("res://content/whalebelly/main.tscn") as PackedScene).instantiate()
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	var note:=Label.new()
	note.position=Vector2(24,170)
	note.text="须门遗港 · 场景接入实机展示（后续房间切换为预览）"
	note.add_theme_color_override("font_outline_color",Color.BLACK)
	note.add_theme_constant_override("outline_size",5)
	host.ui.add_child(note)
	await tick(24)
	Input.action_press("tp_right")
	await tick(170)
	Input.action_release("tp_right")
	await tick(30)
	for index:int in [1,2,3,4,5,6]:
		host.load_room(index,[],false)
		await tick(20)
		Input.action_press("tp_right")
		await tick(30)
		Input.action_release("tp_right")
		await tick(38)
	host.player_ui.open("map")
	await tick(96)
	await host.graceful_quit()
