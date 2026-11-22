extends TestSuite
## 真实加载、物理查询和只读状态测试；不把配置存在当作画面或通关通过。
var sample_flags: Dictionary={}
var sample_completed: Array[String]=[]

class FallingProbe:
	extends CharacterBody2D
	var highest_y: float=INF
	func _physics_process(dt: float) -> void:
		velocity.y+=900.0*dt
		move_and_slide()
		highest_y=minf(highest_y,position.y)

func snapshot() -> Dictionary:
	return {"flags":sample_flags,"completed":sample_completed,"time":0.0,"stage":"fixture"}

func make_reference(chapter: int, world: Node2D, origin: Vector2=Vector2.ZERO) -> ChapterReferencePresentation:
	var view:=ChapterReferencePresentation.new()
	world.add_child(view)
	var floors: Array[Rect2]=[]
	view.install(chapter,floors,origin,snapshot)
	return view

func test_library_decodes_real_bitmaps_and_each_chapter_builds_without_missing() -> void:
	var library:=ChapterReferenceArt.new()
	for id: String in library.entries:
		var texture: Texture2D=library.texture(id)
		check(texture!=null,"Actual texture loads: "+id)
		if texture==null: continue
		var image: Image=texture.get_image()
		check(image!=null and not image.is_empty(),"Decoded pixels available: "+id)
	eq(library.missing.size(),0,"No missing or invalid library texture")
	for chapter: int in range(2,13):
		var world:=Node2D.new()
		add(world)
		var view: ChapterReferencePresentation=make_reference(chapter,world)
		await physics_frames(2)
		check(view.active,"Default reference enabled for chapter %d" % chapter)
		eq(view.art.missing.size(),0,"All instantiated chapter bitmaps load: %d" % chapter)
		check(view.bound_art.size()>0,"Chapter has actual sprite instances")
		world.queue_free()
		await physics_frames(1)

func test_shifted_chapters_collide_at_their_source_positions_exactly_once() -> void:
	for chapter: int in [5,7,8,12]:
		var data: Dictionary=ChapterRunCatalog.read(chapter)
		var origin: Vector2=ChapterRunCatalog.origin(data)
		check(origin.x>0,"Fixture actually uses shifted enemy coordinates")
		var world:=Node2D.new()
		world.position=Vector2(37,11)
		add(world)
		var view: ChapterReferencePresentation=make_reference(chapter,world,origin)
		await physics_frames(4)
		for raw: Rect2 in view.extra_surfaces:
			var expected: Vector2=Vector2(raw.get_center().x,raw.position.y)-origin+world.position
			var query:=PhysicsRayQueryParameters2D.create(expected-Vector2(0,25),expected+Vector2(0,25),1)
			var hit: Dictionary=world.get_world_2d().direct_space_state.intersect_ray(query)
			check(not hit.is_empty(),"Physics ray hits shifted platform in chapter %d" % chapter)
			if hit.is_empty(): continue
			var actual: Vector2=hit.position
			check(actual.distance_to(expected)<0.1,"Actual world contact applies origin exactly once")
			var body: StaticBody2D=hit.collider as StaticBody2D
			check(body!=null and body.get_parent()==view,"Hit is an installed side platform, not a fixture floor")
		world.queue_free()
		await physics_frames(1)

func test_visual_updates_preserve_progress_and_do_not_accumulate_nest_displacement() -> void:
	var world:=Node2D.new()
	add(world)
	sample_flags={"ch04_homes_above_water":false,"sentinel":{"untouched":true}}
	sample_completed=["existing_completed_stage"]
	var view: ChapterReferencePresentation=make_reference(4,world)
	var nest: Sprite2D=view.get_node("nest") as Sprite2D
	var start: Vector2=nest.position
	sample_flags.ch04_homes_above_water=true
	var before: int=hash([sample_flags,sample_completed])
	for frame: int in 90: view._process(0)
	eq(hash([sample_flags,sample_completed]),before,"Presentation never writes facts or completes a stage")
	eq(nest.position,start+Vector2(0,-70),"Repeated updates select one raised state instead of drifting")
	sample_flags.ch04_homes_above_water=false
	view._process(0)
	eq(nest.position,start,"Reloading an earlier state restores the original placement")
	world.queue_free()
	await physics_frames(1)
	world=Node2D.new()
	add(world)
	sample_flags={}
	view=make_reference(12,world)
	var closed: Sprite2D=view.get_node("gate_closed") as Sprite2D
	var opened: Sprite2D=view.get_node("gate_open") as Sprite2D
	check(closed.visible and not opened.visible,"Before opening only closed reference is visible")
	sample_flags.ch12_shift_narrow_cover=true
	before=hash([sample_flags,sample_completed])
	view._process(0)
	check(not closed.visible and opened.visible,"After partial opening the old closed bitmap cannot cover the open state")
	eq(hash([sample_flags,sample_completed]),before,"State selection grants no additional progress")

func test_chapter_four_ledge_can_be_crossed_from_below_and_stood_on() -> void:
	var world:=Node2D.new()
	add(world)
	sample_flags={}
	var view: ChapterReferencePresentation=make_reference(4,world)
	await physics_frames(3)
	var probe:=FallingProbe.new()
	var shape:=CollisionShape2D.new()
	var capsule:=CapsuleShape2D.new()
	capsule.radius=6
	capsule.height=24
	shape.shape=capsule
	probe.add_child(shape)
	probe.position=Vector2(1850,495)
	probe.velocity=Vector2(0,-440)
	world.add_child(probe)
	await physics_frames(95)
	check(probe.highest_y<425,"Actual body travels upward through the one-way ledge")
	check(probe.is_on_floor(),"Actual body lands on the newly installed ledge")
	check(absf(probe.position.y+12.0-450.0)<1.2,"Contact feet agree with the authored y450 surface")
	# 此物理夹具不代替真实玩家跳跃、走出侧台落回底路和跟随镜头验收。
	check(view.extra_surfaces.size()==1,"Physical fixture used only the new refuge ledge")

func test_name_shell_keeps_its_owner_until_recorded_handoff_and_slot_changes() -> void:
	var world:=Node2D.new()
	add(world)
	sample_flags={}
	sample_completed=[]
	var view: ChapterReferencePresentation=make_reference(9,world)
	var held: Sprite2D=view.get_node("name_shell") as Sprite2D
	var carried: Sprite2D=view.get_node("carried_name_shell") as Sprite2D
	check(held.visible and not carried.visible,"Before chapter-nine handoff the guard retains the visible shell")
	sample_completed.append("ch09_receive_name_shell")
	var before: int=hash([sample_flags,sample_completed])
	view._process(0)
	check(not held.visible and carried.visible,"Only the recorded handoff swaps ownership references")
	eq(hash([sample_flags,sample_completed]),before,"Ownership view cannot mark the handoff complete itself")
	world.queue_free()
	await physics_frames(1)
	world=Node2D.new()
	add(world)
	sample_flags={}
	sample_completed=[]
	view=make_reference(10,world)
	var slot: Sprite2D=view.get_node("name_shell") as Sprite2D
	check(not slot.visible,"Entering chapter ten does not pre-place the shell in its slot")
	sample_flags.ch10_set_shell=true
	view._process(0)
	check(slot.visible,"Actual placement fact reveals the shell in the slot")
	sample_flags.ch10_take_shell=true
	before=hash([sample_flags,sample_completed])
	view._process(0)
	check(not slot.visible,"Taking the shell removes its old slot image")
	eq(hash([sample_flags,sample_completed]),before,"Taking display neither grants nor removes facts")
