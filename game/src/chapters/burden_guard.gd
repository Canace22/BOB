class_name BurdenGuard
extends ChapterEnemy
## Purpose-built gatekeeper. Telegraph, contact and recovery follow the drawn timeline.

var frames := GuardFrames.new()
var motion_time: float = 0.0
var breath_time: float = 0.0
var block_flash: float = 0.0
var hit_time: float = 10.0
var turn_target: float = -1.0


func _ready() -> void:
	super._ready()
	if state == "dead":
		timer = 10.0
	_render_pose()


func _physics_process(delta: float) -> void:
	timer += delta
	breath_time += delta
	hit_time += delta
	flash = maxf(0, flash - delta)
	block_flash = maxf(0, block_flash - delta)
	stagger_cooldown = maxf(0, stagger_cooldown - delta)
	velocity.x = 0
	velocity.y = minf(850, velocity.y + 1000 * delta)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and not player.dead and state != "dead":
		match state:
			"idle":
				_approach(player, delta)
			"turn":
				if timer >= 0.36:
					facing = turn_target
					change("idle")
			"tell":
				if timer >= tell_duration():
					_enter_active()
			"active":
				if timer >= active_duration():
					hitbox.deactivate()
					change("recover")
			"recover", "stagger":
				if timer >= (1.12 if kind == "slam" else 0.88):
					change("idle")
	var before := position.x
	move_and_slide()
	motion_time += absf(position.x - before) / 88.0 * 0.96
	_render_pose()


func _approach(player: Player, delta: float) -> void:
	if not GameState.arena_active or not GameState.has_flag("chapter.challenge"):
		return
	var dx := player.global_position.x - global_position.x
	if dx * facing < -45:
		turn_target = signf(dx)
		change("turn")
		return
	if absf(dx) > 185:
		var from := global_position + Vector2(facing * (radius + speed * delta), -8)
		var ray := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 32), 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			velocity.x = facing * speed
	elif timer >= 0.45:
		start_tell("slam" if attack_count % 2 == 1 else "sweep")


func tell_duration() -> float:
	return 0.94 if kind == "slam" else 0.74


func active_duration() -> float:
	return 0.28 if kind == "slam" else 0.20


func configure_attack() -> void:
	var shape := hitbox.get_node("Shape") as CollisionShape2D
	(shape.shape as RectangleShape2D).size = Vector2(190, 140) if kind == "slam" else Vector2(150, 50)
	shape.position = Vector2(facing * 100, -50 if kind == "slam" else -24)
	# The moving claw/shell is the tell. No unrelated striped warning sprite.
	warning.hide()


func _on_damage(hit: HitData) -> void:
	super._on_damage(hit)
	hit_time = 0
	if hit.heavy and stagger_cooldown <= 0 and state != "dead":
		hitbox.deactivate()
		change("stagger")
		stagger_cooldown = 1.6


func _retire() -> void:
	change("dead")
	hurtbox.immune = true
	hitbox.deactivate()
	warning.hide()
	visual.modulate = Color.WHITE
	visual.rotation = 0


func _render_pose() -> void:
	var clip := "idle"
	var elapsed := breath_time
	match state:
		"dead":
			clip = "retire"
			elapsed = timer
		"tell", "active", "recover":
			clip = kind
			elapsed = timer
			if state == "active":
				elapsed += tell_duration()
			elif state == "recover":
				elapsed += tell_duration() + active_duration()
		"idle":
			if absf(velocity.x) > 1:
				clip = "walk"
				elapsed = motion_time
	if hit_time < 0.48 and state in ["recover", "stagger"]:
		clip = "hit"
		elapsed = hit_time
	frames.display(visual, clip, elapsed, facing)
	visual.rotation = 0
	visual.modulate = Color(1.5, 1.3, 1.1) if flash > 0 else Color.WHITE
	if block_flash > 0:
		visual.modulate = Color(0.8, 1.2, 1.4)
	warning.hide()
