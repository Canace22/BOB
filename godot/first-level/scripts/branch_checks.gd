extends Node
var host: Node
var checks: Array=[]

func run(main: Node) -> Dictionary:
	host=main
	host.game.reset_game()
	host.change_room(2)
	await get_tree().create_timer(0.3).timeout
	var elapsed=0.0
	# Local branch fixture starts at the normal left entrance; no player teleport,
	# invulnerability, damage boost, or direct reward assignment during traversal.
	while host.level.player.position.x<23.4*64 and elapsed<35:
		host.drive_e2e(1.0/60)
		elapsed+=1.0/60
		await get_tree().physics_frame
	release()
	var p=host.level.player
	checks.append({"id":"reach_branch_base","passed":p.position.x>=23.4*64})
	await get_tree().create_timer(0.2).timeout
	if not p.is_on_floor(): await get_tree().create_timer(0.5).timeout
	host.tap("jump")
	Input.action_press("right")
	elapsed=0
	while elapsed<2:
		if p.position.x>24.5*64: Input.action_release("right")
		elapsed+=1.0/60
		await get_tree().physics_frame
	release()
	checks.append({"id":"jump_to_U0","passed":p.is_on_floor() and absf(p.position.y-11.3*64)<8})
	host.tap("interact")
	await get_tree().create_timer(0.15).timeout
	host.tap("interact")
	await get_tree().create_timer(0.65).timeout
	checks.append({"id":"latch_and_fragment","passed":host.game.data.fragment and host.game.data.get("latch",false) and is_instance_valid(host.level.bridge)})
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		host.get_viewport().get_texture().get_image().save_png(host.evidence_dir+"/branch-open.png")
	Input.action_press("right")
	elapsed=0
	while p.position.x<30*64 and elapsed<5:
		elapsed+=1.0/60
		await get_tree().physics_frame
	release()
	await get_tree().create_timer(0.4).timeout
	checks.append({"id":"branch_returns_to_main","passed":p.position.x>=30*64 and p.is_on_floor()})
	Input.action_press("left")
	elapsed=0
	var jumped=false
	while p.position.x>27*64 and elapsed<4:
		if p.position.x<29.6*64 and p.is_on_floor() and not jumped:
			host.tap("jump")
			jumped=true
		elapsed+=1.0/60
		await get_tree().physics_frame
	release()
	await get_tree().create_timer(0.5).timeout
	checks.append({"id":"reverse_return","passed":p.position.x<27*64 and p.is_on_floor()})
	var count=host.game.events.filter(func(e):return e.event=="latch_open").size()
	checks.append({"id":"unique_latch","passed":count==1})
	host.game.hp=1
	p.invulnerable=0
	p.take_hit(p.position.x+50)
	await get_tree().create_timer(0.6).timeout
	checks.append({"id":"death_keeps_latch","passed":host.game.data.get("latch",false) and host.game.hp==4})
	host.change_room(2)
	await get_tree().create_timer(0.4).timeout
	checks.append({"id":"reenter_restores_bridge","passed":is_instance_valid(host.level.bridge) and not host.level.bridge.get_child(0).disabled and host.level.latch_anim==1.0})
	return {"passed":checks.all(func(c):return c.passed),"checks":checks,"events":host.game.events,"note":"Local fixture starts at R1-03 left door; traversal and interaction use Input actions. Separate full-start e2e required."}

func release() -> void:
	for action in ["left","right","jump","attack","heavy","heal","dash","interact"]:Input.action_release(action)
