class_name EnemyLabWaterOrb
extends Node2D
## 脱身时发出的一次性水弹；不追踪，使用已有玩家受伤/格挡协议。
var source: WeakRef
var player: EnemyLabPlayer
var velocity: Vector2
var life: float=1.8
var spent: bool=false
const RADIUS: float=9.0

func _ready() -> void:
	add_to_group("tide_hostile_projectiles")
	var sprite := Sprite2D.new()
	sprite.texture=preload("res://art/tide-picker-action36/projectile.png")
	sprite.scale=Vector2.ONE*22.0/float(sprite.texture.get_width())
	sprite.modulate=Color(0.65,0.95,1.0)
	add_child(sprite)
	z_index=7

func _physics_process(dt: float) -> void:
	if spent: return
	var enemy: EnemyLabPredator=source.get_ref() as EnemyLabPredator if source!=null else null
	if not is_instance_valid(enemy) or not enemy.outcome.is_empty() or not is_instance_valid(player):
		_consume()
		return
	life-=dt
	var start: Vector2=global_position
	var end: Vector2=start+velocity*dt
	var query := PhysicsRayQueryParameters2D.create(start,end,1)
	var wall: Dictionary=get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty(): end=wall.position
	global_position=end
	var body := Rect2(player.global_position-Vector2(14,65),Vector2(28,65)).grow(RADIUS)
	if _crosses(start,end,body):
		spent=true
		var guard: EnemyLabSkills=player.skill_controller as EnemyLabSkills
		var before: int=guard.guard_count
		if player.take_damage(1,start):
			enemy.water_hits+=1
			enemy.last_result="水弹命中"
		elif guard.guard_count>before:
			enemy.water_blocks+=1
			enemy.last_result="水弹被格挡"
		enemy.changed.emit(enemy.last_result)
		_consume()
	elif life<=0.0 or not wall.is_empty(): _consume()

func _crosses(start: Vector2, end: Vector2, rect: Rect2) -> bool:
	return EnemyLabWaterTrace.crosses(start,end,rect)

func _consume() -> void:
	spent=true
	remove_from_group("tide_hostile_projectiles")
	queue_free()
