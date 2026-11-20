class_name EnemyLabNestEgg
extends Node2D
## 布巢卵囊可被真实攻击拆除；落地胀裂前有明确等待，不靠触碰持续扣血。
var source: WeakRef
var player: EnemyLabPlayer
var velocity: Vector2
var age: float=0.0
var flight_age: float=0.0
var landed: bool=false
var spent: bool=false
var burst_left: float=0.0
var sprite: Sprite2D
var health: int=1
var data: Dictionary={"alive":true}
var pause_left: float=0.0
const FUSE: float=1.25
const SHEET: Texture2D=preload("res://art/enemy-lab-eel-nest-v2/nest_actions.png")
var frames: Array[Texture2D]=[]

func _ready() -> void:
	add_to_group("tide_targets")
	add_to_group("enemy_lab_nest_eggs")
	add_to_group("tide_hostile_projectiles")
	var meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/enemy-lab-eel-nest-v2/atlas.json"))
	for index: int in [12,13,14]:
		var r: Array=meta.props[str(index)]
		var texture := AtlasTexture.new()
		texture.atlas=SHEET
		texture.region=Rect2(r[0],r[1],r[2],r[3])
		texture.filter_clip=true
		frames.append(texture)
	sprite=Sprite2D.new()
	sprite.texture=frames[0]
	# 完整与鼓胀用同一比例，胀裂碎膜另按实际伤害宽度呈现。
	sprite.scale=Vector2.ONE*30.0/frames[0].get_height()
	add_child(sprite)
	z_index=5

func owner_enemy() -> EnemyLabEel:
	return source.get_ref() as EnemyLabEel if source!=null else null

func _physics_process(dt: float) -> void:
	var enemy: EnemyLabEel=owner_enemy()
	if not is_instance_valid(enemy) or not enemy.outcome.is_empty() or not is_instance_valid(player):
		consume()
		return
	if spent:
		burst_left-=dt
		if burst_left<=0.0: queue_free()
		return
	pause_left=maxf(0.0,pause_left-dt)
	if pause_left>0.0: return
	if not landed: _fly(dt)
	else:
		age+=dt
		sprite.texture=frames[1] if age>=FUSE-0.55 else frames[0]
		sprite.modulate=Color.WHITE.lerp(Color("ffc38c"),0.35*maxf(0.0,sin(age*15.0)))
		if age>=FUSE: _burst(enemy)

func _fly(dt: float) -> void:
	flight_age+=dt
	velocity.y+=850.0*dt
	var target: Vector2=global_position+velocity*dt
	var query := PhysicsRayQueryParameters2D.create(global_position,target+Vector2(0,14),1)
	var hit: Dictionary=get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.normal.y< -0.5 and velocity.y>0.0:
			global_position=hit.position-Vector2(0,14)
			landed=true
			velocity=Vector2.ZERO
		elif absf(hit.normal.x)>0.5: consume()
		else: velocity.y=absf(velocity.y)
	else: global_position=target
	if flight_age>2.5: consume()

func _burst(enemy: EnemyLabEel) -> void:
	enemy.nest.eggs_burst+=1
	var area := Rect2(global_position+Vector2(-48,-26),Vector2(96,40))
	var body := Rect2(player.global_position-Vector2(14,65),Vector2(28,65))
	if area.intersects(body):
		var guard: EnemyLabSkills=player.skill_controller as EnemyLabSkills
		var before: int=guard.guard_count
		if player.take_damage(1,global_position): enemy.nest.egg_hits+=1
		elif guard.guard_count>before: enemy.nest.egg_blocks+=1
	_spend()
	sprite.texture=frames[2]
	sprite.scale=Vector2.ONE*96.0/frames[2].get_width()
	sprite.modulate=Color.WHITE
	burst_left=0.24

func hurt_rect() -> Rect2:
	return Rect2(global_position-Vector2(18,18),Vector2(36,36))
func can_receive_hit() -> bool: return not spent
func take_hit(amount: int) -> void:
	if amount<=0 or spent: return
	var enemy: EnemyLabEel=owner_enemy()
	if is_instance_valid(enemy):
		enemy.nest.eggs_broken+=1
		enemy.changed.emit("卵囊击碎 · 清出退路")
	consume()
func receive_feedback(seconds: float, _direction: float, _power: float) -> void:
	pause_left=minf(seconds,0.08)
func _spend() -> void:
	if spent: return
	spent=true
	health=0
	data.alive=false
	remove_from_group("tide_targets")
	remove_from_group("tide_hostile_projectiles")
	remove_from_group("enemy_lab_nest_eggs")
	var enemy: EnemyLabEel=owner_enemy()
	if is_instance_valid(enemy): enemy.nest.live_eggs=maxi(0,enemy.nest.live_eggs-1)
func consume() -> void:
	_spend()
	queue_free()
