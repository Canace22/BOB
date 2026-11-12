class_name TideSkillHits
extends RefCounted
var actor: TidePlayer

func area_hit(spec: Dictionary, direction: float) -> void:
	var reach: float=float(spec.get("reach",100.0))
	var origin: Vector2=actor.global_position
	var shape: String=str(spec.get("shape","front"))
	var area:=Rect2(origin+Vector2(0 if direction>0 else -reach,-110),Vector2(reach,110))
	if shape=="up": area=Rect2(origin+Vector2(-70,-reach-50),Vector2(140,reach))
	elif shape=="radial": area=Rect2(origin-Vector2(reach,reach),Vector2.ONE*reach*2.0)
	for target: Node in actor.get_tree().get_nodes_in_group("tide_targets"):
		if not target.has_method("hurt_rect") or not area.intersects(target.hurt_rect()): continue
		if actor.hit_targets.has(target.get_instance_id()): continue
		actor._hit(target,int(spec.get("damage",actor.melee_damage)),bool(spec.get("gain",false)))
		if not actor.hit_targets.has(target.get_instance_id()): continue
		if target.has_method("apply_knockback"): target.apply_knockback(direction*float(spec.get("knockback",0.0)))
		if shape=="front" and str(spec.get("motion",""))=="free": actor.start_recoil(-direction)

func projectile(damage: int, direction: float, piercing: bool=false) -> void:
	var orb:=preload("res://src/campaign/tide_orb.gd").new()
	var fallback: Vector2=actor.global_position+Vector2(direction*26,-actor.collision_size.y*0.65)
	var origin: Vector2=socket_world("shadow_orb" if piercing else "orb","muzzle",fallback,direction)
	orb.direction=direction
	orb.speed=actor.orb_speed
	orb.life=actor.orb_lifetime
	orb.damage=damage
	orb.caster=actor
	orb.piercing=piercing
	actor.get_parent().add_child(orb)
	orb.global_position=origin

func socket_world(key: String, socket_name: String, fallback: Vector2, direction: float) -> Vector2:
	var view: Node=actor.get_node_or_null("RunVisualController")
	if view!=null and view.has_method("world_socket"):
		return view.world_socket(key,socket_name,fallback,direction)
	return fallback
