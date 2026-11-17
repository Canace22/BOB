class_name CombatWhiteboxTimelineData
extends RefCounted
## 只读当前控制器与角色状态，不用UI自己的计时器推算战斗进度。

static func sample(p: CombatWhiteboxPlayer, enemy: CombatWhiteboxEnemy) -> Dictionary:
	var c := p.skill_controller as CombatWhiteboxSwordSkills
	var key: String = c.visual_key if c.active else p.state
	var duration: float = c.duration if c.active else p.state_duration
	var elapsed: float = p.state_time
	var active: bool = c.active or duration > 0.0
	if not active: elapsed = 0.0
	var hits: Array = []
	var release: float = 0.0
	var recovery: float = duration
	if c.active:
		release = float(c.data.release)
		if c.data.has("damage"):
			hits = c.data.get("pulses",[release]).duplicate()
			recovery = float(hits.back()) if not hits.is_empty() else release
			if str(c.data.get("motion","")) == "dive":
				recovery = c.landed_at if c.landed else duration
	elif p._offense_active():
		release = p.action_trigger_time()
		hits = [release]
		recovery = release+(1.0/p.animation_fps if p.state in ["strike_01","A3_anchor"] else 0.0)
	var offense: bool = p._offense_active()
	var recovery_open: bool = offense and p._offense_released()
	var idle_ready: bool = not active and not p.retreating
	var available: bool = p.controls_enabled and p.health > 0
	var cancel_open: bool = available and not p.retreating and (recovery_open or idle_ready)
	var guard_window: bool = c.active and key == "parry"
	var guard_start: float = float(c.data.get("release",0.0)) if guard_window else 0.0
	var guard_end: float = float(c.data.get("parry_end",0.0)) if guard_window else 0.0
	if guard_window: recovery = guard_end
	var chain_open: bool = c.drive_window > 0.0 and c.drive_step < 3
	var backstep_ready: bool = available and p.backstep_enabled and not p.retreating and p.retreat_cooldown <= 0.0 and p.is_on_floor() and p.state not in ["hit","defeat","recover","interact"]
	var phase: String = "IDLE"
	if active:
		phase = "STARTUP" if elapsed < release else ("RECOVERY" if elapsed >= recovery else "ATTACK")
		if guard_window: phase = "STARTUP" if elapsed < guard_start else ("GUARD" if elapsed <= guard_end and not c.parried else "RECOVERY")
		elif key in ["A1_dash","A5_slit"]: phase = "DASH"
		elif not offense: phase = key.to_upper()
	if p.retreating and not c.active:
		key = "BACKSTEP"
		elapsed = p.retreat_time
		duration = 0.0
		active = true
		phase = "UNTIL LANDING"
	var enemy_duration: float = float({"tell":0.7,"active":0.2,"recover":1.1,"stagger":enemy.stagger_duration,"down":0.45}.get(enemy.state,0.0))
	return {
		"key":key,"active":active,"elapsed":elapsed,"duration":duration,"phase":phase,
		"progress":clampf(elapsed/duration,0.0,1.0) if duration > 0.0 else 0.0,
		"release":release,"hits":hits,"recovery":recovery,"offense":offense,"recovery_open":recovery_open,
		"dash_ready":cancel_open and float(p.cooldowns.dash) <= 0.0,"dash_cd":float(p.cooldowns.dash),
		"guard_ready":cancel_open and float(p.cooldowns.parry) <= 0.0,"guard_cd":float(p.cooldowns.parry),
		"guard_track":guard_window,"guard_start":guard_start,"guard_end":guard_end,
		"guard_open":guard_window and elapsed >= guard_start and elapsed <= guard_end and not c.parried,
		"guard_used":c.parried,"invulnerable":p.invulnerable,"hitstop":p.hitstop,
		"chain_open":chain_open,"chain_left":c.drive_window,"chain_max":c.DRIVE_CHAIN_WINDOW,"chain_step":c.drive_step,
		"backstep_ready":backstep_ready,"retreating":p.retreating,"retreat_elapsed":p.retreat_time,
		"enemy_state":enemy.state,"enemy_elapsed":enemy.elapsed,"enemy_duration":enemy_duration,
		"enemy_hit":enemy.state == "active" and not enemy.hit_sent
	}
