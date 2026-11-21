class_name ChapterTwoWhitebox
extends Node2D
## 独立章节入口、存档和重试所有权；不实例化正式主线宿主。
var player: ChapterTwoPlayer
var guard: ChapterTwoGuard
var world: Node2D
var camera: Camera2D
var view: ChapterTwoView
var reference: ChapterReferencePresentation
var hud: ChapterTwoHUD
var flow: ChapterTwoFlow
var blockade: CollisionShape2D
var facts: Dictionary = {}
var events: Array[Dictionary] = []
var elapsed: float = 0.0
var save_enabled: bool = true
var restore_progress: bool = true
var qa_save_suffix: String = "play"
var save_failed: bool = false
var paused_by_user: bool = false
var resume_wait: float = 0.0
var reset_requested: bool = false
const PLATFORMS: Array[Rect2] = [Rect2(0,300,470,60),Rect2(460,390,270,50),Rect2(720,470,270,50),Rect2(950,520,1000,80),Rect2(1930,650,920,80)]
const HOLD_KEYS: Array[Key] = [KEY_A,KEY_D,KEY_W,KEY_S,KEY_J,KEY_K,KEY_I,KEY_L,KEY_Q,KEY_E,KEY_Z,KEY_SPACE,KEY_F,KEY_ENTER]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_tree().has_meta("chapter_two_launch"):
		var config: Dictionary = get_tree().get_meta("chapter_two_launch")
		get_tree().remove_meta("chapter_two_launch")
		qa_save_suffix = str(config.suffix)
		save_enabled = bool(config.save)
		restore_progress = bool(config.restore)
	DisplayServer.window_set_title("鲸落 · 第二章折井白盒（独立进度）")
	if restore_progress: read_progress()
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	for rect: Rect2 in PLATFORMS: _body(rect)
	_body(Rect2(-40,-300,40,1700))
	_body(Rect2(2850,-300,40,1700))
	_body(Rect2(1805,65,50,455),true)
	var actor: Node = preload("res://content/whalebelly/Player.tscn").instantiate()
	actor.set_script(preload("res://src/prototypes/chapter_two/player.gd"))
	player = actor as ChapterTwoPlayer
	player.position = checkpoint()
	world.add_child(player)
	player.world_bounds = Rect2(-100,-400,3100,1450)
	player.collision_mask = 5
	player.show_debug = false
	player.died.connect(func() -> void: record("player_failed"))
	guard = ChapterTwoGuard.new()
	guard.profile = EnemyLabCatalog.profile(2)
	guard.player = player
	guard.position = Vector2(1570,520)
	guard.show_ranges = false
	guard.auto_attack = false
	world.add_child(guard)
	view = ChapterTwoView.new()
	view.host = self
	world.add_child(view)
	camera = Camera2D.new()
	camera.position = Vector2(640,280)
	camera.position_smoothing_enabled = false
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	canvas.layer = 100
	hud = ChapterTwoHUD.new()
	hud.host = self
	canvas.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flow = ChapterTwoFlow.new()
	flow.host = self
	add_child(flow)
	guard.blockade_removed.connect(flow.defeated)
	flow.restore()
	install_reference(2,PLATFORMS)
	record("ready",{"restored":facts.duplicate()})

func install_reference(id: int, floors: Array[Rect2], origin: Vector2=Vector2.ZERO) -> void:
	reference=ChapterReferencePresentation.new()
	world.add_child(reference)
	reference.install(id,floors,origin,reference_state)
	view.queue_redraw()

func reference_state() -> Dictionary:
	return {"flags":facts,"stage":flow.stage,"time":elapsed,"phase":flow.rescue_time}

func using_reference() -> bool: return is_instance_valid(reference) and reference.active

func _body(rect: Rect2, is_blockade: bool = false) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	world.add_child(body)
	if is_blockade: blockade = shape

func checkpoint() -> Vector2:
	if facts.get("guard_defeated",false): return Vector2(1760,510)
	return Vector2(1000,510) if facts.get("refusal",false) else Vector2(150,290)

