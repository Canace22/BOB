class_name TideSkillController
extends RefCounted
## Extensions retain TidePlayer's physics and campaign compatibility boundary.
var actor: TidePlayer
var visual_key: String = ""
var last_key: String = ""
var elapsed: float = 0.0
var duration: float = 0.0
var active: bool = false
var entering: bool = false
var data: Dictionary = {}
var attack_id: int = 0
var released: bool = false
var pulse_index: int = 0
var landed: bool = false
var landed_at: float = 0.0
var parried: bool = false
var use_upgrades: bool = true
var locked_facing: float = 1.0
var attacks := TideSkillHits.new()
var input := TideSkillInput.new()
var water: WeakRef

func setup(player: TidePlayer) -> void:
	actor = player
	attacks.actor = actor
	input.controller = self
	for key: String in TideSkillCatalog.ACTIONS:
		actor.cooldowns[key] = 0.0

func dispose() -> void:
	active=false
	input.clear()
	input.controller=null
	attacks.actor=null
	actor=null

func request(key: String) -> bool:
	var spec: Dictionary = TideSkillCatalog.definition(key)
	if spec.is_empty() or actor.health <= 0 or not actor.controls_enabled: return false
	if not actor.skill_unlocked(spec.unlock):
		actor.notification.emit(TideSkillCatalog.unlock_hint(spec.unlock)+"；F9可临时练习")
		return false
	var dash_followup: bool=key=="dash_slash" and visual_key in ["shadow_dash","crystal_dash"]
	if active and not dash_followup and not can_cancel("skill"): return false
	if not active and actor.state_duration > 0:
		var dash_attack: bool = key == "dash_slash" and actor.state in ["A1_dash","A5_slit"]
		var jump_attack: bool=actor.state=="strike_02"
		var heal_cancel: bool=key=="shadow_dash" and actor.state=="recover"
		if not dash_attack and not jump_attack and not heal_cancel and (actor.state in ["hit","defeat","recover","interact"] or actor.state_time < actor.state_duration * 0.65): return false
	if actor.cooldowns.get(key,0.0) > 0.0 or actor.cooldowns.get(spec.cooldown_group,0.0)>0.0: return false
	if bool(spec.get("air_only",false)) and actor.is_on_floor(): return false
	if bool(spec.get("interaction",false)) and (not is_instance_valid(actor.interacted_target) or not actor.interacted_target.has_method("use_transit_pass")): return false
	if actor.soul < int(spec.cost):
		actor.notification.emit("魂量不足 · 需要%d点" % int(spec.cost))
		return false
	cancel()
	data = spec
	visual_key = key
	last_key = key
	duration = float(spec.duration)
	elapsed = 0.0
	locked_facing = actor.facing
	attack_id += 1
	released = false
	pulse_index = 0
	landed = false
	landed_at = 0.0
	parried = false
	entering = true
	actor._enter(str(spec.proxy),duration)
	entering = false
	active = true
	actor.soul -= int(spec.cost)
	actor.cooldowns[key] = float(spec.cooldown)
	actor.cooldowns[spec.cooldown_group] = float(spec.cooldown)
	actor.stats_changed.emit(actor.health,actor.soul)
	actor.animation_tag.emit(key+":start")
	actor.skill_effect.emit(key,"start",actor.global_position,locked_facing)
	if bool(spec.get("immune",false)): actor.invulnerable=maxf(actor.invulnerable,duration)
	return true

func tick() -> void:
	if not active: return
	elapsed = actor.state_time
	if visual_key=="parry" and elapsed>=float(data.release) and elapsed<=float(data.parry_end):
		for projectile: Node2D in actor.get_tree().get_nodes_in_group("tide_hostile_projectiles"):
			if not projectile.has_method("reflect") or parried: continue
			var delta: Vector2=projectile.global_position-(actor.global_position+Vector2(0,-40))
			if delta.length()<=70.0 and delta.x*locked_facing>=0:
				projectile.reflect(actor,locked_facing)
				parry_damage(projectile.global_position)
	if elapsed >= float(data.release) and not released:
		released = true
		actor.animation_tag.emit(visual_key+":release")
		if str(data.get("motion","")) != "dive":
			actor.skill_effect.emit(visual_key,"release",actor.global_position,locked_facing)
			_release()
	if data.has("pulses"):
		var pulses: Array = data.pulses
		while pulse_index < pulses.size() and elapsed >= float(pulses[pulse_index]):
			actor.hit_targets.clear()
			attacks.area_hit(data,locked_facing)
			pulse_index += 1
	if elapsed >= duration: finish()

