class_name CampaignContinuity
extends Node
## A saved anatomical room graph + in-world shared door motifs. No new rooms.
var host: Node2D
var portals: Array[XumenContinuityPortal] = []
var depth: XumenContinuousDepth
var transition: XumenContinuityTransition

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	transition=XumenContinuityTransition.new()
	add_child(transition)

func bind_room() -> void:
	portals.clear()
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

func _process(_dt: float) -> void:
	if not is_instance_valid(host.camera): return
	var shift: Vector2 = (host.camera.position - host.point(host.room.size)*0.5)*0.009
	for portal: XumenContinuityPortal in portals:
		if is_instance_valid(portal): portal.set_camera_offset(shift)

func state() -> Dictionary:
	var items: Array[Dictionary] = []
	for portal: XumenContinuityPortal in portals:
		if is_instance_valid(portal): items.append(portal.snapshot())
	return {"room":host.room.get("id",""),"portals":items,"count":items.size(),"shared_depth":depth!=null,"depth_time":depth.elapsed if depth!=null else 0.0,"transition_active":transition.active}
