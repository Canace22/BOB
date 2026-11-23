extends SceneTree
## 正式首页空档/续档及护盾排版；只使用本夹具专属路径。
class ProbeHost extends WhalebellyMain:
	func save_path() -> String:
		return "user://whalebelly/title-shield-isolated.json"

var host: WhalebellyMain
var failures: int=0
var output: String="res://build/qa/title-shield"

func _initialize() -> void:
	run.call_deferred()

func frames(count: int=5) -> void:
	for i: int in count: await process_frame

func check(label: String, passed: bool) -> void:
	print(("PASS " if passed else "FAIL ")+label)
	if not passed: failures+=1

func screenshot(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	for suffix: String in ["", ".bak", ".before-new"]:
		DirAccess.remove_absolute("user://whalebelly/title-shield-isolated.json"+suffix)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(ProbeHost)
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await frames(90)
	var ui: WhaleCampaignUI=host.player_ui
	check("Empty profile title does not create a save",not FileAccess.file_exists(host.save_path()))
	check("Empty profile has Start and no Continue",ui.body.find_child("Continue",true,false)==null and (ui.body.find_child("NewGame",true,false) as Button).text=="开始旅程")
	await screenshot("01-clean-title")
	# 使用正式焦点按钮和真实键盘事件启动；不直接调用保存接口伪装新旅途。
	(ui.body.find_child("NewGame",true,false) as Button).grab_focus()
	for pressed: bool in [true,false]:
		var event:=InputEventKey.new()
		event.physical_keycode=KEY_ENTER
		event.keycode=KEY_ENTER
		event.pressed=pressed
		Input.parse_input_event(event)
		await frames(3)
	await frames(30)
	check("Keyboard Start creates valid isolated journey",host.ui_session_started and not WhaleUISaveAccess.read(host.save_path(),host.rooms).is_empty())
	# 新旅途自动开场会暂停对话；先收回该模态再检查返回首页，避免测到被对话拒绝的open。
	# 主干新增过场会阻止打开菜单；本UI夹具先结束演出，不将其时长作为续档判定。
	host.story.enabled=false
	host.story.cinematic.cancel()
	host.dialogue.cancel()
	host.dialogue.enabled=false
	ui.open("title")
	await frames()
	check("Existing profile offers Continue",ui.body.find_child("Continue",true,false)!=null)
	await screenshot("02-saved-title")
	ui.close_all()
	await frames(20)
	# 显示夹具只配置护盾奖励，截图与正常获取路线分开记录。
	host.collected["R1-03"]=true
	host.relics.refill(host.collected)
	ui.show_notice("当前章节 · 胃室的回水")
	ui.notice_left=30.0
	await frames()
	check("Shield row expands status bounds",ui.hud.vitals.has_shields() and ui.hud.vitals.content_bottom()==133.0)
	check("Shield icon uses a real bitmap region",WhaleActionHUDStyle.region("guard").size.x>1)
	await screenshot("03-shield-notice")
	host.relics.charges=1
	await screenshot("04-shield-one-left")
	host.relics.charges=0
	await screenshot("05-shield-empty")
	for suffix: String in ["", ".bak", ".before-new"]:
		DirAccess.remove_absolute(host.save_path()+suffix)
	await host.graceful_quit(1 if failures else 0)
