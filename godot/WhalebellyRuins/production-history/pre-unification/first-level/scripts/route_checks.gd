extends Node
var host: Node
var checks: Array=[]
var normal_hash: String

func check(id: String,value: bool,detail: Dictionary={}) -> void:
	checks.append({"id":id,"passed":value,"detail":detail})
	print("ROUTE_CHECK ",id," ",value)

func release() -> void:
	for key in ["left","right","up","down","anchor","jump","interact"]:Input.action_release(key)

func wait_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func move_x(x: float,timeout: float=8.0) -> bool:
	var elapsed=0.0
	while elapsed<timeout:
		var dx=x*64-host.level.player.position.x
		if absf(dx)<8:break
		Input.action_release("left" if dx>0 else "right")
		Input.action_press("right" if dx>0 else "left")
		elapsed+=1.0/60
		await get_tree().physics_frame
	release()
	return absf(x*64-host.level.player.position.x)<12

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png(host.evidence_dir+"/"+name+".png")

func ascend(x: float,y: float) -> bool:
	var elapsed=0.0
	var p=host.level.player
	Input.action_press("up")
	while elapsed<1.34:
		var dx=x*64-p.position.x
		Input.action_release("left")
		Input.action_release("right")
		if absf(dx)>8:Input.action_press("right" if dx>0 else "left")
		if p.position.y<(y-0.65)*64:Input.action_release("up")
		elapsed+=1.0/60
		await get_tree().physics_frame
		if p.is_on_floor() and absf(p.position.y-y*64)<8:break
	release()
	await wait_seconds(0.7)
	return p.is_on_floor() and absf(p.position.y-y*64)<8

func grab(index: int) -> bool:
	var p=host.level.player
	var a=host.level.route_system.rings[index]
	p.facing=signf(a.x*64-p.position.x)
	host.tap("anchor")
	await wait_seconds(0.65)
	return p.anchor_index==index and p.anchor_arrived

func drop_to(x: float,y: float) -> bool:
	host.tap("jump")
	await move_x(x,3)
	await wait_seconds(1.0)
	return host.level.player.is_on_floor() and absf(host.level.player.position.y-y*64)<8

func run(main: Node) -> Dictionary:
	host=main
	normal_hash=FileAccess.get_sha256("user://save-v1.json") if FileAccess.file_exists("user://save-v1.json") else "absent"
	await wait_seconds(0.2)
	# Main progression gates before any temporary abilities.
	host.change_room(1)
	await wait_seconds(0.3)
	host.game.data.A2=false
	host.game.data.A3=false
	check("A2_gate_locked_before_unlock",host.level.route_system.denied(host.rooms[1].doors[2])!="")
	check("A3_gate_locked_before_unlock",host.level.route_system.denied(host.rooms[1].doors[3])!="")
	host.inspector.toggle_sandbox()
	await wait_seconds(0.3)
	check("sandbox_no_save",host.game.transient and host.route_sandbox)
	await move_x(5)
	for y in [13.5,10.0,6.5]:
		var success=await ascend(5,y)
		check("A2_platform_"+str(y),success,{"position":[host.level.player.position.x/64,host.level.player.position.y/64],"pressure":host.level.player.float_pressure})
	await capture("A2-three-platforms")
	host.tap("interact")
	await wait_seconds(0.4)
	check("E33_to_06",host.game.room_index==5)
	if host.game.room_index!=5:return finish()
	for item in [[5.4,8.5,17.0],[10.4,13.5,14.0],[15.4,18.5,11.0]]:
		await move_x(item[0])
		var success=await ascend(item[1],item[2])
		check("06_ascending_"+str(item[2]),success,{"position":[host.level.player.position.x/64,host.level.player.position.y/64]})
	await move_x(18)
	host.tap("interact")
	await wait_seconds(0.2)
	check("06_module_collected",host.game.data.get("R1-06_REWARD_0",false))
	await move_x(23)
	host.tap("interact")
	await wait_seconds(0.2)
	check("E34_remote_latch_stays_locked",host.game.room_index==5 and not host.game.data.get("SC_BLOWHOLE",false))
	await capture("06-remote-latch")
	# Reverse descent uses the same shelves; no teleport.
	for x in [18.0,14.0,9.0,3.0]:
		await move_x(x)
		await wait_seconds(0.8)
	await move_x(1)
	host.tap("interact")
	await wait_seconds(0.3)
	check("E33_returns_to_upper_02",host.game.room_index==1 and absf(host.level.player.position.y/64-6.5)<0.2)
	# Separate A3 fixture starts on the same main-route shelf before the first legal anchor.
	# Only this fixture positioning bypasses intervening combat; all ring traversal and door transitions use Input.
	host.level.player.position=Vector2(25,16)*64
	host.level.player.velocity=Vector2.ZERO
	await wait_seconds(0.1)
	for i in range(3):check("02_A3_anchor_"+str(i),await grab(i))
	check("02_A3_landing",await drop_to(33,10))
	host.tap("interact")
	await wait_seconds(0.3)
	check("E35_to_07",host.game.room_index==6)
	if host.game.room_index!=6:return finish()
	await move_x(5.3)
	for i in [0,1]:check("07_out_ring_"+str(i),await grab(i))
	check("07_middle_landing",await drop_to(12.5,15))
	await move_x(15.3)
	for i in [2,3]:check("07_out_ring_"+str(i),await grab(i))
	check("07_right_landing",await drop_to(22.5,15))
	for x in [24.5,27]:
		await move_x(x)
		host.tap("interact")
		await wait_seconds(0.2)
	check("07_both_rewards",host.game.data.get("R1-07_REWARD_0",false) and host.game.data.get("R1-07_REWARD_1",false))
	await move_x(27.6)
	host.tap("interact")
	await wait_seconds(0.2)
	check("07_no_right_exit",host.game.room_index==6 and host.rooms[6].doors.size()==1)
	await capture("07-right-wall-rewards")
	await move_x(21.5)
	for i in [3,2]:check("07_back_ring_"+str(i),await grab(i))
	check("07_return_middle",await drop_to(14.5,15))
	await move_x(11.5)
	for i in [1,0]:check("07_back_ring_"+str(i),await grab(i))
	check("07_return_left",await drop_to(4.5,15))
	await move_x(1)
	host.tap("interact")
	await wait_seconds(0.3)
	check("E35_returns_to_upper_02",host.game.room_index==1 and absf(host.level.player.position.y/64-10)<0.2)
	host.inspector.toggle_sandbox()
	await wait_seconds(0.3)
	check("sandbox_restores_progress",not host.game.transient and not host.game.data.get("A2",false) and not host.game.data.get("A3",false))
	return finish()

func finish() -> Dictionary:
	release()
	var after=FileAccess.get_sha256("user://save-v1.json") if FileAccess.file_exists("user://save-v1.json") else "absent"
	check("normal_save_untouched",after==normal_hash)
	return {"passed":checks.all(func(c):return c.passed),"checks":checks,"events":host.game.events,"fixture":"Temporary late abilities, starts R1-02; A2 roundtrip input-driven. A3 fixture starts x25 y16 on main shelf, then all anchors/doors/07 double crossing use Input. No claim later-chapter ability acquisition implemented."}
