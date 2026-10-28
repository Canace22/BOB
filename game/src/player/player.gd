class_name Player
extends CharacterBody2D

@export var tuning: PlayerTuning
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var actions: PlayerActions = $Actions
@onready var locomotion: PlayerLocomotion = $Locomotion

var facing: float = 1.0
var invulnerable: float = 0.0
var last_safe: Vector2 = Vector2.ZERO
var bounds: Rect2 = Rect2(0, 0, 1920, 1200)
var arena_bounds: Vector2 = Vector2.ZERO
var fall_damage: int = 0
var dead: bool = false


func _ready() -> void:
	health.restore(GameState.hp)
	health.damaged.connect(_on_damage)
	health.died.connect(_on_death)


func _physics_process(delta: float) -> void:
	if dead:
		return
	invulnerable = maxf(0, invulnerable - delta)
	actions.step(self, delta)
	locomotion.step(self, delta)
	hurtbox.immune = invulnerable > 0 or (actions.mode == "dash" and actions.elapsed > 0.06 and actions.elapsed < 0.16)
	move_and_slide()
	position.x = clampf(position.x, 20, bounds.size.x - 20)
	if GameState.arena_active:
		position.x = clampf(position.x, arena_bounds.x, arena_bounds.y)
	if position.y > bounds.end.y:
		recover_fall()
	if Input.is_action_just_pressed("interact") and is_on_floor():
		interact()


func safe_floor() -> bool:
	# Keep a margin from ledges so fall recovery never places the capsule over a gap.
	for offset: float in [-28.0, 28.0]:
		var ray := PhysicsRayQueryParameters2D.create(global_position + Vector2(offset, -8), global_position + Vector2(offset, 12), 1)
		if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			return false
	return true


func interact() -> void:
	var nearest: Interactable
	var distance := INF
	for node in get_tree().get_nodes_in_group("interactable"):
		var item := node as Interactable
		var d := global_position.distance_to(item.global_position)
		if item.available() and d < item.radius and d < distance:
			nearest = item
			distance = d
	if nearest != null:
		nearest.use()


func _on_damage(hit: HitData) -> void:
	GameState.damage(hit.damage)
	invulnerable = tuning.invulnerability
	hurtbox.immune = true
	actions.change("hurt")
	hitbox.deactivate()
	var direction := 1.0 if position.x >= hit.origin.x else -1.0
	velocity = Vector2(direction * 140, -130)
	EventBus.sfx.emit("hurt")


func _on_death() -> void:
	dead = true
	EventBus.player_died.emit()


func recover_fall() -> void:
	position = last_safe
	velocity = Vector2.ZERO
	actions.change("idle")
	hitbox.deactivate()
	if fall_damage > 0:
		hurtbox.receive(HitData.create(fall_damage, position))
	invulnerable = tuning.invulnerability
	hurtbox.immune = true


func reset_at(at: Vector2) -> void:
	position = at
	last_safe = at
	velocity = Vector2.ZERO
	dead = false
	invulnerable = tuning.invulnerability
	hurtbox.immune = true
	health.restore(GameState.hp)
	actions.change("idle")
	actions.air_dash = false
	locomotion.buffered_jump = 0
	locomotion.grounded_time = 0
	hitbox.deactivate()
