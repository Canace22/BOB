extends TestSuite

func grounded_player() -> TidePlayer:
	var floor_body:=StaticBody2D.new()
	floor_body.position=Vector2(0,200)
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(4000,20)
	collision.shape=shape
	floor_body.add_child(collision)
	add(floor_body)
	var p: TidePlayer=load("res://content/whalebelly/Player.tscn").instantiate()
	p.preload_actions=false
	p.position=Vector2(0,185)
	p.gravity=1050.0
	p.jump_height=154.71428571428572
	p.dash_duration=.2
	p.dash_speed=800.0
	p.jump_buffer_time=.12
	p.world_collision_mask=5
	p.world_bounds=Rect2(-5000,-5000,10000,10000)
	add(p)
	await physics_frames(24)
	check(p.is_on_floor(),"fixture settled on real collision floor")
	return p

func actual_jump_from_dash(key: String,direction: float,delay: int) -> void:
	var p: TidePlayer=await grounded_player()
	p.facing=direction
	check(p.request_action(key),key+" accepted")
	await physics_frames(delay)
	var before_y: float=p.position.y
	Input.action_press("tp_jump")
	await physics_frames(3)
	Input.action_release("tp_jump")
	check(p.velocity.y< -100.0,key+" preserves upward velocity after cancellation physics")
	check(not p.is_on_floor(),key+" actually leaves the collision floor")
	await physics_frames(4)
	check(p.position.y<before_y-20.0,key+" produces upward world displacement")
	check(not p.skill_controller.active,key+" no longer owns physics")
	eq(p.collision_mask,p.world_collision_mask,key+" restores world collision mask")

func test_crystal_dash_jump_cancel_right_moves_up() -> void:
	await actual_jump_from_dash("crystal_dash",1.0,2)

func test_crystal_dash_jump_cancel_left_moves_up() -> void:
	await actual_jump_from_dash("crystal_dash",-1.0,2)

func test_shadow_dash_recovery_jump_moves_up() -> void:
	await actual_jump_from_dash("shadow_dash",1.0,12)

func test_base_dash_keeps_lock_then_consumes_buffer_into_real_jump() -> void:
	var p: TidePlayer=await grounded_player()
	check(p.request_action("A1_dash"),"base dash accepted")
	await physics_frames(8)
	var before_y: float=p.position.y
	check(not p._can_jump_cancel(),"base dash early jump lock remains")
	Input.action_press("tp_jump")
	await physics_frames(9)
	Input.action_release("tp_jump")
	check(p.velocity.y< -100.0,"buffered base dash jump has real upward velocity")
	check(not p.is_on_floor() and p.position.y<before_y-15.0,"base dash buffer yields actual airborne displacement")
	eq(p.collision_mask,p.world_collision_mask,"base dash ended collision phase")
