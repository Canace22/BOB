extends TestSuite
## Verifies the migrated scene without touching the playable campaign or user saves.

func test_fish_population_and_clock() -> void:
	var scene := load("res://src/world/scenery/local_environment/xumen_reference.tscn") as PackedScene
	var environment := add(scene.instantiate()) as LocalEnvironment
	environment.set_process(false)
	var schools: Array[Node] = []
	for child: Node in environment.get_children():
		if child is EnvironmentFishSchool:
			schools.append(child)
	eq(schools.size(), 3, "Three migrated fish schools")
	var total := 0
	for school: EnvironmentFishSchool in schools:
		total += school.sprites.size()
	eq(total, 62, "All authored fish retained")
	var fish: Sprite2D = schools[0].sprites[0]
	var start := fish.position
	environment.elapsed = 2.0
	environment.update_visuals()
	check(fish.position.distance_to(start) > 1.0, "Shared clock animates fish")
	var paused := fish.position
	environment.animate_environment = false
	environment._process(1.0)
	eq(fish.position, paused, "Paused clock holds fish position")
	check(not environment.get_node("CHARACTER").visible, "Reference character hidden in reusable scene")

func test_preview_has_no_gameplay_or_persistence() -> void:
	var scene := load("res://content/environment/local_environment_preview.tscn") as PackedScene
	var preview := add(scene.instantiate()) as Node2D
	check(preview.get_node("Environment/CHARACTER").visible, "Preview retains the reference silhouette")
	check(not _contains_physics(preview), "Environment preview contains no gameplay collision")
	eq(GameState.save_path, TEST_SAVE, "Preview does not change the save path")

func _contains_physics(node: Node) -> bool:
	if node is CollisionObject2D:
		return true
	for child: Node in node.get_children():
		if _contains_physics(child):
			return true
	return false
