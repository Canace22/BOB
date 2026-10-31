@warning_ignore_start("untyped_declaration")
class_name WhalebellyMechanisms
extends Node2D
## Native physics/art bindings for image-derived interactables. All coordinates
## are source pixels, so the triggers stay attached to fixed art, not parallax.
var host: Node2D
var phase: float = 0.0
var membrane_time: float = 0.0
var membrane_drop: float = 0.0
var original_polygon: PackedVector2Array
var contour: CollisionPolygon2D
var gate: Node2D
var gate_alpha: float = 1.0
var reward: Node2D
var trigger_nodes: Array[Area2D] = []
var rings_node: Node2D
var last_ring: Vector2 = Vector2.INF
var ring_pulse: float = 0.0
var membrane_events: int = 0
var last_event_sequence: int = 0

func _ready() -> void:
	name = "VisualMechanisms"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	last_event_sequence = host.event_sequence
	var doors: Node2D = Node2D.new()
	doors.name = "Doors"
	add_child(doors)
	for i: int in range(host.room.get("doors",[]).size()):
		var item: Dictionary = host.room.doors[i]
		var area: Area2D = Area2D.new()
		area.name = "Door" + str(i+1)
		area.position = host.point(item.pos) - Vector2(0,35)
		area.collision_layer = 0
		area.collision_mask = 2
		area.set_meta("destination", item.to)
		area.set_meta("ability", item.ability)
		var collider: CollisionShape2D = CollisionShape2D.new()
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = 100
		collider.shape = shape
		area.add_child(collider)
		doors.add_child(area)
		trigger_nodes.append(area)
	rings_node = Node2D.new()
	rings_node.name = "AnchorRings"
	rings_node.z_index = 5
	add_child(rings_node)
	rings_node.draw.connect(_draw_rings)
	for i: int in range(host.room.get("rings",[]).size()):
		var anchor: Marker2D = Marker2D.new()
		anchor.name = "Ring"+str(i+1)
		anchor.position = host.point(host.room.rings[i])
		rings_node.add_child(anchor)
	gate = host.scenery.get_node_or_null("World/DoorArt")
	reward = host.scenery.get_node_or_null("World/RewardArt")
	if host.room_index == 2:
		contour = host.scenery.get_node("World/Terrain/Surface0/Contour")
		original_polygon = contour.polygon.duplicate()
	if gate != null and host.defeated.get("R1-04:0",false):
		gate_alpha = 0
		gate.modulate.a = 0

func _physics_process(dt: float) -> void:
	if host == null or not is_instance_valid(host.player): return
	if host.reference_visible or host.layer_solo >= 0 or not host.capture_path.is_empty(): return
	if host.room_index == 2:
		var p: Vector2 = host.player.position
		var loaded: bool = p.x > 700 and p.x < 970 and p.y > 580 and p.y < 720 and host.player.is_on_floor()
		membrane_time = minf(1.3,membrane_time+dt) if loaded else maxf(0,membrane_time-dt*1.5)
		var target: float = smoothstep(0.25,0.85,membrane_time)*42.0
		var previous: float = membrane_drop
		membrane_drop = move_toward(membrane_drop,target,dt*85)
		if previous < 5 and membrane_drop >= 5:
			membrane_events += 1
			host.record_event("membrane_sag",{"drop":membrane_drop})
			host.sfx("sweep")
		var changed: PackedVector2Array = original_polygon.duplicate()
		for i: int in range(changed.size()):
			var weight: float = sin(clampf((original_polygon[i].x-680.0)/320.0,0,1)*PI)
			changed[i].y += membrane_drop*weight
		contour.polygon = changed
		var world: Sprite2D = host.scenery.get_node("World/WorldOriginalPixels")
		world.material.set_shader_parameter("membrane_drop", membrane_drop)

func _process(dt: float) -> void:
	if host == null: return
	var frozen: bool = host.reference_visible or host.layer_solo >= 0 or not host.capture_path.is_empty()
	if frozen: return
	phase += dt
	for layer: String in ["Far","Middle","World","Foreground"]:
		var sprite: Sprite2D = host.scenery.get_node_or_null(layer+"/"+layer+"OriginalPixels")
		if sprite != null:
			sprite.material.set_shader_parameter("clock", phase)
			sprite.material.set_shader_parameter("motion", 1.0)
	if reward != null:
		reward.position.y = sin(phase*1.9)*2.5
		reward.modulate = Color(1.0+sin(phase*2.1)*0.07,1.0+sin(phase*2.1)*0.07,1.0)
	if gate != null:
		var target: float = 0.0 if host.defeated.get("R1-04:0",false) else 1.0
		gate_alpha = move_toward(gate_alpha,target,dt*0.8)
		gate.modulate.a = gate_alpha
		gate.position.y = -18*(1-gate_alpha)
		if target == 0 and gate_alpha > 0.98:
			host.sfx("save")
			host.record_event("gate_open",{"room":str(host.room.id)})
	ring_pulse = maxf(0,ring_pulse-dt)
	# Consume the authoritative event as well as the current pose. A short
	# grapple can finish within catch-up physics steps before a render frame.
	var new_events: Array = []
	for i: int in range(host.events.size()-1,-1,-1):
		var event: Dictionary = host.events[i]
		if int(event.get("seq",0)) <= last_event_sequence: break
		new_events.push_front(event)
	last_event_sequence = host.event_sequence
	for event: Dictionary in new_events:
		if event.event == "anchor":
			last_ring = host.point(event.data.target)-Vector2(0,55)
			ring_pulse = 0.6
			host.sfx("collect")
			host.record_event("ring_attached",{"x":last_ring.x,"y":last_ring.y})
	if host.player.grapple_target != Vector2.INF:
		var target: Vector2 = host.player.grapple_target-Vector2(0,55)
		if target != last_ring:
			last_ring=target
			ring_pulse=0.6
			host.sfx("collect")
			host.record_event("ring_attached",{"x":target.x,"y":target.y})
	rings_node.queue_redraw()

func _draw_rings() -> void:
	if ring_pulse>0 and last_ring!=Vector2.INF:
		rings_node.draw_arc(last_ring,25+(0.6-ring_pulse)*30,0,TAU,40,Color(0.55,0.85,1,ring_pulse),2,true)

func evidence_state() -> Dictionary:
	return {"doors":trigger_nodes.size(),"rings":rings_node.get_child_count(),"membrane_drop":membrane_drop,"membrane_events":membrane_events,"gate_alpha":gate_alpha,"phase":phase}
