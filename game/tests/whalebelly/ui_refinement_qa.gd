extends SceneTree
## 正式入口与隔离存档；站位/能力为显式夹具，移动、过门与菜单使用键盘事件。
const OUT := "res://build/qa/ui-refinement"
var host: WhalebellyMain
var ui: WhaleCampaignUI
var failures: int = 0
var checks: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()
func tick(count: int = 8) -> void:
	for i: int in count: await physics_frame
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func tap(code: Key) -> void:
	key(code,true)
	await tick(2)
	key(code,false)
	await tick(10)
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"pass":passed})
	if not passed: failures+=1
	print("PASS " if passed else "FAIL ",label)
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(OUT.path_join(label+".png"))
func resume() -> void:
	for i: int in 80:
		if not paused and not ui.pending_resume: return
		await tick(1)

func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUT)
	host=load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","ui-refinement")
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	host.ui_interactive_in_tests=true
	root.add_child(host)
	current_scene=host
	await tick(45)
	ui=host.player_ui as WhaleCampaignUI
	ui.preferences.path="user://whalebelly/ui-refinement-settings.cfg"
	ui.preferences.numbers=false
	ui.preferences.contrast=false
	var map: WhaleCampaignMinimap=ui.hud.minimap
	check("Native QA uses isolated progress",host.save_path().contains("ui-refinement"))
	check("Start plan shows only its real exit",map.exits.size()==1 and map.exits[0].target==1)
	await tick(250)
	await shot("01-exploration")
	var before: Vector2=map.project(map.player_point())
	key(KEY_D,true)
	await tick(18)
	key(KEY_D,false)
	check("Walking moves the actual room marker",map.project(map.player_point()).x>before.x+1)
	await tap(KEY_C)
	check("C keeps the whale anatomy map available",ui.page_id=="map" and not ui.hud.is_visible_in_tree())
	await shot("02-region-map")
	await tap(KEY_ESCAPE)
	await resume()
	await tap(KEY_ESCAPE)
	check("Pause gives its primary action keyboard focus",ui.page_id=="pause" and root.gui_get_focus_owner().name=="Resume")
	await shot("03-pause")
	await tap(KEY_ENTER)
	await resume()
	check("Enter returns from pause without a gameplay action",ui.page_id.is_empty() and not paused)
	# 复用当前首门末段平台作为起点；过连接段只按D，不按E或写入位置。
	var door: Dictionary=host.room.doors[0]
	var lane: Dictionary=host.room.layout.checkpoint_lanes.filter(func(value: Dictionary) -> bool: return float(value.x[0])<float(door.pos[0]) and float(value.x[1])>float(door.pos[0]) and absf(float(value.y)-float(door.pos[1]))<24)[0]
	host.player.position=Vector2(float(lane.x[0])+4,float(lane.y)-4)
	host.player.velocity=Vector2.ZERO
	await tick(15)
	var identity: int=host.player.get_instance_id()
	key(KEY_D,true)
	for i: int in 600:
		await tick(1)
		if host.room_index==1: break
	key(KEY_D,false)
	await tick(25)
	check("Real walking crosses the first connection with the same player",host.room_index==1 and host.player.get_instance_id()==identity)
	check("Junction plan separates upper branches from lower main exits",map.exits.size()==4 and map.exits[2].point.y<map.exits[0].point.y and map.exits[3].point.y<map.exits[1].point.y)
	await shot("04-junction")
	# 胃枢站位夹具：验证门高差与实体强流门，不声称从开局自然走到这里。
	host.load_room(7,[1347,2080],false)
	await tick(50)
	check("Hub plan keeps the strong-current exit 720px above lower return",is_equal_approx(map.exits[0].point.y-map.exits[2].point.y,720))
	check("Missing pressure is marked closed on that actual exit",map.exits[2].blocked)
	await shot("05-hub-exits")
	var gates:=host.streaming.gates as CampaignStreamingGates
	var entry: Dictionary=gates.entries.filter(func(item: Dictionary) -> bool: return item.source==7 and CampaignWorld.requirements(item.door).has("pressure"))[0]
	var foot: Vector2=entry.body.global_position
	host.player.global_position=foot-Vector2(260,10)
	host.player.velocity=Vector2.ZERO
	host.player.invulnerable=100
	await tick(15)
	key(KEY_D,true)
	for frame: int in 240:
		await tick(1)
		if ui.hud.interaction_prompt.blocked and ui.hud.interaction_prompt.message=="需要潮压": break
	key(KEY_D,false)
	await tick(15)
	check("Approaching the actual upper gate retains the pressure explanation",host.player.global_position.x<foot.x and ui.hud.interaction_prompt.blocked and ui.hud.interaction_prompt.message=="需要潮压")
	await shot("06-upper-gate")
	host.abilities.pressure=true
	await tick(20)
	check("Grant fixture clears the map lock without changing room discovery",not map.exits[2].blocked)
	# 原有居民对话由F打开；测试焦点、退出和共用面板，不增加剧情。
	host.load_room(7,[1347,2080],false)
	await tick(40)
	await tap(KEY_F)
	await tick(40)
	check("Physical F opens the authored resident conversation",ui.page_id=="conversation")
	if ui.page_id=="conversation":
		check("Reading hides the minimap and routine controls",not map.visible and not ui.hud.map_button.visible)
		check("Conversation uses the shared dialogue bounds",ui.frame.get_rect().is_equal_approx(WhaleUIStyle.dialogue_rect(ui.panel.size,"\n".join(ui.conversation_lines),120)))
		var reading_area:=ui.body.get_parent() as ScrollContainer
		check("Short reading keeps its return button fully visible",not reading_area.get_v_scroll_bar().visible and reading_area.get_global_rect().encloses(ui.body.find_child("ConversationClose",true,false).get_global_rect()))
		await shot("07-conversation")
		await tap(KEY_SPACE)
		await resume()
		check("Space closes reading without jumping",ui.page_id.is_empty() and host.player.jump_buffer==0)
	# 开场剧情使用正式触发器，清空的只是本专项叙事状态。
	host.load_room(0)
	host.dialogue.restore({})
	host.dialogue.enabled=true
	for i: int in 150:
		await tick(1)
		if ui.page_id=="dialogue": break
	await tick(15)
	check("Authored opening starts in the unified dialogue panel",ui.page_id=="dialogue")
	if ui.page_id=="dialogue":
		check("Story initially focuses Continue",ui.dialogue_view.next_button.has_focus())
		await tap(KEY_ENTER)
		check("First Enter reveals without skipping the current line",host.dialogue.cursor==0 and ui.dialogue_view.text_label.visible_characters==ui.dialogue_view.text_label.get_total_character_count())
		await shot("08-story")
		check("Short story keeps a compact readable panel",ui.dialogue_view.panel.size.x<=760 and ui.dialogue_view.panel.size.y<=180)
		var original: String=ui.dialogue_view.text_label.text
		var speaker: String=ui.dialogue_view.speaker_label.text
		# 只重复呈现文本作为溢出夹具，不推进或替换主线剧情。
		ui.dialogue_view.present(speaker,original.repeat(20))
		ui.dialogue_view.text_label.visible_characters=-1
		ui.dialogue_view.reveal=float(ui.dialogue_view.text_label.get_total_character_count())
		await tick(15)
		check("Long story expands without covering the world",ui.dialogue_view.panel.size.y<=224 and ui.dialogue_view.text_label.get_v_scroll_bar().max_value>ui.dialogue_view.text_label.size.y)
		var wheel:=InputEventMouseButton.new()
		wheel.position=ui.dialogue_view.text_label.get_global_rect().get_center()
		wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed=true
		Input.parse_input_event(wheel)
		await tick(4)
		check("Mouse wheel scrolls overflowing dialogue",ui.dialogue_view.text_label.get_v_scroll_bar().value>0)
		await shot("08b-long-story")
		ui.dialogue_view.present(speaker,original)
		await tick(15)
		await tap(KEY_TAB)
		check("Tab reaches the story Skip button",ui.dialogue_view.skip_button.has_focus())
		await tap(KEY_ESCAPE)
		check("One Escape cannot skip unread narrative",ui.page_id=="dialogue" and ui.dialogue_view.skip_pending and not host.dialogue.seen.get("opening.arrival",false))
		await shot("09-skip-confirm")
		await tap(KEY_F)
		check("Continuing cancels the skip and restores Continue focus",not ui.dialogue_view.skip_pending and ui.dialogue_view.next_button.has_focus())
		await tick(15)
		key(KEY_D,true)
		await tap(KEY_ESCAPE)
		await tap(KEY_ESCAPE)
		check("Confirmed skip still waits for held gameplay keys",ui.pending_resume and paused and not host.player.controls_enabled)
		key(KEY_D,false)
		await resume()
		check("Key release restores gameplay and original narrative progress",not paused and host.player.controls_enabled and host.dialogue.seen.get("opening.arrival",false))
	host.dialogue.enabled=false
	# 缩小窗口与高对比，检查两种阅读面板、菜单恢复和控件可达。
	root.size=Vector2i(960,540)
	await tick(12)
	ui.open_conversation("刻痕",PackedStringArray(["在旧壳中，让潮声平息。"]),"qa.layout")
	ui.preferences.contrast=true
	WhaleUIPages.layout(ui)
	await tick(12)
	check("Small viewport keeps reading panel and primary action inside",ui.panel.get_global_rect().encloses(ui.frame.get_global_rect()) and ui.frame.get_global_rect().encloses(ui.body.find_child("ConversationClose",true,false).get_global_rect()))
	await shot("10-small-contrast")
	await tap(KEY_ESCAPE)
	await resume()
	await tap(KEY_ESCAPE)
	await tick(10)
	check("Returning to pause restores full-screen layout",ui.page_id=="pause" and not ui.frame.visible and ui.margin.offset_left==0)
	await shot("11-small-pause")
	await tap(KEY_ESCAPE)
	await resume()
	root.size=Vector2i(1280,720)
	ui.preferences.contrast=false
	host.load_room(3)
	await tick(40)
	check("Boss encounter hides routine menu buttons",not ui.hud.map_button.visible and not ui.hud.pause_button.visible)
	await shot("12-boss-hud")
	await tap(KEY_C)
	check("Combat shortcuts still open the map",ui.page_id=="map")
	await tap(KEY_ESCAPE)
	await resume()
	var file:=FileAccess.open(OUT.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"failed":failures,"checks":checks},"  "))
	file.close()
	print("UI_REFINEMENT_COMPLETE checks=",checks.size()," failed=",failures)
	await host.graceful_quit(0 if failures==0 else 1)
