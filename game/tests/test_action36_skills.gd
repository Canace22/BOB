extends TestSuite

class Target extends Node2D:
	var hits: Array[int] = []
	var receives: bool = true
	func _ready() -> void: add_to_group("tide_targets")
	func hurt_rect() -> Rect2: return Rect2(global_position - Vector2(10,10), Vector2(20,20))
	func can_receive_hit() -> bool: return receives
	func take_hit(amount: int) -> void: hits.append(amount)

class Gate extends Node2D:
	var uses: int = 0
	func use_transit_pass(_actor: Node) -> void: uses += 1

func player() -> TidePlayer:
	var p: TidePlayer = load("res://content/whalebelly/Player.tscn").instantiate()
	p.preload_actions = false
	add(p)
	p.set_physics_process(false)
	p.world_bounds = Rect2(-10000,-10000,20000,20000)
	return p

func target(at: Vector2) -> Target:
	var value: Target = Target.new()
	value.position = at
	add(value)
	return value

func test_release_crossing_and_cost_are_once() -> void:
	var p: TidePlayer = player()
	var victim: Target = target(Vector2(0,-100))
	check(p.request_action("up_spell"), "up spell accepted")
	eq(p.soul, 66, "resource consumed exactly on acceptance")
	p.state_time = .45
	p.skill_controller.tick()
	eq(victim.hits.size(), 1, "large time step crosses release and still hits")
	p.skill_controller.tick()
	eq(victim.hits.size(), 1, "repeated update cannot repeat release")
	eq(p.soul, 66, "release does not deduct resource again")
	p.state_time = 1.0
	p.skill_controller.tick()
	check(not p.skill_controller.active, "skill finishes after elapsed duration")
	check(not p.request_action("up_spell"), "cooldown rejects repeated request")
	eq(p.soul, 66, "rejected request does not charge")
	p.cooldowns.up_spell = 0.0
	p.soul = 32
	check(not p.request_action("up_spell"), "insufficient resource rejects skill")
	eq(p.soul, 32, "insufficient request leaves resource unchanged")

func test_multihit_and_direction_lock() -> void:
	var p: TidePlayer = player()
	var left: Target = target(Vector2(-70,-50))
	var right: Target = target(Vector2(70,-50))
	p.facing = -1.0
	check(p.request_action("great_slash"), "charged slash accepted")
	p.facing = 1.0
	p.skill_controller.apply_motion(.016)
	eq(p.facing, -1.0, "active attack keeps its accepted direction")
	p.state_time = .3
	p.skill_controller.tick()
	eq(left.hits.size(), 1, "left target receives left-facing slash")
	eq(right.hits.size(), 0, "opposite target is outside front slash")
	p.skill_controller.cancel()
	left.hits.clear()
	check(p.request_action("cyclone"), "cyclone accepted")
	p.state_time = .7
	p.skill_controller.tick()
	eq(left.hits.size(), 3, "all three crossed pulse events occur once")
	p.skill_controller.tick()
	eq(left.hits.size(), 3, "pulse index prevents duplicate hits")

func test_damage_interrupts_and_clears_charge() -> void:
	var p: TidePlayer = player()
	var victim: Target = target(Vector2(0,-100))
	check(p.request_action("abyss_scream"), "upgraded spell accepted")
	p.skill_controller.input.attack_hold = 1.0
	check(p.take_damage(1, Vector2(50,0), true), "forced real hit accepted")
	check(not p.skill_controller.active, "hit interrupts skill")
	eq(p.skill_controller.visual_key, "", "hit clears skill visual override")
	eq(p.skill_controller.input.attack_hold, 0.0, "hit clears held charge")
	p.state_time = 1.0
	p.skill_controller.tick()
	eq(victim.hits.size(), 0, "interrupted release cannot fire later")
	p.respawn()
	check(not p.skill_controller.active, "respawn has no active skill")
	eq(p.skill_controller.visual_key, "", "respawn clears visual state")

func test_parry_window_and_front_side() -> void:
	var p: TidePlayer = player()
	check(p.request_action("parry"), "parry accepted")
	check(not p.skill_controller.parry_damage(Vector2(50,0)), "startup has no parry")
	p.state_time = .1
	p.skill_controller.tick()
	check(not p.skill_controller.parry_damage(Vector2(-50,0)), "back side cannot be parried")
	check(p.skill_controller.parry_damage(Vector2(50,0)), "front hit inside window is parried")
	p.state_time = .3
	p.skill_controller.tick()
	check(not p.skill_controller.parry_damage(Vector2(50,0)), "recovery has no parry")

func test_transit_requires_real_target_and_water_is_explicit() -> void:
	var p: TidePlayer = player()
	check(not p.request_action("tram"), "transit cannot activate without compatible target")
	var gate: Gate = Gate.new()
	add(gate)
	p.interacted_target = gate
	check(p.request_action("tram"), "compatible transit target accepts request")
	p.state_time = .4
	p.skill_controller.tick()
	p.skill_controller.tick()
	eq(gate.uses, 1, "transit callback is exactly once")
	p.skill_controller.cancel()
	var surface: Node2D = Node2D.new()
	add(surface)
	p.position.y = 10
	p.skill_controller.set_water(surface)
	p.skill_controller.apply_motion(.016)
	eq(p.skill_controller.visual_key, "swim", "only explicit water selects swim")
	p.skill_controller.set_water(null)
	eq(p.skill_controller.visual_key, "", "leaving water clears swim immediately")
