class_name CampaignCinematicView
extends CanvasLayer
## 只负责演出镜头、已有逐帧素材和字幕；不执行技能、不发伤害、不写章节事实。
var director: CampaignCinematic
var camera: Camera2D
var caption: Label
var hint: Label
var skip_button: Button
var actors: Array[Dictionary]=[]
var props: Array[Sprite2D]=[]
var flow: Array[Sprite2D]=[]
var guard_frames:=EnemyLabAnimationOverride.new()
var player_view: TideActionVisual
var hidden: Array[CanvasItem]=[]
var start_camera: Vector2
var shot_start: Vector2
var target_camera: Vector2
var from_zoom: Vector2
var target_zoom: Vector2
var player_proxy: Sprite2D
var guard_proxy: Sprite2D
var elapsed: float=0.0
var lower_bar: ColorRect

func setup(value: CampaignCinematic) -> void:
	director=value
	layer=18
	var host: WhalebellyMain=director.story.host
	player_view=host.player.action_visual
	start_camera=host.camera.global_position
	camera=Camera2D.new()
	camera.position=start_camera
	camera.zoom=host.camera.zoom
	camera.process_mode=Node.PROCESS_MODE_ALWAYS
	host.add_child(camera)
	camera.make_current()
	var ui:=Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	for top: bool in [true,false]:
		var bar:=ColorRect.new()
		bar.color=Color(0.015,0.025,0.04,0.9)
		bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
		ui.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.offset_top=0 if top else -114
		bar.offset_bottom=38 if top else 0
		if not top: lower_bar=bar
	caption=Label.new()
	ui.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_left=48
	caption.offset_right=-48
	caption.offset_top=-102
	caption.offset_bottom=-39
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font",WhaleUIStyle.FONT)
	caption.add_theme_font_size_override("font_size",20)
	hint=Label.new()
	ui.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left=48
	hint.offset_top=-31
	hint.offset_bottom=-7
	hint.text="按住 Tab 暂停阅读 · F 结束观看 · Esc 跳过"
	hint.add_theme_font_override("font",WhaleUIStyle.FONT)
	hint.add_theme_font_size_override("font_size",14)
	skip_button=Button.new()
	ui.add_child(skip_button)
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip_button.offset_left=-150
	skip_button.offset_right=-20
	skip_button.offset_top=4
	skip_button.offset_bottom=34
	skip_button.text="跳过过场"
	skip_button.add_theme_font_override("font",WhaleUIStyle.FONT)
	skip_button.pressed.connect(director.request_skip)
	get_viewport().size_changed.connect(_layout)
	_layout()
	# 演出代理只复用纹理；真实主角与敌人冻结，绝不运行攻击执行器。
	player_proxy=_sprite()
	player_proxy.global_position=host.player.global_position
	for i: int in 24:
		var particle:=_sprite()
		particle.texture=load("res://art/world-kit/bloodnest-water-filament-v5.png")
		particle.hide()
		flow.append(particle)

func _layout() -> void:
	var narrow: bool=get_viewport().get_visible_rect().size.x<800
	var height: float=180 if narrow else 114
	lower_bar.offset_top=-height
	caption.offset_top=-height+12
	caption.offset_left=24 if narrow else 48
	caption.offset_right=-caption.offset_left
	caption.add_theme_font_size_override("font_size",16 if narrow else 20)
	hint.add_theme_font_size_override("font_size",12 if narrow else 14)

func focus(value: Variant) -> Vector2:
	var host: WhalebellyMain=director.story.host
	if value is Array: return host.actor_frame.to_global(host.point(value))-Vector2(0,58)
	if str(value)=="player": return host.player.global_position-Vector2(0,48)
	var identity: String=str(value)
	if identity=="body":
		for body: Node2D in director.story.encounter.retired:
			if not is_instance_valid(body): continue
			for child: Node in body.get_children():
				if child is EnemyLabEnemy: return child.global_position-Vector2(0,45)
	for actor: ChapterCharacterActor in director.story.view.actors:
		if actor.get_meta("story_identity","")==identity: return actor.global_position-Vector2(0,50)
	var body: EnemyLabEnemy=director.story.encounter.body_for(identity)
	if is_instance_valid(body): return body.global_position-Vector2(0,50)
	return host.player.global_position-Vector2(0,48)

