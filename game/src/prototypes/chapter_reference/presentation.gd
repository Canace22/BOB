class_name ChapterReferencePresentation
extends Node2D
## 位图/侧台只读既有进度；不完成任务、不写存档、不控制Boss。
var active: bool=false
var chapter: int=0
var config: Dictionary={}
var art: ChapterReferenceArt
var state_reader: Callable
var bound_art: Array[Dictionary]=[]
var ambient: Array[Node]=[]
var water_fields: Array[KitDriftField]=[]
var extra_surfaces: Array[Rect2]=[]
var current_state: Dictionary={}
var gate_views: Array[Sprite2D]=[]

func install(id: int, floors: Array[Rect2], origin: Vector2, reader: Callable) -> void:
	chapter=id
	state_reader=reader
	position=-origin
	config=ChapterReferenceLayout.read(id)
	if config.is_empty() or not ChapterReferenceLayout.enabled(): return
	active=true
	z_index=-10
	art=ChapterReferenceArt.new()
	build_background()
	for floor_rect: Rect2 in floors: art.surface(self,str(config.get("platform","r4-bone-platform")),floor_rect)
	for platform: Dictionary in config.get("side_platforms",[]):
		var rect: Rect2=ChapterReferenceLayout.rect(platform.rect)
		ChapterReferenceLayout.body(self,platform.rect)
		art.surface(self,str(platform.get("art",config.get("platform","r4-bone-platform"))),rect)
		extra_surfaces.append(rect)
	for entry: Dictionary in config.get("objects",[]): build_object(entry)
	build_ambient()
	_process(0)
	print("CHAPTER_REFERENCE_READY chapter=",chapter," extra_surfaces=",extra_surfaces.size()," missing=",art.missing)
	queue_redraw()

func build_background() -> void:
	var id: String=str(config.get("background","r3-gastric-depth"))
	var tex: Texture2D=art.texture(id)
	if tex==null: return
	var span: float=1500
	var count: int=ceili(float(config.get("width",3800))/span)+2
	for i: int in count:
		var sprite:=Sprite2D.new()
		sprite.texture=tex
		sprite.centered=false
		sprite.scale=Vector2.ONE*maxf(1800.0/float(tex.get_width()),1350.0/float(tex.get_height()))
		sprite.position=Vector2(float(i-1)*span,-300)
		sprite.z_index=-20
		var mat:=ShaderMaterial.new()
		mat.shader=preload("res://src/prototypes/chapter_reference/depth_edge.gdshader")
		sprite.material=mat
		add_child(sprite)

func build_object(entry: Dictionary) -> void:
	var at: Vector2=ChapterReferenceLayout.point(entry.at)
	var sprite: Sprite2D=art.sprite(str(entry.art),at,float(entry.get("width",220)),str(entry.get("anchor","foot")))
	if sprite==null: return
	sprite.name=str(entry.id)
	sprite.z_index=int(entry.get("z",9))
	if entry.has("tint"): sprite.modulate=Color(str(entry.tint))
	add_child(sprite)
	bound_art.append({"node":sprite,"rule":entry,"at":at,"base_position":sprite.position,"tint":sprite.modulate})

func build_ambient() -> void:
	for entry: Dictionary in config.get("water",[]):
		var field:=KitDriftField.new()
		field.texture=art.texture("fx-particle-drift")
		if field.texture==null: continue
		field.bounds=ChapterReferenceLayout.rect(entry.rect)
		field.population=int(entry.get("population",16))
		field.velocity=Vector2(float(entry.get("speed",8)),0)
		field.size_range=Vector2(18,32)
		field.opacity=0.35
		field.external_clock=true
		field.z_index=7
		add_child(field)
		water_fields.append(field)
		ambient.append(field)
	for entry: Array in config.get("bubbles",[]):
		var bubble:=EnvironmentBubbleEmitter.new()
		bubble.bounds=ChapterReferenceLayout.rect(entry)
		bubble.population=7
		bubble.external_clock=true
		bubble.z_index=3
		add_child(bubble)
		ambient.append(bubble)
	var glow:=WhalebellySoftUnderwaterLight.new()
	glow.texture=art.texture("soft-light")
	if glow.texture!=null:
		glow.position=Vector2(650,120)
		glow.scale=Vector2.ONE*0.7
		glow.intensity=0.07
		glow.external_clock=true
		glow.z_index=-15
		add_child(glow)
		ambient.append(glow)

