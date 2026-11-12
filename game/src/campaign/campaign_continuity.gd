class_name CampaignContinuity
extends Node
## A saved anatomical room graph + in-world shared door motifs. No new rooms.
var host: Node2D
var portals: Array[XumenContinuityPortal] = []
var depth: XumenContinuousDepth
var transition: XumenContinuityTransition
var doorways: Array[CampaignDoorway] = []
var travelling: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	transition=XumenContinuityTransition.new()
	add_child(transition)

func bind_room() -> void:
	portals.clear()
	doorways.clear()
	var entrances: Node = host.scenery.get_node_or_null("Doorways")
	if entrances != null:
		for entrance: CampaignDoorway in entrances.get_children():
			for door: Dictionary in host.room.get("doors", []):
				var target: int = int(door.to)
				var target_id: String = str(host.rooms[target].id) if target >= 0 else ("chapter-exit" if target == -1 else "far-latch")
				# Later regions name their target directly; the first-region exit keeps its authored node.
				if entrance.destination_id == target_id or (door.has("to_id") and entrance.destination_id == str(door.to_id)) or (entrance.destination_id == "chapter-exit" and door.get("completes", false)):
					entrance.bind(host, door)
					doorways.append(entrance)
	depth=host.scenery.get_node_or_null("ContinuousOralDepth") as XumenContinuousDepth
	if depth!=null:
		depth.host=host
		depth.elapsed=host.clock
	for node: Node in host.scenery.find_children("*","Node2D",true,false):
		if node is XumenContinuityPortal:
			node.bind_level(host)
			node.update_at(host.clock)
			portals.append(node)

func begin_transition() -> void:
	if host.reference_visible or not host.capture_path.is_empty():return
	transition.begin()

func nearby_door() -> CampaignDoorway:
	if travelling: return null
	var closest: CampaignDoorway
	var distance: float = INF
	for entrance: CampaignDoorway in doorways:
		var d: float = host.player.position.distance_to(entrance.position)
		if entrance.nearby() and d < distance:
			closest = entrance
			distance = d
	return closest

func automatic_entry() -> Dictionary:
	if travelling: return {}
	for entrance: CampaignDoorway in doorways:
		if entrance.update_entry():
			entrance.armed = false
			return entrance.data
	return {}

func travel(door: Dictionary) -> void:
	if travelling: return
	travelling = true
	host.player_ui.notice_left = 0.0
	host.message_time = 0.0
	var actor: WhalebellyCampaignPlayer = host.player
	actor.transition_locked = true
	actor.invulnerable = maxf(actor.invulnerable, 2.0)
	actor.skill_controller.cancel()
	actor.skill_controller.input.clear()
	actor.clear_projectiles()
	actor.world_effects.clear()
	var start_room: Dictionary = host.room
	var delta: float = clampf(host.point(door.pos).x - actor.position.x, -22.0, 22.0)
	actor.facing = signf(delta) if absf(delta) > 1.0 else actor.facing
	actor.state = "run" if absf(delta) > 1.0 else "idle"
	actor.state_duration = 0.0
	for frame: int in 10:
		await get_tree().physics_frame
		if not is_instance_valid(actor) or host.room != start_room:
			travelling = false
			return
		var old_x: float = actor.position.x
		actor.move_and_collide(Vector2(delta / 10.0, 0))
		actor.run_visual.update(1.0 / 60.0, actor.position.x - old_x)
	await transition.fade_out()
	if host.room == start_room:
		host.record_event("door", {"from":host.room_index,"to":int(door.to)})
		host.load_room(int(door.to), door.get("spawn", []))
		host.player.transition_locked = true
		host.player.invulnerable = maxf(host.player.invulnerable, 0.8)
	await transition.fade_in()
	if is_instance_valid(host.player):
		host.player.transition_locked = false
		host.player.skill_controller.input.clear()
	travelling = false

func _process(_dt: float) -> void:
	if is_instance_valid(host.player):
		for entrance: CampaignDoorway in doorways:
			if is_instance_valid(entrance) and host.player.position.distance_to(entrance.position) > entrance.radius + 35.0:
				entrance.armed = true
	if not is_instance_valid(host.camera): return
	var shift: Vector2 = (host.camera.position - host.point(host.room.size)*0.5)*0.009
	for portal: XumenContinuityPortal in portals:
		if is_instance_valid(portal): portal.set_camera_offset(shift)

func state() -> Dictionary:
	var items: Array[Dictionary] = []
	for portal: XumenContinuityPortal in portals:
		if is_instance_valid(portal): items.append(portal.snapshot())
	var entrances: Array[Dictionary] = []
	for entrance: CampaignDoorway in doorways:
		if is_instance_valid(entrance): entrances.append({"destination":entrance.destination_id,"kind":entrance.kind,"x":entrance.position.x,"y":entrance.position.y,"armed":entrance.armed,"nearby":entrance.nearby(),"prompt":entrance.prompt()})
	return {"travelling":travelling,"doorways":entrances,"room":host.room.get("id",""),"portals":items,"count":items.size(),"shared_depth":depth!=null,"depth_time":depth.elapsed if depth!=null else 0.0,"transition_active":transition.active}
