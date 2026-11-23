extends TestSuite
## 挑战配置边界、有限连段与真实反制；不拿参数存在性替代正常交战采样。
func fixture(index: int=2, challenge: bool=true) -> ChapterPressureArena:
	var arena:=ChapterPressureArena.new(index,challenge)
	add(arena)
	await physics_frames(8)
	arena.enemy.set_physics_process(false)
	arena.player.set_physics_process(false)
	arena.enemy.auto_attack=true
	arena.player.position=arena.enemy.position-Vector2(90,0)
	arena.player.facing=1.0
	return arena

func after_each() -> void:
	# TestSuite稍后统一queue_free；先在角色仍在树内时收回输入、反馈与弹体。
	for node: Node in _nodes:
		if node is ChapterPressureArena: node.shutdown()
	await super.after_each()

func test_default_trial_is_not_silently_upgraded() -> void:
	var arena:=await fixture(2,false)
	check(not arena.enemy.pressure.enabled(),"default enemy lab has no chapter pressure")
	eq(arena.enemy.maximum,12,"original catalog health remains intact")
	eq(arena.enemy.action_spec("shell_push"),EnemyLabCatalog.action("shell_push"),"original timings are unchanged")
	eq(arena.player.melee_damage,1,"actual chapter player basic damage stays one")

func test_two_move_chain_has_a_full_terminal_opening() -> void:
	var arena:=await fixture()
	var e: EnemyLabEnemy=arena.enemy
	check(e.begin_attack("poke"),"first attack begins")
	for expected: String in ["shell_push"]:
		e.set_state("active")
		e.set_state("recover")
		eq(e.pressure.queued,expected,"next move is bounded and explicit")
		check(is_equal_approx(float(e.spec.recover),0.22),"link has a visible short recovery")
		e.set_state("idle")
		check(e.begin_attack(),"queued move begins through normal attack executor")
	e.set_state("active")
	e.set_state("recover")
	eq(e.pressure.queued,"","two moves finish before another full opening")
	check(float(e.spec.recover)>=1.05,"terminal opening allows approach and two swings")

func test_chapter_bosses_have_bounded_endurance_and_readable_openings() -> void:
	for index: int in range(1,8):
		var base: Dictionary=EnemyLabCatalog.profile(index)
		var chapter: Dictionary=ChapterCombatPressure.apply(base)
		check(int(chapter.hp)<=int(base.hp)*2,"chapter endurance stays within twice trial HP: "+str(base.id))
		check(int(chapter.chapter_pressure.links)<=1,"at most one extra linked move: "+str(base.id))
		var pressure:=ChapterCombatPressure.new()
		pressure.settings=chapter.chapter_pressure
		for move: String in base.moves:
			var action: Dictionary=pressure.action(move)
			check(float(action.recover)>=1.05,"natural recovery leaves time to retaliate: "+move)

func test_hitting_link_cancels_next_move_without_invulnerability() -> void:
	var arena:=await fixture()
	var e: EnemyLabEnemy=arena.enemy
	e.begin_attack("poke")
	e.set_state("active")
	e.set_state("recover")
	var health: int=e.health
	e.take_hit(1)
	eq(e.health,health-1,"link interruption still deals full damage")
	eq(e.pressure.queued,"","hit actually removes next move")
	var budget: float=e.pressure.recovery_left
	e.pressure.tick(0.10)
	e.take_hit(1)
	check(e.pressure.recovery_left<budget,"repeated hits do not restart exposure budget")
	check(e.can_receive_hit(),"finite stagger recovery never grants damage immunity")

