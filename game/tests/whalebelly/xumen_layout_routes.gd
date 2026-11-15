extends SceneTree
## Room-entry fixtures, followed by original Input only. Does not write real saves.
class RouteCampaign extends WhalebellyMain:
	var route_id: String="default"
	func save_path() -> String:
		return "user://whalebelly/xumen-layout-route-%s-%s.json" % [str(ProjectSettings.globalize_path("res://").hash()),route_id]

const OUT := "res://build/qa/xumen-layout-integration"
var host: WhalebellyMain
var room_id := "R1-01"
var route_name := "main"
var route_file := ""
var label := ""
var down: Dictionary = {}
var inputs: Array[Dictionary] = []
var trace: Array[Dictionary] = []
var checks: Array[Dictionary] = []
var first_sequence: int = 0
var jump_release_frame: int = -1

func output_directory() -> String:
	var requested: String = OS.get_environment("XUMEN_QA_OUT")
	return requested if not requested.is_empty() else OUT

func _initialize() -> void: run.call_deferred()
func tick(frames: int) -> void:
	for i: int in frames:
		await physics_frame
		if jump_release_frame>=0 and Engine.get_physics_frames()>=jump_release_frame: action("tp_jump",false)
		if is_instance_valid(host) and is_instance_valid(host.player) and Engine.get_physics_frames() % 6 == 0:
			trace.append(state())
func state() -> Dictionary:
	return {"frame":Engine.get_physics_frames(),"room":host.room.id,"pos":[host.player.position.x,host.player.position.y],"health":host.player.health,"floor":host.player.is_on_floor(),"state":host.player.state}
func action(key: String, pressed: bool) -> void:
	if bool(down.get(key,false)) == pressed: return
	down[key] = pressed
	if key=="tp_jump" and not pressed: jump_release_frame=-1
	if pressed: Input.action_press(key)
	else: Input.action_release(key)
	inputs.append({"frame":Engine.get_physics_frames(),"action":key,"pressed":pressed})
func release() -> void:
	for key: String in down.keys(): action(key,false)
func check(name: String, passed: bool, detail: Variant=null) -> void:
	checks.append({"name":name,"pass":passed,"detail":detail})
	print("LAYOUT_ROUTE ","PASS " if passed else "FAIL ",name," ",detail if not passed else "")
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_directory().path_join(label+"-"+name+".png"))
func index_of(id: String) -> int:
	return host.rooms.find_custom(func(r: Dictionary)->bool:return str(r.id)==id)
func args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--room="): room_id=arg.trim_prefix("--room=")
		if arg.begins_with("--route="): route_name=arg.trim_prefix("--route=")
		if arg.begins_with("--routes="):
			var value: String=arg.trim_prefix("--routes=")
			if value.ends_with(".json"): route_file=value
			else: route_name=value
	label=room_id+"-"+route_name.replace("/","-")
func route_data() -> Dictionary:
	var routes: Variant=host.rooms[index_of(room_id)].get("layout",{}).get("qa_routes",{})
	if not route_file.is_empty():
		var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(route_file))
		if raw is Dictionary:
			if raw.has("rooms"):
				for r: Dictionary in raw.rooms:
					if str(r.id)==room_id: routes=r.get("layout",r).get("qa_routes",{})
			else: routes=raw.get("qa_routes",raw)
	if routes is Dictionary: return routes.get(route_name,{})
	if routes is Array:
		for r: Dictionary in routes:
			if str(r.get("name","main"))==route_name: return r
	return {}
func fixture(data: Dictionary) -> void:
	release()
	host.player_ui.close_all()
	await tick(12)
	host.abilities={"anchor":true,"dash":false,"float":false}
	var abilities: Variant=data.get("abilities",["anchor"])
	if abilities is Dictionary: host.abilities.merge(abilities,true)
	else:
		for flag: String in abilities: host.abilities[flag]=true
	host.defeated={}
	for id: String in data.get("defeated",[]): host.defeated[id]=true
	host.collected=data.get("collected",{}).duplicate(true)
	host.completed=bool(data.get("completed",false))
	host.health=5
	host.load_room(index_of(room_id),data.get("spawn",[]),false)
	host.player.automatic_doors=false
	if data.get("invulnerable",false): host.player.invulnerable=99999.0
	await tick(25)
	first_sequence=host.event_sequence
