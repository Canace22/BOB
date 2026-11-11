extends TestSuite
## Campaign fixtures exercise the real adapter, target dispatch, save flags and collision rules.

func campaign() -> WhalebellyMain:
	var host: WhalebellyMain = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	add(host)
	host.load_room(3)
	host.set_process(false)
	host.set_physics_process(false)
	host.player.set_physics_process(false)
	host.enemies[0].actor.set_physics_process(false)
	return host

func test_real_mother_crab_replaces_only_the_boss() -> void:
	var host := campaign()
	var crab: CampaignCrabBoss = host.enemies[0].actor
	eq(crab.data.key,"R1-04:0","existing stable save ID preserved")
	eq(crab.data.max_hp,180,"first campaign boss health budget")
	eq(tree.get_nodes_in_group("tide_targets").filter(func(n: Node) -> bool: return n is CampaignCrabTarget).size(),1,"one live mother crab target")
	check(not host.scenery.get_node("World/EnemyArt0").visible,"old cutout hidden")
	check(crab.visual.texture != null,"real atlas loaded")
	check(not host.abilities.dash,"boss does not grant an ability on spawn")
	host.load_room(1)
	check(host.enemies[0].actor is CampaignCorpseCrab,"ordinary crab has its own adapter, not the boss")

func test_shell_exposure_counter_and_projectile_dispatch() -> void:
	var host := campaign()
	var crab: CampaignCrabBoss = host.enemies[0].actor
	crab.running = true
	crab.change("observe")
	host.player.soul = 0
	host.player._hit(crab.receiver,1,true)
	eq(crab.data.hp,175,"armored short hit deals five damage")
	eq(host.player.soul,11,"current short-hit resource rule is unchanged")
	eq(crab.hurtbox.last_result,"shell","shell feedback")
	crab.kind = "slam"
	crab.change("tell")
	crab.timer = 0.8
	host.player.hit_targets.clear()
	host.player.state = "heavy"
	host.player._hit(crab.receiver,2,false)
	eq(crab.state,"stagger","actual heavy dispatch interrupts raised claw")
	eq(crab.hurtbox.last_result,"break","counter receives break feedback")
	eq(crab.data.hp,155,"counter bypasses armor")
	var orb := WhalebellyTideOrb.new()
	orb.caster = host.player
	orb.damage = 2
	orb.position = crab.global_position+Vector2(-170,-110)
	orb.direction = 1
	add(orb)
	orb.set_physics_process(false)
	orb._physics_process(0.1)
	eq(crab.data.hp,135,"ranged hit shares exposed damage rule")
	eq(crab.state,"stagger","ranged hit cannot add another interrupt")

func test_basic_melee_makes_progress_through_shell_and_can_finish() -> void:
	var host := campaign()
	var crab: CampaignCrabBoss = host.enemies[0].actor
	for guarded: String in ["observe","tell","active","phase"]:
		crab.change(guarded)
		crab.receive_attack(1,false,false,host.player.position)
		eq(crab.hurtbox.last_damage,5,"basic melee chips in " + guarded)
	crab.change("observe")
	crab.receive_attack(2,false,true,host.player.position)
	eq(crab.hurtbox.last_damage,5,"guarded projectile reduction is preserved")
	crab.receive_attack(2,true,false,host.player.position)
	eq(crab.hurtbox.last_damage,10,"guarded heavy reduction is preserved")
	crab.change("recover")
	crab.receive_attack(1,false,false,host.player.position)
	eq(crab.hurtbox.last_damage,10,"recovery still rewards timing with double damage")
	crab.change("observe")
	for i in 26: crab.receive_attack(1,false,false,host.player.position)
	check(crab.data.alive and crab.data.hp == 5,"shell damage reaches final hit without resetting HP")
	crab.receive_attack(1,false,false,host.player.position)
	check(not crab.data.alive and crab.state == "dead","final shell hit defeats boss")
	check(host.defeated.get("R1-04:0",false) and host.abilities.dash,"normal hit path grants victory")

func test_attack_bounds_jump_dodge_and_safe_corner_sequence() -> void:
	var host := campaign()
	var crab: CampaignCrabBoss = host.enemies[0].actor
	crab.kind = "sweep"
	crab.facing = -1
	var ground := Rect2(crab.position+Vector2(-230,-65),Vector2(28,65))
	check(crab.attack_rect().intersects(ground),"low sweep covers the front feet")
	check(not crab.attack_rect().intersects(Rect2(ground.position-Vector2(0,110),ground.size)),"jump clears low sweep")
	crab.kind = "slam"
	check(crab.attack_rect().intersects(Rect2(ground.position-Vector2(0,110),ground.size)),"slam demands retreat or counter")
	crab.facing = 1
	check(not crab.attack_rect().intersects(ground),"attack cannot hit behind shell")
	crab.phase = 2
	crab.target.position.x = 290
	crab.facing = -1
	crab.sequence = ["sweep","slam"]
	crab.sequence_index = 0
	crab.finish_active()
	eq(crab.kind,"second","corner removes unavoidable full-height finisher")
	eq(CampaignCrabMoves.phase_for_health(118,180),1,"phase one above threshold")
	eq(CampaignCrabMoves.phase_for_health(117,180),2,"65 percent phase threshold")
	eq(CampaignCrabMoves.phase_for_health(64,180),2,"phase two above threshold")
	eq(CampaignCrabMoves.phase_for_health(63,180),3,"35 percent phase threshold")

func test_defeat_opens_existing_gate_and_survives_room_reload() -> void:
	var host := campaign()
	var crab: CampaignCrabBoss = host.enemies[0].actor
	host.checkpoint = {"room":3,"pos":[80,645]}
	host.damage_enemy(crab.data,int(crab.data.max_hp))
	check(host.defeated.get("R1-04:0",false) and host.abilities.dash,"real campaign defeat owns reward")
	eq(crab.state,"dead","death animation starts")
	eq(crab.collision_layer,0,"dead shell no longer blocks the path")
	check(host.last_save_ok,"campaign V6 save accepted")
	host.load_progress()
	host.load_room(3)
	check(not host.enemies[0].alive and not host.enemies[0].has("actor"),"defeated mother crab stays removed")
	check(not host.scenery.get_node("World/EnemyArt0").visible,"old cutout also stays removed")
	check(host.abilities.dash,"earned dash survives reload")
