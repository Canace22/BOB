extends SceneTree
## Native GPU manual-pose visual fixture：只采样呈现，不触发出招/命中，不作为实战证据。
var lab: EnemyLab
var title_label: Label
var source_label: Label
var output: String="res://build/qa/enemy-animation-v2"
var records: Array[Dictionary]=[]
var playlists: Array[Dictionary]=[]
var failures: Array[String]=[]
var full_frames: bool=false
var covered_profiles: Array[String]=[]

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("enemy_animation_v2_qa requires a native GPU window; no headless screenshot claim")
		quit(2)
		return
	if not OS.get_environment("ENEMY_ANIMATION_QA_OUT").is_empty(): output=OS.get_environment("ENEMY_ANIMATION_QA_OUT")
	full_frames="--all-frames" in OS.get_cmdline_user_args()
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	lab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.auto_attack=false
	lab.ranges=false
	root.add_child(lab)
	current_scene=lab
	await ticks(12)
	# Lab控制器会重设world.process_mode；先停它，再禁用整棵战斗树。
	lab.set_physics_process(false)
	lab.set_process_unhandled_key_input(false)
	lab.hud.hide()
	make_labels()
	for index: int in EnemyLabCatalog.PROFILES.size():
		var id: String=str(EnemyLabCatalog.profile(index).id)
		if not selected("profile",id): continue
		covered_profiles.append(id)
		lab.profile_index=index
		lab.reset_round()
		await ticks(4)
		var enemy: EnemyLabEnemy=lab.enemies[0]
		lab.world.process_mode=Node.PROCESS_MODE_DISABLED
		enemy.set_physics_process(false)
		lab.player.set_physics_process(false)
		lab.player.clear_combat_input()
		lab.player.position=Vector2(340,EnemyLab.FLOOR)
		lab.player.velocity=Vector2.ZERO
		enemy.position=Vector2(800,EnemyLab.FLOOR)
		enemy.velocity=Vector2.ZERO
		enemy.show_ranges=false
		enemy.visual.animation_override.warmup(id)
		for message: String in enemy.visual.animation_override.diagnostics: failures.append(id+": "+message)
		var actions: Array=enemy.profile.moves.duplicate()
		if id=="beam_guard": actions.append("beam_riposte")
		if id=="membrane_hunter": actions.append("hunter_escape")
		for action: String in actions:
			if not selected("action",action): continue
			configure_action(enemy,action)
			for facing: float in [-1.0,1.0]: await capture_action(enemy,id,action,facing)
	if records.is_empty(): failures.append("no selected profile/action produced a sample")
	write_json("coverage.json",{"method":"native GPU manual-pose visual fixture; no input, AI transitions, damage or projectile execution", "renderer_config":ProjectSettings.get_setting("rendering/renderer/rendering_method",""),"display_server":DisplayServer.get_name(),"profiles":covered_profiles,"all_frames":full_frames,"samples":records,"failures":failures})
	write_json("slow-playlists.json",{"method":"ordered screenshots for 0.5x presentation preview; sparse samples unless --all-frames", "sequences":playlists})
	print("ENEMY_ANIMATION_V2_GPU samples=",records.size()," failures=",failures.size()," output=",output)
	quit(1 if not failures.is_empty() else 0)

func ticks(count: int) -> void:
	for index: int in count: await physics_frame

func selected(key: String, value: String) -> bool:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--"+key+"="): return argument.trim_prefix("--"+key+"=")==value
	return true

func make_labels() -> void:
	var canvas: CanvasLayer=CanvasLayer.new()
	canvas.layer=100
	lab.add_child(canvas)
	title_label=Label.new()
	title_label.position=Vector2(30,24)
	title_label.add_theme_font_size_override("font_size",24)
	canvas.add_child(title_label)
	source_label=Label.new()
	source_label.position=Vector2(30,72)
	source_label.add_theme_font_size_override("font_size",16)
	canvas.add_child(source_label)
	var reference: Label=Label.new()
	reference.text="PLAYER / native size reference\nMANUAL-POSE VISUAL FIXTURE / NO COMBAT CLAIM"
	reference.position=Vector2(180,345)
	reference.add_theme_font_size_override("font_size",16)
	canvas.add_child(reference)

