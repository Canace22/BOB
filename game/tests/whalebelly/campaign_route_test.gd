@warning_ignore_start("untyped_declaration")
extends SceneTree
var host:Node2D
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func step(n:int) -> void:
	for i in range(n):await physics_frame
func check(name:String,ok:bool,detail:Variant=null) -> void:
	checks.append({"name":name,"pass":ok,"detail":detail});print("PASS " if ok else "FAIL ",name," ",detail)
func drive(target:Vector2,next_room:int=-99,budget:int=1100) -> bool:
	var room:int=host.room_index
	var jump_hold:int=0
	for frame in range(budget):
		if host.room_index!=room:
			print("ROUTE_ROOM_CHANGED ",room," -> ",host.room_index)
			host.release_controls();return host.room_index==next_room
		var p=host.player
		var delta:Vector2=target-p.position
		if absf(delta.x)<24 and absf(delta.y)<65:
			host.release_controls();return true
		Input.action_release("left");Input.action_release("right")
		if absf(delta.x)>12:Input.action_press("right" if delta.x>0 else "left")
		if jump_hold>0:
			jump_hold-=1
			if jump_hold==0:Input.action_release("jump")
		if frame%55==0 and jump_hold==0 and (delta.y< -35 or absf(p.velocity.x)<30):
			Input.action_press("jump");jump_hold=34
		if frame%26==0 and host.enemies.any(func(e):return e.alive and Vector2(e.pos).distance_to(p.position)<180):Input.action_press("attack")
		if frame%26==2:Input.action_release("attack")
		if p.is_on_floor():
			for surface:Array in host.room.surfaces:
				var edge:Vector2=host.point(surface[-1] if delta.x>0 else surface[0])
				if jump_hold==0 and absf(p.position.x-edge.x)<75 and absf(p.position.y-edge.y)<50 and absf(delta.x)>95:
					Input.action_press("jump");jump_hold=34
		await physics_frame
	host.release_controls();return false
func run() -> void:
	host=load("res://content/whalebelly/main.tscn").instantiate();host.qa=true;host.qa_full_abilities=false;host.integration_external_test=true;root.add_child(host);current_scene=host
	await step(40)
	if "--reload-fixture" in OS.get_cmdline_user_args():
		host.load_progress();host.load_room(host.room_index,host.checkpoint.pos);await step(30)
		check("independent_process_v6_reload",host.room_index==3 and host.abilities.dash and host.defeated.get("R1-04:0",false) and host.player.is_on_floor())
		check("reload_ui_binding",host.player_ui.player==host.player and host.player_ui.health_value==5)
	else:
		for index in range(3):
			if host.room_index!=index:check("route_room_%d"%index,false,host.room_index);break
			var door:Dictionary={}
			for d:Dictionary in host.room.doors:
				if int(d.to)==index+1:door=d
			var passed:bool=await drive(host.point(door.pos),index+1)
			check("continuous_walk_%d"%index,passed,{"room":host.room_index,"position":host.player.position,"health":host.health})
			if host.room_index==index:
				Input.action_press("right");await step(20);Input.action_release("right")
			check("automatic_door_%d"%index,host.room_index==index+1,host.room_index)
			await step(35)
		if host.room_index==3:
			check("boss_camp_walk",await drive(Vector2(105,648)),host.player.position)
			await step(30);Input.action_press("interact");await step(1);Input.action_release("interact");await step(40)
			check("boss_camp_heals",host.health==5 and host.checkpoint.room==3,host.health)
			var boss:Dictionary=host.enemies[0]
			var approached:bool=await drive(Vector2(830,710))
			check("boss_approach",approached,host.player.position)
			for i in range(600):
				if not boss.alive:break
				Input.action_release("left");Input.action_release("right")
				Input.action_press("right" if Vector2(boss.pos).x>host.player.position.x else "left")
				if i%26==0:Input.action_press("attack")
				if i%90==4:Input.action_press("tp_orb")
				if i%90==5:Input.action_release("tp_orb")
				if i%26==2:Input.action_release("attack")
				await physics_frame
			host.release_controls();check("boss_normal_combat",not boss.alive and host.abilities.dash,host.health)
			if not boss.alive:
				check("boss_exit_walk",await drive(Vector2(1505,710),4),host.player.position)
				if host.room_index==3:Input.action_press("right");await step(20);Input.action_release("right")
				check("boss_door",host.room_index==4)
		if host.room_index==4:
			for x in [600,960,1450,1515]:check("throat_walk_%d"%x,await drive(Vector2(x,560)),host.player.position)
			Input.action_press("interact");await step(1);Input.action_release("interact");await step(40)
			check("campaign_exit",host.completed)
	var failed:int=checks.filter(func(c):return not c.pass).size()
	var name:String="reload" if "--reload-fixture" in OS.get_cmdline_user_args() else "route"
	var f:=FileAccess.open("res://build/qa/whalebelly/tide-main-integration/"+name+"-tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failed":failed},"\t"));f.close()
	print("CAMPAIGN_ROUTE_COMPLETE ",name," checks=",checks.size()," failed=",failed)
	host.graceful_quit(1 if failed else 0)
