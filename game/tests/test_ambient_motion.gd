extends TestSuite

const SCENE := preload("res://content/rooms/prototype/crab_environment_motion.tscn")


func test_authored_atlases_and_draw_order_preserve_combat_space() -> void:
	var scenery := add(preload("res://content/rooms/prototype/crab_scenery.tscn").instantiate())
	var board := scenery.get_node("Environment") as Sprite2D
	var scene := board.get_node("EnvironmentMotion") as Control
	eq(scene.get_global_rect(), Rect2(board.global_position, board.texture.get_size()), "clip matches the backdrop in the arena")
	var total := 0
	for node: Node in scene.get_children():
		if node is AmbientFishSchool:
			var school := node as AmbientFishSchool
			total += school.fish.size()
			for fish: Sprite2D in school.fish:
				eq(fish.texture.get_size(), Vector2(2560, 896), "full fish atlas loaded")
				check(fish.global_position.y < 750, "fish stay above fighting floor")
			check(school.z_index > 0 and board.z_index + school.z_index < 0, "fish draw above the backdrop and behind fighters")
		elif node is AmbientAtlas:
			var sprite := node as AmbientAtlas
			eq(sprite.texture.get_size(), Vector2(3072, 2304), "V3 original atlas loaded")
			eq(sprite.offset, Vector2(-192, -127), "fixed source root")
			eq(sprite.scale.x, sprite.scale.y, "baleen uses isotropic scaling")
	eq(total, 22, "three sparse schools avoid crowding the arena")


func test_complete_environment_cycle_returns_without_moving_roots() -> void:
	var scene := add(SCENE.instantiate())
	for node: Node in scene.get_children():
		if node is AmbientFishSchool:
			var school := node as AmbientFishSchool
			var start := school.fish[0].position
			var frame := school.fish[0].frame
			school._process(0.5)
			check(school.fish[0].position.distance_to(start) > 1, "fish swim forward")
			school._process(15.5)
			eq(school.fish[0].frame, frame, "tail returns after full group cycle")
			check(school.fish[0].position.is_equal_approx(start), "travel path loops")
		elif node is AmbientAtlas:
			var sprite := node as AmbientAtlas
			var root := sprite.position
			var first := sprite.frame
			sprite._process(1.0)
			check(sprite.frame != first, "authored poses advance")
			sprite._process(3.0)
			eq(sprite.frame, first, "48 poses loop at four seconds")
			eq(sprite.position, root, "attachment never drifts")


func test_tree_pause_and_world_hit_stop_freeze_environment() -> void:
	var scene := add(SCENE.instantiate())
	await tree.process_frame
	var school := scene.get_node("Silverfin") as AmbientFishSchool
	var sprite := scene.get_node("BaleenLeft") as AmbientAtlas
	tree.paused = true
	var frozen := Vector2(school.elapsed, sprite.elapsed)
	await tree.create_timer(0.05).timeout
	eq(Vector2(school.elapsed, sprite.elapsed), frozen, "pause freezes both clocks")
	tree.paused = false
	await tree.create_timer(0.05).timeout
	check(school.elapsed != frozen.x and sprite.elapsed != frozen.y, "resume advances both")
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	frozen = Vector2(school.elapsed, sprite.elapsed)
	await tree.create_timer(0.05).timeout
	eq(Vector2(school.elapsed, sprite.elapsed), frozen, "parent hit-stop freezes both")
