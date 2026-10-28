class_name EnemyBase
extends CharacterBody2D

@export var boss: bool = false
@export var victory_flag: String = ""
@export var speed: float = 48.0
@export var radius: float = 30.0
@export var approach_distance: float = 85.0
@export var attack_reach: float = 100.0
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var visual: Sprite2D = $Visual
@onready var warning: Sprite2D = $Warning

var state: String = "idle"
var timer: float = 0.0
var kind: String = "sweep"
var facing: float = -1.0
var attack_count: int = 0
var short_hits: int = 0
var earned: bool = false
var stagger_cooldown: float = 0.0
var flash: float = 0.0


func _ready() -> void:
	health.damaged.connect(_on_damage)
	health.died.connect(_on_death)
	if not victory_flag.is_empty() and GameState.has_flag(victory_flag):
		queue_free()


func _physics_process(delta: float) -> void:
	if state == "dead":
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.dead:
		return
	timer += delta
	flash = maxf(0, flash - delta)
	stagger_cooldown = maxf(0, stagger_cooldown - delta)
	velocity.y = minf(850, velocity.y + 1000 * delta)
	velocity.x = 0
	match state:
		"idle":
			_idle(player, delta)
		"tell":
			var duration := 1.1 if kind == "slam" else (0.55 if kind == "second" else 0.8)
			if timer >= duration:
				_enter_active()
		"active":
			if timer > 0.18:
				hitbox.deactivate()
				if boss and health.current <= health.maximum / 2 and kind == "sweep":
					start_tell("second")
				else:
					change("recover")
		"recover":
			if timer > (1.0 if kind == "slam" else 0.75):
				change("idle")
		"stagger":
			if timer > 0.12:
				change("idle")
	move_and_slide()
	_update_visual()


func _idle(player: Player, delta: float) -> void:
	if boss and not GameState.arena_active:
		return
	var dx := player.global_position.x - global_position.x
	facing = 1.0 if dx >= 0 else -1.0
	if absf(dx) >= 500 or absf(player.global_position.y - global_position.y) >= 120:
		return
	if absf(dx) >= approach_distance:
		var from := global_position + Vector2(facing * (radius + speed * delta), -8)
		var ray := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 28), 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			velocity.x = facing * speed
	elif timer > 0.45:
		start_tell("slam" if boss and attack_count % 3 == 2 else "sweep")


func change(next: String) -> void:
	state = next
	timer = 0


func start_tell(attack: String) -> void:
	kind = attack
	attack_count += 1
	change("tell")
	configure_attack()


func configure_attack() -> void:
	var reach := 190.0 if kind == "slam" else attack_reach
	var height := 125.0 if kind == "slam" else 28.0
	var shape := hitbox.get_node("Shape") as CollisionShape2D
	(shape.shape as RectangleShape2D).size = Vector2(reach + radius, height + 60)
	shape.position = Vector2(facing * (reach - radius) / 2, (60 - height) / 2)
	warning.position = Vector2(facing * reach / 2, -8)
	warning.scale = Vector2.ONE * reach / warning.texture.get_width()


func _enter_active() -> void:
	change("active")
	hitbox.activate(HitData.create(1, global_position))
	EventBus.sfx.emit("slam" if kind == "slam" else "sweep")


func _on_damage(hit: HitData) -> void:
	flash = 0.12
	EventBus.sfx.emit("hit")
	if boss:
		if not hit.heavy:
			short_hits += 1
			if short_hits % 6 == 0:
				GameState.add_energy(1)
	elif not earned:
		earned = true
		GameState.add_energy(1)
	if not boss and stagger_cooldown <= 0:
		hitbox.deactivate()
		change("stagger")
		stagger_cooldown = 0.8


func _on_death() -> void:
	change("dead")
	hurtbox.immune = true
	hitbox.deactivate()
	visual.modulate = Color(0.4, 0.45, 0.45, 0.5)
	warning.hide()
	if not victory_flag.is_empty():
		GameState.set_flag(victory_flag)
		GameState.save_progress()
		GameState.arena_active = false
		EventBus.arena_changed.emit(false)
		EventBus.toast.emit("负壳蟹退让了 · 到右岸按 E 承接贴流冲")


func _update_visual() -> void:
	visual.scale.x = absf(visual.scale.x) * facing
	visual.rotation = -0.08 * facing if state == "tell" else (0.12 * facing if state == "active" else 0.0)
	visual.modulate = Color(2, 1.4, 0.9) if flash > 0 else Color.WHITE
	warning.visible = state in ["tell", "active"]
	warning.modulate = Color(1, 0.7, 0.3, 0.7 + sin(timer * 20) * 0.2)
