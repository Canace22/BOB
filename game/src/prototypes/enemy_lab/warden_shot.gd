class_name EnemyLabWardenShot
extends Node2D
## 压囊水弹/水龙卷仅归施放者所有，沿用玩家真实伤害/格挡入口。
var source: WeakRef
var player: EnemyLabPlayer
var kind: String="bullet"
var velocity: Vector2
var life: float=1.5
var spent: bool=false
var sprite: Sprite2D
var clock: float=0.0
const SHEET: Texture2D=preload("res://art/enemy-lab-warden-water-v3/water_actions.png")

func _ready() -> void:
	add_to_group("tide_hostile_projectiles")
	add_to_group("enemy_lab_warden_water")
	var meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/enemy-lab-warden-water-v3/atlas.json"))
	var r: Array=meta.props["13" if kind=="vortex" else "12"]
	var texture := AtlasTexture.new()
	texture.atlas=SHEET
	texture.region=Rect2(r[0],r[1],r[2],r[3])
	texture.filter_clip=true
	sprite=Sprite2D.new()
	sprite.texture=texture
	sprite.scale=Vector2.ONE*(130.0 if kind=="vortex" else 24.0)/texture.get_height()
	var material := ShaderMaterial.new()
	material.shader=preload("pump_flow.gdshader")
	sprite.material=material
	add_child(sprite)
	z_index=5
	if kind=="vortex": life=2.20

func _physics_process(dt: float) -> void:
	if spent: return
	var owner: EnemyLabWarden=source.get_ref() as EnemyLabWarden if source!=null else null
	if not is_instance_valid(owner) or not owner.outcome.is_empty() or not is_instance_valid(player):
		consume()
		return
	clock+=dt
	if kind=="vortex":
		# 贴地追击只改水平速度，转向有惯性；不会跳到玩家身上或跟着升空。
		var axis: float=player.global_position.x-global_position.x
		var desired: float=signf(axis)*220.0 if absf(axis)>8.0 else 0.0
		velocity.x=move_toward(velocity.x,desired,900.0*dt)
	(sprite.material as ShaderMaterial).set_shader_parameter("clock",clock)
	life-=dt
	var start: Vector2=global_position
	var end: Vector2=start+velocity*dt
	var query := PhysicsRayQueryParameters2D.create(start,end,1)
	var wall: Dictionary=get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty(): end=wall.position
	global_position=end
	var half := Vector2(35,60) if kind=="vortex" else Vector2(11,11)
	var body := Rect2(player.global_position-Vector2(14,65)-half,Vector2(28,65)+half*2.0)
	if EnemyLabWaterTrace.crosses(start,end,body):
		var guard: EnemyLabSkills=player.skill_controller as EnemyLabSkills
		var before: int=guard.guard_count
		guard.incoming_pressure=35.0 if kind=="vortex" else 24.0
		var damaged: bool=player.take_damage(1,start)
		guard.incoming_pressure=28.0
		if damaged: owner.water.hits+=1
		elif guard.guard_count>before:
			owner.water.blocks+=1
			if kind=="vortex" and guard.perfect and owner.move_key=="warden_vortex": owner.water.overload()
		consume()
	elif life<=0.0 or not wall.is_empty(): consume()

func consume() -> void:
	if spent: return
	spent=true
	remove_from_group("tide_hostile_projectiles")
	remove_from_group("enemy_lab_warden_water")
	queue_free()
