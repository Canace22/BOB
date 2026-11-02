class_name CrabPrototype
extends CharacterBody2D
## Independent training boss. Never grants story flags or writes saves.

signal defeated

@export var arena_bounds := Vector2(110, 1170)
@export var retreat_bounds := Vector2(20, 1260)
@export var speed := 90.0
@onready var health: Health = $Health
@onready var hurtbox: CrabShell = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var visual: CrabPrototypeVisual = $Visual

var target: Player
var state := "waiting"
var timer := 0.0
var kind := "sweep"
var facing := -1.0
var retreat_combo := CrabMoves.RetreatCombo.WAITING
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
var sequence: Array[String] = []
var sequence_index := 0
var round_index := 0
var stagger := 0.0
var stagger_cooldown := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	health.died.connect(_on_death)

func reset_at(at: Vector2, random_seed: int = 7) -> void:
	stop()
	position = at
	velocity = Vector2.ZERO
	health.restore()
	change("waiting")
	hurtbox.immune = false
	retreat_combo = CrabMoves.RetreatCombo.WAITING
	phase = 1
	kind = "sweep"
	facing = -1
	previous = ""
	streak = 0
	short_hits = 0
	combo_planned = false
	sequence.clear()
	hurtbox.reset_feedback()
	sequence_index = 0
	round_index = 0
	stagger = 0
	stagger_cooldown = 0
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
	var offset := target.position.x - position.x if target != null else 0.0
	var gap := maxf(0, absf(offset) - CrabMoves.BODY_RADIUS - CrabMoves.PLAYER_RADIUS)
	if phase == 2 and target != null:
		retreat_combo = CrabMoves.track_retreat(retreat_combo, gap, target.velocity.x * offset > 0 and target.actions.mode != "hurt")
	timer += delta
	stagger_cooldown = maxf(0, stagger_cooldown - delta)
	for attack: String in cooldowns:
		cooldowns[attack] = maxf(0, float(cooldowns[attack]) - delta)
	match state:
		"observe":
			observe(gap)
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
				CrabMoves.set_cooldowns(cooldowns, sequence)
				_finish_round()
		"phase":
			if timer >= CrabMoves.PHASE_TIME:
				phase = mini(3, phase + 1)
				change("observe")
		"stagger":
			if timer >= CrabMoves.STAGGER_TIME:
				_finish_round()

func _finish_round() -> void:
	change("phase" if CrabMoves.phase_for_health(health.current, health.maximum) > phase else "observe")

func observe(distance: float) -> void:
	face_target()
	if CrabMoves.phase_for_health(health.current, health.maximum) > phase:
		change("phase")
		return
	var retreat := _retreat_space()
	var selected := CrabMoves.select(distance, _free_space(), cooldowns, previous, streak, rng, retreat, first_retreat_ready())
	if not selected.is_empty() and timer >= 0.35:
		selection_reason = "near_weighted" if distance <= 100 else "distance_charge"
		start_tell(selected)
	elif distance > 70:
		selection_reason = "approach"
		velocity.x = facing * speed * (1.65 if distance > CrabMoves.CHARGE_MIN_GAP else 1.0)
	else:
		selection_reason = "cooldown_or_repeat"

func first_retreat_ready() -> bool:
	return phase == 2 and retreat_combo == CrabMoves.RetreatCombo.READY

func face_target() -> void:
	if target != null:
		facing = 1.0 if target.position.x >= position.x else -1.0

func _free_space() -> float:
	return maxf(0, arena_bounds.y - position.x if facing > 0 else position.x - arena_bounds.x)

func _retreat_space() -> float:
	if target == null:
		return INF
	return retreat_bounds.y - target.position.x if facing > 0 else target.position.x - retreat_bounds.x

func start_tell(attack: String) -> void:
	streak = streak + 1 if attack == previous else 1
	previous = attack
	round_index += 1
	sequence = CrabMoves.sequence(attack, phase, round_index,
		_retreat_space() >= CrabMoves.RETREAT_SPACE, float(cooldowns.get("slam", 0)) <= 0)
	if attack == "charge" and first_retreat_ready():
		sequence.append("sweep")
		retreat_combo = CrabMoves.RetreatCombo.USED
	sequence_index = 0
	combo_planned = sequence.size() > 1
	_tell(attack)

func _tell(attack: String) -> void:
	kind = attack
	hitbox.deactivate()
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
	sequence_index += 1
	if sequence_index < sequence.size():
		# A retreat can become blocked during the first attack. Never add an
		# unavoidable full-height finisher to a player now against the wall.
		if sequence[sequence_index] == "slam" and _retreat_space() < CrabMoves.RETREAT_SPACE:
			sequence[sequence_index] = "second"
		_tell(sequence[sequence_index])
	else:
		sequence_index = maxi(0, sequence.size() - 1)
		change("recover")

func change(next: String) -> void:
	state = next
	timer = 0

func register_exposed_hit(hit: HitData, counter: bool) -> void:
	if not hit.heavy and not hit.ranged:
		short_hits += 1
		if short_hits % 6 == 0:
			GameState.add_energy(1)
	if hit.ranged or health.current <= 0 or not running or state in ["phase", "stagger"] or stagger_cooldown > 0:
		return
	stagger += CrabMoves.STAGGER_LIMIT if counter else (42.0 if hit.heavy else 14.0)
	if stagger >= CrabMoves.STAGGER_LIMIT:
		stagger = 0
		stagger_cooldown = CrabMoves.STAGGER_COOLDOWN
		hitbox.deactivate()
		velocity.x = 0
		CrabMoves.set_cooldowns(cooldowns, sequence)
		sequence.clear()
		combo_planned = false
		change("stagger")

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
		"next_phase": mini(3, phase + 1), "combo_index": sequence_index + 1, "combo_total": sequence.size(),
		"stagger": stagger, "stagger_max": CrabMoves.STAGGER_LIMIT, "stagger_cooldown": stagger_cooldown,
		"braced": hurtbox.braced(), "counter_window": hurtbox.counter_window(),
		"feedback": hurtbox.last_result, "damage": hurtbox.last_damage, "feedback_left": hurtbox.feedback_left,
		"effects": ($Effects as CrabPrototypeEffects).snapshot(),
		"animation": visual.action_id, "frame": visual.frame_index, "opacity": visual.modulate.a}
