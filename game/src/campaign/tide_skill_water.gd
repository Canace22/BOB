class_name TideSkillWater
extends Area2D
## Place at the authored liquid surface. Visual water stays owned by the room.
@export var corrosive: bool = true
var occupants: Array[Node2D] = []
var damage_clock: float = 0.0

func _ready() -> void:
	collision_layer=0
	collision_mask=2
	body_entered.connect(_enter)
	body_exited.connect(_exit)

func _enter(body: Node2D) -> void:
	if not body is TidePlayer: return
	if not occupants.has(body): occupants.append(body)
	body.skill_controller.set_water(self)

func _exit(body: Node2D) -> void:
	occupants.erase(body)
	if body is TidePlayer: body.skill_controller.set_water(null)

func _physics_process(dt: float) -> void:
	damage_clock-=dt
	if not corrosive or damage_clock>0: return
	damage_clock=0.6
	for body: Node2D in occupants:
		if is_instance_valid(body) and not body.skill_unlocked("chapter"): body.take_damage(1,global_position)

func _exit_tree() -> void:
	for body: Node2D in occupants:
		if is_instance_valid(body): body.skill_controller.set_water(null)
