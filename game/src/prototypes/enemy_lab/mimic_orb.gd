class_name EnemyLabMimicOrb
extends Node2D
## 复现远程技能的有限射弹，复用连续检测与玩家伤害/格挡入口。
var source: WeakRef
var player: TideCombatPlayer
var velocity: Vector2
var life: float=1.8
var spent: bool=false

func _ready() -> void:
	z_index=7
	add_to_group("tide_hostile_projectiles")
	var sprite := Sprite2D.new()
	var owner_enemy: EnemyLabElder=source.get_ref() as EnemyLabElder
	sprite.texture=preload("res://art/tide-picker-action36/shadow_projectile.png") if owner_enemy.mimic.source_key=="shadow_orb" else preload("res://art/tide-picker-action36/projectile.png")
	sprite.scale=Vector2.ONE*26.0/float(sprite.texture.get_width())
	sprite.modulate=Color(0.95,0.83,0.52)
	add_child(sprite)

func _physics_process(dt: float) -> void:
	if spent: return
	var enemy: EnemyLabElder=source.get_ref() as EnemyLabElder if source!=null else null
	if not is_instance_valid(enemy) or not enemy.outcome.is_empty() or not is_instance_valid(player):
		_consume()
		return
	life-=dt
	var start: Vector2=global_position
	var end: Vector2=start+velocity*dt
	var ray := PhysicsRayQueryParameters2D.create(start,end,1)
	var wall: Dictionary=get_world_2d().direct_space_state.intersect_ray(ray)
	if not wall.is_empty(): end=wall.position
	global_position=end
	var area := Rect2(player.global_position-Vector2(14,65),Vector2(28,65)).grow(12)
	if EnemyLabWaterTrace.crosses(start,end,area):
		var guard: TideCombatGuardSkills=player.skill_controller as TideCombatGuardSkills
		var before: int=guard.guard_count
		guard.incoming_pressure=28.0
		guard.incoming_unblockable=false
		if player.take_damage(1,start): enemy.hit_count+=1
		elif guard.guard_count>before:
			enemy.parry_count+=1
			enemy.guard_reaction(guard.perfect)
		_consume()
	elif life<=0.0 or not wall.is_empty(): _consume()

func _consume() -> void:
	spent=true
	remove_from_group("tide_hostile_projectiles")
	queue_free()
