extends TestSuite
## 连按必须以实际起手推进段数；判定使用武器/有效弧光包围范围，不能按Boss中心特判。
class Target extends Node2D:
	var hits: int=0
	func _ready() -> void: add_to_group("tide_targets")
	func hurt_rect() -> Rect2: return Rect2(global_position-Vector2(2,2),Vector2(4,4))
	func take_hit(_amount: int) -> void: hits+=1

func fixture() -> Node2D:
	var arena: Node2D=load("res://tests/whitebox_combat/main.tscn").instantiate()
	add(arena)
	arena.enemy.auto_attack=false
	arena.enemy.position.x=1100
	await physics_frames(8)
	return arena

func key(down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_J
	event.keycode=KEY_J
	event.pressed=down
	Input.parse_input_event(event)

func after_each() -> void:
	key(false)
	await super.after_each()

func test_rapid_taps_keep_alternating_and_finish_swing() -> void:
	var arena: Node2D=await fixture()
	var p: TideCombatPlayer=arena.player
	var starts: Array[String]=[]
	var tips: Array[int]=[]
	var last_id: int=-1
	for frame: int in 110:
		if frame<70 and frame%6==0: key(true)
		if frame%6==1: key(false)
		await physics_frames(1)
		var id: int=p.skill_controller.attack_id
		if p.skill_controller.active and id!=last_id:
			starts.append(p.skill_controller.visual_key)
			tips.append(0)
			last_id=id
		if p.skill_controller.active and not tips.is_empty(): tips[-1]=maxi(tips[-1],p.action_visual.frame_index)
	check(starts.size()>=3,"rapid taps produce an actual attack chain")
	for i: int in starts.size():
		eq(starts[i],"strike1" if i%2==0 else "strike2","accepted swings alternate despite rejected extra taps")
		check(tips[i]>=12,"swing reaches weapon return frames before next normal attack")

func test_both_strikes_use_visible_envelope_and_single_damage() -> void:
	var arena: Node2D=await fixture()
	var p: TideCombatPlayer=arena.player
	p.set_physics_process(false)
	for action: String in ["strike_01","strike2"]:
		p.skill_controller.cancel()
		p.state="idle"
		p.state_duration=0.0
		p.facing=1.0
		var near:=Target.new()
		near.position=p.position+Vector2(48,-50)
		add(near)
		var far:=Target.new()
		far.position=p.position+Vector2(150,-50)
		add(far)
		var high:=Target.new()
		high.position=p.position+Vector2(40,-118)
		add(high)
		check(p.request_action(action),"normal attack accepted")
		p.state_time=0.16
		p._update_action_events()
		p._update_action_events()
		eq(near.hits,1,"visible weapon contact hits once")
		eq(far.hits,0,"beyond weapon and arc never hits")
		eq(high.hits,0,"above visible swing never hits")
		near.queue_free()
		far.queue_free()
		high.queue_free()
		await physics_frames(1)

func test_swing_cannot_be_restarted_early_but_defense_still_cancels() -> void:
	var arena: Node2D=await fixture()
	var p: TideCombatPlayer=arena.player
	check(p.request_action("strike_01"),"first attack accepted")
	await physics_frames(13)
	check(not p.request_action("strike2"),"next attack cannot cut the outgoing weapon short")
	check(p.request_action("parry"),"guard still cancels attack recovery")
	p.skill_controller.cancel()
	p.state="idle"
	p.state_duration=0.0
	check(p.request_action("strike_01"),"new swing starts")
	check(p.try_backstep(),"backstep still force-cancels startup")
	check(not p.request_action("strike_01"),"normal attack cannot replace the dedicated retreat cut")

func test_first_arc_contact_frame_is_not_skipped_at_sixty_hz() -> void:
	var arena: Node2D=await fixture()
	var p: TideCombatPlayer=arena.player
	p.set_physics_process(false)
	check(p.request_action("strike_01"),"first swing begins")
	# 100ms事件在浮点累计后可到116ms才跨过，峰值弧光仍须至少显示一个物理帧。
	p.state_time=7.0/60.0
	p._update_action_events()
	p.action_visual.update(1.0/60.0,0.0)
	check(p.action_visual.effect.visible,"real release shows authored arc")
	var actual: AtlasTexture=p.action_visual.effect.texture
	var contact: AtlasTexture=p.action_visual.load_clip("strike1").fx[4]
	eq(actual.region,contact.region,"first visible arc uses the contact frame, not its nearly invisible tail")
