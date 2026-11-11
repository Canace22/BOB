class_name CampaignCrabBoss
extends CharacterBody2D
## Mother crab from the training battle, bound to campaign enemies and V6 progress.

var host: Node2D
var data: Dictionary
var target: WhalebellyCampaignPlayer
var state := "waiting"
var timer := 0.0
var kind := "sweep"
var facing := -1.0
var phase := 1
var running := false
var flash := 0.0
var cooldowns: Dictionary = {"slam": 0.0, "charge": 0.0}
var previous := ""
var streak := 0
var sequence: Array[String] = []
var sequence_index := 0
var round_index := 0
var charge_start := 0.0
var stagger := 0.0
var stagger_cooldown := 0.0
var hit_sent := false
var retreat_combo := CampaignCrabMoves.RetreatCombo.WAITING
var arena_bounds := Vector2(460, 1400)
var retreat_bounds := Vector2(285, 1490)
var rng := RandomNumberGenerator.new()
var hurtbox := CampaignCrabShell.new()
var visual: CampaignCrabVisual
var effects: CampaignCrabEffects
var receiver: CampaignCrabTarget

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	position = data.pos
	z_index = 3
	process_mode = Node.PROCESS_MODE_PAUSABLE
	target = host.player
	hurtbox.crab = self
	rng.seed = 7
	var shape := CollisionShape2D.new()
	var body := RectangleShape2D.new()
	body.size = Vector2(CampaignCrabMoves.BODY_RADIUS * 2, CampaignCrabMoves.BODY_HEIGHT)
	shape.shape = body
	shape.position.y = -CampaignCrabMoves.BODY_HEIGHT * 0.5
	add_child(shape)
	visual = CampaignCrabVisual.new()
	visual.name = "Visual"
	add_child(visual)
	effects = CampaignCrabEffects.new()
	add_child(effects)
	data.actor = self
	data.visual = self
	data.hp = 180
	data.max_hp = 180
	receiver = CampaignCrabTarget.new()
	receiver.boss = self
	receiver.data = data
	add_child(receiver)
	_sync()

func _physics_process(dt: float) -> void:
	visual.visible = not (host.reference_visible or host.layer_solo >= 0 or not host.capture_path.is_empty())
	if not visual.visible or not target.controls_enabled: return
	flash = maxf(0, flash - dt)
	hurtbox.feedback_left = maxf(0, hurtbox.feedback_left - dt)
	velocity.x = 0
	velocity.y = 0
	if data.alive and target.health > 0:
		if not running and absf(target.position.x-position.x) < 540:
			running = true
			change("observe")
		if running: step_ai(dt)
	if state == "active": _contact()
	if data.alive:
		move_and_slide()
		# The authored low side shelves are for the player; the wide crab follows
		# the continuous floor rather than wedging its shell against those shelves.
		position.y = host.ground_y(position.x, position.y)
	position.x = clampf(position.x, arena_bounds.x, arena_bounds.y)
	if state == "active" and kind == "charge":
		if is_on_wall() or absf(position.x-charge_start) >= CampaignCrabMoves.CHARGE_DISTANCE or _free_space() <= 1:
			finish_active()
	_sync()

func step_ai(dt: float) -> void:
	var offset := target.position.x - position.x
	var gap := maxf(0, absf(offset)-CampaignCrabMoves.BODY_RADIUS-CampaignCrabMoves.PLAYER_RADIUS)
	if phase == 2:
		retreat_combo = CampaignCrabMoves.track_retreat(retreat_combo, gap, target.velocity.x*offset > 0 and target.state != "hurt")
	timer += dt
	stagger_cooldown = maxf(0, stagger_cooldown-dt)
	for attack: String in cooldowns:
		cooldowns[attack] = maxf(0, float(cooldowns[attack])-dt)
	match state:
		"observe":
			face_target()
			if CampaignCrabMoves.phase_for_health(int(data.hp), int(data.max_hp)) > phase:
				change("phase")
				return
			var selected := CampaignCrabMoves.select(gap, _free_space(), cooldowns, previous, streak, rng,
				_retreat_space(), phase == 2 and retreat_combo == CampaignCrabMoves.RetreatCombo.READY)
			if not selected.is_empty() and timer >= 0.35: start_tell(selected)
			elif gap > 70: velocity.x = facing * 90 * (1.65 if gap > CampaignCrabMoves.CHARGE_MIN_GAP else 1.0)
		"tell":
			if kind == "charge" and timer < 0.9: face_target()
			if timer >= CampaignCrabMoves.value(kind, "tell"):
				change("active")
				charge_start = position.x
				hit_sent = false
				host.sfx("slam" if kind == "slam" else "sweep")
				host.record_event("enemy_attack_active", {"id":data.key,"kind":kind})
		"active":
			if timer >= CampaignCrabMoves.value(kind, "active"): finish_active()
			elif kind == "charge": velocity.x = facing * minf(CampaignCrabMoves.CHARGE_SPEED, _free_space()/maxf(dt,0.001))
		"recover":
			if timer >= CampaignCrabMoves.value(kind, "recover"):
				CampaignCrabMoves.set_cooldowns(cooldowns, sequence)
				_finish_round()
		"phase":
			if timer >= CampaignCrabMoves.PHASE_TIME:
				phase = mini(3, phase+1)
				change("observe")
		"stagger":
			if timer >= CampaignCrabMoves.STAGGER_TIME: _finish_round()

