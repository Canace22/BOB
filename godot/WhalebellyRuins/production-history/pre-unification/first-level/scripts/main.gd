extends Node2D
const GAME=preload("res://scripts/game.gd")
const LEVEL=preload("res://scripts/level.gd")
var game: Node
var level: Node2D
var rooms: Array
var ui: CanvasLayer
var hud: Label
var bottom: Label
var message_label: Label
var menu: PanelContainer
var menu_text: Label
var message_timer:=0.0
var finished:=false
var map_open:=false
var paused:=false
var changing:=false
var qa_mode:=""
var qa_step:=0
var qa_time:=0.0
var qa_jump_time:=-1.0
var qa_last_x:=0.0
var qa_stuck:=0.0
var qa_elapsed:=0.0
var frame_times: Array=[]
var overlay:=""
var evidence_dir:="res://evidence"
var capture_timer:=0.0
var capture_index:=0
var hint: Label
var finalizing:=false
var effect_counts: Dictionary={}
var scenery_preview:=false
var preview_camera:=Vector2.ZERO
var preview_return_room:=0
var preview_return_position:=Vector2.ZERO
var route_overlay:=false
var route_sandbox:=false
var preview_fit:=false
var inspector: Node
var atlas_panel: Control
var atlas_buttons: Array[Button]=[]

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	setup_inputs()
	game=Node.new()
	game.set_script(GAME)
	add_child(game)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa"): qa_mode=arg
		if arg.begins_with("--evidence-dir="): evidence_dir=arg.trim_prefix("--evidence-dir=")
	if qa_mode!="": DirAccess.make_dir_recursive_absolute(evidence_dir)
	game.qa=qa_mode!=""
	game.load_game()
	if qa_mode in ["--qa-e2e","--qa-render","--qa-combat","--qa-integration"]: game.reset_game()
	rooms=JSON.parse_string(FileAccess.get_file_as_string("res://assets/rooms.json"))
	setup_ui()
	setup_atlas()
	inspector=load("res://scripts/scene_inspector.gd").new()
	add_child(inspector)
	inspector.setup(self)
	change_room(int(game.data.checkpoint))
	if qa_mode=="--qa-routes": call_deferred("verify_routes")
	if qa_mode=="--qa-mechanisms": call_deferred("verify_mechanisms")
	if qa_mode=="--qa-v04-art": call_deferred("verify_v04_art")
	if qa_mode=="--qa-scenery": call_deferred("verify_scenery")
	if qa_mode=="--qa-load": call_deferred("verify_load")
	if qa_mode=="--qa-integration": call_deferred("verify_integration")
	if qa_mode=="--qa-branch": call_deferred("verify_branch")
	if qa_mode=="--qa-latch-load": call_deferred("verify_latch_load")
	if qa_mode=="--qa-sample": call_deferred("verify_sample")
	if qa_mode=="--qa-visual":
		await get_tree().create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(evidence_dir+"/art-viewport-v2.png")
		get_tree().quit()
	if qa_mode!="": print("QA mode ",qa_mode)
	if "--scene-tour" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.3).timeout
		tap("preview")
	if "--route-tour" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.3).timeout
		inspector.toggle_sandbox()