func set_blockade(open: bool) -> void:
	blockade.set_deferred("disabled",open)
	view.queue_redraw()

func _process(dt: float) -> void:
	if not is_instance_valid(flow): return
	if resume_wait>0:
		resume_wait = maxf(0,resume_wait-dt)
		if resume_wait<=0 and not keys_held():
			get_tree().paused = false
			player.controls_enabled = true
		else: resume_wait = maxf(resume_wait,0.01)
	if not get_tree().paused:
		elapsed += dt
		flow.tick(dt)
	_update_camera(dt)
	hud.queue_redraw()
	view.queue_redraw()
	if reset_requested:
		reset_requested = false
		# 同一白盒重试沿用独立存档配置，不能落回另一测试/试玩进度。
		get_tree().set_meta("chapter_two_launch",{"suffix":qa_save_suffix,"save":save_enabled,"restore":true})
		get_tree().paused = false
		get_tree().reload_current_scene()

func _update_camera(dt: float) -> void:
	var desired := Vector2(clampf(player.position.x,640,2210),clampf(player.position.y-190,250,460))
	if flow.stage=="rescue": desired = Vector2(2200,420)
	# 战后对话保留上层守卫、断口和下层救援者的同屏关系。
	elif flow.dialogue_id=="permit": desired = Vector2(1920,420)
	camera.position = camera.position.lerp(desired,minf(1,dt*6))

func keys_held() -> bool:
	for key: Key in HOLD_KEYS:
		if Input.is_physical_key_pressed(key) or Input.is_key_pressed(key): return true
	return false

func hold_world() -> void:
	player.controls_enabled = false
	player.clear_combat_input()
	player.velocity = Vector2.ZERO
	get_tree().paused = true

func release_world() -> void:
	player.clear_combat_input()
	resume_wait = 0.12

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var code: int = event.physical_keycode if event.physical_keycode else event.keycode
	if code==KEY_F6:
		facts.clear()
		save_progress()
		reset_requested = true
	elif code==KEY_R:
		record("retry_requested")
		reset_requested = true
	elif hud.dialogue.visible:
		if code in [KEY_F,KEY_SPACE,KEY_ENTER]: hud.dialogue.advance()
		elif code==KEY_ESCAPE: flow.close_dialogue()
	elif code==KEY_ESCAPE:
		if flow.stage=="rescue": return
		paused_by_user = not paused_by_user
		if paused_by_user: hold_world()
		else: release_world()
	elif code==KEY_F and not get_tree().paused: flow.interact()
	else: return
	get_viewport().set_input_as_handled()

func save_path() -> String:
	var workspace: String = ProjectSettings.globalize_path("res://").sha256_text().left(10)
	return "user://chapter-two-whitebox/"+workspace+"-"+qa_save_suffix+".json"

func read_progress() -> void:
	if not save_enabled or not FileAccess.file_exists(save_path()): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path()))
	if parsed is Dictionary and int(parsed.get("version",0))==1:
		facts = parsed.get("facts",{}).duplicate()

func save_progress() -> void:
	if not save_enabled: return
	DirAccess.make_dir_recursive_absolute(save_path().get_base_dir())
	var file := FileAccess.open(save_path(),FileAccess.WRITE)
	save_failed = file==null
	if file!=null: file.store_string(JSON.stringify({"version":1,"facts":facts}))

func record(id: String, detail: Dictionary = {}) -> void:
	events.append({"id":id,"seconds":snappedf(elapsed,0.01),"detail":detail})
	DirAccess.make_dir_recursive_absolute("res://build/qa/chapter-two")
	var file := FileAccess.open("res://build/qa/chapter-two/latest-play.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"facts":facts,"events":events,"seconds":elapsed,"scope":"Independent whitebox; rescue uses labelled proxies."},"\t"))

func _exit_tree() -> void:
	get_tree().paused = false