func _finish_round() -> void:
	change("phase" if CampaignCrabMoves.phase_for_health(int(data.hp), int(data.max_hp)) > phase else "observe")

func face_target() -> void:
	facing = 1.0 if target.position.x >= position.x else -1.0

func _free_space() -> float:
	return maxf(0, arena_bounds.y-position.x if facing > 0 else position.x-arena_bounds.x)

func _retreat_space() -> float:
	return retreat_bounds.y-target.position.x if facing > 0 else target.position.x-retreat_bounds.x

func start_tell(attack: String) -> void:
	streak = streak+1 if attack == previous else 1
	previous = attack
	round_index += 1
	sequence = CampaignCrabMoves.sequence(attack, phase, round_index,
		_retreat_space() >= CampaignCrabMoves.RETREAT_SPACE, float(cooldowns.get("slam",0)) <= 0)
	if attack == "charge" and phase == 2 and retreat_combo == CampaignCrabMoves.RetreatCombo.READY:
		sequence.append("sweep")
		retreat_combo = CampaignCrabMoves.RetreatCombo.USED
	sequence_index = 0
	kind = attack
	change("tell")

func finish_active() -> void:
	velocity.x = 0
	sequence_index += 1
	if sequence_index < sequence.size():
		if sequence[sequence_index] == "slam" and _retreat_space() < CampaignCrabMoves.RETREAT_SPACE:
			sequence[sequence_index] = "second"
		kind = sequence[sequence_index]
		change("tell")
	else:
		sequence_index = maxi(0, sequence.size()-1)
		change("recover")

func change(next: String) -> void:
	state = next
	timer = 0

func _contact() -> void:
	if hit_sent or target.health <= 0: return
	var player_rect := Rect2(target.global_position-Vector2(14,65),Vector2(28,65))
	if attack_rect().intersects(player_rect) and target.take_damage(1,global_position):
		hit_sent = true

func attack_rect() -> Rect2:
	var area := CampaignCrabMoves.attack_rect(kind, facing)
	area.position += global_position
	return area

func hurt_rect() -> Rect2:
	return Rect2(global_position-Vector2(150,240),Vector2(300,240)) if data.alive else Rect2()

func receive_attack(amount: int, heavy: bool, ranged: bool, origin: Vector2) -> void:
	if not data.alive or amount <= 0: return
	hurtbox.receive(amount*10, heavy, ranged)
	effects.received(origin, ranged)
	_sync()

func exposed_hit(heavy: bool, ranged: bool, counter: bool) -> void:
	if ranged or not data.alive or state in ["phase","stagger"] or stagger_cooldown > 0: return
	stagger += CampaignCrabMoves.STAGGER_LIMIT if counter else (42.0 if heavy else 14.0)
	if stagger >= CampaignCrabMoves.STAGGER_LIMIT:
		stagger = 0
		stagger_cooldown = 6
		velocity.x = 0
		CampaignCrabMoves.set_cooldowns(cooldowns,sequence)
		sequence.clear()
		change("stagger")

func on_defeated() -> void:
	running = false
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	change("dead")
	_sync()

func _sync() -> void:
	data.merge({"pos":position,"state":state,"timer":timer,"facing":facing,"hit_sent":hit_sent},true)
	if is_instance_valid(receiver): receiver.synchronize()

func snapshot() -> Dictionary:
	return {"state":state,"kind":kind,"timer":timer,"phase":phase,"hp":data.hp,"maximum":data.max_hp,
		"facing":facing,"x":position.x,"y":position.y,"stagger":stagger,"stagger_cooldown":stagger_cooldown,
		"combo_index":sequence_index+1,"combo_total":sequence.size(),"braced":hurtbox.braced(),
		"counter_window":hurtbox.counter_window(),"feedback":hurtbox.last_result,"damage":hurtbox.last_damage,
		"feedback_left":hurtbox.feedback_left,"animation":visual.action_id,"frame":visual.frame_index}
