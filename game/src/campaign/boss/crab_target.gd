class_name CampaignCrabTarget
extends Node2D
## Adapt the large shell to the unchanged campaign target/skill contract.
var boss: Node2D
var data: Dictionary
var resolved_projectiles: Dictionary = {}

func _ready() -> void:
	add_to_group("tide_targets")
	synchronize()

func synchronize() -> void:
	var area: Rect2 = boss.hurt_rect()
	var at: Vector2 = boss.target.global_position
	global_position = Vector2(clampf(at.x,area.position.x,area.end.x),clampf(at.y,area.position.y,area.end.y)) if area.has_area() else boss.global_position

func is_campaign_enemy() -> bool: return true
func can_receive_hit() -> bool: return data.alive
func hurt_rect() -> Rect2: return boss.hurt_rect()

func take_hit(amount: int) -> void:
	# Existing projectiles mark their target immediately before take_hit().
	# Read that record to preserve ranged classification without changing them.
	for orb: Node in get_tree().get_nodes_in_group("tide_player_projectiles"):
		var hits: Dictionary = orb.get("hit_ids")
		if hits.has(get_instance_id()) and not resolved_projectiles.has(orb.get_instance_id()):
			resolved_projectiles[orb.get_instance_id()] = true
			boss.receive_attack(amount,false,true,orb.global_position)
			return
	var p: Node2D = boss.target
	var key: String = p.skill_controller.visual_key if p.skill_controller.active else p.state
	boss.receive_attack(amount,key in ["heavy","great_slash","dive","dark_dive"],false,p.global_position)
