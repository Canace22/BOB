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
	if kind != "door": return
	inset = Sprite2D.new()
	inset.texture = load("res://art/doorways/tunnel.png")
	inset.centered = false
	var factor: float = height / inset.texture.get_height()
	inset.scale = Vector2.ONE * factor
	inset.position = art_offset - Vector2(inset.texture.get_width() * factor * 0.5, height)
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
	if is_instance_valid(inset):
		var open: bool = str(data.get("ability", "")) != "boss" or restriction().is_empty()
		inset.visible = open
		lip.visible = open

func nearby() -> bool:
	var delta: Vector2 = host.player.position - position
	return absf(delta.x) < radius and absf(delta.y) < 58.0

func restriction() -> String:
	var needed: String = str(data.get("ability", ""))
	if needed == "boss":
		for enemy: Dictionary in host.enemies:
			if enemy.boss and enemy.alive: return "先击败负壳守卫"
	elif not needed.is_empty() and not host.has_ability(needed):
		return "需要" + WhaleUICampaignData.ability_name(needed)
	if kind == "sealed": return "后续区域未开放 · 原路返回"
	return ""

func prompt() -> String:
	if not armed: return ""
	var reason: String = restriction()
	if not reason.is_empty(): return reason
	if kind == "passage": return ""
	if kind == "exit": return CampaignGuidance.door_label(host, data)
	return CampaignGuidance.door_label(host, data)

func update_entry() -> bool:
	var p: WhalebellyCampaignPlayer = host.player
	if p.position.distance_to(position) > radius + 35.0: armed = true
	if kind != "passage" or not armed or not nearby() or not restriction().is_empty(): return false
	return p.movement_axis() * direction > 0.1 and (p.position.x - position.x) * direction > -24.0
