extends SceneTree
var host: Node2D
var rows: Array = []
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i: int in range(n): await physics_frame
func note(id: String,passed: bool,detail: Dictionary={}) -> void:
	detail["name"]=id
	detail["pass"]=passed
	rows.append(detail)
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://evidence/"+name+".png")
func run() -> void:
	host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	host.qa=true
	host.completed=false
	host.load_room(2,[820,615])
	await frames(80)
	var mech: Node2D=host.scenery.get_node("VisualMechanisms")
	var world: Sprite2D=host.scenery.get_node("World/WorldOriginalPixels")
	var sag: float=mech.membrane_drop
	var rendered: float=world.material.get_shader_parameter("membrane_drop")
	note("tongue_visual_collision_same_depression",sag>30 and absf(rendered-sag)<0.01,{"sag_px":sag,"shader_px":rendered,"player_y":host.player.position.y,"events":mech.membrane_events})
	await shot("membrane-loaded")
	Input.action_press("left")
	await frames(75)
	Input.action_release("left")
	await frames(110)
	note("tongue_recovers_after_unload",mech.membrane_drop<0.5,{"drop":mech.membrane_drop})
	host.load_room(3,[380,708])
	await frames(5)
	mech=host.scenery.get_node("VisualMechanisms")
	note("boss_door_initially_closed",mech.gate_alpha>0.99)
	host.defeated["R1-04:0"]=true
	await frames(100)
	note("boss_door_opens_visually",mech.gate_alpha<0.01 and mech.gate.modulate.a<0.01)
	await shot("gate-open")
	host.load_room(3,[380,708])
	await frames(3)
	mech=host.scenery.get_node("VisualMechanisms")
	note("boss_door_reentry_preserves_state",mech.gate_alpha<0.01)
	host.load_room(1,[1060,650])
	host.practice=true
	host.abilities={"dash":true,"float":true,"anchor":true}
	await frames(5)
	mech=host.scenery.get_node("VisualMechanisms")
	note("room02_four_door_areas_three_rings",mech.trigger_nodes.size()==4 and mech.rings_node.get_child_count()==3)
	Input.action_press("grapple")
	await frames(12)
	Input.action_release("grapple")
	note("anchor_has_event_and_pulse",mech.last_ring!=Vector2.INF and mech.ring_pulse>0,{"pulse":mech.ring_pulse,"events":host.events.slice(-5)})
	host.load_room(6,[1300,569])
	await frames(8)
	mech=host.scenery.get_node("VisualMechanisms")
	var y0: float=mech.reward.position.y
	await frames(25)
	note("reward_independently_floats",absf(mech.reward.position.y-y0)>0.2)
	Input.action_press("interact")
	await frames(3)
	Input.action_release("interact")
	note("reward_hides_on_pickup",host.collected.get("R1-07",false) and not mech.reward.visible)
	await shot("reward-collected")
	host.load_room(6,[300,570])
	await frames(4)
	note("reward_reentry_preserves_state",not host.scenery.get_node("World/RewardArt").visible)
	var passed: int=0
	for row: Dictionary in rows:
		if row.pass:passed+=1
	FileAccess.open("res://evidence/mechanisms.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"total":rows.size(),"tests":rows},"\t"))
	print("MECHANISMS ",passed,"/",rows.size())
	host.queue_free()
	await frames(10)
	quit(0 if passed==rows.size() else 1)
