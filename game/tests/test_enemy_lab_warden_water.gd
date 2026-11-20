extends TestSuite
## Boss水术在无膜泵/泄压瓣的默认场地独立成立。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=5
	lab.terrain=0
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	return lab
func after_each() -> void:
	tree.paused=false
	for code: Key in [KEY_F,KEY_I,KEY_J,KEY_D,KEY_SPACE,KEY_E]:
		var event := InputEventKey.new()
		event.keycode=code
		event.pressed=false
		Input.parse_input_event(event)
	await super.after_each()

func test_default_boss_has_three_self_owned_water_moves_and_no_level_machine() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	check(lab.pump_court==null and e.court==null,"boss encounter has no level pump dependency")
	for move: String in EnemyLabWardenWater.KEYS: check(e.profile.moves.has(move),"water ability available without apparatus")
	eq(lab.hud.move_menu.item_count,7,"three water abilities and three pole auxiliaries")
	e.begin_attack("warden_barrage")
	await physics_frames(100)
	eq(e.water.total_shots,3,"one cast emits a finite three-bullet wave")
	eq(e.hit_count,0,"ranged pose does not add invisible body damage")

func test_water_shot_aim_does_not_follow_late_movement() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.begin_attack("warden_barrage")
	var aim: Vector2=e.water.aim
	lab.player.position=Vector2(1050,520)
	await physics_frames(63)
	eq(e.water.aim,aim,"committed aim is fixed")
	check(not e.water.shots.is_empty(),"committed shot was emitted")
	if e.water.shots.is_empty(): return
	var shot: EnemyLabWardenShot=e.water.shots[0].get_ref() as EnemyLabWardenShot
	check(shot!=null and shot.velocity.x<0.0,"bullet travels to prior target without homing")

func test_vortex_is_single_visible_moving_projectile() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.begin_attack("warden_vortex")
	await physics_frames(70)
	eq(e.water.total_shots,1,"one pole turn creates one vortex")
	check(not e.water.shots.is_empty(),"committed shot was emitted")
	if e.water.shots.is_empty(): return
	var shot: EnemyLabWardenShot=e.water.shots[0].get_ref() as EnemyLabWardenShot
	check(shot.kind=="vortex" and shot.sprite.texture!=null,"vortex has independent authored silhouette")
	var x: float=shot.position.x
	await physics_frames(8)
	check(shot.position.x<x,"vortex advances physically")

func test_waterstep_is_visible_finite_and_no_contact_damage_while_washing() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	lab.player.position=Vector2(800,520)
	e.begin_attack("warden_waterstep")
	await physics_frames(42)
	check(e.state=="wash" and not e.can_receive_hit(),"only dissolving movement is untargetable")
	var goal: Vector2=e.water.wash_goal
	lab.player.position=Vector2(1100,520)
	for i: int in 24:
		var before: Vector2=e.position
		await physics_frames(1)
		check(e.position.distance_to(before)<20.0,"water trail traverses space without teleporting")
	eq(e.water.wash_goal,goal,"late player movement cannot drag reform point")
	check(e.state=="reform" and e.can_receive_hit(),"visible reform opens damage again before attack")
	eq(lab.player.health,5,"wash itself has no hidden contact attack")

func test_back_pressure_sac_hits_interrupt_charge_without_valve() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	lab.player.position=Vector2(e.position.x-180,520)
	e.begin_attack("warden_barrage")
	e.timer=0.55
	lab.player.position=Vector2(e.position.x+100,520)
	e.take_hit(1)
	e.take_hit(1)
	check(e.water.overloads==1 and e.state=="recover","two rear hits unload the caster's own sac")
	eq(e.health,16,"weakness keeps actual damage")
	await physics_frames(40)
	eq(e.water.total_shots,0,"canceled cast cannot leak queued bullets")

func test_caster_defeat_and_r_remove_all_water_threats() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.begin_attack("warden_barrage")
	await physics_frames(65)
	e.take_hit(100)
	eq(tree.get_nodes_in_group("enemy_lab_warden_water").size(),0,"defeat clears emitted water immediately")
	lab.reset_round()
	await physics_frames(12)
	eq((lab.enemies[0] as EnemyLabWarden).water.total_shots,0,"new owner has no old sequence")

func test_close_pressure_uses_waterstep_but_respects_lethal_burst() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.auto_attack=true
	lab.player.position=e.position
	e.take_hit(1)
	e.take_hit(1)
	check(e.move_key=="warden_waterstep" and e.state=="tell","two central hits trigger visible water escape")
	eq(e.health,16,"response does not erase combo damage")
	e.take_hit(100)
	eq(e.state,"ended","lethal burst still wins before dissolution")

func test_level_pump_is_only_created_when_explicitly_selected() -> void:
	var lab := await fixture()
	lab.select_terrain(4)
	await physics_frames(12)
	check(lab.pump_court!=null,"old interaction remains an explicit level sample")
	lab.select_terrain(3)
	await physics_frames(12)
	check(lab.pump_court==null and lab.player.pump_drift==0.0,"returning to boss sample removes level interaction")

func test_vortex_turns_toward_new_player_side_and_remains_grounded() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.begin_attack("warden_vortex")
	await physics_frames(66)
	var shot: EnemyLabWardenShot=e.water.shots[0].get_ref() as EnemyLabWardenShot
	check(shot.velocity.x<0.0,"starts toward original player side")
	var height: float=shot.position.y
	lab.player.position=Vector2(1050,330)
	await physics_frames(25)
	check(shot.velocity.x>0.0,"pursuit can reverse after player changes sides")
	eq(shot.position.y,height,"vortex does not follow player into air")
	check(shot.sprite.texture.get_height()*shot.sprite.scale.y>120.0,"vortex presentation is larger than original sample")

func test_all_water_preparations_share_rear_sac_interrupt() -> void:
	var lab := await fixture()
	for move: String in EnemyLabWardenWater.KEYS:
		lab.reset_round()
		await physics_frames(14)
		var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
		lab.player.position=Vector2(e.position.x-150,520)
		e.begin_attack(move)
		e.timer=float(e.spec.tell)*0.55
		e.visual.present(e)
		check(e.hurt_rect().has_point(e.position+Vector2(40,-48)),"highlighted sac is actually hittable")
		check(float((e.visual.material as ShaderMaterial).get_shader_parameter("weak_glow"))>0.0,"yellow cue shares actual weak window")
		lab.player.position=Vector2(e.position.x+100,520)
		e.take_hit(1)
		e.take_hit(1)
		check(e.water.overloads==1 and e.state=="recover","rear hits cancel "+move)
		eq(float((e.visual.material as ShaderMaterial).get_shader_parameter("weak_glow")),0.0,"interrupt immediately clears cue")
		eq(e.water.total_shots,0,"cancel before release has no hidden threat")

func test_reactive_waterstep_prepares_toward_actual_attacker() -> void:
	var lab := await fixture()
	var e: EnemyLabWarden=lab.enemies[0] as EnemyLabWarden
	e.auto_attack=true
	e.facing=-1.0
	lab.player.position=Vector2(e.position.x+60,520)
	e.take_hit(1)
	e.take_hit(1)
	check(e.move_key=="warden_waterstep" and e.facing>0.0,"reactive preparation faces its attacker before locking direction")
