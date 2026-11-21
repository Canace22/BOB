class_name ChapterRun
extends Node2D
## 后续章节统一白盒宿主，只负责生命周期；内容、阶段和敌人由各自模块拥有。
@export var chapter_id: int=4
var suffix: String="play"
var save_enabled: bool=true
var restore_progress: bool=true
var data: Dictionary={}
var flags: Dictionary={}
var completed: Array[String]=[]
var offset: Vector2=Vector2.ZERO
var world: Node2D
var player: ChapterTwoPlayer
var camera: Camera2D
var flow: ChapterRunFlow
var encounter: ChapterRunEncounter
var view: ChapterRunView
var hud: ChapterRunHUD
var resume_wait: float=0
var paused_by_user: bool=false
var save_failed: bool=false
var elapsed: float=0
var events: Array[Dictionary]=[]
const KEYS: Array[Key]=[KEY_A,KEY_D,KEY_W,KEY_S,KEY_J,KEY_K,KEY_I,KEY_L,KEY_Q,KEY_E,KEY_Z,KEY_SPACE,KEY_F,KEY_ENTER]

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	if get_tree().has_meta("chapter_run_launch"):
		var config: Dictionary=get_tree().get_meta("chapter_run_launch")
		get_tree().remove_meta("chapter_run_launch")
		chapter_id=int(config.get("id",chapter_id))
		suffix=str(config.get("suffix",suffix))
		save_enabled=bool(config.get("save",true))
		restore_progress=bool(config.get("restore",true))
	data=ChapterRunCatalog.read(chapter_id)
	var errors: PackedStringArray=ChapterRunCatalog.validate(data)
	if not errors.is_empty():
		push_error("Chapter whitebox data invalid: "+str(chapter_id)+" "+str(errors))
		var notice: Label=WhaleUIStyle.paragraph("白盒章节无法加载：%d\n%s" % [chapter_id,str(errors)])
		notice.position=Vector2(60,80)
		notice.size=Vector2(1050,400)
		add_child(notice)
		return
	offset=ChapterRunCatalog.origin(data)
	if restore_progress: read_save()
	DisplayServer.window_set_title("鲸落 · 第%d章 %s（连续白盒）" % [chapter_id,str(data.title)])
	world=Node2D.new()
	world.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	for rect: Array in data.platforms:
		var floor_body: StaticBody2D=body(Rect2(point([rect[0],rect[1]]),Vector2(rect[2],rect[3])))
		# 薄高台单向支撑，保证底层绕行不被台阶的侧边堵住。
		(floor_body.get_child(0) as CollisionShape2D).one_way_collision=float(rect[1])<500 and float(rect[3])<=30
	body(Rect2(-40-offset.x,-400,40,1800))
	body(Rect2(float(data.get("width",3600))-offset.x,-400,40,1800))
	var actor: Node=preload("res://content/whalebelly/Player.tscn").instantiate()
	actor.set_script(preload("res://src/prototypes/chapter_two/player.gd"))
	player=actor as ChapterTwoPlayer
	player.position=point(checkpoint())
	player.world_bounds=Rect2(-80-offset.x,-400,float(data.get("width",3600))+160,1800)
	world.add_child(player)
	player.collision_mask=5
	player.show_debug=false
	player.died.connect(func() -> void: record("player_failed"))
	camera=Camera2D.new()
	camera.position=player.position+Vector2(0,-190)
	add_child(camera)
	encounter=ChapterRunEncounter.new()
	encounter.host=self
	world.add_child(encounter)
	view=ChapterRunView.new()
	view.host=self
	view.position=-offset
	world.add_child(view)
	var layer:=CanvasLayer.new()
	layer.layer=100
	add_child(layer)
	hud=ChapterRunHUD.new()
	hud.host=self
	layer.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flow=ChapterRunFlow.new()
	flow.host=self
	add_child(flow)
	flow.restore()
	encounter.restore_completed_bodies()
	record("ready",{"chapter":chapter_id,"stage":flow.stage().get("id","finished")})

func point(value: Array) -> Vector2: return ChapterRunCatalog.point(value)-offset

