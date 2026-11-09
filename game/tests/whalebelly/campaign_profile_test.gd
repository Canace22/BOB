@warning_ignore_start("untyped_declaration")
extends SceneTree
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func step(n:int) -> void:
	for i in range(n):await physics_frame
func check(name:String,ok:bool,details:Variant=null) -> void:
	checks.append({"name":name,"pass":ok,"details":details});print("PASS " if ok else "FAIL ",name," ",details)
func run() -> void:
	var scene=load("res://content/whalebelly/test/PlayerTest.tscn").instantiate();scene.show_guide=false;root.add_child(scene);current_scene=scene
	var p:TidePlayer=scene.player
	await step(10)
	check("baseline_265_1050_5hp",p.max_speed==265 and p.gravity==1050 and p.health==5)
	check("capsule_28_65",p.get_node("CollisionShape2D").shape is CapsuleShape2D and p.collision_size==Vector2(28,65))
	check("spawn_floor",p.is_on_floor())
	Input.action_press("tp_right");await step(15);Input.action_release("tp_right");check("baseline_speed",absf(p.velocity.x-265)<.1,p.velocity.x)
	await step(15);check("stop",absf(p.velocity.x)<1)
	p.position=Vector2(180,850);p.velocity=Vector2.ZERO;await step(5)
	Input.action_press("tp_jump");var ground:float=p.position.y;var peak:float=ground
	for i in range(90):await physics_frame;peak=minf(peak,p.position.y)
	Input.action_release("tp_jump");check("baseline_jump",ground-peak>140 and ground-peak<165,ground-peak)
	p.position=Vector2(459,850);p.velocity=Vector2.ZERO;p.facing=1;p.soul=0;await step(5)
	Input.action_press("tp_attack");await step(1);Input.action_release("tp_attack");await step(25)
	check("baseline_damage_and_soul",scene.targets[0].health==99 and p.soul==11,{"target":scene.targets[0].health,"soul":p.soul})
	p.invulnerable=0;p.take_damage(1);check("baseline_damage_received",p.health==4)
	check("full_15_animation_library",p.anim.get_animation_library("full").get_animation_list().size()==15)
	check("ray_positions",p.get_node("WallRight").position.y==-32.5 and p.get_node("WallRight").target_position.x==17)
	check("legacy_timing_reused",p.jump_buffer_time==.12 and p.coyote_time==.12 and p.dash_cooldown==.7)
	var failed:int=checks.filter(func(c):return not c.pass).size()
	var file:=FileAccess.open("res://build/qa/whalebelly/tide-main-integration/independent-tests.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"));file.close()
	print("CAMPAIGN_PROFILE_TEST_COMPLETE failures=",failed);quit(1 if failed else 0)
