extends TestSuite

class ResidentActor extends Node2D:
	var health: int = 5

class ResidentHost extends Node2D:
	var player: ResidentActor
	var scenery: Node2D
	var flags: Dictionary = {}
	func has_ability(id: String) -> bool: return bool(flags.get(id,false))

func fixture() -> ResidentHost:
	var level: ResidentHost = ResidentHost.new()
	level.player = ResidentActor.new()
	level.scenery = Node2D.new()
	level.add_child(level.player)
	level.add_child(level.scenery)
	add(level)
	return level

func resident(parent: Node2D, at: Vector2) -> KitInteractable:
	var result: KitInteractable = KitInteractable.new()
	result.position = at
	parent.add_child(result)
	return result

func test_resident_requires_current_visible_room_and_living_player() -> void:
	var level: ResidentHost = fixture()
	var actor: KitInteractable = resident(level.scenery,Vector2(80,20))
	check(actor.nearby(level),"nearby resident is interactive")
	actor.hide()
	check(not actor.nearby(level),"hidden resident cannot intercept input")
	actor.show()
	level.player.health = 0
	check(not actor.nearby(level),"dead player cannot start a conversation")
	level.player.health = 5
	var previous_room: Node2D = Node2D.new()
	level.add_child(previous_room)
	check(not resident(previous_room,Vector2.ZERO).nearby(level),"old scenery pending cleanup is ignored")

func test_nearest_selects_resident_in_range_and_current_room() -> void:
	var level: ResidentHost = fixture()
	var near: KitInteractable = resident(level.scenery,Vector2(35,0))
	resident(level.scenery,Vector2(90,0))
	resident(level.scenery,Vector2(0,150))
	var another: ResidentHost = fixture()
	resident(another.scenery,Vector2.ZERO)
	check(KitInteractable.nearest(level)==near,"nearest ignores wrong floor and other hosts")
	level.player.position = Vector2(300,0)
	check(KitInteractable.nearest(level)==null,"no interaction outside range")

func test_progress_text_reads_existing_flags_without_granting_progress() -> void:
	var level: ResidentHost = fixture()
	var actor: KitInteractable = resident(level.scenery,Vector2.ZERO)
	actor.lines = PackedStringArray(["base"])
	actor.progress_flag = "pressure"
	actor.progressed_lines = PackedStringArray(["after"])
	actor.required_flags = PackedStringArray(["bone","silence"])
	actor.locked_lines = PackedStringArray(["locked"])
	check(actor.lines_for(level)==PackedStringArray(["locked"]),"missing flags show locked text")
	level.flags = {"bone":true,"silence":true}
	check(actor.lines_for(level)==PackedStringArray(["base"]),"all prerequisites read normal lines")
	level.flags.pressure = true
	check(actor.lines_for(level)==PackedStringArray(["after"]),"existing progress selects followup")
	eq(level.flags,{"bone":true,"silence":true,"pressure":true},"reading does not alter progression")