func edge_distance(direction: float) -> float:
	var point: Vector2=host.player.position
	var distance: float=INF
	for surface: Array in host.room.surfaces:
		for i: int in range(surface.size()-1):
			var a: Vector2=host.point(surface[i])
			var b: Vector2=host.point(surface[i+1])
			if absf(b.x-a.x)<0.001 or point.x<minf(a.x,b.x)-15 or point.x>maxf(a.x,b.x)+15: continue
			var y: float=lerpf(a.y,b.y,clampf((point.x-a.x)/(b.x-a.x),0,1))
			if absf(point.y-y)>55: continue
			var end: Vector2=host.point(surface[-1] if direction>0 else surface[0])
			distance=minf(distance,absf(end.x-point.x))
	return distance
func move(step: Dictionary) -> bool:
	var target: Vector2=host.point(step.at)
	var initial: int=host.room_index
	var mode: String=str(step.get("mode","walk"))
	var grounded: bool=bool(step.get("grounded",true))
	var hold: int=0
	var age: int=100
	var launched: bool=false
	var second: bool=false
	var dashed: bool=false
	for frame: int in int(step.get("budget",600)):
		if host.room_index!=initial or host.player.health<=0: break
		var p: WhalebellyCampaignPlayer=host.player
		var delta: Vector2=target-p.position
		if absf(delta.x)<float(step.get("tolerance_x",24)) and absf(delta.y)<float(step.get("tolerance_y",38)) and (not grounded or p.is_on_floor()):
			if grounded: release()
			return true
		action("tp_right",delta.x>10)
		action("tp_left",delta.x< -10)
		age+=1
		if hold>0:
			hold-=1
			if hold==0: action("tp_jump",false)
		var may_jump: bool=mode in ["jump","float","jump-float","jump-dash","double"]
		var launch: bool=age>38 and (p.grapple_hanging or (p.is_on_floor() and (edge_distance(signf(delta.x))<55 or (delta.y< -35 and absf(delta.x)<160))))
		if step.has("launch_x"): launch=p.is_on_floor() and age>38 and absf(p.position.x-float(step.launch_x))<16
		if may_jump and launch and hold==0:
			action("tp_jump",true);hold=int(step.get("jump_hold",35));age=0;launched=true;second=false;dashed=false
			jump_release_frame=Engine.get_physics_frames()+hold
		if (mode=="double" or step.get("double",false)) and launched and age>36 and hold==0 and not second and not p.is_on_floor() and p.velocity.y>=-20:
			action("tp_jump",true);hold=35;second=true
			jump_release_frame=Engine.get_physics_frames()+hold
		action("float",mode in ["float","jump-float"] and launched and hold==0 and not p.is_on_floor() and delta.y<20)
		if mode in ["dash","jump-dash"] and not dashed and (mode=="dash" or (launched and age>=int(step.get("dash_frame",12)))):
			action("tp_dash",true);dashed=true
		else: action("tp_dash",false)
		if step.get("attack",false): action("tp_attack",frame%30<2 and host.enemies.any(func(e:Dictionary)->bool:return e.alive and Vector2(e.pos).distance_to(p.position)<150))
		await tick(1)
	release()
	return false
func interact(step: Dictionary) -> bool:
	release();await tick(24)
	var initial: String=str(host.room.id)
	var door: CampaignDoorway=host.continuity.nearby_door()
	if str(step.get("mode",""))=="door":
		check(str(step.get("label","door"))+" visible prompt",door!=null and host.player_ui.data.prompt_door()==door)
	action("tp_interact",true);await tick(3);action("tp_interact",false)
	for frame: int in int(step.get("budget",150)):
		await tick(1)
		if step.has("to") and str(host.room.id)==str(step.to) and not host.continuity.travelling and not host.player.transition_locked: return true
		if not step.has("to") and frame>=40 and not host.player.transition_locked: return true
	return not step.has("to") and str(host.room.id)==initial