func configure_action(enemy: EnemyLabEnemy, action: String) -> void:
	enemy.move_key=action
	enemy.spec=enemy.action_spec("hunter_pounce" if action=="hunter_escape" else action)
	enemy.outcome=""
	enemy.followup_cancelled=false
	if enemy is EnemyLabEel: enemy.nest.stage="spit"
	if enemy is EnemyLabElder and action=="elder_mimic":
		# 仅为幻影取帧准备普攻快照，不调用begin/release，不执行攻击事件。
		enemy.mimic.memory={"key":"strike_01","steps":1,"data":{"duration":3.0/lab.player.animation_fps+lab.player.attack_recovery,"release":2.0/lab.player.animation_fps,"shape":"front"}}
		enemy.mimic.begin()

func plan(action: String) -> Array[Dictionary]:
	var phases: Array[Dictionary]=[]
	var states: Array=["tell","active","recover"]
	match action:
		"hunter_escape": states=["escape_tell","evade","return"]
		"eel_burrow": states=["tell","dive","tunnel","emerge","active","recover"]
		"eel_brood": states=["tell","active","link","coil","active","coil","active","recover"]
		"warden_waterstep": states=["tell","wash","reform","active","recover"]
		"beam_brace": states=["brace","tell","active","recover"]
		"beam_guard": states=["tell","guarding","guard_contact","recover"]
		"elder_vault": states=["tell","vault","settle","active","recover","reground"]
		"double","warden_double","elder_grip": states=["tell","active","tell","active","recover"]
	# 完整收口也要看：旧采样遗漏回挂，且只有撑跃采到了独立回稳。
	if action.begins_with("hunter_") and not states.has("return"): states.append("return")
	if action.begins_with("elder_") and not states.has("reground"): states.append("reground")
	var pulse: int=1
	for state: String in states:
		if state=="coil" or (state=="tell" and not phases.is_empty()): pulse+=1
		phases.append({"state":state,"pulse":pulse})
	return phases

func sample_points(enemy: EnemyLabEnemy, state: String, pulse: int) -> Array[float]:
	# 三元表达式会得到无类型Array，显式assign后保留浮点返回合同。
	var points: Array[float]=[]
	points.assign([0.0,0.5,0.95] if state not in ["active","recover"] else ([0.0,0.5] if state=="active" else [0.0,0.95]))
	if full_frames:
		var entry: Dictionary=enemy.visual.animation_override.enemies.get(str(enemy.profile.id),{})
		for kind: String in ["clips","windups"]:
			for clip: Dictionary in entry.get(kind,[]):
				if clip.action!=enemy.move_key or clip.state!=state or int(clip.get("pulse",pulse))!=pulse: continue
				for frame: Dictionary in clip.frames:
					var at: float=float(frame.at)
					if str(clip.get("time_unit","phase"))=="seconds": at/=maxf(enemy.phase_duration(),0.001)
					if at>1.0: continue
					if not points.has(at): points.append(at)
	points.sort()
	return points

func capture_action(enemy: EnemyLabEnemy, id: String, action: String, facing: float) -> void:
	var sequence: Array[Dictionary]=[]
	for phase: Dictionary in plan(action):
		enemy.state=str(phase.state)
		enemy.pulse=int(phase.pulse)
		enemy.facing=facing
		if enemy is EnemyLabEel and action=="eel_brood": enemy.nest.stage="bites" if enemy.pulse>1 else "spit"
		var duration: float=enemy.phase_duration()
		var points: Array[float]=sample_points(enemy,enemy.state,enemy.pulse)
		for cursor: int in points.size():
			var progress: float=points[cursor]
			enemy.timer=progress*duration
			enemy.visual.present(enemy)
			if enemy is EnemyLabElder:
				enemy.mimic.view._physics_process(0.0)
			var filename: String="%s--%s--p%d-%s-%03d--%s.png"%[id,action,enemy.pulse,enemy.state,roundi(progress*100),"left" if facing<0 else "right"]
			var data: Dictionary=describe(enemy,id,action,progress)
			data.file=filename
			title_label.text="MANUAL-POSE / %s / %s / %s p%d %.2f / facing %d"%[id,action,enemy.state,enemy.pulse,progress,int(facing)]
			source_label.text="source: %s\nrect: %s  pivot: %s  scale: %s\nwindup FX: %s  weakpoint: %s"%[data.body.texture,str(data.body.rect),str(data.body.pivot),str(data.body.scale),str(data.windup.visible),str(data.weakpoint)]
			await process_frame
			await RenderingServer.frame_post_draw
			var status: Error=root.get_texture().get_image().save_png(output.path_join(filename))
			if status!=OK: failures.append("save_png "+filename+": "+error_string(status))
			data.saved=status==OK
			records.append(data)
			var next_at: float=points[cursor+1] if cursor+1<points.size() else 1.0
			sequence.append({"file":filename,"duration_ms":maxi(50,roundi((next_at-progress)*maxf(duration,0.001)*2000.0)),"state":enemy.state,"progress":progress})
	playlists.append({"profile":id,"action":action,"facing":facing,"frames":sequence})

