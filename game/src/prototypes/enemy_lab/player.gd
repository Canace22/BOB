class_name EnemyLabPlayer
extends CombatWhiteboxPlayer
## 试验场只扩展无敌练习和水流；格挡与主线共用。
var all_skill_practice: bool=false
var invincible: bool = false
var pump_drift: float=0.0
var pump_applied: bool=false
var pump_base_x: float=0.0
func skill_unlocked(rule: String) -> bool:
	return all_skill_practice or super.skill_unlocked(rule)

func create_skill_controller() -> TideCombatSkills:
	return EnemyLabSkills.new()

func take_damage(amount: int=1, source: Vector2=Vector2.ZERO, force: bool=false) -> bool:
	if invincible and not force:
		skill_controller.parry_damage(source)
		return false
	return super.take_damage(amount,source,force)

func _before_move(dt: float) -> void:
	super._before_move(dt)
	# 场景只发布水流速度，仍由角色唯一的move_and_slide执行物理位移。
	if not retreating and not is_zero_approx(pump_drift):
		pump_base_x=velocity.x
		pump_applied=true
		velocity.x+=pump_drift

func _physics_process(dt: float) -> void:
	pump_applied=false
	super._physics_process(dt)
	# 水流不是每帧累加的角色加速度，移动后归还基础速度，避免无限加速。
	if pump_applied: velocity.x=0.0 if is_on_wall() else pump_base_x
