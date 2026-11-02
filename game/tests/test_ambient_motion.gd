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
	var light := scene.get_node("SoftLightLeft") as AmbientSoftLight
	eq(light.texture.get_size(), Vector2(512, 768), "actual painted light from main")
	eq(light.scale.x, light.scale.y, "light remains isotropic")
	var bubbles := scene.get_node("BubblesMiddle") as AmbientBubbles
	eq(bubbles.bubbles[0].texture.get_size(), Vector2(12, 12), "actual bubble bitmap from main")
	check(board.z_index + bubbles.z_index < 0, "bubbles stay behind combatants")
	check(bubbles.bounds.end.y + board.position.y < 896, "bubbles remain above floor")


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
	var light := scene.get_node("SoftLightLeft") as AmbientSoftLight
	var bubbles := scene.get_node("BubblesMiddle") as AmbientBubbles
	tree.paused = true
	var frozen := Vector4(school.elapsed, sprite.elapsed, light.elapsed, bubbles.elapsed)
	await tree.create_timer(0.05).timeout
	eq(Vector4(school.elapsed, sprite.elapsed, light.elapsed, bubbles.elapsed), frozen, "pause freezes all four clocks")
	tree.paused = false
	await tree.create_timer(0.05).timeout
	check(school.elapsed != frozen.x and sprite.elapsed != frozen.y, "resume advances both")
	check(light.elapsed != frozen.z and bubbles.elapsed != frozen.w, "new layers resume with World")
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	frozen = Vector4(school.elapsed, sprite.elapsed, light.elapsed, bubbles.elapsed)
	await tree.create_timer(0.05).timeout
	eq(Vector4(school.elapsed, sprite.elapsed, light.elapsed, bubbles.elapsed), frozen, "parent hit-stop freezes all four clocks")


func test_bubbles_recycle_within_approved_background_bounds() -> void:
	var scene := add(SCENE.instantiate())
	var emitter := scene.get_node("BubblesMiddle") as AmbientBubbles
	var first := emitter.bubbles[1].position
	emitter._process(0.5)
	check(emitter.bubbles[1].position.y < first.y, "bubbles rise")
	for step in 80:
		emitter._process(0.5)
		for bubble in emitter.bubbles:
			check(emitter.bounds.grow(0.001).has_point(bubble.position), "recycling stays in background water, including invisible boundary")
			check(bubble.modulate.a >= 0 and bubble.modulate.a <= emitter.opacity + 0.00001, "fade never flashes")
