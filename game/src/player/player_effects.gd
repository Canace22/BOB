class_name PlayerEffects
extends Node2D
## Trails follow the weapon; actual contact bursts remain at their world impact.

var trail: CombatEffect
var impact: CombatEffect
var was_active := false
var swings := 0
var hits := 0
@onready var player: Player = get_parent() as Player


func _ready() -> void:
	trail = CombatEffect.new()
	add_child(trail)
	trail.z_index = 4
	impact = CombatEffect.new()
	add_child(impact)
	impact.top_level = true
	impact.z_index = 4
	(player.get_node("Hitbox") as Hitbox).landed.connect(_landed)


func reset() -> void:
	trail.reset()
	impact.reset()
	was_active = false
	swings = 0
	hits = 0


func _physics_process(delta: float) -> void:
	if not player.tuning.prototype_controls:
		return
	trail.advance(delta)
	impact.advance(delta)
	var active := player.hitbox.active and player.actions.mode == "attack"
	if active and not was_active:
		var kind := player.actions.attack_kind
		var heavy := kind == "heavy"
		trail.play(kind, player.global_position + Vector2(player.facing * (76 if heavy else 48), -42),
			160 if heavy else 100, 0.28 if heavy else 0.20, 0.64 if heavy else 0.72, player.facing)
		swings += 1
	was_active = active
	if player.actions.mode in ["hurt", "dash"] or player.dead or not player.is_physics_processing():
		trail.hide()


func _landed(target: Hurtbox, hit: HitData) -> void:
	if not player.tuning.prototype_controls or hit.ranged:
		return
	hits += 1
	if target is CrabShell:
		return # The shell presents its resolved damage, including ranged impacts.
	var weapon := player.global_position + Vector2(player.facing * 65, -38)
	impact.play("hit", CombatEffect.contact_point(target, weapon), 76 if hit.heavy else 48,
		0.26 if hit.heavy else 0.18, 0.85, player.facing)


func snapshot() -> Dictionary:
	return {"trail": trail.snapshot(), "impact": impact.snapshot(), "swings": swings, "hits": hits}