func setup_inputs() -> void:
	var keys={"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE],"attack":[KEY_Q],"heavy":[KEY_R],"heal":[KEY_F],"interact":[KEY_E],"lamp":[KEY_L],"dash":[KEY_SHIFT],"pause":[KEY_ESCAPE],"map":[KEY_TAB],"restart":[KEY_F2],"camp":[KEY_C],"preview":[KEY_F6],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"anchor":[KEY_J]}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for code in keys[action]:
			var event=InputEventKey.new()
			event.physical_keycode=code
			InputMap.action_add_event(action,event)

func setup_ui() -> void:
	ui=CanvasLayer.new()
	add_child(ui)
	var shade=ColorRect.new()
	shade.color=Color(0.02,0.06,0.08,0.78)
	shade.size=Vector2(1280,92)
	ui.add_child(shade)
	hud=Label.new()
	hud.position=Vector2(35,20)
	hud.add_theme_font_size_override("font_size",21)
	ui.add_child(hud)
	bottom=Label.new()
	bottom.position=Vector2(35,682)
	bottom.add_theme_font_size_override("font_size",16)
	bottom.text="F5 全房 F7 坐标 F8 原图 F9 回访 F10 分层 | A D 移动   Space 跳跃   Q 短击   E 交互   Tab 地图   F6 巡览"
	var footer=ColorRect.new()
	footer.color=Color(0.02,0.06,0.08,0.8)
	footer.position=Vector2(0,675)
	footer.size=Vector2(1280,45)
	ui.add_child(footer)
	ui.add_child(bottom)
	hint=Label.new()
	hint.position=Vector2(35,110)
	hint.add_theme_font_size_override("font_size",20)
	hint.add_theme_color_override("font_color",Color("efd5a0"))
	ui.add_child(hint)
	message_label=Label.new()
	message_label.position=Vector2(200,145)
	message_label.size=Vector2(880,50)
	message_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size",22)
	ui.add_child(message_label)
	menu=PanelContainer.new()
	menu.position=Vector2(230,165)
	menu.size=Vector2(820,380)
	menu_text=Label.new()
	menu_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	menu_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	menu_text.add_theme_font_size_override("font_size",22)
	menu.add_child(menu_text)
	ui.add_child(menu)
	menu.hide()

func change_room(index: int,entry: String="left") -> void:
	if changing: return
	changing=true
	call_deferred("_change_room",index,entry)

func _change_room(index: int,entry: String) -> void:
	if level:
		remove_child(level)
		level.queue_free()
	game.room_index=index
	level=Node2D.new()
	level.set_script(LEVEL)
	level.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(level)
	level.setup(game,self,rooms[index],entry)
	changing=false
	notify(["沿受光坡前进 · 营地按 E 记录","举钳是预告 · 后退，等收招再打","两只蟹各有节奏 · 分开应对","门庭营地在左 · 首Boss不需要冲刺","Shift 贴流冲 · 跳起后跨过宽沟","颅侧旧伤 · 鼻道外侧，通向肺侧的闩仍关闭","须根记忆袋 · 四环两沟，右岸封闭，原路返回"][index])
	if scenery_preview:
		level.player.set_physics_process(false)
		level.player.visible=false
		for e in level.enemies: e.set_physics_process(false)
		preview_camera=Vector2(400 if index==0 else 760,float(rooms[index].platforms[0].y)*64-250)
	if is_instance_valid(inspector):inspector.apply_layers()
	qa_jump_time=-1
	qa_stuck=0

func _process(delta: float) -> void:
	if not is_instance_valid(level): return
	if qa_mode=="--qa-render": frame_times.append(delta*1000)
	if qa_mode=="--qa-render" and not get_tree().paused:
		capture_timer+=delta
		if capture_timer>=2.0:
			capture_timer=0
			capture_frame()
	message_timer=maxf(0,message_timer-delta)
	message_label.visible=message_timer>0 and not scenery_preview
	hint.text=level.interaction_hint()
	if scenery_preview and not preview_fit and overlay=="":
		preview_camera+=Vector2(Input.get_axis("left","right"),Input.get_axis("up","down"))*delta*650
		preview_camera.x=clampf(preview_camera.x,400 if game.room_index==0 else 640, maxf(640,level.room_width-640))
		preview_camera.y=clampf(preview_camera.y,360, maxf(360,level.death_y-360))
	hud.text="鲸落万物生 v0.4   /   "+str(rooms[game.room_index].name)+"\n生命 "+"●".repeat(game.hp)+"○".repeat(4-game.hp)+"     蓄振 "+"▰".repeat(game.energy)+"▱".repeat(4-game.energy)+("     贴流冲 Shift" if game.data.dash else "")
	if scenery_preview: hud.text="须门遗港 · 场景巡览   /   "+str(rooms[game.room_index].name)+"\n"+str(rooms[game.room_index].anatomy.part)+" · 不写入存档"
	if route_sandbox:hud.text+="    [回访验证 · 不写档]"
	if scenery_preview:hud.text+="    ["+["合成","远景","中景","可玩层","前景"][inspector.layer_index]+"]"
	if game.room_index==3 and not game.data.boss and level.boss_started and level.enemies.size()>0: hud.text+="       负壳蟹  "+str(level.enemies[0].hp)+" / 180"

func handle_overlay_inputs() -> void:
	if Input.is_action_just_pressed("preview") and not changing:
		set_overlay("")
		if not scenery_preview:
			preview_return_room=game.room_index
			preview_return_position=level.player.position
			scenery_preview=true
			change_room(game.room_index)
		else:
			scenery_preview=false
			inspector.layer_index=0
			change_room(preview_return_room)
			get_tree().create_timer(0.12).timeout.connect(func():
				if is_instance_valid(level): level.player.position=preview_return_position)
	if Input.is_action_just_pressed("pause"):
		set_overlay("pause" if overlay=="" else "")
	if Input.is_action_just_pressed("map"):
		set_overlay("" if overlay=="map" else "map")
	if paused and Input.is_action_just_pressed("camp"):
		set_overlay("")
		level.respawn()
	if Input.is_action_just_pressed("restart") and overlay in ["pause","complete","restart"]:
		if overlay=="restart":
			game.reset_game()
			finished=false
			set_overlay("")
			change_room(0)
		else:
			set_overlay("restart")

func set_overlay(mode: String) -> void:
	overlay=mode
	paused=mode=="pause"
	map_open=mode=="map"
	get_tree().paused=mode!=""
	menu.visible=mode!="" and mode!="map" and mode!="reference"
	if is_instance_valid(inspector):
		inspector.panel.hide()
		if mode=="reference":inspector.show_reference()
	atlas_panel.visible=mode=="map"
	for button in atlas_buttons: button.disabled=not (scenery_preview or route_sandbox)
	if mode=="pause": menu_text.text="已暂停\n\nEsc 继续    C 回营地\nF2 新旅程（再按一次确认）\n\n走跳 → 观察预告 → 反击 → 承接贴流冲 → 到达胃枢入口"
	elif mode=="map": menu_text.text="须门遗港 · 头部口角至咽后\n\n外伤坡 → 须筛 → 舌台 → 负壳蟹 → 流膜育窝\n\n当前位置："+str(rooms[game.room_index].name)+"\n\n鼻端3–32米带 · 全鲸120米（幻想尺度）\n高处支路需未来能力，本关不开放\n\nTab 或 Esc 关闭"
	elif mode=="restart": menu_text.text="确定抹去本首关的当前存档并重新开始？\n\nF2 确认    Esc 取消"

func _physics_process(delta: float) -> void:
	handle_overlay_inputs()
	if qa_mode=="" or not is_instance_valid(level) or changing: return
	if finished and qa_mode in ["--qa-e2e","--qa-render"]:
		if not finalizing:
			finalizing=true
			complete_qa()
		return
	qa_elapsed+=delta
	if qa_elapsed>240:
		write_qa(false,"timeout")
		get_tree().quit(2)
		return
	if qa_mode in ["--qa-e2e","--qa-render"] and not get_tree().paused: drive_e2e(delta)
	elif qa_mode=="--qa-combat": drive_combat(delta)

func complete_qa() -> void:
	write_qa(true,"five-room input-driven completion")
	if qa_mode=="--qa-render":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(evidence_dir+"/complete.png")
	# Release the completion jingle before the automated process exits.
	# Normal gameplay keeps playing it; this is only the QA shutdown path.
	for audio in find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
		audio.stream=null
		audio.queue_free()
	await get_tree().create_timer(0.15,true).timeout
	get_tree().call_deferred("quit")

func tap(action: String) -> void:
	Input.action_press(action)
	get_tree().create_timer(0.05).timeout.connect(func():Input.action_release(action))

func drive_e2e(delta: float) -> void:
	qa_time+=delta
	var p=level.player
	if p.respawning: return
	if absf(p.position.x-qa_last_x)<1: qa_stuck+=delta
	else: qa_stuck=0
	qa_last_x=p.position.x
	Input.action_release("left")
	Input.action_press("right")
	if game.room_index in [0,3] and p.position.x<4*64 and not game.events.any(func(e):return e.event=="checkpoint" and e.room==game.room_index): tap("interact")
	var target: Node2D=null
	for e in level.enemies:
		if not e.dead and ((e.boss and absf(e.position.x-p.position.x)<600) or (not e.boss and absf(e.position.x-p.position.x)<220 and absf(e.position.y-p.position.y)<30 and level.floor_at(Vector2((e.position.x+p.position.x)/2,p.position.y)))):
			target=e
			break
	if target:
		var dx=target.position.x-p.position.x
		if qa_stuck>1.5 and p.is_on_floor(): tap("jump")
		Input.action_release("right")
		Input.action_press("right" if dx>0 else "left")
		if target.state=="tell" or target.state=="active":
			if target.kind=="slam":
				Input.action_release("right")
				Input.action_press("left" if dx>0 else "right")
			else:
				if target.state=="tell" and target.timer>(0.20 if target.kind=="second" else 0.43) and p.is_on_floor(): tap("jump")
				if absf(dx)<100: Input.action_release("right")
		else:
			if dx<0:
				Input.action_release("right")
				Input.action_press("left")
			if absf(dx)<105:
				Input.action_release("right")
				Input.action_release("left")
				p.facing=signf(dx)
				if p.attack_time<0: tap("attack")
				elif p.attack_kind=="short1" and p.attack_time>0.31: tap("attack")
		return
	if game.room_index==3 and game.data.boss and not game.data.dash and p.position.x>31*64: tap("interact")
	if game.room_index==4 and p.position.x<5*64 and not game.data.habitat: tap("interact")
	if p.is_on_floor():
		qa_jump_time=-1
		for platform in level.platforms:
			var end=(float(platform.x)+float(platform.w))*64
			if absf(p.position.y-float(platform.y)*64)<8 and p.position.x<end and end-p.position.x<35 and end<level.room_width-10:
				tap("jump")
				qa_jump_time=0
				break
	elif qa_jump_time>=0:
		qa_jump_time+=delta
		if game.room_index==4 and qa_jump_time>0.30 and not p.air_dash: tap("dash")
	if p.position.x>level.room_width-150: tap("interact")
	if qa_stuck>2 and p.is_on_floor(): tap("jump")
	if finished:
		write_qa(true,"five-room input-driven completion")
		get_tree().quit()

func drive_combat(delta: float) -> void:
	qa_time+=delta
	var p=level.player
	if qa_step==0 and qa_time>0.3:
		var hp=game.hp
		p.take_hit(p.position.x+50)
		p.take_hit(p.position.x+50)
		game.record("test_invulnerability",{"passed":game.hp==hp-1})
		qa_step=1
	elif qa_step==1 and qa_time>1.5:
		p.position.y=level.death_y+50
		qa_step=2
	elif qa_step==2 and qa_time>1.8:
		game.record("test_fall",{"passed":p.position.y<level.death_y})
		game.hp=1
		p.invulnerable=0
		p.take_hit(p.position.x+50)
		qa_step=3
	elif qa_step==3 and qa_time>2.2:
		game.record("test_respawn",{"passed":game.hp==4 and game.room_index==0})
		write_qa(game.events.filter(func(e):return e.event.begins_with("test_")).all(func(e):return e.detail.passed),"failure recovery fixture")
		get_tree().quit()

func verify_load() -> void:
	var passed=game.data.boss and game.data.dash and game.data.complete
	var f=FileAccess.open(evidence_dir+"/persistence.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":passed,"loaded":game.data,"separate_process":true},"\t"))
	f.close()
	get_tree().quit(0 if passed else 2)

