extends "res://tests/whalebelly/xumen_atmosphere_qa.gd"
## Pause the whole scene, then advance only the registered distant effects.

func differences(a: Image,b: Image) -> int:
	var result:=0
	for y: int in range(0,a.get_height(),2):
		for x: int in range(0,a.get_width(),2):
			var p:=a.get_pixel(x,y)
			var q:=b.get_pixel(x,y)
			if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>.002: result+=1
	return result

func run() -> void:
	label="background"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory()))
	host=load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(RouteCampaign)
	host.set("route_id",label)
	host.qa=true
	host.qa_full_abilities=false
	host.integration_external_test=true
	root.add_child(host)
	current_scene=host
	await tick(30)
	var selected: Array=[3] if "--sample" in OS.get_cmdline_user_args() else [0,1,2,3,4,5,6]
	for index: int in selected:
		host.load_room(index,[],false)
		host.player_ui.close_all()
		host.reference_follow=false
		host.zoomed=false
		host.player.invulnerable=99999.0
		await tick(60)
		var id: String=host.room.id
		var current: XumenBackgroundCurrent=host.scenery.get_node("BackgroundCurrent")
		var lights: Array=host.scenery.find_children("WaterLight*","WhalebellySoftUnderwaterLight",true,false)
		check(id+" only registered distant paintings",current.materials.size()==2)
		check(id+" three feathered light volumes",lights.size()==3)
		check(id+" effects use campaign clock",absf(current.elapsed-host.clock)<.05 and absf(lights[0].time-host.clock)<.05)
		paused=true
		var held: float=current.elapsed
		var light_time: float=lights[0].time
		await tick(15)
		check(id+" water and shafts freeze on pause",current.elapsed==held and lights[0].time==light_time)
		current.update_at(0.0)
		for light: WhalebellySoftUnderwaterLight in lights: light.update_at(0.0)
		var base:=await frame_image()
		current.update_at(8.0)
		var water:=await frame_image()
		var moved:=differences(base,water)
		check(id+" water drift actually changes painted pixels",moved>100,moved)
		current.update_at(54.0)
		check(id+" water returns to source exposure",differences(base,await frame_image())<8)
		current.update_at(8.0)
		for light: WhalebellySoftUnderwaterLight in lights: light.hide()
		var unlit:=await frame_image()
		for light: WhalebellySoftUnderwaterLight in lights: light.show()
		var lit:=await frame_image()
		var painted:=differences(unlit,lit)
		check(id+" independent light volumes contribute",painted>100,painted)
		for light: WhalebellySoftUnderwaterLight in lights: light.update_at(9.0)
		var flowed:=differences(lit,await frame_image())
		check(id+" source light texture moves internally",flowed>20,flowed)
		(await frame_image()).save_png(output_directory().path_join(id+"-background-overview.png"))
		# Hide Far to isolate every actor/platform/UI and prove that their pixels
		# do not inherit a fullscreen exposure or distortion pass.
		host.scenery.get_node("Far").hide()
		var protected:=await frame_image()
		current.update_at(23.0)
		for light: WhalebellySoftUnderwaterLight in lights: light.update_at(24.0)
		check(id+" world actors platforms and UI are unchanged",differences(protected,await frame_image())==0)
		host.scenery.get_node("Far").show()
		for light: WhalebellySoftUnderwaterLight in lights:
			check(id+" light stays behind middle and battle",light.get_parent().name=="Depth" and light.get_parent().get_parent().z_index+light.z_index< -15 and light.external_clock)
		current.update_at(host.clock)
		for light: WhalebellySoftUnderwaterLight in lights: light.update_at(host.clock)
		paused=false
		await tick(20)
		check(id+" resume continues background time",current.elapsed>held and lights[0].time>light_time)
		if index==3:
			await measure()
			if "--clip" in OS.get_cmdline_user_args(): await capture_clip()
	var failures: int=checks.filter(func(c: Dictionary)->bool:return not c["pass"]).size()
	FileAccess.open(output_directory().path_join(label+".json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"performance":performance,"method":"Paused-scene shader-only renderer differences; independent source textures; 54-second exposure loop; protected World/UI isolation; shared-clock pause/resume. Camera/time fixtures, not gameplay or listening approval."},"\t"))
	print("XUMEN_BACKGROUND_COMPLETE failed=",failures)
	host.graceful_quit.call_deferred(1 if failures else 0)
