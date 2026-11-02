class_name CrabPrototype
extends CharacterBody2D
## Independent training boss. Never grants story flags or writes saves.

signal defeated

@export var arena_bounds := Vector2(110, 1170)
@export var retreat_bounds := Vector2(20, 1260)
@export var speed := 90.0
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var visual: CrabPrototypeVisual = $Visual

var target: Player
var state := "waiting"
var timer := 0.0
var kind := "sweep"
var facing := -1.0
var phase := 1
var selection_reason := "waiting"
var cooldowns: Dictionary = {"slam": 0.0, "charge": 0.0}
var running := false
var flash := 0.0
var short_hits := 0
var previous := ""
var streak := 0
var combo_planned := false
var charge_start := 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	health.damaged.connect(_on_damage)
	health.died.connect(_on_death)
	rng.seed = 7


func reset_at(at: Vector2, random_seed: int = 7) -> void:
	stop()
	position = at
	velocity = Vector2.ZERO
	health.restore()
	change("waiting")
	hurtbox.immune = false
	phase = 1
	kind = "sweep"
	facing = -1
	previous = ""
	streak = 0
	short_hits = 0
	combo_planned = false
	flash = 0
	cooldowns = {"slam": 0.0, "charge": 0.0}
	rng.seed = random_seed
	visual.reset()
	($Effects as CrabPrototypeEffects).reset()
	visual.present(self)


func begin() -> void:
	if health.current <= 0:
		return
	running = true
	change("observe")


func stop() -> void:
	running = false
	velocity = Vector2.ZERO
	hitbox.deactivate()
	change("dead" if health.current <= 0 else "waiting")
	selection_reason = "waiting"


func _physics_process(delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Player
	flash = maxf(0, flash - delta)
	velocity.x = 0
	velocity.y = minf(850, velocity.y + 1000 * delta)
	if running and target != null and not target.dead:
		step_ai(delta)
	else:
		hitbox.deactivate()
	move_and_slide()
	position.x = clampf(position.x, arena_bounds.x, arena_bounds.y)
	if state == "active" and kind == "charge":
		hitbox.hit.origin = global_position
		if is_on_wall() or absf(position.x - charge_start) >= CrabMoves.CHARGE_DISTANCE or _free_space() <= 1:
			finish_active()
	visual.present(self)


func step_ai(delta: float) -> void:
	timer += delta
	for attack: String in cooldowns:
		cooldowns[attack] = maxf(0, float(cooldowns[attack]) - delta)
	match state:
		"observe":
			observe()
		"tell":
			if kind == "charge" and timer < 0.9:
				face_target()
				CrabMoves.configure(hitbox, kind, facing)
			if timer >= CrabMoves.value(kind, "tell"):
				start_active()
		"active":
			if timer >= CrabMoves.value(kind, "active"):
				finish_active()
			elif kind == "charge":
				velocity.x = facing * minf(CrabMoves.CHARGE_SPEED, _free_space() / maxf(delta, 0.001))
		"recover":
			if timer >= CrabMoves.value(kind, "recover"):
				var completed := "sweep" if kind == "second" else kind
				cooldowns[completed] = CrabMoves.value(completed, "cooldown")
				if phase == 1 and health.current * 2 <= health.maximum:
					change("phase")
				else:
					change("observe")
		"phase":
			if timer >= 0.8:
				phase = 2
				change("observe")


func observe() -> void:
	face_target()
	if phase == 1 and health.current * 2 <= health.maximum:
		change("phase")
		return
	var distance := maxf(0, absf(target.position.x - position.x) - CrabMoves.BODY_RADIUS - CrabMoves.PLAYER_RADIUS)
	var retreat := retreat_bounds.y - target.position.x if facing > 0 else target.position.x - retreat_bounds.x
	var selected := CrabMoves.select(distance, _free_space(), cooldowns, previous, streak, rng, retreat)
	if not selected.is_empty() and timer >= 0.35:
		selection_reason = "near_weighted" if distance <= 100 else "distance_charge"
		start_tell(selected)
	elif distance > 70:
		selection_reason = "approach"
		velocity.x = facing * speed
	else:
		selection_reason = "cooldown_or_repeat"


func face_target() -> void:
	if target != null:
		facing = 1.0 if target.position.x >= position.x else -1.0


func _free_space() -> float:
	return maxf(0, arena_bounds.y - position.x if facing > 0 else position.x - arena_bounds.x)


func start_tell(attack: String) -> void:
	kind = attack
	if attack != "second":
		streak = streak + 1 if attack == previous else 1
		previous = attack
		combo_planned = phase == 2 and attack == "sweep"
	change("tell")
	CrabMoves.configure(hitbox, kind, facing)


func start_active() -> void:
	change("active")
	charge_start = position.x
	hitbox.activate(HitData.create(1, global_position))
	EventBus.sfx.emit("slam" if kind == "slam" else "sweep")


func finish_active() -> void:
	hitbox.deactivate()
	velocity.x = 0
	if kind == "sweep" and combo_planned:
		start_tell("second")
	else:
		change("recover")


func change(next: String) -> void:
	state = next
	timer = 0


func _on_damage(hit: HitData) -> void:
	flash = 0.12
	EventBus.sfx.emit("hit")
	if not hit.heavy:
		short_hits += 1
		if short_hits % 6 == 0:
			GameState.add_energy(1)


func _on_death() -> void:
	running = false
	change("dead")
	hitbox.deactivate()
	hurtbox.immune = true
	velocity.x = 0
	defeated.emit()


func snapshot() -> Dictionary:
	return {"state": state, "timer": timer, "kind": kind, "phase": phase,
		"facing": facing, "hp": health.current, "maximum": health.maximum,
		"x": position.x, "y": position.y, "reason": selection_reason,
		"cooldowns": cooldowns.duplicate(), "active": hitbox.active, "combo": combo_planned,
		"animation": visual.action_id, "frame": visual.frame_index, "opacity": visual.modulate.a}
