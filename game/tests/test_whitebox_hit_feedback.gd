extends TestSuite
## 从实际攻击进入反馈，检查双方停顿、接触点、群攻限额与呈现清理。

func fixture() -> Node2D:
	var arena: Node2D = preload("res://tests/whitebox_combat/main.tscn").instantiate()
	add(arena)
	await physics_frames(8)
	return arena

func wait_hit(arena: Node2D, before: int = 0) -> bool:
	for i: int in 50:
		if arena.player.hit_feedback.event_count > before: return true
		await physics_frames(1)
	return false

func visible_particles(feedback: CombatWhiteboxHitFeedback) -> int:
	var count: int = 0
	for item: Dictionary in feedback.particles:
		if (item.node as Sprite2D).visible: count += 1
	return count

func test_real_hit_synchronizes_target_clock_and_marks_near_contact_edge() -> void:
	var arena := await fixture()
	check(arena.player.request_action("strike_01"),"real attack starts")
	check(await wait_hit(arena),"actual damage produces feedback")
	check(arena.player.hitstop > 0.0 and arena.enemy.feedback_stop > 0.0,"both sides freeze")
	var enemy_time: float = arena.enemy.elapsed
	var actor_time: float = arena.player.state_time
	await physics_frames(1)
	eq(arena.enemy.elapsed,enemy_time,"enemy AI clock freezes")
	eq(arena.player.state_time,actor_time,"attack clock freezes with enemy")
	eq(arena.player.hit_feedback.last_point.x,arena.enemy.hurt_rect().position.x,"impact is on struck face instead of target center")
	check(visible_particles(arena.player.hit_feedback) > 0,"authored bitmap particles appear")
	arena.enemy.action_visual.present(arena.enemy)
	check(float(arena.enemy.action_visual.material.get_shader_parameter("flash")) > 0.0,"hit flash appears")

func test_empty_swing_has_no_damage_feedback() -> void:
	var arena := await fixture()
	arena.player.position.x = 100
	check(arena.player.request_action("strike_01"),"empty swing starts")
	await physics_frames(30)
	eq(arena.player.hit_feedback.event_count,0,"no false hit event")
	eq(visible_particles(arena.player.hit_feedback),0,"no false contact sparks")
	eq(arena.enemy.health,12,"target remains untouched")

func test_multi_target_hit_caps_attacker_pause_instead_of_adding() -> void:
	var arena := await fixture()
	arena.toggle_group()
	arena.extra_targets[0].position.x = 600
	arena.extra_targets[1].position.x = 700
	check(arena.player.request_action("wb_draw"),"group sweep starts")
	check(await wait_hit(arena),"group impact occurs")
	eq(arena.player.hit_feedback.event_count,3,"each real target receives feedback")
	check(arena.player.hitstop <= 4.0/60.0+0.001,"three targets do not triple attacker pause")
	eq(arena.player.hit_feedback.particles.size(),32,"effect pool remains bounded")
	check(visible_particles(arena.player.hit_feedback) <= 32,"particle count remains capped")

func test_flurry_uses_light_inner_hits_and_heavier_final_without_moving_target() -> void:
	var arena := await fixture()
	arena.enemy.health = 60
	var grades: Array[int] = []
	arena.player.skill_effect.connect(func(_key: String,event: String,_origin: Vector2,_direction: float) -> void:
		if event == "impact": grades.append(arena.player.hit_feedback.last_grade))
	check(arena.player.request_action("wb_flurry"),"flurry starts")
	await physics_frames(100)
	eq(grades,[0,0,0,0,2],"five pulses retain identity and final emphasis")
	eq(arena.enemy.health,55,"damage and hit count unchanged")
	eq(arena.enemy.position.x,650.0,"secondary flinch never changes collider or combo spacing")

func test_armor_flashes_without_faking_interrupt_or_launch() -> void:
	var arena := await fixture()
	arena.enemy.armored = true
	arena.enemy.begin_attack()
	check(arena.player.request_action("wb_rise"),"attack armored tell")
	check(await wait_hit(arena),"armor still accepts damage feedback")
	eq(arena.enemy.state,"tell","no fake interrupt")
	eq(arena.enemy.vertical_speed,0.0,"no fake launch")
	arena.enemy.action_visual.present(arena.enemy)
	eq(arena.enemy.action_visual.action_id,"tell","armor keeps its actual attack pose")
	check(float(arena.enemy.action_visual.material.get_shader_parameter("flash")) > 0.0,"armor hit is still readable")

func test_projectile_uses_same_feedback_and_reset_clears_pool() -> void:
	var arena := await fixture()
	check(arena.player.request_action("A4_parry"),"projectile starts")
	check(await wait_hit(arena),"projectile enters shared impact presentation")
	check(arena.enemy.health < 12,"projectile really deals damage")
	arena.reset_arena()
	eq(visible_particles(arena.player.hit_feedback),0,"reset hides all active particles")
	eq(arena.enemy.feedback_stop,0.0,"reset clears local freeze")
	eq(arena.enemy.feedback_power,0.0,"reset clears visual recoil")
	arena.player.hit_feedback.toggle()
	check(arena.player.request_action("strike_01"),"baseline attack remains available")
	await physics_frames(20)
	eq(arena.enemy.health,11,"A/B switch does not disable damage")
	eq(arena.enemy.feedback_stop,0.0,"baseline does not add target feedback")
	eq(visible_particles(arena.player.hit_feedback),0,"baseline does not spawn new feedback")
