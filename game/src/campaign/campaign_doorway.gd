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
var data: Dictionary = {}
var armed: bool = false
var host: Node2D
var inset: Sprite2D
var lip: Sprite2D

func bind(level: Node2D, door: Dictionary) -> void:
	host = level
	data = door
	position = host.point(door.pos)
	armed = host.player.position.distance_to(position) > radius + 35.0
	if kind not in ["door", "passage"] or height <= 0.0: return
	inset = Sprite2D.new()
	inset.texture = load("res://art/doorways/tunnel.png")
	inset.centered = false
	var factor: float = height / inset.texture.get_height()
	inset.scale = Vector2.ONE * factor
	var placement: Vector2 = art_offset
	if kind == "passage":
		# Door graph points can sit above a slope. Put the painted lip on the
		# surface under the art centre, rather than across the standing actor.
		var floor_y: float = host.ground_y(position.x + placement.x, position.y)
		placement.y += floor_y - position.y + 192.0 * factor
	inset.position = placement - Vector2(inset.texture.get_width() * factor * 0.5, height)
	inset.z_index = 1
	add_child(inset)
	# Reuse the painted threshold as a foreground lip; it can cover entering feet.
	lip = Sprite2D.new()
	lip.texture = inset.texture
	lip.centered = false
	lip.region_enabled = true
	lip.region_rect = Rect2(0, 1344, 1024, 192)
	lip.scale = inset.scale
	lip.position = inset.position + Vector2(0, 1344 * factor)
	lip.z_index = host.player.z_index + 1
	add_child(lip)

func _process(_dt: float) -> void:
	if not is_instance_valid(host): return
	visible = not host.reference_visible and host.layer_solo < 0 and host.capture_path.is_empty()
	# Kit gates carry both states; the door graph decides which one shows.
	if has_node("Closed"):
		var shut: bool = not restriction().is_empty()
		get_node("Closed").visible = shut
		if has_node("Open"): get_node("Open").visible = not shut
	if is_instance_valid(inset):
		var open: bool = str(data.get("ability", "")) != "boss" or restriction().is_empty()
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