func test_shell_chip_and_exposed_hits_use_the_new_health_budget() -> void:
	var arena:=await fixture()
	var e: EnemyLabEnemy=arena.enemy
	# 正面护壳仍累计半点；进入收招后每刀完整扣血，不用减甲伪装血量调整。
	e.facing=-1.0
	var initial: int=e.health
	e.take_hit(1)
	eq(e.health,initial,"first front hit keeps the fractional shell damage")
	e.take_hit(1)
	eq(e.health,initial-1,"second front hit completes one point of damage")
	e.spec=e.action_spec("poke")
	e.set_state("recover")
	e.take_hit(1)
	eq(e.health,initial-2,"recovery accepts a full basic hit")
	for i: int in initial-2: e.take_hit(1)
	eq(e.health,0,"bounded full hits exhaust the chapter health budget")
	eq(e.outcome,"surrender","reduced endurance still uses the nonlethal ending")

func test_perfect_guard_stops_elder_second_grip_and_keeps_mimic_executor() -> void:
	var arena:=await fixture(7)
	var e: EnemyLabElder=arena.enemy as EnemyLabElder
	check(e.begin_attack("elder_grip"),"elder starts actual grip")
	e.set_state("active")
	e.guard_reaction(true)
	eq(e.state,"recover","perfect guard ends grip before second pulse")
	check(e.followup_cancelled and e.pressure.queued.is_empty(),"both intrinsic and queued followups stop")
	check(e.opening_left>=1.55,"perfect guard keeps full earned opening")
	check(e.mimic!=null and e.mimic.view!=null and e.mimic.repertoire!=null,"complete repertoire and phantom are still owned by original executor")

func test_yellow_rear_weakpoint_keeps_its_interrupt_and_long_opening() -> void:
	var arena:=await fixture(5)
	var e: EnemyLabWarden=arena.enemy as EnemyLabWarden
	e.begin_attack("warden_barrage")
	e.timer=float(e.spec.tell)*0.75
	arena.player.position=e.position+Vector2(-e.facing*60.0,0)
	e.take_hit(1)
	e.take_hit(1)
	eq(e.water.overloads,1,"two actual rear hits overload yellow weakpoint")
	eq(e.state,"recover","weakpoint aborts water casting")
	check(e.followup_cancelled and e.pressure.queued.is_empty(),"overload does not queue a hidden thrust")
	check(e.opening_left>=1.45,"earned rear opening stays intact")

func test_red_warning_and_nonlethal_outcomes_survive_pressure_profile() -> void:
	var arena:=await fixture(1)
	var e: EnemyLabEnemy=arena.enemy
	e.begin_attack("flip")
	e.visual.update_warning(e)
	check(float((e.visual.material as ShaderMaterial).get_shader_parameter("danger"))>0.0,"unblockable keeps red bitmap tell")
	check(e.phase_duration()>=0.68,"red preparation keeps reaction time")
	for index: int in [1,2,4,5,6,7]:
		var p: Dictionary=ChapterCombatPressure.apply(EnemyLabCatalog.profile(index))
		eq(p.ending,EnemyLabCatalog.profile(index).ending,"chapter upgrade cannot rewrite narrative ending")

func test_seventh_chapter_goal_still_completes_without_killing_warden() -> void:
	var run: ChapterRun=preload("res://content/prototypes/chapters/main.tscn").instantiate()
	run.chapter_id=7
	run.save_enabled=false
	run.restore_progress=false
	add(run)
	await physics_frames(4)
	for i: int in run.data.stages.size():
		if str(run.data.stages[i].kind)=="escape": run.flow.index=i
	run.flow.enter()
	var stage: Dictionary=run.flow.stage()
	run.encounter.spawn(false)
	run.encounter.started=true
	run.encounter.warning=0.0
	run.encounter.time=float(stage.get("min_seconds",3.0))
	var e: EnemyLabEnemy=run.encounter.enemy
	e.set_physics_process(false)
	run.set_process(false)
	run.player.position=run.point(stage.goal)
	await physics_frames(3)
	run.flow.tick(0.01)
	check(str(stage.id) in run.completed,"arrival and pressure time complete escape")
	check(e.health>0 and e.data.alive,"warden is stopped alive, not killed")
	check(str(run.flow.stage().kind)=="dialogue","escape continues into elder ceasefire dialogue")
