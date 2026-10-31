extends SceneTree
## Independent QA fixture: actual Input jump and physics landing at wet/dry x.
var host: Node
var checks: Array=[]
var preserved: Dictionary={}
var output:="res://evidence/v02/water-final"

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if not "--qa-water-fixture" in OS.get_cmdline_user_args():
		push_error("Missing isolated QA flag")
		quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="):output=arg.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	for path in ["user://save-qa.json","user://save-qa.json.bak"]:
		preserved[path]=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	var normal=FileAccess.get_sha256("user://save-v1.json") if FileAccess.file_exists("user://save-v1.json") else "absent"
	host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await create_timer(0.2).timeout
	host.change_room(0)
	await create_timer(0.4).timeout
	check("qa_isolated",host.game.qa)
	var player=host.level.player
	player.position=Vector2(190,14*64-3)
	await create_timer(0.25).timeout
	var before=int(host.effect_counts.get("ripple",0))
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	await create_timer(0.15).timeout
	check("air_has_no_ripple",int(host.effect_counts.get("ripple",0))==before)
	var ticks=0
	while int(host.effect_counts.get("ripple",0))==before and ticks<120:
		ticks+=1
		await physics_frame
	check("landing_triggers_once",int(host.effect_counts.get("ripple",0))==before+1)
	var ripples=host.level.effects.bursts.filter(func(b):return b.kind=="ripple")
	var surface: Vector2=ripples[-1].at if not ripples.is_empty() else Vector2.ZERO
	check("ripple_on_visible_water",absf(surface.x-190)<1 and absf(surface.y-(14*64+95))<=2.5)
	await create_timer(0.10).timeout
	if DisplayServer.get_name()!="headless":
		# Evidence camera pans down briefly to expose the water below the HUD.
		# Player/physics/effects continue normally; only follow framing is held.
		host.level.set_process(false)
		host.level.camera.position_smoothing_enabled=false
		host.level.camera.position=Vector2(640,14*64-80)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/landing-ripple.png")
		host.level.set_process(true)
	await create_timer(0.35).timeout
	player.position=Vector2(400,14*64-3)
	await create_timer(0.25).timeout
	before=int(host.effect_counts.get("ripple",0))
	var land_before=int(host.effect_counts.get("land",0))
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	await create_timer(1.15).timeout
	check("dry_area_landed",int(host.effect_counts.get("land",0))==land_before+1)
	check("dry_area_has_no_ripple",int(host.effect_counts.get("ripple",0))==before)
	var after=FileAccess.get_sha256("user://save-v1.json") if FileAccess.file_exists("user://save-v1.json") else "absent"
	check("normal_save_untouched",normal==after)
	for path in preserved:
		if preserved[path]==null:
			if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
		else:
			var restored=FileAccess.open(path,FileAccess.WRITE)
			restored.store_buffer(preserved[path])
			restored.close()
	var result={"passed":checks.all(func(c):return c.passed),"checks":checks,"effect_counts":host.effect_counts,"surface":[surface.x,surface.y],"note":"Actual jump Input, physics landing; fixture sets positions at wet and dry parts of P0. Screenshot camera pans down to reveal water below HUD. Landing vibration affects visible water below ledge; no swimming or fluid simulation. QA files restored."}
	var file=FileAccess.open(output+"/water.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	quit(0 if result.passed else 1)

func check(id: String,passed: bool) -> void:
	checks.append({"id":id,"passed":passed})
	print("WATER_CHECK ",id," ",passed)