func execute(step: Dictionary) -> bool:
	var mode: String=str(step.get("mode","walk"))
	if mode=="fight":
		release()
		var won: bool=await CampaignCrabDriver.fight(host,int(step.get("budget",9000)))
		check("boss defeated by original inputs",won and host.defeated.get("R1-04:0",false) and host.abilities.get("dash",false),state())
		return won and host.defeated.get("R1-04:0",false) and host.abilities.get("dash",false)
	if mode=="wait": release();await tick(int(step.get("frames",45)));return true
	if mode=="grapple":
		release();await tick(3)
		action("grapple",true);await tick(2);action("grapple",false)
		for frame: int in int(step.get("budget",120)):
			await tick(1)
			if host.player.grapple_hanging:
				return not step.has("at") or host.player.position.distance_to(host.point(step.at))<45
		return false
	if mode=="drop" and step.get("through_membrane",false):
		release();await tick(60)
		action("down",true);action("tp_jump",true);await tick(3);action("tp_jump",false);action("down",false)
	if step.has("at") and not await move(step): return false
	if mode in ["door","interact"]: return await interact(step)
	return true
func expectations(step: Dictionary) -> void:
	var wanted: Dictionary=step.get("expect",{})
	for flag: String in wanted.get("abilities",[]): check("ability "+flag,host.abilities.get(flag,false))
	for id: String in wanted.get("collected",[]): check("collected "+id,host.collected.get(id,false))
	for event: String in wanted.get("events",[]):
		check("event "+event,host.events.any(func(e: Dictionary)->bool:return int(e.seq)>first_sequence and str(e.get("event",""))==event))
	if wanted.has("room"): check("room "+str(wanted.room),str(host.room.id)==str(wanted.room))
	if wanted.has("health_min"): check("minimum health",host.player.health>=int(wanted.health_min),state())
	if wanted.has("restriction_contains"):
		var door: CampaignDoorway=host.continuity.nearby_door()
		check("door restriction",door!=null and door.restriction().contains(str(wanted.restriction_contains)))
	if wanted.has("prompt_contains"): check("interaction prompt",host.player_ui.data.prompt().contains(str(wanted.prompt_contains)))
func run() -> void:
	args();DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory()))
	host=load("res://content/whalebelly/main.tscn").instantiate();host.set_script(RouteCampaign)
	host.set("route_id",label)
	host.qa=true;host.qa_full_abilities=false;host.integration_external_test=true
	root.add_child(host);current_scene=host;await tick(30)
	var data: Dictionary=route_data()
	check("authored route exists",not data.is_empty(),{"room":room_id,"route":route_name,"file":route_file})
	if not data.is_empty():
		await fixture(data.get("fixture",{}));await shot("start")
		for i: int in data.get("steps",[]).size():
			var step: Dictionary=data.steps[i]
			var ok: bool=await execute(step)
			check(str(step.get("label","step-%02d"%i)),ok,state());expectations(step)
			await shot("%02d"%i)
			if not ok: break
	release()
	var events: Array=host.events.filter(func(e:Dictionary)->bool:return int(e.seq)>first_sequence)
	var failures: int=checks.filter(func(c:Dictionary)->bool:return not c["pass"]).size()
	var result: Dictionary={"checks":checks,"failures":failures,"fixture":data.get("fixture",{}),"inputs":inputs,"trace":trace,"events":events,"save":host.save_path(),"method":"Declared room-entry/progress fixture, followed only by original Input; no transform writes after fixture, no F9 or automatic ability grants. Terrain-route fixture is not continuous new-game/difficulty evidence."}
	FileAccess.open(output_directory().path_join(label+".json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("XUMEN_LAYOUT_ROUTE_COMPLETE ",label," failed=",failures)
	host.graceful_quit.call_deferred(1 if failures else 0)
