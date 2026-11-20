extends TestSuite
## 真实命中驱动架叉与有限破绽；不复制玩家控制器。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=6
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	lab.player.position=Vector2(750,520)
	lab.player.facing=1.0
	return lab

func test_catalog_and_sheet_have_independent_shape() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	check(e!=null,"stable ID chooses beam executor")
	check(lab.player.world_collision_mask==5 and lab.player.phase_collision_mask==1,"beam blocks walking through body while phase actions retain traversal")
	eq(lab.hud.enemy_menu.item_count,EnemyLabCatalog.PROFILES.size(),"catalog drives enemy count")
	eq(lab.hud.move_menu.item_count,5,"natural and four unique actions")
	check(e.visual.texture.resource_path.contains("beam-guard"),"independent broad crescent sheet")
	eq(e.visual.metadata.beam_guard.regions.size(),16,"sixteen poses")

func test_brace_does_not_read_attack_button_or_attack_without_contact() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	e.begin_attack("beam_brace")
	eq(e.state,"brace","first enters nonattacking brace")
	eq(float((e.visual.material as ShaderMaterial).get_shader_parameter("danger")),0.0,"brace itself is not red")
	await physics_frames(73)
	eq(e.counters,0,"no contact no counter")
	eq(lab.player.health,5,"natural expiry does not attack")
	eq(e.state,"idle","unused brace expires")

func test_front_hit_has_damage_and_new_full_unblockable_tell() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	e.begin_attack("beam_brace")
	e.take_hit(1)
	eq(e.reactions.received,1,"actual contact recorded")
	check(is_equal_approx(e.reactions.damage_remainder,0.5),"half damage retained")
	check(e.state=="tell" and is_zero_approx(e.timer),"new tell starts at zero")
	check(e.spec.unblockable and e.phase_duration()==0.8,"full visible counter preparation")
	eq(e.counters,1,"single counter")
	e.timer=0.3
	e.take_hit(1)
	eq(e.timer,0.3,"second hit cannot refresh counter clock")
	eq(e.counters,1,"multihit cannot queue counter")
	eq(e.health,17,"subsequent exposed tell takes full damage")

func test_rear_hit_breaks_brace_without_counter_or_damage_reduction() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	e.begin_attack("beam_brace")
	lab.player.position.x=e.position.x+90
	e.take_hit(1)
	check(e.state=="recover" and e.opening_left==1.2,"rear breaks posture")
	eq(e.health,17,"rear full damage")
	check(e.counters==0 and e.rear_breaks==1,"no revenge after rear break")
	eq(EnemyLabDebug.segments(e).size(),1,"cancelled counter removed from timeline")

func test_opening_budget_survives_control_without_refresh() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	e.begin_attack("beam_press")
	e.take_hit(1)
	eq(e.state,"tell","committed slash takes hit without flinch")
	e.guard_reaction(true)
	for i: int in 12:
		e.pin(0.4)
		e.take_hit(1)
		await physics_frames(10)
	check(e.health>0 and e.state=="idle" and e.opening_left==0.0,"finite opening cannot be extended into permanent lock")

func test_retreat_keeps_facing_and_is_not_a_control_window() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	e.begin_attack("beam_return")
	var x: float=e.position.x
	await physics_frames(25)
	check(e.position.x>x+40 and e.facing==-1.0,"actual backward movement keeps blade towards pursuer")
	check(e.state=="tell" and not e.control_window_open(),"retreat not free opening")
	eq(float((e.visual.material as ShaderMaterial).get_shader_parameter("danger")),0.0,"ordinary action uses pose not red")
	check(float(e.spec.height)==34.0,"low return cut can be jumped")

func test_guard_reward_and_locked_counter_can_be_outflanked() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	e.begin_attack("beam_press")
	e.guard_reaction(false)
	eq(e.opening_left,0.65,"ordinary block short opening")
	e.guard_reaction(true)
	eq(e.opening_left,1.35,"perfect block greater reward")
	e.set_state("idle")
	e.begin_attack("beam_brace")
	e.take_hit(1)
	for frame: int in 60:
		await physics_frames(1)
		if e.timer>=0.48: break
	check(e.state=="tell" and e.timer>=0.45,"observe real lock after feedback freeze")
	var committed: float=e.facing
	lab.player.position.x=e.position.x+90
	await physics_frames(9)
	eq(e.facing,committed,"last 0.35 seconds cannot track behind")

func test_death_wins_over_counter_and_crossing_does_not_end_round() -> void:
	var lab := await fixture()
	var e: EnemyLabBeamGuard=lab.enemies[0] as EnemyLabBeamGuard
	lab.player.position.x=1180
	await physics_frames(3)
	check(not lab.route_passed and e.outcome.is_empty(),"passing is not boss victory")
	lab.player.position.x=e.position.x-70
	e.begin_attack("beam_brace")
	e.take_hit(100)
	check(e.outcome=="kill" and not e.data.alive and e.counters==0,"fatal contact ends before revenge")
	await physics_frames(100)
	eq(lab.player.health,5,"no late death attack")
	lab.reset_round()
	await physics_frames(14)
	check(not is_instance_valid(e) and lab.enemies[0].health==18,"round owns complete cleanup")
