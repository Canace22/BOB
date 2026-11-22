class_name CampaignDoorway
extends Node2D
## Authored entrance presentation; the room graph remains the source of progression.
@export var destination_id: String = ""
@export_enum("door", "passage", "exit", "sealed") var kind: String = "door"
@export var direction: float = 1.0
@export var height: float = 150.0
@export var art_offset: Vector2 = Vector2.ZERO
@export var prompt_offset: Vector2 = Vector2(0, -170)
@export var radius: float = 64.0
@export var tunnel_texture: Texture2D
@export var threshold_region := Rect2(0,1344,1024,192)
@export var texture_bounds := Rect2()
@export var tunnel_material: Material
var data: Dictionary = {}
var armed: bool = false
var host: Node2D
var inset: Sprite2D
var lip: Sprite2D
var barrier: Sprite2D

func bind(level: Node2D, door: Dictionary) -> void:
	host = level
	data = door
	update_visibility()
	position = host.point(door.pos)
	armed = host.player.position.distance_to(position) > radius + 35.0
	if is_instance_valid(inset): return
	var built_exit: bool = kind == "exit" and int(data.get("to", -1)) >= 0
	if (kind not in ["door", "passage", "sealed"] and not built_exit) or height <= 0.0: return
	if tunnel_texture == null: return

	inset = Sprite2D.new()
	inset.texture = tunnel_texture
	inset.centered = false
	inset.material = tunnel_material
	var bounds := texture_bounds if texture_bounds.has_area() else Rect2(Vector2.ZERO,inset.texture.get_size())
	var factor: float = height / bounds.size.y
	inset.scale = Vector2.ONE * factor
	var placement: Vector2 = art_offset
	if kind == "passage":
		# Door graph points can sit above a slope. Put the painted lip on the
		# surface under the art centre, rather than across the standing actor.
		var floor_y: float = host.ground_y(position.x + placement.x, position.y)
		placement.y += floor_y - position.y + threshold_region.size.y * factor
	inset.position = placement - Vector2((bounds.position.x+bounds.size.x*.5)*factor,bounds.end.y*factor)
	inset.z_index = 1
	add_child(inset)
	# Reuse the painted threshold as a foreground lip; it can cover entering feet.
	lip = Sprite2D.new()
	lip.texture = inset.texture
	lip.material = tunnel_material
	lip.centered = false
	lip.region_enabled = true
	lip.region_rect = threshold_region
	lip.scale = inset.scale
	lip.position = inset.position + Vector2(threshold_region.position.x,threshold_region.position.y) * factor
	lip.z_index = host.player.z_index + 1
	add_child(lip)
	if not has_node("Closed") and (kind == "sealed" or CampaignWorld.requirements(data).has("boss")):
		build_barrier()
	update_art()

func build_barrier() -> void:
	barrier = Sprite2D.new()
	barrier.name = "RestrictionArt"
	barrier.texture = load("res://art/world-kit/blowhole-latch-closed.png" if kind == "sealed" else "res://art/world-kit/anchor-pull-gate-closed.png")
	barrier.centered = false
	# Measured alpha >= 32 bounds of the synced masters. Faint export specks
	# around the bone gate must not lift its visible base above the floor.
	var bounds := Rect2i(43,15,255,482) if kind == "sealed" else Rect2i(75,37,272,440)
	var factor: float = height / maxf(float(bounds.size.y), 1.0)
	barrier.scale = Vector2.ONE * factor
	var floor_y: float = host.ground_y(position.x + art_offset.x, position.y)
	barrier.position = Vector2(art_offset.x - (bounds.position.x + bounds.size.x * 0.5) * factor, floor_y - position.y + art_offset.y - bounds.end.y * factor)
	barrier.z_index = 1
	add_child(barrier)

func _process(_dt: float) -> void:
	if not is_instance_valid(host): return
	update_visibility()
	update_art()

func update_visibility() -> void:
	visible = not host.reference_visible and host.layer_solo < 0 and host.capture_path.is_empty()
	# Streaming gates own both locked and open connections. The old room-local
	# frame must not reappear when an ability is missing or on the bind frame.
	if host.streaming.enabled and int(data.get("to",-1))>=0: hide()

func update_art() -> void:
	var shut: bool = not restriction().is_empty()

	# Kit gates carry both states; the door graph decides which one shows.
	if has_node("Closed"):
		get_node("Closed").visible = shut
		if has_node("Open"): get_node("Open").visible = not shut
	if is_instance_valid(barrier): barrier.visible = shut
	if is_instance_valid(inset):
		var open: bool = not shut if is_instance_valid(barrier) else str(data.get("ability", "")) != "boss" or not shut
		inset.visible = open
		lip.visible = open

func nearby() -> bool:
	var delta: Vector2 = host.player.position - position
	return absf(delta.x) < radius and absf(delta.y) < 58.0

func restriction() -> String:
	var reason: String = CampaignWorld.restriction(host, data)
	if reason.is_empty() and kind == "sealed": return CampaignWorld.UNBUILT
	return reason

func prompt() -> String:
	if not armed: return ""
	var reason: String = restriction()
	if not reason.is_empty(): return reason
	if kind == "exit": return CampaignGuidance.door_label(host, data)
	return CampaignGuidance.door_label(host, data)

func update_entry() -> bool:
	var p: WhalebellyCampaignPlayer = host.player
	if p.position.distance_to(position) > radius + 35.0: armed = true
	if kind != "passage" or not armed or not nearby() or not restriction().is_empty(): return false
	return p.movement_axis() * direction > 0.1 and (p.position.x - position.x) * direction > -24.0