func _process(_dt: float) -> void:
	if not active or not state_reader.is_valid(): return
	current_state=state_reader.call()
	var flags: Dictionary=current_state.get("flags",{})
	var completed: Array=current_state.get("completed",[])
	update_gates(current_state.get("gates",[]))
	for item: Dictionary in bound_art:
		var rule: Dictionary=item.rule
		var sprite: Sprite2D=item.node
		sprite.visible=(not rule.has("show_if") or bool(flags.get(str(rule.show_if),false))) and (not rule.has("hide_if") or not bool(flags.get(str(rule.hide_if),false)))
		if rule.has("show_completed"): sprite.visible=sprite.visible and str(rule.show_completed) in completed
		if rule.has("hide_completed"): sprite.visible=sprite.visible and not str(rule.hide_completed) in completed
		if rule.get("follow_player",false):
			var follow_offset: Vector2=ChapterReferenceLayout.point(rule.get("player_offset",[-20,-60]))
			sprite.position=item.base_position+current_state.get("player",Vector2.ZERO)+follow_offset-item.at
		if rule.has("raise_if"):
			var raised: Vector2=ChapterReferenceLayout.point(rule.get("raised_at",[item.at.x,item.at.y-70]))
			sprite.position=item.base_position+(raised-item.at if flags.get(str(rule.raise_if),false) else Vector2.ZERO)
		# 状态只换同族静图/显隐；不冒充搬巢、开闸或器官动作动画。
		if rule.has("dim_if"): sprite.modulate=Color("777b78") if flags.get(str(rule.dim_if),false) else item.tint
	var time: float=float(current_state.get("time",0))
	for i: int in water_fields.size():
		var field: KitDriftField=water_fields[i]
		var water: Dictionary=config.water[i]
		var speed: float=float(water.get("speed",8))
		if chapter==3 and flags.get("valve_opened",false):
			speed=-5
			if str(current_state.get("stage",""))=="rescue": speed=18 if float(current_state.get("phase",0))<2 else -28
		if chapter==4 and flags.get("ch04_limited_flow_open",false): speed=5 if flags.get("ch04_opening_limited",false) else 15
		if chapter==12 and flags.get("ch12_shift_narrow_cover",false): speed=14
		field.velocity=Vector2(speed,0)
	for node: Node in ambient: node.call("update_at",time)
	queue_redraw()

func update_gates(points: Array) -> void:
	# 只包住原遭遇创建的碰撞，不另造战斗栏杆或改变解锁条件。
	while gate_views.size()<points.size():
		var tex: Texture2D=art.texture("anchor-pull-gate-closed")
		if tex==null: return
		var box: Rect2=art.metrics("anchor-pull-gate-closed",tex).bounds
		var gate: Sprite2D=art.sprite("anchor-pull-gate-closed",Vector2.ZERO,440.0*box.size.x/box.size.y)
		gate.z_index=9
		add_child(gate)
		gate_views.append(gate)
	for i: int in gate_views.size():
		var gate: Sprite2D=gate_views[i]
		gate.visible=i<points.size()
		if gate.visible:
			var previous_anchor: Vector2=gate.get_meta("reference_anchor")
			var offset: Vector2=previous_anchor-gate.position
			gate.position=points[i]-offset
			gate.set_meta("reference_anchor",points[i])

func _draw() -> void:
	if not active: return
	for zone: Dictionary in config.get("zones",[]):
		var raw: Array=zone.rect
		WhaleActionHUDStyle.text(self,Vector2(raw[0],raw[1]-18),str(zone.label),17,WhaleUIStyle.BONE)
	for item: Dictionary in bound_art:
		if item.node.visible and item.rule.has("caption"):
			WhaleActionHUDStyle.text(self,item.at+Vector2(-55,-90),str(item.rule.caption),15,WhaleUIStyle.BONE)
	if art!=null and not art.missing.is_empty():
		WhaleActionHUDStyle.text(self,Vector2(160,160),"REFERENCE MISSING: "+str(art.missing),16,Color("ef9680"))
