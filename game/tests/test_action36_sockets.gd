extends TestSuite

func player_with_sockets() -> TidePlayer:
	var room:=Node2D.new()
	room.position=Vector2(31,47)
	add(room)
	var p: TidePlayer=load("res://content/whalebelly/Player.tscn").instantiate()
	p.preload_actions=false
	p.position=Vector2(200,300)
	room.add_child(p)
	p.set_physics_process(false)
	var view:=TideActionVisual.new()
	view.name="RunVisualController"
	p.add_child(view)
	view.setup(p,94.0)
	# Contract fixture: offsets are source-root units, not final world pixels.
	view.manifest.orb={"reference_height":160,"sockets":{"muzzle":[66,-53]}}
	view.manifest.shadow_orb={"reference_height":160,"sockets":{"muzzle":[66,-60]}}
	view.manifest.parry={"reference_height":160,"sockets":{"guard":[45,-65]}}
	return p

func latest_orb(p: TidePlayer) -> WhalebellyTideOrb:
	var result: WhalebellyTideOrb
	for node: Node in tree.get_nodes_in_group("tide_player_projectiles"):
		if node.caster==p: result=node
	return result

func test_projectile_socket_uses_locked_direction_and_flight_is_independent() -> void:
	var p: TidePlayer=player_with_sockets()
	for piercing: bool in [false,true]:
		for direction: float in [-1.0,1.0]:
			p.facing=-direction # Deliberately differs from release direction.
			var initial_actor: Vector2=p.global_position
			p.skill_controller.attacks.projectile(2,direction,piercing)
			var orb: WhalebellyTideOrb=latest_orb(p)
			orb.set_physics_process(false)
			var expected: Vector2=initial_actor+Vector2(direction*66,-60 if piercing else -53)*94.0/160.0
			check(orb.global_position.is_equal_approx(expected),"both projectile variants use mirrored muzzle in world space")
			eq(orb.direction,direction,"flight direction comes from accepted skill")
			p.facing=direction
			p.global_position+=Vector2(100,50)
			orb._physics_process(.05)
			check((orb.global_position.x-expected.x)*direction>0.0,"emitted projectile continues original flight after caster flips")
			eq(orb.global_position.y,expected.y,"caster movement cannot drag emitted projectile")
			p.clear_projectiles()
			await tree.process_frame

func test_missing_socket_keeps_legacy_world_fallback() -> void:
	var p: TidePlayer=player_with_sockets()
	p.get_node("RunVisualController").manifest.erase("orb")
	p.skill_controller.attacks.projectile(2,-1.0)
	var orb: WhalebellyTideOrb=latest_orb(p)
	orb.set_physics_process(false)
	var expected: Vector2=p.global_position+Vector2(-26,-p.collision_size.y*.65)
	check(orb.global_position.is_equal_approx(expected),"missing metadata retains legacy fallback without parent transform duplication")

func test_parry_bitmap_flash_requires_success_and_uses_guard_socket() -> void:
	var p: TidePlayer=player_with_sockets()
	var fx:=TideWorldEffects.new()
	p.add_child(fx)
	fx.setup(p,94.0)
	fx.set_process(false)
	for direction: float in [-1.0,1.0]:
		p.facing=direction
		p.cooldowns.parry=0.0
		check(p.request_action("parry"),"parry request accepted")
		eq(fx.particles.size(),0,"parry startup has no baked success flash")
		p.state_time=.1
		p._update_action_events()
		eq(fx.particles.size(),0,"open parry window alone has no success flash")
		p.facing=-direction
		var source: Vector2=p.global_position+Vector2(direction*50,-30)
		check(p.skill_controller.parry_damage(source),"forward hit inside window actually parried")
		eq(fx.particles.size(),1,"only a confirmed parry creates bitmap feedback")
		if not fx.particles.is_empty():
			var expected: Vector2=p.global_position+Vector2(direction*45,-65)*94.0/160.0
			check(fx.particles[0].node.global_position.is_equal_approx(expected),"parry flash uses locked direction at correct guard socket")
		check(not p.skill_controller.parry_damage(source),"same activation cannot repeat success")
		eq(fx.particles.size(),1,"repeated contact cannot duplicate success flash")
		p.skill_controller.cancel()
		eq(fx.particles.size(),0,"parry cancellation clears its flash")