func _release() -> void:
	if bool(data.get("projectile",false)):
		attacks.projectile(int(data.damage),locked_facing,true)
	elif data.has("damage") and not data.has("pulses"):
		attacks.area_hit(data,locked_facing)
	if visual_key == "scan":
		var count: int = 0
		for target: Node in actor.get_tree().get_nodes_in_group("tide_targets"):
			if actor.global_position.distance_to(target.global_position)<420.0: count+=1
		actor.notification.emit("骨音探潮：附近%d个目标" % count)
		for target: Node in actor.get_tree().get_nodes_in_group("tide_scannable"):
			if actor.global_position.distance_to(target.global_position)<420.0 and target.has_method("reveal"): target.reveal(actor)
	if visual_key == "tram" and is_instance_valid(actor.interacted_target):
		actor.interacted_target.use_transit_pass(actor)

func apply_motion(_dt: float) -> void:
	if not active:
		_apply_water()
		return
	actor.facing = locked_facing
	match str(data.get("motion","")):
		"dash": actor.velocity = Vector2(locked_facing*float(data.speed),0)
		"lunge": actor.velocity.x=locked_facing*float(data.speed) if elapsed<float(data.release) else 0.0
		"dive":
			actor.velocity=Vector2.ZERO if not released or landed else Vector2(0,900)
		_:
			actor.velocity.x=0.0
			if not actor.is_on_floor(): actor.velocity.y=minf(actor.velocity.y,120.0)

func after_move() -> void:
	if not active: return
	if visual_key=="crystal_dash": attacks.area_hit(data,locked_facing)
	if str(data.get("motion","")) == "dive" and released and not landed and actor.is_on_floor():
		landed=true
		landed_at=elapsed
		attacks.area_hit(data,locked_facing)
		actor.skill_effect.emit(visual_key,"land",actor.global_position,locked_facing)
		duration=elapsed+0.24
		actor.state_duration=duration
		if visual_key=="dark_dive": actor.invulnerable=maxf(actor.invulnerable,0.28)
	if str(data.get("motion","")) == "dash" and actor.is_on_wall(): finish()

func can_cancel(kind: String) -> bool:
	if not active: return true
	if visual_key=="crystal_dash": return kind in ["jump","dash","skill"]
	return elapsed >= duration*float(data.get("cancel",0.65))

func cancel() -> void:
	if active:
		actor.skill_effect.emit(visual_key,"cancel",actor.global_position,locked_facing)
		actor.state_duration=0.0
		actor.state_time=0.0
		actor.state=actor.locomotion_animation()
	active=false
	visual_key=""
	elapsed=0.0
	duration=0.0
	landed=false
	landed_at=0.0
	data.clear()

func finish() -> void:
	if not active: return
	actor.animation_tag.emit(visual_key+":end")
	actor.skill_effect.emit(visual_key,"end",actor.global_position,locked_facing)
	cancel()

func blocks_input() -> bool:
	return active and not can_cancel("skill")

func parry_damage(source: Vector2) -> bool:
	if not active or parried or visual_key!="parry" or elapsed<float(data.release) or elapsed>float(data.parry_end): return false
	if source!=Vector2.ZERO and (source.x-actor.global_position.x)*locked_facing<0: return false
	parried=true
	actor.skill_effect.emit("parry","success",actor.global_position,locked_facing)
	actor.invulnerable=maxf(actor.invulnerable,0.18)
	actor.soul=mini(actor.max_soul,actor.soul+actor.soul_per_hit)
	actor.stats_changed.emit(actor.health,actor.soul)
	actor.hit_confirmed.emit()
	return true

func set_water(area: Node2D) -> void:
	water=weakref(area) if is_instance_valid(area) else null
	if water==null and not active and visual_key=="swim": visual_key=""

func nearby_gate() -> Node:
	var nearest: Node
	var distance: float=INF
	for gate: Node2D in actor.get_tree().get_nodes_in_group("tide_transit_gates"):
		var gap: float=gate.global_position.distance_to(actor.global_position)
		if gap<float(gate.interaction_radius) and gap<distance:
			nearest=gate
			distance=gap
	return nearest

func _apply_water() -> void:
	if water==null or not is_instance_valid(water.get_ref()): return
	var area: Node2D=water.get_ref()
	if not actor.skill_unlocked("chapter"): return
	if actor.global_position.y < area.global_position.y-12.0:
		if visual_key=="swim": visual_key=""
		return
	if actor.velocity.y < -180.0:
		visual_key=""
		return
	actor.velocity.y=clampf((area.global_position.y-actor.global_position.y)*8,-140,140)
	actor.jump_count=0
	actor.coyote=actor.coyote_time
	visual_key="swim"
	elapsed+=actor.get_physics_process_delta_time()
	duration=1.0
