extends TestSuite

func campaign() -> WhalebellyMain:
	var host: WhalebellyMain = load("res://content/whalebelly/main.tscn").instantiate()
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	add(host)
	host.load_room(1)
	host.set_process(false)
	host.player.set_physics_process(false)
	for enemy: Dictionary in host.enemies: enemy.actor.set_physics_process(false)
	return host

func test_three_spawns_and_single_target_per_crab() -> void:
	var host := campaign()
	var crab: CampaignCorpseCrab = host.enemies[0].actor
	eq(crab.data.hp,3,"existing ordinary HP preserved")
	eq(crab.data.key,"R1-02:0","stable spawn ID preserved")
	check(crab.is_in_group("tide_targets"),"actor is sole damage receiver")
	check(not host.scenery.get_node("World/EnemyArt0").visible,"old static cutout hidden")
	check(crab.visual.texture != null,"authored atlas is active")
	host.load_room(2)
	eq(host.enemies.size(),2,"two authored tongue terrace encounters retained")
	for enemy: Dictionary in host.enemies: check(enemy.actor is CampaignCorpseCrab,"ordinary actor, not mother crab")

func test_low_sweep_front_back_jump_and_crossed_event() -> void:
	var host := campaign()
	var crab: CampaignCorpseCrab = host.enemies[0].actor
	for direction: float in [-1.0,1.0]:
		crab.facing = direction
		var front := Rect2(crab.position+Vector2(direction*75-14,-65),Vector2(28,65))
		check(crab.attack_rect().intersects(front),"front low sweep")
		check(not crab.attack_rect().intersects(Rect2(front.position-Vector2(0,80),front.size)),"jump clears low attack")
		check(not crab.attack_rect().intersects(Rect2(crab.position+Vector2(-direction*75-14,-65),front.size)),"no rear attack")
	crab.facing = -1
	host.player.position = crab.position+Vector2(-75,0)
	host.player.invulnerable = 0
	crab.change("tell")
	crab.advance_action(.95)
	eq(host.player.health,4,"a tick crossing tell and active still dispatches exactly once")
	eq(crab.state,"recover","large tick consumes phase remainder")
	host.player.invulnerable = 0
	crab.advance_action(.4)
	eq(host.player.health,4,"no repeated damage in recovery")

func test_real_player_hit_interrupts_and_deduplicates() -> void:
	var host := campaign()
	var crab: CampaignCorpseCrab = host.enemies[0].actor
	crab.change("tell")
	crab.timer = .68
	host.player.soul = 0
	host.player._hit(crab,1,true)
	eq(crab.state,"hurt","actual damage callback cancels raised claw")
	eq(crab.data.hp,2,"ordinary damage not boss scaled")
	eq(host.player.soul,11,"existing soul-on-hit kept")
	host.player._hit(crab,1,true)
	eq(crab.data.hp,2,"same player attack cannot hit twice")
	crab.advance_action(.3)
	eq(crab.state,"idle","hurt returns to decision state")
	check(crab.hit_sent,"old attack cannot release later")

func test_projectile_death_cleanup_and_room_respawn() -> void:
	var host := campaign()
	var crab: CampaignCorpseCrab = host.enemies[0].actor
	var orb := WhalebellyTideOrb.new()
	orb.caster = host.player
	orb.damage = 3
	orb.position = crab.global_position+Vector2(-75,-35)
	orb.direction = 1
	add(orb)
	orb.set_physics_process(false)
	orb._physics_process(.2)
	eq(crab.state,"dead","actual projectile dispatch starts death")
	check(not crab.can_receive_hit() and not crab.is_in_group("tide_targets"),"dead target removed")
	eq(crab.collision_layer,0,"dead body releases path immediately")
	check(not host.abilities.dash,"ordinary death grants no boss reward")
	check(not host.defeated.has("R1-02:0"),"does not add ordinary kills to persistent boss flags")
	crab.visual.present(crab)
	eq(crab.visual.action_id,"dead","real death atlas selected")
	host.load_room(1)
	eq(host.enemies[0].hp,3,"ordinary enemy respawns under existing room rule")

func test_distance_animation_and_direction_are_single_owned() -> void:
	var host := campaign()
	var crab: CampaignCorpseCrab = host.enemies[0].actor
	crab.moving = true
	crab.walk_distance = 12
	crab.facing = -1
	crab.visual.present(crab)
	eq(crab.visual.frame_index,2,"walk follows actual travel, not wall-clock")
	check(crab.visual.scale.x>0,"left master not flipped twice")
	crab.facing = 1
	crab.visual.present(crab)
	check(crab.visual.scale.x<0,"right is one visual-root flip")
	crab.moving = false
	crab.visual.present(crab)
	eq(crab.visual.action_id,"idle","blocked movement exits walk")
	crab.change("dead")
	crab.timer = .5
	crab.visual.present(crab)
	eq(crab.visual.frame_index,7,"final authored collapsed pose held")