func body(rect: Rect2, parent: Node=null) -> StaticBody2D:
	var floor_body:=StaticBody2D.new()
	var shape:=CollisionShape2D.new()
	var box:=RectangleShape2D.new()
	box.size=rect.size
	shape.shape=box
	floor_body.position=rect.get_center()
	floor_body.add_child(shape)
	(parent if parent!=null else world).add_child(floor_body)
	return floor_body

func checkpoint() -> Array:
	for stage: Dictionary in data.stages:
		if not str(stage.id) in completed: return stage.get("checkpoint",data.spawn)
	return data.stages.back().get("checkpoint",data.spawn)

func _process(dt: float) -> void:
	if not is_instance_valid(flow): return
	if resume_wait>0:
		resume_wait=maxf(0,resume_wait-dt)
		if resume_wait<=0 and not keys_held():
			get_tree().paused=false
			player.controls_enabled=true
		else: resume_wait=maxf(resume_wait,0.01)
	if not get_tree().paused:
		elapsed+=dt
		flow.tick(dt)
	var cx: float=clampf(player.position.x,640-offset.x,maxf(640,float(data.get("width",3600))-640)-offset.x)
	camera.position=camera.position.lerp(Vector2(cx,clampf(player.position.y-190,300,480)),minf(1,dt*6))
	view.queue_redraw()
	hud.queue_redraw()

func hold() -> void:
	player.controls_enabled=false
	player.skill_controller.cancel()
	player.clear_combat_input()
	player.velocity=Vector2.ZERO
	get_tree().paused=true

func release() -> void:
	player.clear_combat_input()
	resume_wait=0.12

func keys_held() -> bool:
	for key: Key in KEYS:
		if Input.is_physical_key_pressed(key) or Input.is_key_pressed(key): return true
	return false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var code: int=event.physical_keycode if event.physical_keycode else event.keycode
	if code==KEY_F7 and chapter_id>4: launch.call_deferred(chapter_id-1)
	elif code==KEY_F8 and chapter_id<12: launch.call_deferred(chapter_id+1)
	elif code==KEY_R: reload.call_deferred(false)
	elif code==KEY_F6: reload.call_deferred(true)
	elif hud.dialogue.visible:
		if code in [KEY_F,KEY_ENTER,KEY_SPACE]: hud.dialogue.advance()
		elif code==KEY_ESCAPE: flow.close_dialogue()
	elif code==KEY_ESCAPE:
		paused_by_user=not paused_by_user
		if paused_by_user: hold()
		else: release()
	elif code==KEY_F and not get_tree().paused: flow.interact()
	else: return
	get_viewport().set_input_as_handled()

func reload(clear: bool) -> void:
	if clear:
		flags.clear()
		completed.clear()
		write_save()
	launch(chapter_id)

func launch(id: int) -> void:
	get_tree().paused=false
	get_tree().set_meta("chapter_run_launch",{"id":id,"suffix":suffix,"save":save_enabled,"restore":true})
	get_tree().change_scene_to_file("res://content/prototypes/chapters/main.tscn")

func save_path() -> String:
	var workspace: String=ProjectSettings.globalize_path("res://").sha256_text().left(10)
	return "user://chapters-whitebox/%s-%s-ch%02d.json" % [workspace,suffix,chapter_id]

func read_save() -> void:
	if not save_enabled or not FileAccess.file_exists(save_path()): return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(save_path()))
	if parsed is Dictionary and int(parsed.get("chapter",0))==chapter_id:
		flags=parsed.get("flags",{}).duplicate()
		for id: Variant in parsed.get("completed",[]): completed.append(str(id))

func write_save() -> void:
	if not save_enabled: return
	DirAccess.make_dir_recursive_absolute(save_path().get_base_dir())
	var file:=FileAccess.open(save_path(),FileAccess.WRITE)
	save_failed=file==null
	if file!=null: file.store_string(JSON.stringify({"version":1,"chapter":chapter_id,"flags":flags,"completed":completed}))

func record(id: String, detail: Dictionary={}) -> void:
	events.append({"id":id,"detail":detail,"seconds":snappedf(elapsed,0.01)})
	DirAccess.make_dir_recursive_absolute("res://build/qa/chapters")
	var file:=FileAccess.open("res://build/qa/chapters/latest-%02d.json" % chapter_id,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"chapter":chapter_id,"events":events,"completed":completed,"flags":flags}))

func _exit_tree() -> void:
	get_tree().paused=false
