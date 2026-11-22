class_name ChapterThreeWhitebox
extends ChapterTwoWhitebox
## 仅复用白盒宿主的暂停/松键/重试；本章场地、事实和存档独立。
const FLOORS: Array[Rect2] = [Rect2(0,520,1110,65),Rect2(1100,650,1240,65),Rect2(1060,585,130,55),Rect2(2300,590,180,55),Rect2(2440,520,1110,65)]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_tree().has_meta("chapter_two_launch"):
		var config: Dictionary = get_tree().get_meta("chapter_two_launch")
		get_tree().remove_meta("chapter_two_launch")
		qa_save_suffix = str(config.suffix)
		save_enabled = bool(config.save)
		restore_progress = bool(config.restore)
	DisplayServer.window_set_title("鲸落 · 第三章胃室白盒（独立进度）")
	if restore_progress: read_progress()
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	for rect: Rect2 in FLOORS: _body(rect)
	_body(Rect2(-40,-300,40,1700))
	_body(Rect2(3550,-300,40,1700))
	_body(Rect2(3250,120,35,400),true)
	var actor: Node = preload("res://content/whalebelly/Player.tscn").instantiate()
	actor.set_script(preload("res://src/prototypes/chapter_two/player.gd"))
	player = actor as ChapterTwoPlayer
	player.position = checkpoint()
	world.add_child(player)
	player.world_bounds = Rect2(-100,-400,3800,1600)
	player.collision_mask = 5
	player.show_debug = false
	player.died.connect(func() -> void: record("player_failed"))
	guard = ChapterTwoGuard.new()
	guard.profile = EnemyLabCatalog.profile(1)
	guard.player = player
	guard.position = Vector2(1810,650)
	guard.lane = Vector2(1120,2240)
	guard.show_ranges = false
	guard.auto_attack = false
	world.add_child(guard)
	view = ChapterThreeView.new()
	view.host = self
	world.add_child(view)
	camera = Camera2D.new()
	camera.position = Vector2(640,280)
	camera.position_smoothing_enabled = false
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	canvas.layer = 100
	hud = ChapterThreeHUD.new()
	hud.host = self
	canvas.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flow = ChapterThreeFlow.new()
	flow.host = self
	add_child(flow)
	guard.blockade_removed.connect(flow.defeated)
	flow.restore()
	install_reference(3,FLOORS)
	record("ready",{"restored":facts.duplicate()})

func checkpoint() -> Vector2:
	if facts.get("valve_opened",false): return Vector2(900,510)
	if facts.get("enemy_cleared",false): return Vector2(2020,640)
	return Vector2(1050,510) if facts.get("met",false) else Vector2(130,510)

func save_path() -> String:
	return super.save_path().replace("chapter-two-whitebox","chapter-three-whitebox")

func _update_camera(dt: float) -> void:
	var desired := Vector2(clampf(player.position.x,640,2910),clampf(player.position.y-190,330,460))
	if flow.stage=="rescue": desired = Vector2(1200,420)
	camera.position = camera.position.lerp(desired,minf(1,dt*6))

func record(id: String, detail: Dictionary = {}) -> void:
	events.append({"id":id,"seconds":snappedf(elapsed,0.01),"detail":detail})
	DirAccess.make_dir_recursive_absolute("res://build/qa/chapter-three")
	var file := FileAccess.open("res://build/qa/chapter-three/latest-play.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"facts":facts,"events":events,"scope":"Independent chapter-three whitebox; labelled proxies."},"\t"))
