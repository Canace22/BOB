class_name FeelMeleeStartupCases
extends RefCounted
## 近战时序与命中后跳跃的真实输入用例，共用目标与事件取证。

class Target extends Node2D:
	var hits: Array[int] = []
	func _ready() -> void: add_to_group("tide_targets")
	func hurt_rect() -> Rect2: return Rect2(global_position - Vector2(10,10), Vector2(20,20))
	func can_receive_hit() -> bool: return true
	func take_hit(amount: int) -> void: hits.append(amount)

static func swing_hits(suite: TestSuite, p: TidePlayer) -> void:
	var victim := Target.new()
	victim.position = p.position + Vector2(60,-30)
	suite.add(victim)
	var start: Dictionary={}
	var hit: Dictionary={}
	p.animation_tag.connect(func(tag: String) -> void:
		if tag=="strike_01:start": start["tick"]=Engine.get_physics_frames())
	p.hit_resolved.connect(func(_target: Node,_area: Rect2,_key: String,_direction: float) -> void:
		if hit.is_empty(): hit.merge({"tick":Engine.get_physics_frames(),"time":p.state_time}))
	var dt: float=1.0/Engine.physics_ticks_per_second
	var startup_ticks: int=int(ceil(p.melee_startup/dt-0.000001))
	Input.action_press("tp_attack")
	var frames: int = 0
	for i: int in startup_ticks+4:
		await suite.physics_frames(1)
		frames = i + 1
		if not victim.hits.is_empty(): break
	Input.action_release("tp_attack")
	suite.check(not victim.hits.is_empty() and not hit.is_empty(),"swing reaches the real target after configured startup, observed frames %s"%frames)
	if not hit.is_empty() and not start.is_empty():
		# 输入注入和physics_frame观察有边界差；准确约束动作自身首次跨越startup的物理帧。
		var elapsed_ticks: int=int(hit.tick)-int(start.tick)
		suite.check(elapsed_ticks>=startup_ticks-1 and elapsed_ticks<=startup_ticks,"hit occurs on first startup crossing tick")
		suite.check(float(hit.time)>=p.melee_startup-0.00001 and float(hit.time)<=p.melee_startup+dt+0.00001,"hit time is within one physics sample of configured startup")
	Input.action_press("tp_left")
	await suite.physics_frames(4)
	suite.eq(p.facing, 1.0, "swing keeps the direction it started with")
	suite.check(p.velocity.x < -100.0, "movement stays free during a swing")
	Input.action_release("tp_left")
	p.start_recoil(-1.0)
	await suite.physics_frames(1)
	suite.eq(p.velocity.x, -p.hit_recoil_speed, "a landed hit pushes the attacker back")

static func jump_after_hit(suite: TestSuite, p: TidePlayer) -> void:
	var victim:=Target.new()
	victim.position=p.position+Vector2(60,-30)
	suite.add(victim)
	var hit: Dictionary={}
	p.hit_resolved.connect(func(_target: Node,_area: Rect2,_key: String,_direction: float) -> void:
		if hit.is_empty(): hit["time"]=p.state_time)
	Input.action_press("tp_attack")
	for i: int in int(ceil(p.melee_startup*Engine.physics_ticks_per_second))+4:
		await suite.physics_frames(1)
		if not hit.is_empty(): break
	Input.action_release("tp_attack")
	suite.check(not hit.is_empty(),"waited for actual hit_resolved before jumping")
	if not hit.is_empty(): suite.check(p.state_time-float(hit.time)<=1.0/Engine.physics_ticks_per_second+0.00001,"jump is requested immediately after observing the hit")
	suite.check(p._can_jump_cancel(),"production jump cancel opens at the actual hit")
	Input.action_press("tp_jump")
	await suite.physics_frames(3)
	Input.action_release("tp_jump")
	suite.check(p.velocity.y < -100.0 and not p.is_on_floor(), "jump is accepted during swing recovery")
	suite.eq(p.state, "strike_01", "the swing keeps playing through the jump")