func begin_shot(spec: Dictionary) -> void:
	_restore_hidden()
	for prop: Sprite2D in props: prop.queue_free()
	props.clear()
	if is_instance_valid(guard_proxy): guard_proxy.queue_free()
	guard_proxy=null
	shot_start=camera.global_position
	target_camera=focus(spec.get("focus","player"))
	from_zoom=camera.zoom
	target_zoom=Vector2.ONE*float(spec.get("zoom",1.08))
	caption.text=str(spec.get("text",""))
	player_proxy.visible=spec.has("player_pose")
	if player_proxy.visible:
		var visual: CanvasItem=director.story.host.player.get_node("Visual")
		_hide(visual)
	if spec.has("guard"):
		var identity: String=str(spec.guard)
		guard_frames.warmup(identity)
		guard_proxy=_sprite()
		guard_proxy.global_position=focus(identity)+Vector2(0,50)
		if guard_proxy.global_position.distance_to(target_camera)>600: guard_proxy.global_position=target_camera+Vector2(100,58)
		for actor: ChapterCharacterActor in director.story.view.actors:
			if actor.get_meta("story_identity","")==identity: _hide(actor)
		var body: EnemyLabEnemy=director.story.encounter.body_for(identity)
		if is_instance_valid(body):
			_hide(body.visual)
			guard_proxy.global_position=body.global_position
		# 没有静态NPC可替代时仍用已入库演员，不生成几何人形。
		var idle:=ChapterCharacterActor.new()
		idle.configure(identity,135 if identity=="elder_guardian" else 100)
		guard_proxy.texture=idle.texture
		guard_proxy.region_enabled=idle.region_enabled
		guard_proxy.region_rect=idle.region_rect
		guard_proxy.offset=idle.offset
		guard_proxy.scale=idle.scale
		idle.free()
	if spec.has("prop"):
		var prop:=_sprite()
		var sources: Dictionary={"fungus":"res://art/world-kit/habitat-fungus-bed.png","name_shell":"res://art/chapter-reference-v1/name-shell.png","valve":"res://art/world-kit/nursery-valve-leaf.png"}
		prop.texture=load(sources[str(spec.prop)])
		prop.centered=false
		prop.offset=Vector2(-prop.texture.get_width()*0.5,-prop.texture.get_height())
		prop.scale=Vector2.ONE*float({"fungus":90,"name_shell":30,"valve":145}[str(spec.prop)])/prop.texture.get_height()
		prop.global_position=target_camera+Vector2(-80 if spec.prop=="valve" else 0,58)
		props.append(prop)

func advance(spec: Dictionary, time: float, total: float) -> void:
	elapsed=time
	var blend: float=smoothstep(0,1,clampf(time/0.65,0,1))
	camera.global_position=shot_start.lerp(target_camera,blend)
	camera.zoom=from_zoom.lerp(target_zoom,blend)
	camera.force_update_scroll()
	_update_backdrop()
	if player_proxy.visible:
		var key: String=str(spec.player_pose)
		var clip: Dictionary=player_view.manifest[key]
		var frames: Array[Texture2D]=player_view.load_clip(key).body
		var index: int=mini(int(time/maxf(total,0.01)*frames.size()),frames.size()-1)
		player_proxy.texture=frames[index]
		player_proxy.centered=false
		player_proxy.offset=-Vector2(clip.body.pivot[0],clip.body.pivot[1])
		var scale_: float=94.0/float(clip.reference_height)
		player_proxy.scale=Vector2(director.story.host.player.facing*scale_,scale_)
	if is_instance_valid(guard_proxy):
		var sampled: Dictionary=guard_frames.sample(str(spec.guard),str(spec.action),"tell" if time<total*0.45 else "active",1,clampf((time if time<total*0.45 else time-total*0.45)/(total*0.45),0,1))
		if not sampled.is_empty(): guard_frames.apply_body(guard_proxy,sampled,-1,135 if spec.guard=="elder_guardian" else 100)
	var mode: String=str(spec.get("effect",""))
	if spec.get("prop","")=="valve" and not props.is_empty():
		# 膜瓣固定在脚线上的根部，转动只表示既有开合，不改变碰撞或通水事实。
		props[0].rotation=-0.32*smoothstep(0,1,clampf(time/maxf(total*0.6,0.1),0,1)) if mode=="flood" else -0.32*(1.0-clampf(time/total,0,1))
	for i: int in flow.size():
		var item: Sprite2D=flow[i]
		item.visible=mode!=""
		if not item.visible: continue
		var progress: float=fposmod(time*(0.55 if mode=="flood" else 0.22)+float(i)/flow.size(),1.0)
		item.global_position=target_camera+Vector2(lerpf(470,-470,progress),float((i*43)%130)-35)
		item.scale=Vector2(0.8 if mode=="flood" else 0.35,0.12)
		item.modulate=Color(0.5,0.85,1,sin(progress*PI)*(0.65 if mode=="flood" else 0.28))

func begin_return() -> void:
	shot_start=camera.global_position
	from_zoom=camera.zoom

func return_camera(weight: float) -> void:
	camera.global_position=shot_start.lerp(start_camera,smoothstep(0,1,weight))
	camera.zoom=from_zoom.lerp(director.story.host.camera.zoom,smoothstep(0,1,weight))
	camera.force_update_scroll()
	_update_backdrop()

func _update_backdrop() -> void:
	var host: WhalebellyMain=director.story.host
	var water: Sprite2D=host.streaming.corridors.get_node_or_null("ContinuousWater")
	if water!=null and water.material is ShaderMaterial:
		water.material.set_shader_parameter("camera_world",camera.global_position)

func _sprite() -> Sprite2D:
	var sprite:=Sprite2D.new()
	sprite.z_index=director.story.host.player.z_index+1
	director.story.host.actor_frame.add_child(sprite)
	actors.append({"sprite":sprite})
	return sprite

func _hide(item: CanvasItem) -> void:
	if item.visible:
		item.hide()
		hidden.append(item)

func _restore_hidden() -> void:
	for item: CanvasItem in hidden:
		if is_instance_valid(item): item.show()
	hidden.clear()

func release() -> void:
	_restore_hidden()
	for entry: Dictionary in actors:
		if is_instance_valid(entry.sprite): entry.sprite.queue_free()
	actors.clear()
	if is_instance_valid(director.story.host.camera): director.story.host.camera.make_current()
	if is_instance_valid(camera): camera.queue_free()
	queue_free()
