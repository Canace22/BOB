class_name TideCombatSkills
extends TideSkillController
## 剑魂式职责参考，参数与命名为拾潮者白盒自定；复用现有释放、命中和冷却内核。

const DEFINITIONS: Dictionary = {
	"wb_rise": {"proxy":"strike_01","duration":0.36,"release":0.07,"damage":1,"shape":"front","reach":125.0,"cooldown":1.1,"launch":510.0,"motion":"free"},
	"wb_drive": {"proxy":"strike_01","duration":0.24,"release":0.06,"damage":1,"shape":"front","reach":135.0,"cooldown":1.8,"motion":"combo_dash","speed":450.0},
	"wb_draw": {"proxy":"heavy","duration":0.56,"release":0.22,"damage":3,"shape":"radial","reach":220.0,"cooldown":3.0,"knockdown":true,"repulse":true},
	"wb_charge": {"proxy":"strike_01","duration":0.62,"release":0.18,"damage":2,"shape":"front","reach":100.0,"cooldown":2.4,"motion":"shoulder","speed":630.0,"launch":660.0},
	"wb_flurry": {"proxy":"heavy","duration":0.94,"release":0.10,"damage":1,"shape":"front","reach":160.0,"pulses":[0.10,0.24,0.38,0.52,0.66],"cooldown":4.0,"finish_down":true,"motion":"rooted"},
	"wb_backcut": {"proxy":"strike_01","duration":0.18,"release":0.03,"damage":1,"shape":"front","reach":155.0,"cooldown":0.6,"backstep_only":true}
}
const BINDINGS: Dictionary = {"wb_rise":"W+J","wb_drive":"A/D+K","wb_draw":"S+J","wb_charge":"A/D+L","wb_flurry":"E+J"}
const TITLES: Dictionary = {"wb_rise":"Tide Rise","wb_drive":"Triple Current","wb_draw":"Wide Break","wb_charge":"Surge Rise","wb_flurry":"Echo Flurry","wb_backcut":"Backstep Cut"}
var combo_hits: int = 0
var combo_left: float = 0.0
var drive_step: int = 0
var drive_window: float = 0.0
const DRIVE_CHAIN_WINDOW: float = 1.10

func setup(player: TidePlayer) -> void:
	super.setup(player)
	for key: String in DEFINITIONS: actor.cooldowns[key] = 0.0
	actor.skill_effect.connect(_on_hit_effect)

func request(key: String) -> bool:
	if not DEFINITIONS.has(key): return super.request(key)
	if not actor.controls_enabled or actor.health <= 0: return false
	if not actor.skill_unlocked(unlock_rule(key)): return false
	var chaining: bool = key == "wb_drive" and drive_window > 0.0 and drive_step < 3
	if float(actor.cooldowns.get(key,0.0)) > 0.0 and not chaining: return false
	var spec: Dictionary = DEFINITIONS[key].duplicate(true)
	var backcut: bool = bool(spec.get("backstep_only",false))
	if backcut != bool(actor.get("retreating")): return false
	if actor.state in ["hit","defeat","recover","interact"]: return false
	if not backcut and actor.state_duration > 0.0:
		if not bool(actor.call("_offense_active")) or not bool(actor.call("_offense_released")): return false
	# 只有校验成功才撤掉原动作，连招不退款、不跳过剩余攻击段。
	var next_step: int = drive_step+1 if chaining else 1
	var saved_cooldown: float = float(actor.cooldowns.get(key,0.0))
	cancel()
	input.clear()
	actor.pending_action = ""
	actor.pending_left = 0.0
	spec.merge({"cost":0,"cooldown_group":key,"lock_facing":true,"knockback":0.0},false)
	data = spec
	visual_key = key
	last_key = key
	duration = float(spec.duration)
	elapsed = 0.0
	locked_facing = actor.facing
	if key == "wb_drive":
		drive_step = next_step
		drive_window = DRIVE_CHAIN_WINDOW
		var axis: float = actor.movement_axis()
		if not is_zero_approx(axis):
			locked_facing = signf(axis)
			actor.facing = locked_facing
	attack_id += 1
	released = false
	pulse_index = 0
	parried = false
	entering = true
	actor._enter(str(spec.proxy),duration)
	entering = false
	active = true
	actor.cooldowns[key] = saved_cooldown if chaining else float(spec.cooldown)
	actor.animation_tag.emit(key+":start")
	actor.skill_effect.emit(key,"start",actor.global_position,locked_facing)
	return true

func _release() -> void:
	super._release()
	if not active or not DEFINITIONS.has(visual_key): return
	if data.has("launch"): _apply_control("launch",float(data.launch))
	if bool(data.get("knockdown",false)): _apply_control("knock_down",0.0)
	if bool(data.get("repulse",false)): _apply_control("push_away",actor.global_position.x)

func tick() -> void:
	var was_pulse: int = pulse_index
	super.tick()
	if active and visual_key == "wb_flurry" and pulse_index != was_pulse:
		_apply_control("pin",0.28)
	if active and bool(data.get("finish_down",false)) and pulse_index != was_pulse:
		var pulses: Array = data.get("pulses",[])
		if pulse_index == pulses.size(): _apply_control("knock_down",0.0)

func _apply_control(method: String, strength: float) -> void:
	# 使用实际命中集合，范围外目标与拒绝命中的目标不会凭空被挑起。
	for target: Node in actor.get_tree().get_nodes_in_group("tide_targets"):
		if actor.hit_targets.has(target.get_instance_id()) and target.has_method(method):
			target.call(method,strength)

func apply_motion(dt: float) -> void:
	if active and str(data.get("motion","")) == "rooted":
		actor.velocity.x = 0.0
		return
	if active and str(data.get("motion","")) == "shoulder":
		actor.velocity.x = locked_facing*float(data.speed) if not released else 0.0
		for target: Node in actor.get_tree().get_nodes_in_group("tide_targets"):
			var delta: Vector2 = target.global_position-actor.global_position
			if delta.x*locked_facing > 0.0 and absf(delta.x) <= 52.0 and absf(delta.y) < 75.0:
				actor.velocity.x = 0.0
		return
	if active and str(data.get("motion","")) == "combo_dash":
		actor.facing = locked_facing
		actor.velocity.x = locked_facing*float(data.speed) if elapsed <= 0.12 else 0.0
		return
	super.apply_motion(dt)

func can_cancel(kind: String) -> bool:
	if active and DEFINITIONS.has(visual_key):
		return bool(actor.call("_offense_released"))
	return super.can_cancel(kind)

func _on_hit_effect(_key: String,event: String,_origin: Vector2,_direction: float) -> void:
	if event != "impact": return
	combo_hits += 1
	combo_left = 1.0

func update_combo(dt: float) -> void:
	drive_window = maxf(0.0,drive_window-dt)
	combo_left = maxf(0.0,combo_left-dt)
	if combo_left <= 0.0: combo_hits = 0

func cancel() -> void:
	drive_step = 0
	drive_window = 0.0
	super.cancel()

func finish() -> void:
	# 一段自然结束后仍可补按下一段；防御/后跳取消则关闭续段窗口。
	var keep_step: int = drive_step
	var keep_window: float = drive_window
	var keep_chain: bool = visual_key == "wb_drive" and drive_step < 3
	super.finish()
	if keep_chain:
		drive_step = keep_step
		drive_window = keep_window

static func unlock_rule(key: String) -> String:
	# 新增基础剑技可开局使用，进阶连斩沿用负壳守卫的冲刺奖励，不新增存档字段。
	return "dash" if key == "wb_flurry" else "always"
