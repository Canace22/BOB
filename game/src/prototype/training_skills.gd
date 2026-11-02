class_name TrainingSkills
extends Node
## Training-only ranged attack and melee guard. Mainline never instantiates this node.

const PROJECTILE := preload("res://src/prototype/resonance_projectile.tscn")
const CHARGE_TIME := 0.52
const COOLDOWN := 0.55
const SHIELD_HITS := 6
const GUARD_PROTECTION := 0.35
var cooldown := 0.0
var shield_charge := 0
var shield_flash := 0.0
var shots_fired := 0
var ranged_hits := 0
var blocks := 0
var projectiles: Array[ResonanceProjectile] = []
var charge_ring := Sprite2D.new()
var impact := CombatEffect.new()
var full_cue_played := false
var cast_buffer := 0.0
var charged_shot := false
var charged_hits := 0
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
	charge_ring.texture = preload("res://art/fx/heavy_ring.png")
	charge_ring.z_index = 5
	player.add_child(charge_ring)
	charge_ring.hide()
	impact.top_level = true
	impact.z_index = 5
	player.add_child(impact)


func reset() -> void:
	clear_projectiles()
	cooldown = 0
	shield_charge = 0
	shield_flash = 0
	shots_fired = 0
	charged_hits = 0
	ranged_hits = 0
	blocks = 0
	player.hurtbox.guard = 1
	shield.show()


func clear_projectiles() -> void:
	cast_buffer = 0
	charged_shot = false
	charge_ring.hide()
	impact.reset()
	for projectile: ResonanceProjectile in projectiles:
		if is_instance_valid(projectile):
			projectile.deactivate()
			projectile.queue_free()
	projectiles.clear()


func _physics_process(delta: float) -> void:
	shield_flash = maxf(0, shield_flash - delta)
	shield.visible = not player.dead and (player.hurtbox.guard > 0 or shield_flash > 0)
	shield.modulate.a = 1.0 if shield_flash > 0 else 0.65
	impact.advance(delta)
	if not player.is_physics_processing() or player.dead:
		return
	cooldown = maxf(0, cooldown - delta)
	if cast_buffer > 0 and cooldown <= 0 and player.actions.is_free():
		player.actions.change("aim")
		full_cue_played = false
		face_target()
		cast_buffer = 0
	cast_buffer = maxf(0, cast_buffer - delta)
	var aiming := player.actions.mode == "aim"
	charge_ring.visible = aiming
	if aiming:
		var ratio := minf(1, player.actions.elapsed / CHARGE_TIME)
		if ratio >= 1 and not full_cue_played:
			full_cue_played = true
			EventBus.sfx.emit("collect")
		charge_ring.position = Vector2(player.facing * 38, -36)
		charge_ring.scale = Vector2.ONE * lerpf(0.07, 0.26, ratio)
		charge_ring.modulate = Color(1.45, 1.25, 0.85) if ratio >= 1 else Color.WHITE
		if not Input.is_action_pressed("ranged"):
			try_cast(ratio >= 1)


func buffer_cast() -> void:
	cast_buffer = player.tuning.action_buffer


func face_target() -> void:
	if is_instance_valid(target):
		player.facing = 1.0 if target.global_position.x >= player.global_position.x else -1.0


func try_cast(full_charge: bool = false) -> bool:
	if not player.tuning.prototype_controls or player.dead or cooldown > 0 or player.actions.mode not in ["idle", "aim"]:
		return false
	charged_shot = full_charge
	cooldown = 0.85 if full_charge else COOLDOWN
	charge_ring.hide()
	face_target()
	player.actions.begin_attack(player, "ranged")
	return true


func _fire() -> void:
	if player.dead:
		return
	for index in range(projectiles.size() - 1, -1, -1):
		if not is_instance_valid(projectiles[index]):
			projectiles.remove_at(index)
	var projectile := PROJECTILE.instantiate() as ResonanceProjectile
	projectile.charged = charged_shot
	projectile.direction = player.facing
	projectile.position = player.position + Vector2(player.facing * 40, -32)
	projectiles.append(projectile)
	player.get_parent().add_child(projectile)
	projectile.landed.connect(_ranged_hit.bind(projectile))
	shots_fired += 1


func _ranged_hit(body: Hurtbox, hit: HitData, projectile: ResonanceProjectile) -> void:
	ranged_hits += 1
	if projectile.charged:
		charged_hits += 1
	if body is CrabShell:
		return
	var at := CombatEffect.contact_point(body, projectile.global_position)
	impact.play("hit", at, 96 if hit.heavy else 48, 0.24, 0.82, projectile.direction)


func _melee_hit(body: Hurtbox, hit: HitData) -> void:
	if hit.ranged or player.hurtbox.guard > 0 or (body is CrabShell and (body as CrabShell).braced()):
		return
	shield_charge += 2 if hit.heavy else 1
	if shield_charge >= SHIELD_HITS:
		shield_charge = 0
		player.hurtbox.guard = 1
		shield_flash = 0.25


func _block(_hit: HitData) -> void:
	blocks += 1
	shield_flash = 0.3
	player.invulnerable = maxf(player.invulnerable, GUARD_PROTECTION)
	player.hurtbox.immune = true
	EventBus.sfx.emit("hit")


func snapshot() -> Dictionary:
	var positions: Array[Dictionary] = []
	for projectile: ResonanceProjectile in projectiles:
		if is_instance_valid(projectile) and projectile.active:
			positions.append({"x": projectile.position.x, "y": projectile.position.y})
	return {"charge": minf(player.actions.elapsed / CHARGE_TIME, 1) if player.actions.mode == "aim" else 0.0,
		"charged_hits": charged_hits, "impact": impact.snapshot(), "cooldown": cooldown, "shield_charge": shield_charge,
		"shield": player.hurtbox.guard, "shots": shots_fired, "hits": ranged_hits,
		"blocks": blocks, "range": ResonanceProjectile.RANGE, "projectiles": positions}
