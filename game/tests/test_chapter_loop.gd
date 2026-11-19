extends TestSuite
## 非击杀遭遇的关键合同：真实伤害被保留，但撤退不写死亡，也不提供击杀出口。
class EnemyHost extends Node2D:
	var events: Array = []
	func damage_enemy(data: Dictionary, amount: int) -> void:
		data.hp=int(data.hp)-amount
		if int(data.hp)<=0: data.alive=false
	func record_event(id: String, data: Dictionary) -> void: events.append({"id":id,"data":data})

func test_attack_choices_have_distinct_geometry_and_counter_windows() -> void:
	var enemy := WhaleChapterForager.new()
	enemy.facing=1.0
	enemy.attack_kind="sweep"
	check(enemy.attack_rect().size.y<40.0,"sweep can be jumped")
	enemy.attack_kind="rush"
	check(enemy.attack_rect().size.y>70.0,"rush threatens standing body")
	check(float(enemy.PATTERNS.rush.recover)>1.0,"missed rush leaves punish window")
	enemy.free()

func test_double_attack_waits_for_second_strike_and_damage_interrupts() -> void:
	var host := EnemyHost.new()
	var enemy := WhaleChapterForager.new()
	enemy.host=host
	enemy.attack_kind="double"
	enemy.change("active")
	enemy.hit_sent=true
	enemy.advance_action(0.19)
	eq(enemy.state,"tell","first hit leads to second tell, not recovery")
	check(enemy.followup and not enemy.hit_sent,"second hit re-arms once")
	enemy.data={"alive":true}
	enemy.on_damaged()
	enemy.advance_action(0.24)
	eq(enemy.state,"idle","hurt cancels remaining followup")
	enemy.free()
	host.free()

func test_heavy_damage_causes_retreat_instead_of_kill() -> void:
	var host := EnemyHost.new()
	var enemy := WhaleChapterForager.new()
	enemy.host=host
	enemy.data={"key":"qa.forager","alive":true,"hp":8,"max_hp":8}
	enemy.awake=true
	enemy.take_hit(100)
	check(enemy.withdrawing,"large hit withdraws")
	check(enemy.data.alive and enemy.data.hp==1,"health clamps above death")
	check(not enemy.can_receive_hit(),"withdrawn target cannot be farmed")
	eq(host.events.size(),1,"one withdrawal event")
	enemy.take_hit(100)
	eq(host.events.size(),1,"later hits do not duplicate rewards or events")
	enemy.free()
	host.free()

func test_sleeping_target_is_not_damaged_before_encounter() -> void:
	var host := EnemyHost.new()
	var enemy := WhaleChapterForager.new()
	enemy.host=host
	enemy.data={"key":"qa.forager","alive":true,"hp":8,"max_hp":8}
	enemy.take_hit(3)
	eq(enemy.data.hp,8,"sleeping target retains original health")
	check(not enemy.withdrawing and enemy.pressure==0,"no off-screen pressure progress")
	enemy.free()
	host.free()

func test_counter_pressure_rewards_one_opening_only_and_heavy_alone_does_not_end_fight() -> void:
	var host := EnemyHost.new()
	var enemy := WhaleChapterForager.new()
	enemy.host=host
	enemy.data={"key":"qa.counter","alive":true,"hp":8,"max_hp":8}
	enemy.awake=true
	enemy.take_hit(3)
	check(not enemy.withdrawing,"ordinary heavy alone cannot skip reading the encounter")
	enemy.attack_serial=1
	enemy.change("recover")
	enemy.take_hit(1)
	eq(enemy.pressure,6,"one counter earns two bonus pressure")
	check(enemy.withdrawing and enemy.counter_hits==1,"counter completes earned retreat")
	enemy.free()
	host.free()

func test_repeated_hits_cannot_collect_same_counter_bonus() -> void:
	var host := EnemyHost.new()
	var enemy := WhaleChapterForager.new()
	enemy.host=host
	enemy.data={"key":"qa.once","alive":true,"hp":8,"max_hp":8}
	enemy.awake=true
	enemy.attack_serial=1
	enemy.change("recover")
	enemy.take_hit(1)
	enemy.take_hit(1)
	eq(enemy.pressure,4,"second pulse adds normal damage only")
	eq(enemy.counter_hits,1,"one reward per opening")
	enemy.reset_feeding()
	eq(enemy.pressure,0,"reset clears pressure")
	eq(enemy.counter_hits,0,"reset clears counters")
	enemy.free()
	host.free()

func test_tell_frames_are_distinct_and_follow_actual_duration() -> void:
	var enemy := WhaleChapterForager.new()
	var view := WhaleForagerVisual.new()
	view.hframes=4
	view.vframes=2
	view.clips=JSON.parse_string(FileAccess.get_file_as_string(CorpseCrabVisual.CONFIG)).clips
	enemy.state="tell"
	enemy.timer=0.4
	enemy.attack_kind="rush"
	view.present(enemy)
	eq(view.frame_index,0,"rush holds low starting pose")
	enemy.attack_kind="double"
	view.present(enemy)
	eq(view.frame_index,2,"double holds raised claw pose")
	enemy.attack_kind="sweep"
	view.present(enemy)
	eq(view.frame_index,1,"sweep raises claw progressively")
	enemy.state="recover"
	enemy.timer=0.2
	view.present(enemy)
	eq(view.frame_index,6,"recovery pose spans actual opening instead of fixed .14 seconds")
	view.free()
	enemy.free()
