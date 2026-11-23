extends SceneTree
## 分段起点夹具；过场自然播放、镜头截图和清理取证，不冒充连续章节通关。
class FilmHost extends WhalebellyMain:
	func save_path() -> String: return "user://whalebelly/cinematics-preview.json"
var host: WhalebellyMain
var selected: String=""
var stay: bool=false
var failures: int=0
func _initialize() -> void: run.call_deferred()
func tick(n: int) -> void:
	for i: int in n: await process_frame
func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--id="): selected=arg.trim_prefix("--id=")
		if arg=="--stay": stay=true
	root.size=Vector2i(1280,720)
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(FilmHost)
	host.qa=true
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(25)
	host.story.allow_in_tests=true
	host.story.set_process(false)
	host.ui_interactive_in_tests=true
	host.dialogue.enabled=true
	var plans: Dictionary=host.story.cinematic.plans
	for key: String in plans:
		if not selected.is_empty() and selected!=key: continue
		var prefix: Array[String]=[]
		var facts: Dictionary={}
		for stage: Dictionary in host.story.catalog.stages:
			if str(stage.id)==key or stage.get("tasks",[]).any(func(t: Dictionary) -> bool:return str(t.id)==key): break
			prefix.append(str(stage.id))
			for flag: String in stage.get("grant",[]): facts[flag]=true
			if stage.kind=="battle":
				facts[str(stage.id)+"_outcome"]="surrender" if stage.id=="ch12_elder_duel" else "kill"
		host.story.restore({"version":1,"completed":prefix,"facts":facts})
		var s: Dictionary=host.story.stage()
		var room: int=host.rooms.find_custom(func(r: Dictionary) -> bool:return str(r.id)==str(s.room_id))
		host.load_room(room,s.at)
		host.player_ui.close_all()
		host.player_ui.pending_resume=false
		host.player.controls_enabled=true
		paused=false
		await tick(60)
		var film: CampaignCinematic=host.story.cinematic
		var called: Array[bool]=[]
		if not film.play(key,func() -> void:called.append(true)):
			print("FILM_FAIL start ",key," available=",host.dialogue.available()," safe=",host.dialogue.safe_to_talk()," controls=",host.player.controls_enabled," page=",host.player_ui.page_id)
			failures+=1
			continue
		var captured: Dictionary={}
		var frames: Dictionary={}
		for frame: int in 2400:
			await tick(1)
			if not film.active: break
			if is_instance_valid(film.view.player_proxy) and film.view.player_proxy.visible: frames[film.view.player_proxy.texture]=true
			if is_instance_valid(film.view.guard_proxy): frames[film.view.guard_proxy.region_rect]=true
			if DisplayServer.get_name()!="headless" and film.clock>=1.0 and not captured.has(film.cursor) and film.returning<0:
				captured[film.cursor]=true
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://build/qa/cinematic-"+key+"-"+str(film.cursor)+".png")
		if film.active or paused or not host.player.controls_enabled or not host.camera.is_current() or called.size()!=1: failures+=1
		print("FILM_RESULT id=",key," shots=",captured.size()," sampled_poses=",frames.size()," callback=",called.size()," paused=",paused," active=",film.active)
	if stay:
		host.story.set_process(true)
		host.story.view.rebuild()
		DisplayServer.window_set_title("鲸落遗城 · 过场体验 · 独立档")
		return
	print("FILM_ALL failures=",failures)
	await host.graceful_quit(0 if failures==0 else 1)
