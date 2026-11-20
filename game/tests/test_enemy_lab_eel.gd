extends TestSuite
## 单实体合同、两端判定和固定反击预算；自然路线另用原生按键专项。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=4
	lab.auto_attack=false
	add(lab)
	await physics_frames(14)
	return lab

func test_catalog_menu_and_sheet_expose_four_distinct_actions() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	check(e!=null,"stable eel ID selects its executor")
	eq(lab.hud.enemy_menu.item_count,EnemyLabCatalog.PROFILES.size(),"eel remains in expanded catalog")
	eq(lab.hud.move_menu.item_count,5,"four actual actions are exposed")
	check(e.visual.texture.resource_path.contains("enemy-lab-eel-v1"),"own long-body sheet loaded")
	eq(e.visual.metadata.nest_eel.regions.size(),12,"all authored key poses present")

func test_head_and_tail_have_separate_one_sided_hitboxes() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.begin_attack("eel_bite")
	var head: Rect2=e.attack_rect()
	check(head.end.x<e.position.x,"left-facing jaw stays on head side")
	e.set_state("idle")
	e.begin_attack("eel_tail")
	var tail: Rect2=e.attack_rect()
	check(tail.position.x>e.position.x,"tail stays opposite jaw")
	check(not head.intersects(tail),"one action cannot damage both ends")
	eq(tail.size.y,34.0,"sweep remains a low jumpable strike")

func test_late_player_crossing_does_not_swap_head_and_tail() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	var direction: float=e.facing
	lab.player.position=Vector2(1160,520)
	e.begin_attack("eel_bite")
	await physics_frames(35)
	eq(e.facing,direction,"body identity fixed despite player switching sides")
	check(e.attack_rect().get_center().x<e.position.x,"committed jaw does not teleport to tail")

func test_one_real_swing_hits_long_body_only_once() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	lab.player.position=Vector2(e.position.x-200,520)
	lab.player.facing=1.0
	var event := InputEventKey.new()
	event.keycode=KEY_J
	event.pressed=true
	Input.parse_input_event(event)
	await physics_frames(14)
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	eq(e.reactions.received,1,"whole body is one target for actual J")
	eq(e.health,e.maximum-1,"one blade cannot multiply damage by body length")

func test_hits_cannot_refresh_opening_or_launch_entire_body() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.spec=EnemyLabCatalog.action("eel_bite")
	e.set_state("recover")
	e.take_hit(1)
	e.launch(500)
	eq(e.velocity.y,0.0,"long body cannot be launched")
	for i: int in 12:
		e.take_hit(1)
		await physics_frames(8)
	check(e.health>0 and e.state=="idle","short combo budget ends even under repeated hits")
	check(not e.control_window_open(),"idle preparation cannot be endlessly re-stunned")

func test_tail_choice_requires_dwell_and_never_reads_player_buttons() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	lab.player.position=Vector2(e.position.x+200,520)
	e.attack_serial=2
	eq(e.choose_move(),"eel_bite","brief pass does not cause immediate sweep")
	await physics_frames(26)
	eq(e.choose_move(),"eel_tail","lingering at tail selects sweep")

func test_defeat_stops_both_ends_and_round_cleans_owner() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.begin_attack("eel_tail")
	e.take_hit(100)
	eq(e.outcome,"kill","eel has its own narrative defeat contract")
	check(not e.data.alive and not e.can_begin_attack(),"dead body has no queued attack")
	lab.reset_round()
	await physics_frames(8)
	check(not is_instance_valid(e),"R removes whole old eel")
	eq(lab.enemies[0].health,18,"new round owns one fresh health pool")

func test_middle_pressure_gets_short_combo_then_committed_reposition() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	e.auto_attack=true
	lab.player.position=e.position
	e.take_hit(1)
	eq(e.center_repositions,0,"first central hit keeps its damage opportunity")
	e.take_hit(1)
	eq(e.center_repositions,1,"second central hit initiates physical reposition")
	check(e.move_key=="eel_burrow" and e.state=="tell","response starts with visible preparation")
	eq(e.health,16,"central damage is fully retained")
	e.timer=0.2
	e.take_hit(1)
	eq(e.timer,0.2,"later hits cannot restart the burrow warning")
	eq(e.health,15,"preparation is not damage immunity")
	e.take_hit(100)
	eq(e.state,"ended","lethal damage wins over queued response")

func test_wrong_side_uses_burrow_instead_of_spitting_backwards() -> void:
	var lab := await fixture()
	var e: EnemyLabEel=lab.enemies[0] as EnemyLabEel
	lab.player.position=Vector2(e.position.x+200,520)
	eq(e.choose_move(),"eel_burrow","behind head must reposition before ranged attack")
	e.tail_dwell=0.4
	eq(e.choose_move(),"eel_tail","established tail position retains its own response")
