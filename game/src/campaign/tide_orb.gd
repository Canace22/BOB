@warning_ignore_start("untyped_declaration")
class_name WhalebellyTideOrb
extends Area2D
var direction: float = 1
var speed: float = 400
var life: float = 1.5
var damage: int = 20
var caster: Node
var piercing: bool = false
var hit_ids: Dictionary = {}
var radius: float = 7.0
func _ready() -> void:
	add_to_group("tide_player_projectiles")
	if is_instance_valid(caster):
		caster.tree_exiting.connect(_caster_exiting)
		caster.damaged.connect(queue_free)
	collision_layer=0
	collision_mask=1
	var shape:=CollisionShape2D.new()
	var circle:=CircleShape2D.new()
	circle.radius=radius
	shape.shape=circle
	add_child(shape)
	var visual:=Sprite2D.new()
	var art_path: String="res://art/tide-picker-action36/shadow_projectile.png" if piercing else "res://art/tide-picker-action36/projectile.png"
	visual.texture=load(art_path) if ResourceLoader.exists(art_path) else load("res://art/whalebelly/runtime/v02/lamp.png")
	visual.scale=Vector2.ONE*20.0/maxf(visual.texture.get_width(),visual.texture.get_height())
	visual.flip_h=direction<0
	add_child(visual)
	body_entered.connect(func(_body): queue_free())
func _physics_process(dt:float) -> void:
	if not is_instance_valid(caster) or caster.health<=0: queue_free();return
	var start:=global_position
	global_position.x+=speed*direction*dt
	life-=dt
	var query:=PhysicsRayQueryParameters2D.create(start,global_position,1)
	var wall: Dictionary=get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty(): global_position=wall.position
	var swept := Rect2(Vector2(minf(start.x,global_position.x),start.y-radius),Vector2(absf(global_position.x-start.x),radius*2.0))
	var targets: Array[Node]=get_tree().get_nodes_in_group("tide_targets")
	targets.sort_custom(func(a: Node,b: Node) -> bool: return start.distance_squared_to(a.global_position)<start.distance_squared_to(b.global_position))
	for target in targets:
		if hit_ids.has(target.get_instance_id()): continue
		if target.has_method("can_receive_hit") and not target.can_receive_hit(): continue
		if swept.intersects(target.hurt_rect()):
			hit_ids[target.get_instance_id()]=true
			target.take_hit(damage)
			if is_instance_valid(caster):
				caster.skill_effect.emit("shadow_orb" if piercing else "orb","impact",target.hurt_rect().get_center(),direction)
				caster.hitstop=caster.hitstop_duration
				caster.hit_confirmed.emit()
			if not piercing:
				queue_free()
				return
	if life<=0 or not wall.is_empty(): queue_free()

func _caster_exiting() -> void:
	if not is_instance_valid(caster) or not caster.scene_reparenting:queue_free()
