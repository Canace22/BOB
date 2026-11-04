extends TestSuite
## Temporary atlas spec isolates phase timing from pending production-art sync.

func fixture(direction: float) -> TideActionVisual:
	for wall: bool in [false,true]:
		var solid:=StaticBody2D.new()
		solid.position=Vector2(direction*380,0) if wall else Vector2(0,200)
		var collider:=CollisionShape2D.new()
		var shape:=RectangleShape2D.new()
		shape.size=Vector2(20,600) if wall else Vector2(6000,20)
		collider.shape=shape;solid.add_child(collider);add(solid)
	var p: TidePlayer=load("res://content/whalebelly/Player.tscn").instantiate()
	p.preload_actions=false;p.position=Vector2(0,185)
	p.world_bounds=Rect2(-5000,-5000,10000,10000)
	add(p)
	await physics_frames(24)
	check(p.is_on_floor(),"phase fixture rests on real collision floor")
	p.facing=direction
	var view:=TideActionVisual.new()
	p.add_child(view);view.setup(p,94.0)
	var spec: Dictionary=view.manifest.idle.duplicate(true)
	spec.frame_count=24;spec.fps=24.0;spec.loop=false;spec.fx=null
	spec.event_phase=0.01 # Deliberately irrelevant: explicit phases must win.
	spec.phases={"charge":[0.0,14.0/24.0],"flight":[14.0/24.0,23.0/24.0],"exit":[23.0/24.0,1.0]}
	var rect: Array=spec.body.frames[0]
	spec.body.frames=[]
	for i: int in range(24): spec.body.frames.append(rect.duplicate())
	view.manifest.crystal_dash=spec;view.available.crystal_dash=true
	return view

func charge_fly_and_hit_wall(direction: float) -> void:
	var view: TideActionVisual=await fixture(direction)
	var p: TidePlayer=view.actor
	Input.action_press("tp_long_dash")
	await physics_frames(15)
	view.update(1.0/60.0,0.0)
	check(view.current_key=="crystal_dash" and view.frame_index<14,"held input uses only charge poses")
	check(not p.skill_controller.active,"charge preview does not own movement")
	await physics_frames(30)
	view.update(1.0/60.0,0.0)
	eq(view.frame_index,13,"ready charge holds final charge frame without entering flight")
	var before: Vector2=p.position
	Input.action_release("tp_long_dash")
	await physics_frames(2)
	view.update(1.0/60.0,0.0)
	check(p.skill_controller.active,"real release accepts long dash")
	check(view.frame_index>=14 and view.frame_index<=22,"release immediately selects flight range")
	check(p.velocity.x*direction>900 and (p.position.x-before.x)*direction>5,"physical long dash baseline is unchanged")
	check(view.sprite.global_transform.x.x*direction>0,"flight body follows one actual facing flip")
	var exit_seen: bool=false
	for i: int in range(45):
		await physics_frames(1)
		view.update(1.0/60.0,0.0)
		if p.skill_controller.active:
			check(view.frame_index>=14 and view.frame_index<=22,"active dash cannot return to charge or show exit")
		elif view.current_key=="crystal_dash":
			exit_seen=true
			eq(view.frame_index,23,"wall finish uses exit frame")
	check(exit_seen,"real wall collision produces a brief exit pose")
	check(not p.skill_controller.active and absf(p.position.x)<380,"wall exits physics without crossing solid wall")
	eq(view.action_phases.crystal_exit_left,0.0,"exit pose expires without extending skill lock")
	p.animation_tag.emit("crystal_dash:end")
	p.animation_tag.emit("hit:start")
	eq(view.action_phases.crystal_exit_left,0.0,"a new hit state immediately clears presentation tail")
	p.animation_tag.emit("crystal_dash:end")
	p.controls_enabled=false
	view.choose_key(1.0/60.0)
	eq(view.action_phases.crystal_exit_left,0.0,"room or UI input lock clears pending exit")

func test_crystal_charge_flight_wall_exit_right() -> void:
	await charge_fly_and_hit_wall(1.0)

func test_crystal_charge_flight_wall_exit_left() -> void:
	await charge_fly_and_hit_wall(-1.0)

func test_attack_hold_release_survives_physics_edge_and_is_once() -> void:
	var view: TideActionVisual=await fixture(1.0)
	var p: TidePlayer=view.actor
	Input.action_press("tp_attack")
	await physics_frames(45)
	check(p.skill_controller.input.attack_tracking and p.skill_controller.input.attack_hold>=0.55,"attack charge really tracked held input")
	Input.action_release("tp_attack")
	await physics_frames(2)
	check(p.skill_controller.active and p.skill_controller.visual_key=="great_slash","held J release enters charged slash across physics boundary")
	var accepted_id: int=p.skill_controller.attack_id
	await physics_frames(8)
	eq(p.skill_controller.attack_id,accepted_id,"released input cannot retrigger on later physics ticks")

func test_input_lock_and_damage_require_new_press_after_charge_clear() -> void:
	var view: TideActionVisual=await fixture(1.0)
	var p: TidePlayer=view.actor
	for action: String in ["tp_long_dash","tp_attack"]:
		p.state_duration=0.0;p.skill_controller.cancel()
		Input.action_press(action)
		await physics_frames(45)
		p.controls_enabled=false
		await physics_frames(3)
		check(not p.skill_controller.input.attack_tracking and not p.skill_controller.input.long_tracking,"input lock clears both charge trackers")
		p.controls_enabled=true
		await physics_frames(3)
		Input.action_release(action)
		await physics_frames(2)
		check(not p.skill_controller.active,"resume while held then release cannot emit stale charge")
		Input.action_press(action)
		await physics_frames(45)
		check(p.take_damage(1,Vector2(50,0),true),"real damage interrupts renewed hold")
		Input.action_release(action)
		await physics_frames(2)
		check(not p.skill_controller.active,"release after damage cannot start charged skill")
		check(not p.skill_controller.input.attack_tracking and not p.skill_controller.input.long_tracking,"damage clears charge state")
