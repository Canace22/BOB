extends TestSuite
## 捕食者的真实物理落地、受控与回挂；站位夹具不代替自然AI验收。
func fixture() -> EnemyLab:
	var lab: EnemyLab=preload("res://content/prototypes/enemy_lab/main.tscn").instantiate()
	lab.profile_index=3
	lab.terrain=2
	lab.auto_attack=false
	add(lab)
	await physics_frames(12)
	return lab
func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func after_each() -> void:
	tree.paused=false
	for code: Key in [KEY_I,KEY_J,KEY_A,KEY_D,KEY_S,KEY_L,KEY_SPACE]: key(code,false)
	await super.after_each()

func test_repeated_real_basic_attacks_allow_counter_combo_but_not_permanent_lock() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.position=Vector2(600,520)
	e.spec=EnemyLabCatalog.action("hunter_pounce")
	e.move_key="hunter_pounce"
	e.set_state("recover")
	lab.player.position=Vector2(510,520)
	lab.player.facing=1.0
	var escaped: bool=false
	for i: int in 12:
		key(KEY_J,true)
		await physics_frames(6)
		key(KEY_J,false)
		for j: int in 14:
			if e.state in ["escape_tell","evade"]: escaped=true
			await physics_frames(1)
	check(e.reactions.received>=2,"landing still gives a real short combo")
	check(escaped and e.health>0,"ordinary repeated attacks cannot hold predator until death")

func test_escape_windup_resists_control_but_still_takes_full_damage() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.spec=EnemyLabCatalog.action("hunter_pounce")
	e.position=Vector2(600,520)
	e.set_state("recover")
	for i: int in 3: e.take_hit(1)
	eq(e.state,"escape_tell","three actual hits start visible preparation")
	eq(e.health,e.maximum-3,"first combo damage preserved")
	e.timer=0.20
	e.take_hit(1)
	e.launch(500)
	e.pin(0.5)
	eq(e.state,"escape_tell","late stun cannot cancel escape preparation")
	eq(e.timer,0.20,"late hit cannot restart preparation")
	eq(e.health,e.maximum-4,"escape protection is not damage immunity")
	eq(float((e.visual.material as ShaderMaterial).get_shader_parameter("danger")),0.0,"nonattacking escape never signals unblockable damage")

func test_escape_has_no_body_damage_and_pressure_resets_after_regrip() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.spec=EnemyLabCatalog.action("hunter_pounce")
	e.position=Vector2(600,520)
	e.set_state("recover")
	for i: int in 3: e.take_hit(1)
	await physics_frames(220)
	eq(e.hit_count,0,"escape body itself has no contact attack")
	eq(lab.player.health,5-e.water_hits,"damage comes only from the visible projectile")
	eq(e.state,"idle","jet ends by physically regripping a perch")
	eq(e.pressure_hits,0,"new attack cycle receives a fresh combo opportunity")
	check(not e.escape_return,"escape control resistance is not permanent")
	e.position=Vector2(600,520)
	e.set_state("recover")
	e.take_hit(1)
	eq(e.state,"hurt","new grounded opening accepts control again")

func test_lethal_burst_wins_even_during_escape_windup() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.spec=EnemyLabCatalog.action("hunter_pounce")
	e.position=Vector2(600,520)
	e.set_state("recover")
	for i: int in 3: e.take_hit(1)
	e.take_hit(20)
	eq(e.health,0,"sufficient burst retains lethal damage")
	eq(e.state,"ended","defeat has priority over escape")
	await physics_frames(50)
	eq(e.state,"ended","defeated enemy does not resume queued jet")

func test_escape_water_is_single_shot_and_uses_real_guard() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.position=Vector2(600,520)
	e.spec=EnemyLabCatalog.action("hunter_pounce")
	e.set_state("recover")
	lab.player.position=Vector2(510,520)
	lab.player.facing=1.0
	key(KEY_I,true)
	await physics_frames(11)
	for i: int in 3: e.take_hit(1)
	await physics_frames(65)
	eq(e.water_shots,1,"escape emits only one visible projectile")
	eq(e.water_blocks,1,"held front guard blocks the projectile through normal damage protocol")
	eq(lab.player.health,5,"guarded projectile deals no health damage")
	await physics_frames(30)
	eq(e.water_shots,1,"return cannot emit a second projectile")

func test_escape_water_aim_locks_and_round_reset_removes_it() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	e.position=Vector2(600,520)
	e.spec=EnemyLabCatalog.action("hunter_pounce")
	e.set_state("recover")
	lab.player.position=Vector2(510,520)
	for i: int in 3: e.take_hit(1)
	lab.player.position=Vector2(820,520)
	await physics_frames(28)
	var orbs: Array[Node]=tree.get_nodes_in_group("tide_hostile_projectiles")
	eq(orbs.size(),1,"shot exists independently of moving caster")
	if orbs.is_empty(): return
	var orb: EnemyLabWaterOrb=orbs[0] as EnemyLabWaterOrb
	check(orb.velocity.x<0.0 and e.velocity.x>0.0,"locked shot goes toward prior target while caster jets away")
	var velocity: Vector2=orb.velocity
	lab.player.position=Vector2(400,300)
	await physics_frames(3)
	eq(orb.velocity,velocity,"projectile never homes after launch")
	lab.reset_round()
	await physics_frames(6)
	check(not is_instance_valid(orb),"R removes old round water projectile")
	eq(tree.get_nodes_in_group("tide_hostile_projectiles").size(),0,"fresh round has no stale water threat")

func test_water_swept_collision_blocks_tunneling_and_walls_end_shot() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	lab.player.position=Vector2(500,520)
	var orb := EnemyLabWaterOrb.new()
	orb.source=weakref(e)
	orb.player=lab.player
	orb.velocity=Vector2(-12000,0)
	lab.world.add_child(orb)
	orb.position=Vector2(600,485)
	await physics_frames(3)
	eq(lab.player.health,4,"fast water segment cannot tunnel through target")
	eq(e.water_hits,1,"one shot deals damage once")
	orb=EnemyLabWaterOrb.new()
	orb.source=weakref(e)
	orb.player=lab.player
	orb.velocity=Vector2(600,0)
	lab.world.add_child(orb)
	orb.position=Vector2(1260,485)
	await physics_frames(6)
	check(not is_instance_valid(orb),"stage wall consumes water projectile")

func test_owner_defeat_clears_already_emitted_water() -> void:
	var lab := await fixture()
	var e: EnemyLabPredator=lab.enemies[0] as EnemyLabPredator
	var orb := EnemyLabWaterOrb.new()
	orb.source=weakref(e)
	orb.player=lab.player
	orb.velocity=Vector2(100,0)
	lab.world.add_child(orb)
	orb.position=Vector2(900,400)
	e.take_hit(20)
	await physics_frames(3)
	check(not is_instance_valid(orb),"defeated source cannot leave an old hostile shot")
