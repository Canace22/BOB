extends "res://tests/whalebelly/xumen_layout_routes.gd"
## Independent entry fixtures; original Input only afterward. No real save access.
var case_name: String = "short_dash"
var observations: Dictionary = {}

func state() -> Dictionary:
	var result: Dictionary = super.state()
	result["velocity"] = [host.player.velocity.x,host.player.velocity.y]
	result["jumps"] = host.player.jump_count
	result["dash"] = host.has_ability("dash")
	return result

func events_named(id: String) -> Array:
	return host.events.filter(func(event: Dictionary) -> bool: return int(event.seq)>first_sequence and str(event.event)==id)

func short_dash() -> void:
	await fixture({"abilities":["anchor","dash"],"spawn":[570,585]})
	var ok: bool = await execute({"at":[960,585],"mode":"jump-dash","launch_x":620,"jump_hold":2,"dash_frame":8})
	check("short jump and original dash land below the low roof",ok and host.player.is_on_floor(),state())
	check("original dash actually released",not events_named("dash").is_empty())
	check("crossing causes no recovery or injury",events_named("soft_bed_recover").is_empty() and host.player.health==5)
	observations["reached"] = state()
	await shot("landing")

func soft_bed(at: int) -> void:
	var entries: Array = [[300,700],[570,585],[1020,585],[1280,735]]
	var centers: Array[float] = [395.0,760.0,1080.0,1365.0]
	await fixture({"abilities":["anchor","dash"],"spawn":entries[at]})
	check("soft-bed fixture begins grounded",host.player.is_on_floor(),state())
	var bed: Dictionary = host.room.soft_beds[at]
	for frame: int in 420:
		var delta: float = centers[at] - host.player.position.x
		action("tp_right",delta>7.0)
		action("tp_left",delta< -7.0)
		await tick(1)
		if not events_named("soft_bed_recover").is_empty() or host.player.health<=0: break
	release()
	await tick(50)
	var recovered: Array = events_named("soft_bed_recover")
	check("fall actually reaches the authored soft bed",not recovered.is_empty(),{"bed":bed,"last":state()})
	check("fall returns alive to a stable bank",host.player.health==4 and host.player.is_on_floor(),state())
	check("recovery does not change rooms",str(host.room.id)=="R1-05")
	check("one mistake produces one recovery",recovered.size()==1,recovered)
	if not recovered.is_empty():
		observations["recovery"] = recovered[0]
		check("actual fall lies inside this bed",float(recovered[0].data.position[0])>float(bed["from"]) and float(recovered[0].data.position[0])<float(bed.to))
	observations["after"] = state()
	await shot("recovered")

func hub_return() -> void:
	room_id = "R3-01"
	await fixture({"abilities":["anchor","dash"],"spawn":[256,2080],"completed":true})
	var door: Dictionary = host.room.doors.filter(func(value: Dictionary) -> bool: return str(value.get("to_id",""))=="R1-05")[0]
	observations["unchanged_hub_door"] = door.duplicate(true)
	check("hub still carries the old first-region spawn",door.spawn==[1450.0,563.0])
	var ok: bool = await execute({"at":[110,2080],"mode":"walk"})
	check("original input approaches the visible return door",ok,state())
	if ok: ok = await execute({"mode":"door","to":"R1-05"})
	check("actual door transition returns to the remapped room",ok,state())
	release()
	await tick(180)
	check("return settles on the new exit bank",str(host.room.id)=="R1-05" and host.player.is_on_floor() and host.player.position.x>1424.0 and host.player.position.x<1556.0 and absf(host.player.position.y-810.0)<4.0,state())
	check("return causes no injury, fall recovery or automatic bounce",host.player.health==5 and events_named("soft_bed_recover").is_empty() and not host.continuity.travelling and not host.player.transition_locked)
	observations["arrival"] = state()
	await shot("arrival")

func no_dash_probe(hold: int, second_at: int) -> void:
	await fixture({"abilities":["anchor"],"spawn":[570,585]})
	var ready: bool = await execute({"at":[620,585],"mode":"walk","tolerance_x":3})
	check("probe starts grounded without dash or float",ready and host.player.is_on_floor() and not host.has_ability("dash") and not host.has_ability("float"),state())
	var crossed: bool = false
	var second_sent: bool = false
	action("tp_right",true)
	action("tp_jump",true)
	for frame: int in 180:
		if frame==hold: action("tp_jump",false)
		if second_at>=0 and frame==second_at:
			action("tp_jump",true)
			second_sent = true
		if second_sent and frame==second_at+2: action("tp_jump",false)
		if host.player.position.x>=955.0: action("tp_right",false)
		await tick(1)
		if host.player.position.x>884.0 and absf(host.player.position.y-585.0)<5.0 and host.player.is_on_floor():
			crossed = true
			break
		if not events_named("soft_bed_recover").is_empty() or host.player.health<=0: break
	release()
	await tick(15)
	check("probe never receives or releases dash",not host.has_ability("dash") and events_named("dash").is_empty())
	check("unsuccessful traversal recovers instead of falling out of the room",crossed or (host.player.health==4 and not events_named("soft_bed_recover").is_empty()),state())
	observations = {"crossed":crossed,"hold_frames":hold,"second_press_frame":second_at,"jump_events":events_named("jump"),"recoveries":events_named("soft_bed_recover"),"final":state()}
	print("R105_NO_DASH_PROBE ",JSON.stringify(observations))
	await shot("probe")

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--case="): case_name=arg.trim_prefix("--case=")
	label = "R1-05-geometry-"+case_name
	room_id = "R1-05"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory()))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(RouteCampaign)
	host.set("route_id",label)
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(30)
	if case_name=="short_dash": await short_dash()
	elif case_name.begins_with("soft_bed_"): await soft_bed(int(case_name.trim_prefix("soft_bed_")))
	elif case_name=="hub_return": await hub_return()
	elif case_name=="normal_jump": await no_dash_probe(35,-1)
	elif case_name=="short_no_dash": await no_dash_probe(2,-1)
	elif case_name=="double_early": await no_dash_probe(2,18)
	elif case_name=="double_mid": await no_dash_probe(2,24)
	elif case_name=="double_late": await no_dash_probe(2,36)
	else: check("known case",false,case_name)
	release()
	var failures: int=checks.filter(func(value: Dictionary)->bool:return not value["pass"]).size()
	var result: Dictionary={"case":case_name,"checks":checks,"failures":failures,"observations":observations,"inputs":inputs,"trace":trace,"events":host.events,"save":host.save_path(),"method":"Declared room-entry/progress fixture; original Input only afterward; no transform/health/ability writes after fixture. No-dash probes report reachability rather than assuming a mandatory dash gate."}
	FileAccess.open(output_directory().path_join(label+".json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("R105_GEOMETRY_COMPLETE ",case_name," failed=",failures)
	host.graceful_quit.call_deferred(1 if failures else 0)
