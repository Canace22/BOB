extends Area2D
var direction: float = 1
var speed: float = 400
var life: float = 1.5
var damage: int = 20
var caster: Node
func _ready() -> void:
	collision_layer=0
	collision_mask=1
	var shape:=CollisionShape2D.new()
	var circle:=CircleShape2D.new()
	circle.radius=7
	shape.shape=circle
	add_child(shape)
	var visual:=Sprite2D.new()
	visual.texture=load("res://assets/runtime/v02/lamp.png")
	visual.scale=Vector2.ONE*20.0/maxf(visual.texture.get_width(),visual.texture.get_height())
	visual.modulate=Color(.6,1,1)
	add_child(visual)
	body_entered.connect(func(_body): queue_free())
func _physics_process(dt:float) -> void:
	var start:=global_position
	global_position.x+=speed*direction*dt
	life-=dt
	var query:=PhysicsRayQueryParameters2D.create(start,global_position,1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty(): queue_free();return
	for target in get_tree().get_nodes_in_group("tide_targets"):
		if target.hurt_rect().grow(7).has_point(global_position):
			target.take_hit(damage)
			if is_instance_valid(caster):
				caster.hitstop=caster.hitstop_duration
				caster.hit_confirmed.emit()
			queue_free()
			return
	if life<=0: queue_free()