func describe(enemy: EnemyLabEnemy, id: String, action: String, progress: float) -> Dictionary:
	var sampled: Dictionary=enemy.visual.animation_override.sample(id,action,enemy.state,enemy.pulse,progress,"clips",enemy.phase_duration())
	var weak: Dictionary={}
	var material: ShaderMaterial=enemy.visual.material as ShaderMaterial
	if material!=null:
		weak={"center_uv":pair(material.get_shader_parameter("weak_center")),"radius_uv":pair(material.get_shader_parameter("weak_radius")),"glow":material.get_shader_parameter("weak_glow"),"danger":material.get_shader_parameter("danger")}
		# 非水系材质未写入弱点参数时返回 null，不应伪造弱点坐标。
		var uv: Variant=material.get_shader_parameter("weak_center")
		if enemy.visual.texture!=null and uv is Vector2:
			weak.center_world=pair(enemy.visual.to_global(uv*enemy.visual.texture.get_size()-enemy.visual.region_rect.position+enemy.visual.offset))
		elif id=="pump_warden" and not sampled.is_empty():
			failures.append("missing pump weakpoint: %s/%s"%[action,enemy.state])
	var data: Dictionary={"profile":id,"action":action,"state":enemy.state,"pulse":enemy.pulse,"facing":enemy.facing,"progress":progress,"timer":enemy.timer,"phase_duration":enemy.phase_duration(),"body":sprite_info(enemy.visual),"windup":sprite_info(enemy.visual.windup_view),"weakpoint":weak,"override_installed":not sampled.is_empty(),"override_frame":sampled.clip.frames.find(sampled.frame) if not sampled.is_empty() else -1,"active_projectiles_simulated":false}
	var actor_script: Script=enemy.get_script() as Script
	data.actor_script=actor_script.resource_path if actor_script!=null else ""
	var expected_fx: Dictionary=enemy.visual.animation_override.sample(id,action,enemy.state,enemy.pulse,progress,"windups",enemy.phase_duration())
	data.windup_configured=not expected_fx.is_empty()
	if not expected_fx.is_empty() and not enemy.visual.windup_view.visible: failures.append("configured windup invisible: %s/%s/%s"%[id,action,enemy.state])
	if enemy is EnemyLabElder:
		data.phantom={"method":"manual basic-attack reference snapshot, not learned from input","source_key":enemy.mimic.source_key,"body_key":enemy.mimic.view.body_key,"body_frame":enemy.mimic.view.body_frame,"body":sprite_info(enemy.mimic.view.action_echo),"fx":sprite_info(enemy.mimic.view.effect)}
	return data

func sprite_info(sprite: Sprite2D) -> Dictionary:
	var path: String=""
	var rect: Rect2=sprite.region_rect
	if sprite.texture!=null:
		path=sprite.texture.resource_path
		var atlas: AtlasTexture=sprite.texture as AtlasTexture
		if atlas!=null:
			path=atlas.atlas.resource_path
			rect=atlas.region
	return {"visible":sprite.is_visible_in_tree(),"texture":path,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"pivot":pair(-sprite.offset),"scale":pair(sprite.scale),"world_position":pair(sprite.global_position)}

func pair(value: Variant) -> Array:
	return [value.x,value.y] if value is Vector2 else []

func write_json(filename: String, data: Dictionary) -> void:
	var file: FileAccess=FileAccess.open(output.path_join(filename),FileAccess.WRITE)
	if file==null:
		failures.append("write_json "+filename)
		return
	file.store_string(JSON.stringify(data,"\t"))
