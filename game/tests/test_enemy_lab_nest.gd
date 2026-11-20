extends TestSuite
## 巢卵与潜地的时序、所有权和原协议边界，单招夹具不冒充自然通关。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=4
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	return lab

func test_burrow_locks_destination_and_moves_without_teleport() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	lab.player.position=Vector2(450,520)
	e.begin_attack("eel_burrow")
	await physics_frames(51)
	check(e.state=="dive" and not e.can_receive_hit(),"only actual underground phase is untargetable")
	var destination: float=e.nest.target_root
	lab.player.position=Vector2(1100,520)
	var tunnel_seen: bool=false
	for i: int in 130:
		var before: float=e.position.x
		await physics_frames(1)
		if e.state=="tunnel": tunnel_seen=true
		check(absf(e.position.x-before)<20.0,"tunnel advances continuously through world space")
	eq(e.nest.target_root,destination,"late movement does not retarget buried ambush")
	check(tunnel_seen and e.state in ["active","recover","idle"],"finite tunnel gives warning and resumes combat")
	check(e.can_receive_hit(),"visible surfaced body is damageable again")

func test_burrow_at_boundary_never_chooses_outside_or_pins_player() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	lab.player.position=Vector2(65,520)
	e.begin_attack("eel_burrow")
	await physics_frames(51)
	check(e.nest.target_root>=155.0 and e.nest.target_root<=1125.0,"fallback preserves whole body in arena")
	lab.player.position=Vector2(e.nest.target_root,520)
	for i: int in 160:
		await physics_frames(1)
		if e.state=="emerge": break
	check(e.state=="emerge" and e.collision_layer==0,"emerging into player does not create solid trap")
	eq(lab.player.health,5,"warning is not an invisible attack")

func test_brood_sends_three_fixed_eggs_and_caps_ownership() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.begin_attack("eel_brood")
	lab.player.position=Vector2(1150,520)
	await physics_frames(93)
	eq(e.nest.eggs_spawned,3,"one throat sequence releases exactly three sacs")
	eq(e.nest.live_eggs,3,"three independent visible threats")
	var old: int=e.nest.eggs_spawned
	e.nest._spit(0)
	eq(e.nest.eggs_spawned,old,"forced extra spawn cannot exceed cap")
	eq(e.nest.locked_x,420.0,"brood does not aim at late player movement")
	check(e.nest.stage=="spit","no body damage is attached to egg emission")

func test_egg_is_one_hit_target_and_expiration_damages_only_once() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.nest.locked_x=500
	e.nest._spit(1)
	var egg: EnemyLabNestEgg=e.nest.eggs[0].get_ref() as EnemyLabNestEgg
	egg.landed=true
	egg.global_position=Vector2(500,506)
	lab.player.position=Vector2(500,520)
	await physics_frames(80)
	eq(e.nest.eggs_burst,1,"finite fuse produces one burst")
	eq(e.nest.egg_hits,1,"one egg cannot repeatedly damage")
	eq(lab.player.health,4,"visible sac eventually threatens health")
	await physics_frames(25)
	check(not is_instance_valid(egg) and e.nest.live_eggs==0,"burst artwork and threat both clean up")

func test_destroyed_egg_cannot_burst_and_uses_target_group() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.nest.locked_x=500
	e.nest._spit(1)
	var egg: EnemyLabNestEgg=e.nest.eggs[0].get_ref() as EnemyLabNestEgg
	check(egg.is_in_group("tide_targets"),"player's existing attacks can select egg")
	egg.take_hit(1)
	check(not egg.can_receive_hit(),"one hit destroys it immediately")
	await physics_frames(100)
	eq(e.nest.eggs_broken,1,"destruction counted once")
	eq(e.nest.eggs_burst,0,"cleared lane cannot explode later")

func test_guarded_first_bite_cancels_second_bite() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.position=Vector2(800,520)
	lab.player.position=Vector2(620,520)
	lab.player.facing=1.0
	var event := InputEventKey.new()
	event.keycode=KEY_I
	event.pressed=true
	Input.parse_input_event(event)
	await physics_frames(11)
	e.begin_attack("eel_brood")
	e.nest.stage="bites"
	e.set_state("active")
	await physics_frames(10)
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	check(e.parry_count==1 and e.state=="recover","front guard breaks actual first bite")
	await physics_frames(25)
	check(e.state=="recover" and e.nest.bites==0,"old second bite cannot resume after interruption")

func test_owner_defeat_and_round_reset_remove_eggs() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.begin_attack("eel_brood")
	await physics_frames(93)
	e.take_hit(100)
	eq(tree.get_nodes_in_group("enemy_lab_nest_eggs").size(),0,"defeat immediately removes all remaining threats")
	lab.reset_round()
	await physics_frames(12)
	e=lab.enemies[0] as EnemyLabEel
	eq(e.nest.eggs_spawned,0,"fresh round has no old brood queue")
	eq(tree.get_nodes_in_group("enemy_lab_nest_eggs").size(),0,"reset retains no old sac targets")

func test_timeline_distinguishes_tunnel_and_two_melee_windows() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.begin_attack("eel_brood")
	var segments: Array[Dictionary]=EnemyLabDebug.segments(e)
	eq(segments.size(),8,"full spit/link/two-coil plan is visible")
	eq(segments[4].pulse,2,"first melee cursor is separate from spitting")
	eq(segments[6].pulse,3,"second melee has distinct cursor")
	e.followup_cancelled=true
	eq(EnemyLabDebug.segments(e).size(),6,"guarded first bite removes canceled continuation")
	e.set_state("idle")
	e.begin_attack("eel_burrow")
	segments=EnemyLabDebug.segments(e)
	eq(segments[2].phase,"tunnel","underground is not mislabeled as damage")
	eq(segments[3].phase,"emerge","visible emergence warning has its own interval")

func test_pause_freezes_tunnel_and_egg_fuse_together() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.nest.locked_x=500
	e.nest._spit(1)
	var egg: EnemyLabNestEgg=e.nest.eggs[0].get_ref() as EnemyLabNestEgg
	egg.landed=true
	egg.global_position=Vector2(500,506)
	e.begin_attack("eel_burrow")
	await physics_frames(70)
	tree.paused=true
	var time: float=e.timer
	var position: Vector2=e.position
	var age: float=egg.age
	await physics_frames(20)
	eq(e.timer,time,"paused route timer is stable")
	eq(e.position,position,"paused soil ridge does not travel")
	eq(egg.age,age,"paused sac cannot silently count down")
	tree.paused=false

func after_each() -> void:
	tree.paused=false
	for code: Key in [KEY_I,KEY_J,KEY_SPACE,KEY_A,KEY_D]:
		var event := InputEventKey.new()
		event.keycode=code
		event.pressed=false
		Input.parse_input_event(event)
	await super.after_each()
