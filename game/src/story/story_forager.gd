class_name StoryForager
extends CharacterBody2D
## A territorial creature withdraws alive; returning home, not damage alone, resolves it.

signal withdrew
signal struck

@export var stable_id: String = "forager-left"
@export var territory := Vector2(900, 1360)
@export var home := Vector2(1230, 780)
@export var resolve_hits: int = 3
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
	active = settled
	change_state("settled" if settled else "feeding")

func engage() -> void:
	if state != "feeding": return
	active = true
	change_state("approach")

func _physics_process(delta: float) -> void:
	timer += delta
	velocity.y = minf(velocity.y + 1050.0 * delta, 800.0)
	velocity.x = 0.0
	if is_instance_valid(player) and player.health > 0:
		_update_behavior(delta)
	move_and_slide()
	position.x = clampf(position.x, territory.x, territory.y)
	visual.set_facing(facing)
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
			elif absf(difference.y) < 110.0:
				facing = signf(difference.x)
				if absf(difference.x) < 125.0: change_state("tell")
				else: velocity.x = facing * 78.0
		"tell":
			if timer >= 0.55: change_state("lunge")
		"lunge":
			velocity.x = facing * 160.0
			if not attack_sent and timer >= 0.06:
				attack_sent = true
				has_attacked = true
				if in_territory and difference.x * facing >= 0 and absf(difference.x) < 105 and absf(difference.y) < 100:
					player.take_damage(1, global_position)
			if timer >= 0.24: change_state("recover")
		"recover":
			if timer >= 0.7: change_state("approach")
		"retreat":
			if absf(home.x - position.x) > 4.0:
				facing = signf(home.x - position.x)
				velocity.x = facing * 100.0

func change_state(next: String) -> void:
	state = next
	timer = 0.0
	attack_sent = false
	if not is_instance_valid(visual): return
	match state:
		"approach": visual.set_action(&"walk")
		"tell": visual.set_action(&"warn", true)
		"lunge": visual.set_action(&"lunge", true)
		"recover": visual.set_action(&"hurt", true)
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
	struck.emit()
	if firmness == 0: change_state("retreat")
	else: change_state("recover")

func apply_knockback(_impulse: float) -> void:
	pass

func snapshot() -> Dictionary:
	return {"id":stable_id,"x":position.x,"y":position.y,"home_x":home.x,
		"state":state,"firmness":firmness,"hits":accepted_hits,"alive":true,
		"active":active,"frame":visual.frame,"action":str(visual.current_action)}
