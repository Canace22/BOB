extends SceneTree
## Isolated QA: real main scene and parsed keyboard events; explicit fixtures for damage/Boss.
var host: WhalebellyMain
var ui: WhaleCampaignUI
var checks: Array[Dictionary] = []
var failure_count: int = 0
var output: String = "res://build/qa/ui-system"

func _initialize() -> void:
	run.call_deferred()

func step(count: int = 3) -> void:
	for i: int in range(count): await process_frame

func key(code: Key, pressed: bool = true) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code)
	await step(2)
	key(code,false)
	await step(3)

func check(label: String, value: bool) -> void:
	checks.append({"name":label,"pass":value})
	if not value: failure_count+=1
	print(("PASS " if value else "FAIL ")+label)

func screenshot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await step(8)
	await RenderingServer.frame_post_draw
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	host=load("res://content/whalebelly/main.tscn").instantiate() as WhalebellyMain
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	host.ui_interactive_in_tests=true
	root.add_child(host)
	current_scene=host
	ui=host.player_ui as WhaleCampaignUI
	ui.preferences.numbers=true
	ui.preferences.contrast=false
	ui.preferences.reduce_motion=false
	ui.preferences.apply(host)
	ui.panel.theme=WhaleUIStyle.theme(false)
	await step(100)
	check("HUD bound to real player",ui.player==host.player and ui.health_value==host.player.health)
	await screenshot("01-exploration")
	await tap(KEY_ESCAPE)
	var before: Vector2=host.player.position
	var before_clock: float=host.clock
	var cooldown: float=host.player.cooldowns.orb
	key(KEY_D)
	await step(20)
	check("Pause freezes player, world and cooldown",paused and host.player.position==before and host.clock==before_clock and host.player.cooldowns.orb==cooldown)
	await screenshot("02-pause")
	await tap(KEY_ESCAPE)
	await step(20)
	check("Held gameplay input cannot leak on resume",paused and ui.pending_resume and host.player.position==before)
	key(KEY_D,false)
	await step(25)
	check("Release restores gameplay",not paused and host.player.controls_enabled)
	await tap(KEY_ESCAPE)
	ui.open("settings")
	var contrast: CheckButton=ui.body.find_child("Contrast",true,false) as CheckButton
	contrast.button_pressed=true
	var motion: CheckButton=ui.body.find_child("Motion",true,false) as CheckButton
	motion.button_pressed=true
	var volume: HSlider=ui.body.find_child("Volume",true,false) as HSlider
	volume.value=37
	await step()
	check("Settings apply actual audio and camera",is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)),0.37) and host.camera.shake_pixels==0 and host.camera.dash_zoom==1)
	var reloaded := WhaleUIPreferences.new()
	reloaded.path=ui.preferences.path
	reloaded.read()
	check("Settings reload",reloaded.contrast and reloaded.reduce_motion and is_equal_approx(reloaded.volume,0.37))
	await screenshot("03-settings")
	await tap(KEY_ESCAPE)
	check("Settings return to pause",ui.page_id=="pause")
	await tap(KEY_ESCAPE)
	await step(25)
	await tap(KEY_C)
	check("Map known rooms only",ui.page_id=="map" and ui.data.map_rooms().size()==2)
	await screenshot("04-map")
	await tap(KEY_ESCAPE)
	await step(25)
	check("Map returns to gameplay",ui.page_id.is_empty() and not paused)
	var old_camera: bool=host.reference_follow
	await tap(KEY_TAB)
	check("Tab camera preserved",host.reference_follow!=old_camera)
	await tap(KEY_TAB)
	host.player.position=host.point(ui.data.camp_position())
	host.player.soul=44
	host.player.health=3
	host.health=3
	await step(20)
	await tap(KEY_E)
	await step(50)
	check("Camp restores life without inventing energy",ui.page_id=="camp" and host.player.health==5 and host.player.soul==44 and host.last_save_ok)
	await screenshot("05-camp")
	ui.close_all()
	await step(25)
	host.player.take_damage(1,Vector2.ZERO,true)
	await step(3)
	check("Damage reflected in leaves",ui.health_value==4 and host.player.soul==11)
	await screenshot("06-damaged")
	await step(45)
	await tap(KEY_P)
	check("Insufficient-resource feedback",ui.notice_text.contains("不足") and host.player.state!="recover")
	# Explicit fixture: available resource and a safe landing for the real heal action.
	host.player.soul=99
	host.player.stats_changed.emit(host.player.health,host.player.soul)
	await step(30)
	await tap(KEY_P)
	check("Healing consumes actual cost",host.player.state=="recover" and host.player.soul==66)
	await screenshot("07-healing")
	await step(100)
	check("Healing matches campaign amount",host.player.health==5)
	host.player.take_damage(1,Vector2.ZERO,true)
	await step(20)
	host.player.cooldowns.heal=0
	await tap(KEY_P)
	host.player.take_damage(1,Vector2.ZERO,true)
	await step(100)
	check("Interrupted healing does not refund or restore",host.player.health==3 and host.player.soul==0)
	host.checkpoint={"room":0,"pos":[120,host.ground_y(120,550)]}
	host.player.take_damage(5,Vector2.ZERO,true)
	await step(195)
	check("Death opens modal once",ui.page_id=="death" and paused and host.health==0)
	await screenshot("08-death")
	await tap(KEY_R)
	await step(30)
	check("Retry rebinds full player state",ui.player==host.player and host.player.health==5 and host.player.soul==99 and not paused)
	host.player.take_damage(5,Vector2.ZERO,true)
	await step(195)
	await tap(KEY_R)
	await step(30)
	check("Second death retries without duplicate UI",ui.player==host.player and host.player.health==5 and ui.page_id.is_empty() and not paused)
	host.load_room(3)
	await step(20)
	check("Boss HUD binds living Boss",not ui.data.boss().is_empty())
	await screenshot("09-boss")
	for enemy: Dictionary in host.enemies:
		if enemy.boss: host.damage_enemy(enemy,int(enemy.max_hp))
	await step()
	check("Boss HUD disappears after victory",ui.data.boss().is_empty())
	host.load_room(0)
	host.save_progress(false)
	var saved: Dictionary=WhaleUISaveAccess.read(host.save_path(),host.rooms)
	check("Discovery persists with V6",saved.version==6 and saved.visited.has("R1-04") and not saved.visited.has("R1-07"))
	ui.open("title")
	await step()
	check("Continue reflects valid save",not (ui.body.find_child("Continue",true,false) as Button).disabled)
	await screenshot("10-title")
	ui.open("confirm_new")
	await screenshot("11-new-confirm")
	ui.back()
	check("Cancel new game preserves file",WhaleUISaveAccess.read(host.save_path(),host.rooms).defeated==saved.defeated)
	ui.start_game(true)
	await step(25)
	check("Confirmed new game resets and backs up",host.room_index==0 and host.defeated.is_empty() and FileAccess.file_exists(host.save_path()+".before-new"))
	# Native window dimensions are monitor-clamped; ultrawide is checked in Chromium.
	for window: Vector2i in [Vector2i(1920,1080),Vector2i(1280,720)]:
		root.size=window
		ui.open("settings")
		await step(8)
		check("Settings fits "+str(window),ui.body.get_global_rect().end.x<=ui.panel.size.x and ui.footer.get_global_rect().end.y<=ui.panel.size.y)
		await screenshot("settings-"+str(window.x))
		ui.back()
		await step(15)
	for i: int in range(6):
		ui.open("pause")
		ui.open("settings")
		ui.back()
		ui.close_all()
		await step(15)
	check("Repeated menus retain one UI and binding",ui.player==host.player and ui.page_id.is_empty() and not paused)
	var file:=FileAccess.open(output.path_join("runtime-checks.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failure_count,"fixtures":"QA scene; explicit damage/resource/Boss setup, no real save used"},"\t"))
	await host.graceful_quit(1 if failure_count>0 else 0)
