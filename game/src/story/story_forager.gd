class_name StoryForager
extends CharacterBody2D
## A territorial creature withdraws alive; returning home, not damage alone, resolves it.

signal withdrew
signal struck

@export var stable_id: String = "forager-left"
@export var territory := Vector2(900, 1360)
@export var home := Vector2(1230, 780)
@export var resolve_hits: int = 3
@export_range(1, 2) var rush_count: int = 1
const TELL_TIME: float = 0.55
const LUNGE_TIME: float = 0.28
const RECOVER_TIME: float = 0.6
const LUNGE_SPEED: float = 280.0
const HIT_REACH: float = 65.0
var player: TidePlayer
var visual: StorySpriteAnimator
var state: String = "feeding"
var firmness: int = 3
var timer: float = 0.0
var facing: float = -1.0
var has_attacked: bool = false
var attack_sent: bool = false
var active: bool = false
var accepted_hits: int = 0
var rush_index: int = 0
var attack_count: int = 0
var hurt_flash_left: float = 0.0

func _ready() -> void:
	add_to_group("tide_targets")
	collision_layer = 0
	collision_mask = 1
	floor_snap_length = 12.0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(48, 48)
	shape.shape = rectangle
	shape.position.y = -24.0
	add_child(shape)
	visual = StoryArt.actor("forager", 70.0)
	add_child(visual)
	reset(false)

func reset(settled: bool) -> void:
	position = home
	velocity = Vector2.ZERO
	firmness = resolve_hits
	accepted_hits = 0
	has_attacked = false
	rush_index = 0
	attack_count = 0
	hurt_flash_left = 0.0
	active = settled
	change_state("settled" if settled else "feeding")

func engage() -> void:
	if state != "feeding": return
	active = true
	change_state("approach")

func _physics_process(delta: float) -> void:
	timer += delta
	var was_hurt: bool = hurt_flash_left > 0.0
	hurt_flash_left = maxf(0.0, hurt_flash_left - delta)
	if was_hurt and hurt_flash_left <= 0.0:
		if state == "approach": visual.set_action(&"walk")
		elif state == "recover": visual.set_action(&"feed")
	velocity.y = minf(velocity.y + 1050.0 * delta, 800.0)
	velocity.x = 0.0
	if is_instance_valid(player) and player.health > 0:
		_update_behavior(delta)
	move_and_slide()
	position.x = clampf(position.x, territory.x, territory.y)
	visual.set_facing(facing)
	visual.modulate = Color(1.35, 1.2, 1.1) if hurt_flash_left > 0.0 else Color.WHITE
	if state == "retreat" and absf(position.x - home.x) < 5 and timer >= 0.65:
		change_state("settled")
		withdrew.emit()

func _update_behavior(_delta: float) -> void:
	var difference: Vector2 = player.global_position - global_position
	var in_territory: bool = player.position.x >= territory.x - 45 and player.position.x <= territory.y + 45
	match state:
		"approach":
			if not in_territory:
				velocity.x = signf(home.x - position.x) * 65.0 if absf(home.x-position.x)>8 else 0.0
			elif absf(difference.y) < 160.0:
				if not is_zero_approx(difference.x): facing = signf(difference.x)
				if absf(difference.x) < 155.0:
					rush_index = 1
					change_state("tell")
				else: velocity.x = facing * 78.0
		"tell":
			if timer >= TELL_TIME: change_state("lunge")
		"lunge":
			velocity.x = facing * LUNGE_SPEED
			# Body-relative active contact persists through the rush, once per rush.
			if not attack_sent and timer >= 0.04 and timer <= 0.24:
				if in_territory and difference.x * facing >= 0 and absf(difference.x) < HIT_REACH and absf(difference.y) < 72:
					attack_sent = true
					player.take_damage(1, global_position)
			if timer >= LUNGE_TIME:
				velocity.x = 0.0
				if rush_index < rush_count:
					rush_index += 1
					change_state("tell")
				else: change_state("recover")
		"recover":
			if timer >= RECOVER_TIME: change_state("approach")
		"retreat":
			if absf(home.x - position.x) > 4.0:
				facing = signf(home.x - position.x)
				velocity.x = facing * 100.0

func change_state(next: String) -> void:
	state = next
	timer = 0.0
	attack_sent = false
	if state == "tell" and is_instance_valid(player):
		var direction: float = signf(player.global_position.x - global_position.x)
		if not is_zero_approx(direction): facing = direction
	if state == "lunge":
		has_attacked = true
		attack_count += 1
	if not is_instance_valid(visual): return
	match state:
		"approach": visual.set_action(&"walk")
		"tell": visual.set_action(&"warn", true)
		"lunge": visual.set_action(&"lunge", true)
		"recover": visual.set_action(&"feed")
		"retreat": visual.set_action(&"retreat", true)
		_: visual.set_action(&"feed")

func can_receive_hit() -> bool:
	return active and state in ["approach", "tell", "lunge", "recover"]

func hurt_rect() -> Rect2:
	return Rect2(global_position - Vector2(42, 64), Vector2(84, 64))

func take_hit(amount: int) -> void:
	if not can_receive_hit() or amount <= 0: return
	accepted_hits += 1
	firmness = maxi(0, firmness - amount)
	hurt_flash_left = 0.12
	struck.emit()
	if firmness == 0: change_state("retreat")
	elif state in ["approach", "recover"]: visual.set_action(&"hurt", true)
	# Nonlethal hits never restart recovery or cancel a visible committed tell/rush.

func apply_knockback(_impulse: float) -> void:
	pass

func snapshot() -> Dictionary:
	return {"id":stable_id,"x":position.x,"y":position.y,"home_x":home.x,
		"state":state,"firmness":firmness,"hits":accepted_hits,"alive":true,
		"active":active,"frame":visual.frame,"action":str(visual.current_action),
		"phase_time":timer,"attack_count":attack_count,"rush_index":rush_index,
		"rush_count":rush_count,"telegraph_facing":facing}
