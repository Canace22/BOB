extends "res://tests/whalebelly/xumen_layout_routes.gd"
## Fresh first-region playthrough. Progress carries across every door; Input only.

func segment(id: String, name_: String = "main", begin: int = 0, end: int = -1) -> bool:
	var steps: Array = host.rooms[index_of(id)].layout.qa_routes[name_].steps
	for i: int in range(begin, steps.size() if end < 0 else end):
		var ok: bool = await execute(steps[i])
		check("%s/%s/%02d" % [id, name_, i], ok, state())
		expectations(steps[i])
		if not ok: return false
	return true

func run() -> void:
	label = "continuous-main"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory()))
	host = load("res://content/whalebelly/main.tscn").instantiate()
	host.set_script(RouteCampaign)
	host.set("route_id", label)
	host.qa = true
	host.qa_full_abilities = false
	host.integration_external_test = true
	root.add_child(host)
	current_scene = host
	await tick(30)
	if "--reload" in OS.get_cmdline_user_args():
		await reload_saved_run()
		return
	# The only fixture is an empty, new-game entry. No invulnerability or grants.
	await fixture({"abilities":["anchor"]})
	var ok: bool = await segment("R1-01")
	if ok: ok = await segment("R1-02")
	if ok: ok = await segment("R1-03")
	if ok:
		ok = await segment("R1-04", "main", 0, 3)
		if ok:
			ok = await CampaignCrabDriver.fight(host)
			check("original Boss defeated through Input", ok, state())
			check("Boss earned dash", host.abilities.get("dash", false))
			await shot("boss")
		if ok: ok = await segment("R1-04", "main", 3)
	if ok:
		# The original physical camp provides the checkpoint before the final room.
		ok = await execute({"at":host.room.camp,"mode":"interact"})
		ok = ok and host.last_save_ok and int(host.checkpoint.room) == 4 and str(host.room.id)=="R1-05"
		check("physical camp saved", ok, state())
		if ok: ok = await segment("R1-05")
		check("first milestone and hub reached", ok and host.completed and str(host.room.id) == "R3-01")
	release()
	var failures: int = checks.filter(func(c: Dictionary) -> bool: return not c["pass"]).size()
	var report: Dictionary = {"checks":checks,"failures":failures,"inputs":inputs,"trace":trace,"events":host.events,"save":host.save_path(),"method":"One empty new-game entry; original Input only afterward. No transform, health, invulnerability or ability writes between rooms."}
	FileAccess.open(output_directory().path_join(label+".json"), FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("XUMEN_CONTINUOUS_COMPLETE failed=", failures)
	host.graceful_quit.call_deferred(1 if failures else 0)

func reload_saved_run() -> void:
	var save_before: String = FileAccess.get_file_as_string(host.save_path())
	check("prior process produced valid V6 save", not WhaleUISaveAccess.read(host.save_path(),host.rooms).is_empty())
	host.load_progress()
	host.load_room(host.room_index, host.checkpoint.get("pos",[]))
	host.player_ui.close_all()
	await tick(30)
	check("physical camp checkpoint restored", str(host.room.id)=="R1-05" and host.player.is_on_floor() and host.player.health>0,state())
	check("earned Boss and dash survived reload", host.defeated.get("R1-04:0",false) and host.abilities.get("dash",false))
	check("reload did not rewrite save", FileAccess.get_file_as_string(host.save_path())==save_before)
	var failures: int = checks.filter(func(c: Dictionary) -> bool: return not c["pass"]).size()
	FileAccess.open(output_directory().path_join("continuous-reload.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Independent process reads the previous Input playthrough's physical camp V6 save. No progress fixture or save writes."},"\t"))
	print("XUMEN_RELOAD_COMPLETE failed=",failures)
	host.graceful_quit.call_deferred(1 if failures else 0)
