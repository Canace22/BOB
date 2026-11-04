@warning_ignore_start("untyped_declaration")
class_name WhalebellyCampaignEnemyProxy
extends StaticBody2D
signal damage_requested(data:Dictionary,amount:int)
var data:Dictionary
var host:Node2D
func _ready() -> void:
	add_to_group("tide_targets")
	collision_layer=4
	collision_mask=2
	var shape:=CollisionShape2D.new();shape.name="Body"
	var capsule:=CapsuleShape2D.new();capsule.radius=40 if data.boss else 22;capsule.height=90 if data.boss else 64
	shape.shape=capsule;shape.position.y=-capsule.height*.5;add_child(shape)
	position=data.pos
	damage_requested.connect(host.damage_enemy)
func can_receive_hit() -> bool:return data.alive
func is_campaign_enemy() -> bool:return true
func hurt_rect() -> Rect2:
	if not data.alive:return Rect2()
	var size:=Vector2(120,100) if data.boss else Vector2(56,70)
	return Rect2(global_position-Vector2(size.x*.5,size.y),size)
func take_hit(amount:int) -> void:
	if data.alive:damage_requested.emit(data,amount)
func apply_knockback(impulse: float) -> void:
	if not data.alive: return
	var step: float=clampf(impulse*0.12*(0.2 if data.boss else 1.0),-24.0,24.0)
	var candidate: Vector2=Vector2(data.pos)+Vector2(step,0)
	candidate.x=clampf(candidate.x,24.0,float(host.room.size[0])-24.0)
	var ground: float=host.ground_y(candidate.x,candidate.y)
	var ray:=PhysicsRayQueryParameters2D.create(global_position+Vector2(0,-25),candidate+Vector2(0,-25),1)
	if absf(ground-candidate.y)<24 and get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		data.pos=Vector2(candidate.x,ground)
func _physics_process(_dt:float) -> void:
	position=data.pos
	$Body.set_deferred("disabled",not data.alive)
	collision_layer=4 if data.alive else 0
