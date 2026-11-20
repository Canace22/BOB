class_name EnemyLabDebug
extends RefCounted
## 只读适配正式控制器窗口；不依赖旧白盒靶的类型或自己的倒计时。
static func player(p: EnemyLabPlayer) -> Dictionary:
	var c: TideCombatSkills=p.skill_controller as TideCombatSkills
	var guard: bool=c.active and c.visual_key=="parry"
	return {"key":c.visual_key if c.active else p.state,"time":p.state_time,"duration":c.duration if c.active else p.state_duration,
		"release":float(c.data.get("release",0.0)) if c.active else p.action_trigger_time(),
		"guard_open":guard and (c as EnemyLabSkills).guard_open(),
		"cancel_open":p._offense_active() and p._offense_released(),"backstep":p.controls_enabled and p.health>0 and p.is_on_floor() and not p.retreating and p.retreat_cooldown<=0.0 and p.state not in ["hit","defeat","recover","interact"],
		"hitstop":p.hitstop,"buffer":p.pending_action,"buffer_left":p.pending_left,"chord":p.pad_input.waiting_face>=0,"chord_time":p.pad_input.face_age}
static func segments(e: EnemyLabEnemy) -> Array[Dictionary]:
	if e is EnemyLabElder: return e.segments()
	if e is EnemyLabBeamGuard: return e.segments()
	if e is EnemyLabWarden and e.water!=null and e.water.handles(): return e.water.segments()
	if e is EnemyLabEel and e.nest.handles(): return e.nest.segments()
	if e.state in ["return","escape_tell","evade"]: return [{"phase":e.state,"pulse":1,"start":0.0,"end":e.phase_duration()}]
	if e.spec.is_empty(): return []
	var result: Array[Dictionary]=[]
	var cursor: float=0.0
	var parts: int=2 if e.move_key in ["double","warden_double"] else 1
	if e.followup_cancelled: parts=1
	for part: int in parts:
		for phase: String in ["tell","active"]:
			var seconds: float=float(e.spec.get("second",0.30)) if phase=="tell" and part==1 else float(e.spec[phase])
			result.append({"phase":phase,"pulse":part+1,"start":cursor,"end":cursor+seconds})
			cursor+=seconds
	result.append({"phase":"recover","pulse":parts,"start":cursor,"end":cursor+float(e.spec.recover)})
	return result
