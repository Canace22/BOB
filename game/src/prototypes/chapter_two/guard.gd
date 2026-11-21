class_name ChapterTwoGuard
extends EnemyLabEnemy
## 只适配章节交锋范围和非致死事件；原守卫招式、护架与受控规则不变。
signal blockade_removed
var awake: bool = false
var lane := Vector2(1040,1770)

func _ready() -> void:
	profile=ChapterCombatPressure.apply(profile)
	super._ready()

func can_receive_hit() -> bool:
	return awake and super.can_receive_hit()

func _physics_process(dt: float) -> void:
	auto_attack = awake
	super._physics_process(dt)
	position.x = clampf(position.x,lane.x,lane.y)

func finish() -> void:
	if not outcome.is_empty(): return
	kill_comparison = false
	super.finish()
	blockade_removed.emit()

func reset_encounter() -> void:
	pressure.reset()
	health = maximum
	position = home
	velocity = Vector2.ZERO
	outcome = ""
	data.alive = true
	control_left = 0
	reactions.damage_remainder = 0
	feedback.clear()
	collision_layer = 4
	collision_mask = 3
	if not is_in_group("tide_targets"): add_to_group("tide_targets")
	awake = false
	auto_attack = false
	set_state("idle")