func verify_branch() -> void:
	var tester=load("res://scripts/branch_checks.gd").new()
	add_child(tester)
	var result=await tester.run(self)
	var f=FileAccess.open(evidence_dir+"/branch.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"))
	f.close()
	tester.queue_free()
	await get_tree().create_timer(0.2,true).timeout
	get_tree().quit(0 if result.passed else 2)

func verify_sample() -> void:
	var tester=load("res://scripts/sample_checks.gd").new()
	add_child(tester)
	var result=await tester.run(self)
	var f=FileAccess.open(evidence_dir+"/sample.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"))
	f.close()
	tester.queue_free()
	await get_tree().create_timer(0.2,true).timeout
	get_tree().call_deferred("quit",0 if result.passed else 2)

func verify_latch_load() -> void:
	change_room(2)
	await get_tree().create_timer(0.2).timeout
	var passed=game.data.get("latch",false) and is_instance_valid(level.bridge)
	var f=FileAccess.open(evidence_dir+"/latch-reload.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":passed,"data":game.data,"collision_restored":is_instance_valid(level.bridge),"separate_process":true},"\t"))
	f.close()
	get_tree().quit(0 if passed else 2)

func write_qa(passed: bool,reason: String) -> void:
	var name="combat" if qa_mode=="--qa-combat" else "prototype"
	var f=FileAccess.open(evidence_dir+"/"+name+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":passed,"reason":reason,"seconds":qa_elapsed,"deaths":game.deaths,"save":game.data,"events":game.events,"effect_counts":effect_counts},"\t"))
	f.close()
	print("QA_RESULT ",passed," ",reason)
	if qa_mode=="--qa-render":
		var samples=frame_times.slice(120)
		samples.sort()
		var perf=FileAccess.open(evidence_dir+"/performance.json",FileAccess.WRITE)
		perf.store_string(JSON.stringify({"samples":samples.size(),"p50_ms":samples[int(samples.size()*0.5)],"p95_ms":samples[int(samples.size()*0.95)],"max_ms":samples[-1],"frames_over_33ms":samples.filter(func(x):return x>33.3).size(),"renderer":RenderingServer.get_current_rendering_method(),"resolution":[1280,720]},"\t"))

func capture_frame() -> void:
	capture_index+=1
	var name="%03d-room-%d.png"%[capture_index,game.room_index+1]
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence_dir+"/"+name)

