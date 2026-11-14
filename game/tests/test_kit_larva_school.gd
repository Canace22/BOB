extends TestSuite
## Generated pixels are only a test fixture; runtime uses the authored atlas.
const School = preload("res://src/world/scenery/kit/kit_larva_school.gd")
class EcologyHost extends Node2D:
	var abilities: Dictionary = {}
	var practice: bool = false

func make_host() -> EcologyHost:
	var host := EcologyHost.new()
	add(host)
	return host

func make_school(host: EcologyHost) -> KitLarvaSchool:
	var value := School.new()
	value.texture = ImageTexture.create_from_image(Image.create(384,256,false,Image.FORMAT_RGBA8))
	value.bounds = Rect2(0,-90,720,180)
	value.population = 6
	host.add_child(value)
	value.set_process(false)
	return value

func test_larvae_have_separate_swim_frames_and_a_bounded_inert_ecology_pool() -> void:
	var host := make_host()
	var school := make_school(host)
	eq(school.members.size(),6,"Exactly the configured six individuals are created")
	eq(school.get_child_count(),6,"There is no secondary emitter pool or collision object")
	var phases: Dictionary = {}
	for member: Dictionary in school.members:
		phases[int(member.frame_phase)] = true
		check(member.node is Sprite2D,"Every individual is visual only")
	check(phases.size() > 1,"Bodies start in distinct authored poses")
	var original_frame: int = school.members[0].node.frame
	school.update_at(0.12)
	eq(school.members[0].node.frame,(original_frame + 1) % 8,"Body animation advances independently of path position")
	for time: float in [1.0,17.0,1000.0]:
		school.update_at(time)
		for member: Dictionary in school.members:
			check(school.bounds.has_point(member.node.position),"Closed-gate routes remain inside the bowl field")
			check(member.node.position.x < school.bounds.end.x * 0.35,"Closed-gate larvae stay near the bowl, not along the release route")
	eq(school.members.size(),6,"Long closed playback does not create more larvae")

func test_opening_the_gate_starts_from_the_current_pose_and_practice_does_not_release() -> void:
	var host := make_host()
	var school := make_school(host)
	school.update_at(33.0)
	host.practice = true
	school.update_at(33.01)
	check(not school.released,"F9 is not the permanent ending flag")
	var previous: Vector2 = school.members[0].node.position
	host.abilities.ending = true
	school.update_at(school.elapsed)
	eq(school.members[0].node.position,previous,"Unlocking at zero elapsed time does not teleport")
	school.update_at(school.elapsed + 0.01)
	check(school.members[0].node.position.distance_to(previous) < 1.0,"The first released step accelerates smoothly")
	check(school.released,"The real ending flag releases the same individuals")
	eq(school.members.size(),6,"Opening the gate reuses the original pool")

func test_released_school_wraps_with_edge_fade_and_reload_uses_permanent_release_state() -> void:
	var host := make_host()
	host.abilities.ending = true
	var school := make_school(host)
	check(school.released,"A saved ending restores the released state immediately")
	var before: Vector2 = school.members[0].node.position
	school.update_at(4.0)
	check(school.members[0].node.position.x > before.x,"Released swimmers follow the rightward outflow")
	var lowest_alpha: float = 1.0
	for i: int in 600:
		school.update_at(4.0 + float(i + 1) * 0.2)
		for member: Dictionary in school.members:
			check(school.bounds.grow(6.1).has_point(member.node.position),"Released individuals stay in the bounded field")
			lowest_alpha = minf(lowest_alpha,member.node.modulate.a)
	check(lowest_alpha < 0.02,"Swimmers fade to nearly invisible at a wrap boundary")
	eq(school.get_child_count(),6,"Repeated release cycles never expand the node pool")

func test_larva_clock_and_body_pose_hold_during_tree_pause() -> void:
	var host := make_host()
	var school := make_school(host)
	school.set_process(true)
	await tree.process_frame
	tree.paused = true
	var before: float = school.elapsed
	var position: Vector2 = school.members[0].node.position
	var frame: int = school.members[0].node.frame
	host.abilities.ending = true
	for i: int in 3: await tree.process_frame
	eq(school.elapsed,before,"Pause holds one shared path clock")
	eq(school.members[0].node.position,position,"Pause holds ecology positions")
	eq(school.members[0].node.frame,frame,"Pause holds authored body animation")
	tree.paused = false
	for i: int in 2: await tree.process_frame
	check(school.elapsed >= before and school.released,"Resume reads the saved release flag without changing pool size")
	school.set_process(false)
