class_name EnemyLabPlayer
extends CombatWhiteboxPlayer
## 试验场持续格挡通过局部控制器注入；主线默认参数不变。
signal guard_success(perfect: bool)
signal guard_broken
var all_skill_practice: bool=false
var invincible: bool = false
var pump_drift: float=0.0
var pump_applied: bool=false
var pump_base_x: float=0.0
func skill_unlocked(rule: String) -> bool:
	return all_skill_practice or super.skill_unlocked(rule)

func create_skill_controller() -> TideCombatSkills:
	return EnemyLabSkills.new()

func request_action(action: String) -> bool:
	var c: EnemyLabSkills=skill_controller as EnemyLabSkills
	if c.active and c.visual_key=="parry" and c.parried and action!="parry":
		# 仅成功格挡可立即反击；先由共用入口校验，失败不吞原防御。
		if action in ["strike_01","strike2"] and controls_enabled and health>0:
			c.cancel()
	return super.request_action(action)

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