func verify_integration() -> void:
	var tester=load("res://scripts/integration_checks.gd").new()
	add_child(tester)
	var result=await tester.run(self)
	var f=FileAccess.open(evidence_dir+"/integration-v1.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"))
	f.close()
	tester.queue_free()
	await get_tree().create_timer(0.2,true).timeout
	get_tree().quit(0 if result.passed else 2)

func notify(text: String) -> void:
	message_label.text=text
	message_timer=4.5

func finish() -> void:
	finished=true
	set_overlay("complete")
	menu_text.text="须门遗港 · 已完成\n\n你已获得贴流冲，修通第一段迁徙路。\n胃枢位于咽后食管尽头，下一章继续。\n\n本次碎片："+("1 / 4" if game.data.fragment else "0 / 4")+"    清流窝："+("已修通" if game.data.habitat else "待回访")+"\n\nEsc 返回探索    F2 重新开始"

func sfx(name: String) -> void:
	var file="res://assets/runtime/audio/"+name+".wav"
	if not ResourceLoader.exists(file): return
	var audio=AudioStreamPlayer.new()
	audio.stream=load(file)
	audio.volume_db=-14
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (scenery_preview or route_sandbox):
		if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_7:
			set_overlay("")
			change_room(event.physical_keycode-KEY_1)

