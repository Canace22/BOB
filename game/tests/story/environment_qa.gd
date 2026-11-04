extends Node2D
## GPU placement fixtures only: this does not prove keyboard traversal.
const OUT := "res://build/qa/story-c01/"
var host: StoryMain
var checks: Array[Dictionary] = []
var captures: Array[Dictionary] = []

class CollisionOverlay extends Node2D:
	var shapes: Array[CollisionShape2D] = []
	var actors: Array[Node2D] = []
	func _draw() -> void:
		for collider: CollisionShape2D in shapes:
			draw_set_transform_matrix(collider.global_transform)
			collider.shape.draw(get_canvas_item(), Color(0.2, 1.0, 0.8, 0.18))
			draw_rect(collider.shape.get_rect(), Color(0.2, 1.0, 0.8, 0.9), false, 1.5)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		for actor: Node2D in actors:
			draw_line(actor.global_position-Vector2(18,0), actor.global_position+Vector2(18,0), Color(1,0.4,0.2), 2)
			draw_line(actor.global_position-Vector2(0,8), actor.global_position+Vector2(0,8), Color(1,0.4,0.2), 2)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func tick(count: int) -> void:
	for i: int in count: await get_tree().physics_frame

func check(id: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"id":id, "pass":passed, "detail":detail})
	print("STORY_ENV ", id, " ", passed, " ", detail)

func shot(id: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	RenderingServer.force_draw()
	var rendered: Image = get_viewport().get_texture().get_image()
	var error := rendered.save_png(OUT+"environment-"+id+".png")
	check(id+"_capture", error == OK and not rendered.is_empty(), rendered.get_size())
	captures.append({"id":id,"viewport":rendered.get_size(),"player_foot":host.player.position,
		"camera":host.camera.position,"zoom":host.camera.zoom,"fixture":true})

func motion_state() -> String:
	var data: Array = [host.environment.elapsed]
	for part: Node in host.environment.get_node("Motion").get_children():
		if part is WhalebellyBaleenFrames: data.append([part.frame,part.position])
		elif part is ChapterFishGroup:
			for fish: Sprite2D in part.sprites: data.append([fish.position,fish.frame])
		elif part is EnvironmentBubbleEmitter:
			for bubble: Dictionary in part.bubbles: data.append(bubble.node.position)
	for wisp: Node2D in host.environment.get_node("ReturningSilt").get_children():
		data.append(wisp.position)
	return var_to_str(data)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	if DisplayServer.get_name() == "headless":
		push_error("environment_qa requires a real GPU viewport; headless is not a capture.")
		get_tree().quit(1)
		return
	host = preload("res://content/story/main.tscn").instantiate() as StoryMain
	host.qa_save = true
	add_child(host)
	host.set_process(false)
	host.set_physics_process(false)
	host.ui.hide()
	host.ui.hide_modal()
	host.player.controls_enabled = true
	get_tree().paused = false
	check("qa_save_isolation", host.progress.path == "user://story-c01-qa/progress.json")
	# Disable event progression, never save flags or resolve combat in these fixtures.
	host.environment.animation_enabled = false
	host.environment.update_at(1.25)
	for enemy: StoryForager in host.foragers: enemy.reset(false)
	var debug := CollisionOverlay.new()
	debug.z_index = 100
	debug.visible = false
	add_child(debug)
	for collision: Node in host.environment.get_node("Collisions").find_children("*","CollisionShape2D"):
		debug.shapes.append(collision as CollisionShape2D)
	debug.shapes.append(host.player.get_node("CollisionShape2D") as CollisionShape2D)
	debug.actors.append(host.player)
	for enemy: StoryForager in host.foragers:
		debug.actors.append(enemy)
		for child: Node in enemy.get_children():
			if child is CollisionShape2D: debug.shapes.append(child)
	for fixture: Dictionary in [
		{"id":"left-residents","foot":Vector2(150,780),"camera":Vector2(640,640),"floor":780.0},
		{"id":"left-perch","foot":Vector2(1185,650),"camera":Vector2(1360,640),"floor":650.0},
		{"id":"central-divider","foot":Vector2(1570,650),"camera":Vector2(1570,640),"floor":650.0},
		{"id":"right-perch","foot":Vector2(1945,650),"camera":Vector2(1840,640),"floor":650.0},
		{"id":"right-current","foot":Vector2(2580,780),"camera":Vector2(2560,640),"floor":780.0}
	]:
		host.player.position = fixture.foot-Vector2(0,20)
		host.player.velocity = Vector2.ZERO
		host.camera.zoom = Vector2.ONE
		host.camera.position = fixture.camera
		await tick(48)
		check(fixture.id+"_feet", host.player.is_on_floor() and absf(host.player.position.y-fixture.floor)<1.5,host.player.position)
		debug.visible = false
		await shot(fixture.id)
		debug.queue_redraw()
		debug.visible = true
		await shot(fixture.id+"-collision")
		debug.visible = false
	for enemy: StoryForager in host.foragers:
		check(enemy.stable_id+"_feet",enemy.is_on_floor() and absf(enemy.position.y-780)<1.5,enemy.position)
	host.camera.position = Vector2(1600,500)
	var viewport_size := get_viewport_rect().size
	host.camera.zoom = Vector2.ONE*minf(viewport_size.x/3200.0, viewport_size.y/1000.0)
	await shot("panorama")
	host.environment.animation_enabled = true
	await tick(8)
	var before := motion_state()
	get_tree().paused = true
	await get_tree().create_timer(0.18,true).timeout
	check("tree_pause_holds",before==motion_state())
	get_tree().paused = false
	await tick(8)
	check("resume_advances",before!=motion_state())
	host.environment.animation_enabled = false
	before = motion_state()
	await tick(8)
	check("animation_toggle_holds",before==motion_state())
	host.environment.animation_enabled = true
	host.environment.animation_speed = 0.0
	before = motion_state()
	await tick(8)
	check("zero_speed_holds",before==motion_state())
	host.environment.update_at(180.0)
	var fish_count := 0
	var bubble_count := 0
	for element: Node in host.environment.get_node("Motion").get_children():
		if element is ChapterFishGroup: fish_count += element.sprites.size()
		elif element is EnvironmentBubbleEmitter: bubble_count += element.bubbles.size()
	check("bounded_after_180_seconds",fish_count==16 and bubble_count==13 and host.environment.get_node("ReturningSilt").get_child_count()==9,
		{"fish":fish_count,"bubbles":bubble_count,"silt":9,"mode":"time-jump state check, not 180s visual review"})
	var failures: int = checks.filter(func(item: Dictionary) -> bool: return not item.pass).size()
	FileAccess.open(OUT+"environment-checks.json",FileAccess.WRITE).store_string(JSON.stringify({
		"checks":checks,"failed":failures,"captures":captures,
		"boundary":"Real main and GPU viewport, QA saves only; explicit actor/camera placement fixtures. Not keyboard route completion or user art approval."
	},"\t"))
	get_tree().paused = false
	get_tree().quit(0 if failures==0 else 1)
