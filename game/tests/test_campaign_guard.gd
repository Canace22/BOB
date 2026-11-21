extends TestSuite
## 在正式主场景验证持续格挡，不以试验场通过代替主线接入。
func fixture() -> WhalebellyMain:
	var host: WhalebellyMain=preload("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(preload("res://tests/whalebelly/doorway_test_host.gd"))
	host.set("suite","campaign-guard")
	host.qa=true
	host.qa_full_abilities=true
	host.integration_external_test=true
	add(host)
	await physics_frames(40)
	host.player.controls_enabled=true
	return host
func key(down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=KEY_I
	event.physical_keycode=KEY_I
	event.pressed=down
	Input.parse_input_event(event)
func after_each() -> void:
	key(false)
	await super.after_each()
func test_mainline_held_guard_blocks_after_one_second() -> void:
	var host := await fixture()
	var p: WhalebellyCampaignPlayer=host.player
	key(true)
	await physics_frames(80)
	check(not p.take_damage(1,p.global_position+Vector2(p.facing*80,0)),"formal mainline holds front guard beyond old short window")
	check(p.skill_controller.get("guard_meter")!=null,"formal skill controller owns stance meter")

class CounterTarget extends Node2D:
	var damage: int=0
	func is_campaign_enemy() -> bool: return true
	func can_receive_hit() -> bool: return true
	func take_hit(amount: int) -> void: damage+=amount
	func hurt_rect() -> Rect2: return Rect2(global_position-Vector2(20,60),Vector2(40,60))

func test_mainline_perfect_guard_cancels_to_skill_and_rewards_one_hit() -> void:
	var host := await fixture()
	var p: WhalebellyCampaignPlayer=host.player
	key(true)
	await physics_frames(11)
	var guard := p.skill_controller as TideCombatGuardSkills
	check(guard!=null,"mainline owns shared guard controller")
	if guard==null: return
	check(not p.take_damage(1,p.global_position+Vector2(p.facing*80,0)),"timed front hit is blocked")
	check(guard.perfect and guard.counter_bonus==2,"perfect guard grants enhanced reward")
	key(false)
	check(p.request_action("wb_draw"),"successful guard immediately cancels into sword skill")
	var target := CounterTarget.new()
	add(target)
	p._hit(target,3,false)
	eq(target.damage,5,"real mainline hit receives counter bonus")
	p.hit_targets.clear()
	p._hit(target,3,false)
	eq(target.damage,8,"reward is consumed exactly once")

func test_mainline_guard_break_recovers_only_after_release_and_rejects_rear() -> void:
	var host := await fixture()
	var p: WhalebellyCampaignPlayer=host.player
	key(true)
	await physics_frames(80)
	var guard := p.skill_controller as TideCombatGuardSkills
	if guard==null:
		check(false,"mainline owns stance controller")
		return
	guard.guard_meter=1.0
	check(p.take_damage(1,p.global_position+Vector2(p.facing*80,0)),"breaking hit deals real damage")
	check(guard.guard_lock>0.0 and guard.counter_bonus==0,"break locks guard and clears counter")
	await physics_frames(90)
	check(guard.guard_meter<=0.1,"holding cannot refill empty stance")
	key(false)
	await physics_frames(150)
	check(guard.guard_meter>25.0,"releasing recovers stance")
	p.invulnerable=0.0
	check(p.request_action("parry"),"recovered stance can defend again")
	await physics_frames(5)
	check(p.take_damage(1,p.global_position-Vector2(p.facing*80,0)),"rear attack bypasses front guard")

func test_mainline_boss_one_attack_cannot_charge_guard_every_frame() -> void:
	var host := await fixture()
	host.load_room(3)
	await physics_frames(10)
	var p: WhalebellyCampaignPlayer=host.player
	var boss: CampaignCrabBoss=host.enemies[0].actor
	boss.running=false
	boss.kind="sweep"
	boss.facing=1.0
	boss.change("active")
	boss.hit_sent=false
	p.set_physics_process(false)
	p.global_position=boss.attack_rect().get_center()+Vector2(0,32)
	p.facing=signf(boss.global_position.x-p.global_position.x)
	var guard := p.skill_controller as TideCombatGuardSkills
	check(p.request_action("parry"),"guard starts at actual boss contact")
	p.state_time=0.1
	guard.guard_age=0.5
	boss._contact()
	var count: int=guard.guard_count
	boss._contact()
	eq(count,1,"actual boss attack is guarded")
	eq(guard.guard_count,count,"same attack has only one guard settlement")