func setup_atlas() -> void:
	atlas_panel=Control.new()
	atlas_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(atlas_panel)
	var bg=ColorRect.new()
	bg.color=Color("071823")
	bg.size=Vector2(1280,720)
	atlas_panel.add_child(bg)
	var art=Sprite2D.new()
	art.texture=load("res://assets/runtime/v03/panorama.png")
	art.centered=false
	art.position=Vector2(28,88)
	art.scale=Vector2(1224,612)/art.texture.get_size()
	atlas_panel.add_child(art)
	var title=Label.new()
	title.text="须门遗港  /  巨鲸头部 · 七房位置\nTab / Esc 返回    F6 切换场景巡览后，可点房间查看实景；首通按原路线解锁"
	title.position=Vector2(28,16)
	title.add_theme_font_size_override("font_size",20)
	atlas_panel.add_child(title)
	var points=[Vector2(75,377),Vector2(280,370),Vector2(555,400),Vector2(895,420),Vector2(1100,400),Vector2(730,230),Vector2(430,265)]
	for i in range(7):
		var button=Button.new()
		button.position=points[i]
		button.text=str(i+1)+" · "+str(rooms[i].name)
		button.pressed.connect(func():
			set_overlay("")
			change_room(i))
		atlas_panel.add_child(button)
		atlas_buttons.append(button)
	atlas_panel.hide()

func verify_scenery() -> void:
	var tester=load("res://scripts/scenery_checks.gd").new()
	add_child(tester)
	var result=await tester.run(self)
	var f=FileAccess.open(evidence_dir+"/scenery.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"))
	f.close()
	tester.queue_free()
	await get_tree().create_timer(0.2,true).timeout
	get_tree().call_deferred("quit",0 if result.passed else 2)

func verify_routes() -> void:
	var tester=load("res://scripts/route_checks.gd").new()
	add_child(tester)
	var result=await tester.run(self)
	var f=FileAccess.open(evidence_dir+"/routes.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"))
	f.close()
	await get_tree().create_timer(0.2,true).timeout
	get_tree().quit(0 if result.passed else 2)

func verify_mechanisms() -> void:
	var tester=load("res://scripts/route_mechanism_checks.gd").new()
	add_child(tester)
	var result=await tester.run(self)
	var f=FileAccess.open(evidence_dir+"/mechanisms.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"))
	f.close()
	await get_tree().create_timer(0.2,true).timeout
	get_tree().quit(0 if result.passed else 2)

func verify_v04_art() -> void:
	var tester=load("res://scripts/v04_art_checks.gd").new()
	add_child(tester)
	var result=await tester.run(self)
	var f=FileAccess.open(evidence_dir+"/art.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"))
	f.close()
	await get_tree().create_timer(0.2,true).timeout
	get_tree().quit(0 if result.passed else 2)
