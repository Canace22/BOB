class_name TrainingSkills
extends Node
## Training-only ranged attack and melee guard. Mainline never instantiates this node.

const PROJECTILE := preload("res://src/prototype/resonance_projectile.tscn")
const COOLDOWN := 1.0
const SHIELD_HITS := 4
var cooldown := 0.0
var shield_charge := 0
var shield_flash := 0.0
var shots_fired := 0
var ranged_hits := 0
var blocks := 0
var projectiles: Array[ResonanceProjectile] = []
var shield: Sprite2D
var target: Node2D
@onready var player: Player = get_parent() as Player


func _ready() -> void:
	player.actions.ranged_fired.connect(_fire)
	player.hitbox.landed.connect(_melee_hit)
	player.hurtbox.blocked.connect(_block)
	shield = Sprite2D.new()
	shield.texture = load("res://art/fx/echo_guard.png") as Texture2D
	shield.position = Vector2(0, -32)
	shield.scale = Vector2.ONE * 0.40
	shield.z_index = 5
	player.add_child(shield)


func reset() -> void:
	clear_projectiles()
	cooldown = 0
	shield_charge = 0
	shield_flash = 0
	shots_fired = 0
	ranged_hits = 0
	blocks = 0
	player.hurtbox.guard = 1
	shield.show()


func clear_projectiles() -> void:
	for projectile: ResonanceProjectile in projectiles:
		if is_instance_valid(projectile):
			projectile.deactivate()
			projectile.queue_free()
	projectiles.clear()


func _physics_process(delta: float) -> void:
	shield_flash = maxf(0, shield_flash - delta)
	shield.visible = not player.dead and (player.hurtbox.guard > 0 or shield_flash > 0)
	shield.modulate.a = 1.0 if shield_flash > 0 else 0.65
	if not player.is_physics_processing() or player.dead:
		return
	cooldown = maxf(0, cooldown - delta)
	if Input.is_action_pressed("ranged"):
		try_cast()


func try_cast() -> bool:
	if not player.tuning.prototype_controls or player.dead or cooldown > 0 or not player.actions.is_free():
		return false
	cooldown = COOLDOWN
	if is_instance_valid(target):
		player.facing = 1.0 if target.global_position.x >= player.global_position.x else -1.0
	player.actions.begin_attack(player, "ranged")
	return true


func _fire() -> void:
	if player.dead:
		return
	for index in range(projectiles.size() - 1, -1, -1):
		if not is_instance_valid(projectiles[index]):
			projectiles.remove_at(index)
	var projectile := PROJECTILE.instantiate() as ResonanceProjectile
	projectile.direction = player.facing
	projectile.position = player.position + Vector2(player.facing * 40, -32)
	projectiles.append(projectile)
	player.get_parent().add_child(projectile)
	projectile.landed.connect(_ranged_hit)
	shots_fired += 1


func _ranged_hit(_target: Hurtbox, _hit: HitData) -> void:
	ranged_hits += 1


func _melee_hit(_target: Hurtbox, hit: HitData) -> void:
	if hit.ranged or player.hurtbox.guard > 0:
		return
	shield_charge += 2 if hit.heavy else 1
	if shield_charge >= SHIELD_HITS:
		shield_charge = 0
		player.hurtbox.guard = 1
		shield_flash = 0.25


func _block(_hit: HitData) -> void:
	blocks += 1
	shield_flash = 0.3
	player.invulnerable = maxf(player.invulnerable, player.tuning.invulnerability + 0.2)
	player.hurtbox.immune = true
	EventBus.sfx.emit("hit")


func snapshot() -> Dictionary:
	var positions: Array[Dictionary] = []
	for projectile: ResonanceProjectile in projectiles:
		if is_instance_valid(projectile) and projectile.active:
			positions.append({"x": projectile.position.x, "y": projectile.position.y})
	return {"cooldown": cooldown, "shield_charge": shield_charge,
		"shield": player.hurtbox.guard, "shots": shots_fired, "hits": ranged_hits,
		"blocks": blocks, "range": ResonanceProjectile.RANGE, "projectiles": positions}
